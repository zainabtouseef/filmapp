import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/projects/project_models.dart';
import '../../../core/projects/projects_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../general_public/routes/general_public_routes.dart';
import '../models/dp_candidate.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_candidate_card.dart';
import '../widgets/dp_empty_state.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../../../shared/layout/kyc_status_banner.dart';
import '../../../shared/widgets/cine_marketplace_card.dart';
import '../../../shared/marketplace/marketplace_routes.dart';

const _categoryKeys = [
  'All',
  'Actors',
  'Models',
  'Influencers',
  'Crew',
  'Locations',
  'Media & Equipment',
  'Agencies',
  'Distribution',
];

class DPMarketplaceDiscoveryScreen extends StatefulWidget {
  final String? initialCategory;
  final String? projectId;
  final bool publicBuyerMode;
  final bool browseOnly;

  const DPMarketplaceDiscoveryScreen({
    super.key,
    this.initialCategory,
    this.projectId,
    this.publicBuyerMode = false,
    this.browseOnly = false,
  });

  @override
  State<DPMarketplaceDiscoveryScreen> createState() =>
      _DPMarketplaceDiscoveryScreenState();
}

class _DPMarketplaceDiscoveryScreenState
    extends State<DPMarketplaceDiscoveryScreen> {
  late String _category = _normalizeCategory(widget.initialCategory);
  bool _verifiedOnly = false;
  bool _newOnly = false;
  final _search = TextEditingController();
  String? _projectId;
  Future<List<DpCandidate>>? _candidatesFuture;
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _projectId ??= widget.projectId;
    _candidatesFuture ??= _load();
  }

  Future<List<DpCandidate>> _load() async {
    if (!_categoryHasLiveFeed(_category)) {
      return const <DpCandidate>[];
    }
    final auth = AuthScope.maybeOf(context);
    if (auth == null || !auth.isAuthenticated) {
      throw const ApiException(
        code: 'auth.required',
        message: 'Sign in to load the live marketplace.',
      );
    }
    if (widget.publicBuyerMode || widget.browseOnly) {
      final listings = await auth.marketplaceListings(
        type: _publicListingType(_category),
        query: _search.text.trim(),
      );
      return listings.map((item) => item.toCandidate()).toList();
    }
    final discovery = await auth.directorDiscovery(
      category: _category,
      query: _search.text.trim(),
    );
    return discovery.items.map((item) => item.toCandidate()).toList();
  }

  String? _publicListingType(String category) {
    return switch (category) {
      'Actors' => 'actor',
      'Models' => 'model',
      'Influencers' => 'influencer',
      'Locations' => 'location',
      'Media & Equipment' => 'equipment',
      'Crew' => 'crew',
      'Agencies' => 'agency',
      'Distribution' => 'distribution',
      _ => null,
    };
  }

  bool _categoryHasLiveFeed(String category) {
    return category == 'All' ||
        category == 'Actors' ||
        category == 'Models' ||
        category == 'Influencers' ||
        category == 'Crew' ||
        category == 'Locations' ||
        category == 'Media & Equipment' ||
        category == 'Agencies' ||
        category == 'Distribution';
  }

  bool _matchesFilters(DpCandidate candidate) {
    final categoryMatch = _category == 'All' || candidate.category == _category;
    final trustMatch = (!_verifiedOnly || candidate.verified) &&
        (!_newOnly || candidate.isNew);
    final query = _search.text.trim().toLowerCase();
    final queryMatch = query.isEmpty ||
        candidate.name.toLowerCase().contains(query) ||
        candidate.city.toLowerCase().contains(query) ||
        candidate.category.toLowerCase().contains(query) ||
        candidate.rateRange.toLowerCase().contains(query) ||
        candidate.notes.toLowerCase().contains(query) ||
        candidate.skills.any((skill) => skill.toLowerCase().contains(query));
    return categoryMatch && trustMatch && queryMatch;
  }

  void _setCategory(String category) {
    setState(() {
      _category = _normalizeCategory(category);
      _candidatesFuture = _load();
    });
  }

  void _searchChanged() {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _candidatesFuture = _load());
    });
  }

  String _normalizeCategory(String? category) {
    return category == 'Talent' ? 'Actors' : (category ?? 'All');
  }

  Future<void> _openMarketplaceFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, sheetSetState) {
          void update(VoidCallback change) {
            setState(change);
            sheetSetState(() {});
          }

          return SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              decoration: BoxDecoration(
                color: CineMarketplaceVisuals.of(context).surface,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                    color: CineMarketplaceVisuals.of(context).border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'FILTER MARKETPLACE',
                          style: CineMarketplaceVisuals.of(context).archivo(
                            size: 13,
                            weight: FontWeight.w700,
                            color: CineMarketplaceVisuals.of(context).gold,
                            letterSpacing: 2.6,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close filters',
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: Icon(
                          Icons.close_rounded,
                          color: CineMarketplaceVisuals.of(context).ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _MarketplaceFilterSwitch(
                    label: 'Verified only',
                    subtitle: 'Show approved and verified profiles',
                    value: _verifiedOnly,
                    onChanged: (value) => update(() => _verifiedOnly = value),
                  ),
                  const SizedBox(height: 10),
                  _MarketplaceFilterSwitch(
                    label: 'New this week',
                    subtitle: 'Prioritize recently published listings',
                    value: _newOnly,
                    onChanged: (value) => update(() => _newOnly = value),
                  ),
                  if (!widget.publicBuyerMode && !widget.browseOnly) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          Navigator.pushNamed(
                            this.context,
                            DirectorProducerRoutes.filters,
                          );
                        },
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        label: const Text('Open smart filters'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              CineMarketplaceVisuals.of(context).gold,
                          side: BorderSide(
                            color: CineMarketplaceVisuals.of(context).gold,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: CineMarketplaceVisuals.of(context).archivo(
                            size: 13,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.publicBuyerMode
        ? const ['All', 'Actors', 'Models', 'Influencers']
        : widget.browseOnly
            ? const [
                'All',
                'Actors',
                'Models',
                'Influencers',
                'Crew',
                'Locations',
                'Media & Equipment',
                'Agencies',
                'Distribution',
              ]
            : _categoryKeys;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        MediaQuery.sizeOf(context).width < 600 ? 14 : 28,
        MediaQuery.sizeOf(context).width < 600 ? 24 : 34,
        MediaQuery.sizeOf(context).width < 600 ? 14 : 28,
        30,
      ),
      decoration: BoxDecoration(
        color: CineMarketplaceVisuals.of(context).background,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: CineMarketplaceVisuals.of(context).border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MarketplaceReveal(
            child: _MarketplaceHeroHeader(
              subtitle: widget.publicBuyerMode
                  ? 'BOOK ACTORS, MODELS & CREATORS'
                  : widget.browseOnly
                      ? 'LIVE APPROVED LISTINGS'
                      : 'CINECONNECT',
              title: widget.publicBuyerMode
                  ? 'Find your next face'
                  : 'Marketplace',
              actions: widget.browseOnly || widget.publicBuyerMode
                  ? null
                  : _MarketplaceHeaderActions(
                      onCreateAudition: _openAuditionBuilder,
                      onFilters: () => Navigator.pushNamed(
                        context,
                        DirectorProducerRoutes.filters,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 22),
          _MarketplaceReveal(
            delay: 55,
            child: _MarketplaceSearchBar(
              controller: _search,
              hintText: widget.publicBuyerMode
                  ? 'Search actors, models, influencers…'
                  : null,
              onChanged: _searchChanged,
              onFilters: _openMarketplaceFilters,
              onSaveSearch: _saveCurrentSearch,
            ),
          ),
          if (!widget.publicBuyerMode &&
              !widget.browseOnly &&
              _projectId != null) ...[
            const SizedBox(height: 12),
            _MarketplaceReveal(
              delay: 80,
              child: _MarketplaceProjectScope(
                projectTitle: _projectTitle(_projectId),
              ),
            ),
          ],
          const SizedBox(height: 17),
          _MarketplaceReveal(
            delay: 100,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final category in categories)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _MarketplaceCategoryChip(
                        label: category,
                        active: _category == category,
                        onTap: () => _setCategory(category),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_verifiedOnly || _newOnly) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_verifiedOnly)
                  _MarketplaceActiveFilter(
                    label: 'Verified only',
                    onRemove: () => setState(() => _verifiedOnly = false),
                  ),
                if (_newOnly)
                  _MarketplaceActiveFilter(
                    label: 'New this week',
                    onRemove: () => setState(() => _newOnly = false),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          FutureBuilder<List<DpCandidate>>(
            future: _candidatesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const _MarketplaceLoadingState();
              }
              if (snapshot.hasError) {
                return _MarketplaceErrorState(
                  message: _friendlyError(snapshot.error),
                  onRetry: () => setState(() => _candidatesFuture = _load()),
                );
              }
              final candidates = (snapshot.data ?? const <DpCandidate>[])
                  .where(_matchesFilters)
                  .toList()
                ..sort((a, b) {
                  final verified =
                      b.verified.toString().compareTo(a.verified.toString());
                  if (verified != 0) return verified;
                  final trust = (b.trustMetrics?.score ?? -1)
                      .compareTo(a.trustMetrics?.score ?? -1);
                  if (trust != 0) return trust;
                  final rating = b.rating.compareTo(a.rating);
                  if (rating != 0) return rating;
                  return a.name.compareTo(b.name);
                });
              if (candidates.isEmpty) {
                return _MarketplaceEmptyState(
                  icon: _categoryHasLiveFeed(_category)
                      ? Icons.manage_search_outlined
                      : Icons.construction_outlined,
                  title: _categoryHasLiveFeed(_category)
                      ? 'No live listings match'
                      : 'Live $_category feed is not connected yet',
                  message: _categoryHasLiveFeed(_category)
                      ? 'Try clearing filters or searching another city, name, or category.'
                      : 'This portal no longer shows fake $_category records. Add the planned Director discovery endpoint to populate this category from the database.',
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CineMarketplaceResults(
                    cards: candidates.indexed
                        .map(
                          (entry) => DPCandidateCard(
                            featured: entry.$1 == 0,
                            candidate: entry.$2,
                            heroTag: 'marketplace-profile-'
                                '${widget.publicBuyerMode ? (entry.$2.marketplaceListingId ?? entry.$2.profileId) : entry.$2.profileId}',
                            onProfile: () => Navigator.pushNamed(
                              context,
                              widget.browseOnly
                                  ? MarketplaceRoutes.profile
                                  : widget.publicBuyerMode
                                      ? GeneralPublicRoutes.profile
                                      : DirectorProducerRoutes.profile,
                              arguments: {
                                'candidateId':
                                    widget.browseOnly || widget.publicBuyerMode
                                        ? entry.$2.marketplaceListingId ??
                                            entry.$2.profileId
                                        : entry.$2.profileId,
                                'type': entry.$2.category,
                                if (!widget.publicBuyerMode &&
                                    !widget.browseOnly)
                                  'projectId': _projectId,
                              },
                            ),
                            onRequest: widget.browseOnly
                                ? null
                                : entry.$2.marketplaceListingId == null
                                    ? () => _showProviderActionPending(entry.$2)
                                    : () async {
                                        final isPublicBuyer =
                                            AuthScope.maybeOf(context)
                                                    ?.user
                                                    ?.primaryRole
                                                    ?.code ==
                                                'general_public';
                                        if (!isPublicBuyer &&
                                            !await ensureKycApproved(context)) {
                                          return;
                                        }
                                        if (!context.mounted) return;
                                        Navigator.pushNamed(
                                          context,
                                          widget.publicBuyerMode
                                              ? GeneralPublicRoutes
                                                  .bookingRequest
                                              : DirectorProducerRoutes
                                                  .bookingRequest,
                                          arguments: {
                                            'candidateId':
                                                entry.$2.marketplaceListingId,
                                            if (!widget.publicBuyerMode)
                                              'projectId': _projectId,
                                            'category': entry.$2.category,
                                          },
                                        );
                                      },
                            onShortlist: widget.browseOnly
                                ? null
                                : widget.publicBuyerMode
                                    ? () async {
                                        _showSnack(
                                          'Saved lists for customer campaigns are coming next. Use Request to send a booking now.',
                                        );
                                        return false;
                                      }
                                    : entry.$2.marketplaceListingId == null
                                        ? () async {
                                            _showProviderActionPending(
                                                entry.$2);
                                            return false;
                                          }
                                        : () => _shortlistCandidate(entry.$2),
                          ),
                        )
                        .toList(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveCurrentSearch() async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null || !auth.isAuthenticated) {
      _showSnack('Sign in to save marketplace searches.');
      return;
    }
    try {
      await auth.createSavedSearch(
        name: _category == 'All' ? 'Marketplace search' : '$_category search',
        listingType: switch (_category) {
          'Actors' => 'actor',
          'Models' => 'model',
          'Influencers' => 'influencer',
          'Locations' => 'location',
          'Media & Equipment' => 'equipment',
          'Crew' => 'crew',
          'Agencies' => 'agency',
          'Distribution' => 'distribution',
          _ => null,
        },
      );
      if (!mounted) return;
      _showSnack('Search saved.');
    } on ApiException catch (exception) {
      if (!mounted) return;
      _showSnack(exception.message);
    } catch (_) {
      if (!mounted) return;
      _showSnack('Could not save search right now.');
    }
  }

  Future<void> _openAuditionBuilder() async {
    if (_projectId != null) {
      Navigator.pushNamed(
        context,
        DirectorProducerRoutes.requirements,
        arguments: {'id': _projectId},
      );
      return;
    }

    final projectsController = ProjectsScope.maybeOf(context);
    if (projectsController == null) {
      _showSnack('Sign in and create a project before publishing auditions.');
      return;
    }

    late final List<Project> projects;
    try {
      projects = await projectsController.projects();
    } on ApiException catch (exception) {
      if (!mounted) return;
      _showSnack(exception.message);
      return;
    } catch (_) {
      if (!mounted) return;
      _showSnack('Could not load projects for audition creation.');
      return;
    }

    if (!mounted) return;
    if (projects.isEmpty) {
      _showSnack('Create a project first, then add audition calls to it.');
      Navigator.pushNamed(context, DirectorProducerRoutes.createProject);
      return;
    }

    final selectedProject = await showModalBottomSheet<Project>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _AuditionProjectPicker(projects: projects),
    );
    if (!mounted || selectedProject == null) return;
    setState(() => _projectId = selectedProject.publicId);
    Navigator.pushNamed(
      context,
      DirectorProducerRoutes.requirements,
      arguments: {'id': selectedProject.publicId},
    );
  }

  Future<bool> _shortlistCandidate(DpCandidate candidate) async {
    final selection = await _pickShortlistTarget(candidate);
    if (selection == null) return false;
    if (!mounted) return false;
    final auth = AuthScope.maybeOf(context);
    if (auth == null || !auth.isAuthenticated) {
      _showSnack(
        '${candidate.name} staged for ${selection.project.title} → ${selection.requirement.title}. Sign in to save.',
      );
      return true;
    }
    try {
      await auth.addToDefaultShortlist(
        candidate.marketplaceListingId ?? candidate.id,
      );
      if (!mounted) return false;
      _showSnack(
        '${candidate.name} added to ${selection.project.title} → ${selection.requirement.title}.',
      );
      return true;
    } on ApiException catch (exception) {
      if (!mounted) return false;
      _showSnack(exception.message);
      return false;
    } catch (_) {
      if (!mounted) return false;
      _showSnack('Could not update shortlist right now.');
      return false;
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showProviderActionPending(DpCandidate candidate) {
    _showSnack(
      '${candidate.name} is a live ${candidate.category} profile but does not have a public marketplace listing yet.',
    );
  }

  String _projectTitle(String? projectId) {
    if (projectId == null) return 'All projects';
    final cached = ProjectsScope.maybeOf(context)?.cachedProjects;
    if (cached == null) return 'selected project';
    for (final project in cached) {
      if (project.publicId == projectId) return project.title;
    }
    return 'selected project';
  }

  String _friendlyError(Object? error) {
    if (error is ApiException) {
      return switch (error.code) {
        'auth.required' ||
        'auth.invalid_token' =>
          'Sign in to load live marketplace listings.',
        'network.offline' =>
          'Live marketplace is unavailable. Check your connection and retry.',
        _ => error.message,
      };
    }
    return 'Live marketplace is unavailable right now.';
  }

  Future<_ShortlistTarget?> _pickShortlistTarget(DpCandidate candidate) async {
    final projectsController = ProjectsScope.maybeOf(context);
    if (projectsController == null) {
      _showSnack('Sign in and load projects before shortlisting.');
      return null;
    }
    late final List<Project> projects;
    try {
      projects = await projectsController.projects();
    } on ApiException catch (exception) {
      _showSnack(exception.message);
      return null;
    } catch (_) {
      _showSnack('Could not load live projects for shortlisting.');
      return null;
    }
    if (!mounted) return null;
    if (projects.isEmpty) {
      _showSnack(
          'Create a live project before shortlisting marketplace listings.');
      return null;
    }

    var selectedProjectId = _projectId;
    if (!projects.any((project) => project.publicId == selectedProjectId)) {
      selectedProjectId = projects.first.publicId;
    }
    Future<List<ProjectRequirement>> requirementsFuture =
        projectsController.requirements(selectedProjectId!);
    String? selectedRequirementId;

    return showModalBottomSheet<_ShortlistTarget>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
              ),
              child: DPGlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shortlist ${candidate.name}',
                      style: AppTextStyles.cardTitle.copyWith(
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    dpText(
                      context,
                      'Choose the project and requirement this candidate belongs to.',
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      key: ValueKey(selectedProjectId),
                      initialValue: selectedProjectId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Project',
                        prefixIcon: Icon(Icons.movie_creation_outlined),
                      ),
                      items: [
                        for (final item in projects)
                          DropdownMenuItem(
                            value: item.publicId,
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setSheetState(() {
                          selectedProjectId = value;
                          selectedRequirementId = null;
                          requirementsFuture =
                              projectsController.requirements(value);
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<ProjectRequirement>>(
                      future: requirementsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const DPGlassCard(
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (snapshot.hasError) {
                          return DPEmptyState(
                            icon: Icons.rule_folder_outlined,
                            title: 'Requirements unavailable',
                            message: _friendlyError(snapshot.error),
                          );
                        }
                        final requirements =
                            snapshot.data ?? const <ProjectRequirement>[];
                        if (requirements.isEmpty) {
                          return const DPEmptyState(
                            icon: Icons.rule_folder_outlined,
                            title: 'No live requirements',
                            message:
                                'Create a requirement on this project before shortlisting candidates to it.',
                          );
                        }
                        if (!requirements.any(
                            (item) => item.publicId == selectedRequirementId)) {
                          selectedRequirementId = requirements.first.publicId;
                        }
                        final selectedRequirement = requirements.firstWhere(
                          (item) => item.publicId == selectedRequirementId,
                        );
                        final selectedProject = projects.firstWhere(
                          (item) => item.publicId == selectedProjectId,
                        );
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DropdownButtonFormField<String>(
                              key: ValueKey(
                                '$selectedProjectId-$selectedRequirementId',
                              ),
                              initialValue: selectedRequirementId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Requirement',
                                prefixIcon: Icon(Icons.rule_folder_outlined),
                              ),
                              items: [
                                for (final item in requirements)
                                  DropdownMenuItem<String>(
                                    value: item.publicId,
                                    child: Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setSheetState(
                                  () => selectedRequirementId = value,
                                );
                              },
                            ),
                            const SizedBox(height: 14),
                            DPHolographicButton(
                              label: 'Add to project shortlist',
                              icon: Icons.favorite_rounded,
                              onTap: () => Navigator.pop(
                                sheetContext,
                                _ShortlistTarget(
                                  selectedProject,
                                  selectedRequirement,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ShortlistTarget {
  final Project project;
  final ProjectRequirement requirement;

  const _ShortlistTarget(this.project, this.requirement);
}

class _MarketplaceReveal extends StatelessWidget {
  final Widget child;
  final int delay;

  const _MarketplaceReveal({required this.child, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 430 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, animatedChild) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 18),
          child: animatedChild,
        ),
      ),
      child: child,
    );
  }
}

class _MarketplaceHeroHeader extends StatelessWidget {
  final String subtitle;
  final String title;
  final Widget? actions;

  const _MarketplaceHeroHeader({
    required this.subtitle,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: CineMarketplaceVisuals.of(context).archivo(
                size: compact ? 10.5 : 12,
                weight: FontWeight.w700,
                color: CineMarketplaceVisuals.of(context).gold,
                letterSpacing: compact ? 3.2 : 4.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: CineMarketplaceVisuals.of(context).archivo(
                size: compact ? 37 : 54,
                weight: FontWeight.w700,
                height: 0.98,
                letterSpacing: -1.7,
              ),
            ),
          ],
        );
        if (actions == null) return heading;
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading,
              const SizedBox(height: 18),
              SizedBox(width: double.infinity, child: actions),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: heading),
            const SizedBox(width: 24),
            actions!,
          ],
        );
      },
    );
  }
}

class _MarketplaceProjectScope extends StatelessWidget {
  final String projectTitle;

  const _MarketplaceProjectScope({required this.projectTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: CineMarketplaceVisuals.of(context).gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              CineMarketplaceVisuals.of(context).gold.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 17,
            color: CineMarketplaceVisuals.of(context).gold,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'SCOPED TO $projectTitle · YOUR FILTERS STAY ACTIVE',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: CineMarketplaceVisuals.of(context).archivo(
                size: 10.5,
                weight: FontWeight.w600,
                color: CineMarketplaceVisuals.of(context).secondary,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketplaceCategoryChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _MarketplaceCategoryChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? CineMarketplaceVisuals.of(context).gold
          : CineMarketplaceVisuals.of(context).surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 190),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active
                  ? CineMarketplaceVisuals.of(context).gold
                  : CineMarketplaceVisuals.of(context).border,
            ),
          ),
          child: Text(
            label,
            style: CineMarketplaceVisuals.of(context).archivo(
              size: 11.5,
              weight: active ? FontWeight.w700 : FontWeight.w500,
              color: active
                  ? CineMarketplaceVisuals.of(context).onGold
                  : CineMarketplaceVisuals.of(context).secondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MarketplaceActiveFilter extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _MarketplaceActiveFilter({
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 11),
      decoration: BoxDecoration(
        color: CineMarketplaceVisuals.of(context).gold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color:
              CineMarketplaceVisuals.of(context).gold.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: CineMarketplaceVisuals.of(context).archivo(
              size: 10.5,
              weight: FontWeight.w600,
              color: CineMarketplaceVisuals.of(context).goldLight,
            ),
          ),
          IconButton(
            tooltip: 'Remove $label',
            onPressed: onRemove,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.close_rounded,
              size: 15,
              color: CineMarketplaceVisuals.of(context).gold,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketplaceFilterSwitch extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MarketplaceFilterSwitch({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CineMarketplaceVisuals.of(context).background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value
                ? CineMarketplaceVisuals.of(context)
                    .gold
                    .withValues(alpha: 0.55)
                : CineMarketplaceVisuals.of(context).border,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: CineMarketplaceVisuals.of(context).archivo(
                      size: 14,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: CineMarketplaceVisuals.of(context).archivo(
                      size: 11,
                      color: CineMarketplaceVisuals.of(context).muted,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: CineMarketplaceVisuals.of(context).gold,
              activeThumbColor: CineMarketplaceVisuals.of(context).onGold,
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketplaceLoadingState extends StatelessWidget {
  const _MarketplaceLoadingState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: CineMarketplaceVisuals.of(context).gold,
        ),
      ),
    );
  }
}

class _MarketplaceEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _MarketplaceEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 38),
      decoration: BoxDecoration(
        color: CineMarketplaceVisuals.of(context).surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: CineMarketplaceVisuals.of(context).border),
      ),
      child: Column(
        children: [
          Icon(icon, color: CineMarketplaceVisuals.of(context).gold, size: 30),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: CineMarketplaceVisuals.of(context).archivo(
              size: 17,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: CineMarketplaceVisuals.of(context).archivo(
              size: 12,
              color: CineMarketplaceVisuals.of(context).muted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketplaceHeaderActions extends StatelessWidget {
  final VoidCallback onCreateAudition;
  final VoidCallback onFilters;

  const _MarketplaceHeaderActions({
    required this.onCreateAudition,
    required this.onFilters,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 330;
        final buttons = [
          _MarketplaceHeaderButton(
            label: 'Create audition',
            icon: Icons.campaign_rounded,
            onTap: onCreateAudition,
            primary: true,
          ),
          _MarketplaceHeaderButton(
            label: 'Smart filters',
            icon: Icons.tune_rounded,
            onTap: onFilters,
          ),
        ];
        if (stack) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final button in buttons) ...[
                SizedBox(width: double.infinity, child: button),
                if (button != buttons.last) const SizedBox(height: 8),
              ],
            ],
          );
        }
        if (buttons.length == 1) return buttons.first;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: buttons.first),
            const SizedBox(width: 8),
            Flexible(child: buttons.last),
          ],
        );
      },
    );
  }
}

class _MarketplaceHeaderButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  const _MarketplaceHeaderButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: primary
            ? CineMarketplaceVisuals.of(context).onGold
            : CineMarketplaceVisuals.of(context).gold,
        backgroundColor: primary
            ? Colors.transparent
            : CineMarketplaceVisuals.of(context).surface,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: primary
                ? CineMarketplaceVisuals.of(context).gold
                : CineMarketplaceVisuals.of(context)
                    .gold
                    .withValues(alpha: 0.55),
          ),
        ),
        textStyle: CineMarketplaceVisuals.of(context).archivo(
          size: 12,
          weight: FontWeight.w700,
        ),
      ),
    );
    if (!primary) return child;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: CineMarketplaceVisuals.of(context).goldGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _AuditionProjectPicker extends StatelessWidget {
  final List<Project> projects;

  const _AuditionProjectPicker({required this.projects});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: DPGlassCard(
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create audition for project',
                style: AppTextStyles.cardTitle.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              dpText(
                context,
                'Pick the production this audition call belongs to.',
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: projects.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.pop(context, project),
                      child: DPGlassCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.movie_creation_outlined,
                              color: colors.goldDark,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    project.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.statusText.copyWith(
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    [
                                      _titleCase(project.projectType),
                                      project.status,
                                      if (project.city != null)
                                        project.city!.name,
                                    ].join(' · '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.smallMeta.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: colors.iconMuted,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketplaceErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _MarketplaceErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CineMarketplaceVisuals.of(context).surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CineMarketplaceVisuals.of(context).border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            color: CineMarketplaceVisuals.of(context).gold,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Could not load live marketplace',
                  style: CineMarketplaceVisuals.of(context).archivo(
                    size: 16,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: CineMarketplaceVisuals.of(context).archivo(
                    size: 12,
                    color: CineMarketplaceVisuals.of(context).muted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                    style: TextButton.styleFrom(
                      foregroundColor: CineMarketplaceVisuals.of(context).gold,
                      textStyle: CineMarketplaceVisuals.of(context).archivo(
                        size: 12,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketplaceSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final VoidCallback onChanged;
  final VoidCallback? onFilters;
  final VoidCallback onSaveSearch;

  const _MarketplaceSearchBar({
    required this.controller,
    this.hintText,
    required this.onChanged,
    this.onFilters,
    required this.onSaveSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: CineMarketplaceVisuals.of(context).surface,
              borderRadius: BorderRadius.circular(17),
              border:
                  Border.all(color: CineMarketplaceVisuals.of(context).border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: CineMarketplaceVisuals.of(context).muted,
                  size: 21,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: (_) => onChanged(),
                    cursorColor: CineMarketplaceVisuals.of(context).gold,
                    style:
                        CineMarketplaceVisuals.of(context).archivo(size: 13.5),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: hintText ?? 'Search talent, crew, locations…',
                      hintStyle: CineMarketplaceVisuals.of(context).archivo(
                        size: 13.5,
                        color: CineMarketplaceVisuals.of(context).muted,
                      ),
                    ),
                  ),
                ),
                if (controller.text.isNotEmpty)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      controller.clear();
                      onChanged();
                    },
                    child: Icon(
                      Icons.close_rounded,
                      color: CineMarketplaceVisuals.of(context).muted,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 9),
        _MarketplaceSquareButton(
          tooltip: 'Save search',
          icon: Icons.bookmark_add_outlined,
          onTap: onSaveSearch,
        ),
        if (onFilters != null) ...[
          const SizedBox(width: 9),
          _MarketplaceSquareButton(
            tooltip: 'Filters',
            icon: Icons.tune_rounded,
            onTap: onFilters!,
            emphasized: true,
          ),
        ],
      ],
    );
  }
}

class _MarketplaceSquareButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final bool emphasized;

  const _MarketplaceSquareButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: emphasized
            ? CineMarketplaceVisuals.of(context).gold
            : CineMarketplaceVisuals.of(context).surface,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: emphasized
                    ? CineMarketplaceVisuals.of(context).gold
                    : CineMarketplaceVisuals.of(context).border,
              ),
            ),
            child: Icon(
              icon,
              color: emphasized
                  ? CineMarketplaceVisuals.of(context).onGold
                  : CineMarketplaceVisuals.of(context).gold,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }
}

String _titleCase(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.trim().isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
