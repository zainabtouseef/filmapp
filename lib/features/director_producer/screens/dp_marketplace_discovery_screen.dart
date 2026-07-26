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
import '../widgets/dp_status_chip.dart';
import '../../../shared/layout/kyc_status_banner.dart';

const _categoryKeys = [
  'All',
  'Actors',
  'Models',
  'Influencers',
  'Crew',
  'Locations',
  'Media & Equipment',
  'Agencies',
];

class DPMarketplaceDiscoveryScreen extends StatefulWidget {
  final String? initialCategory;
  final String? projectId;
  final bool publicBuyerMode;

  const DPMarketplaceDiscoveryScreen({
    super.key,
    this.initialCategory,
    this.projectId,
    this.publicBuyerMode = false,
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

  @override
  void dispose() {
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
    final discovery = await auth.directorDiscovery(category: _category);
    return discovery.items.map((item) => item.toCandidate()).toList();
  }

  bool _categoryHasLiveFeed(String category) {
    return category == 'All' ||
        category == 'Actors' ||
        category == 'Models' ||
        category == 'Influencers' ||
        category == 'Locations' ||
        category == 'Media & Equipment' ||
        category == 'Agencies';
  }

  bool _matchesFilters(DpCandidate candidate) {
    final categoryMatch = _category == 'All' || candidate.category == _category;
    final trustMatch = (!_verifiedOnly || candidate.verified) &&
        (!_newOnly || candidate.isNew);
    final query = _search.text.trim().toLowerCase();
    final queryMatch = query.isEmpty ||
        candidate.name.toLowerCase().contains(query) ||
        candidate.city.toLowerCase().contains(query) ||
        candidate.category.toLowerCase().contains(query);
    return categoryMatch && trustMatch && queryMatch;
  }

  void _setCategory(String category) {
    setState(() {
      _category = _normalizeCategory(category);
      _candidatesFuture = _load();
    });
  }

  String _normalizeCategory(String? category) {
    return category == 'Talent' ? 'Actors' : (category ?? 'All');
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.publicBuyerMode
        ? const ['All', 'Actors', 'Models', 'Influencers']
        : _categoryKeys;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DPPageHeader(
          eyebrow: widget.publicBuyerMode
              ? 'Book actors, models and influencers'
              : _categoryHasLiveFeed(_category)
                  ? 'Live marketplace listings'
                  : 'Backend feed pending for $_category',
          title: widget.publicBuyerMode
              ? 'Find talent for your campaign'
              : 'Marketplace',
          trailing: _MarketplaceHeaderActions(
            showAudition: !widget.publicBuyerMode,
            onCreateAudition: _openAuditionBuilder,
            onFilters: () =>
                Navigator.pushNamed(context, DirectorProducerRoutes.filters),
          ),
        ),
        const SizedBox(height: 14),
        _MarketplaceSearchBar(
          controller: _search,
          hintText: widget.publicBuyerMode
              ? 'Search actors, models, influencers…'
              : null,
          onChanged: () => setState(() {}),
          onFilters: () =>
              Navigator.pushNamed(context, DirectorProducerRoutes.filters),
          onSaveSearch: _saveCurrentSearch,
        ),
        const SizedBox(height: 10),
        if (!widget.publicBuyerMode && _projectId != null) ...[
          DPGlassCard(
            padding: const EdgeInsets.all(11),
            child: Row(
              children: [
                const Icon(Icons.account_tree_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: dpText(
                    context,
                    'Discover is scoped to ${_projectTitle(_projectId)}. Returning from profiles keeps these filters alive.',
                    strong: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final category in categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: DpDotChip(
                    label: category,
                    active: _category == category,
                    onTap: () => _setCategory(category),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            DpDotChip(
              label: 'Verified only',
              active: _verifiedOnly,
              onTap: () => setState(() => _verifiedOnly = !_verifiedOnly),
            ),
            DpDotChip(
              label: 'New this week',
              active: _newOnly,
              onTap: () => setState(() => _newOnly = !_newOnly),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<DpCandidate>>(
          future: _candidatesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const DPGlassCard(
                child: Center(child: CircularProgressIndicator()),
              );
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
                final rating = b.rating.compareTo(a.rating);
                if (rating != 0) return rating;
                return a.name.compareTo(b.name);
              });
            if (candidates.isEmpty) {
              return DPEmptyState(
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
                DPResponsiveGrid(
                  minWidth: 300,
                  children: candidates
                      .map(
                        (candidate) => DPCandidateCard(
                          candidate: candidate,
                          onProfile: () => Navigator.pushNamed(
                            context,
                            widget.publicBuyerMode
                                ? GeneralPublicRoutes.profile
                                : DirectorProducerRoutes.profile,
                            arguments: {
                              'candidateId': candidate.profileId,
                              'type': candidate.category,
                              if (!widget.publicBuyerMode)
                                'projectId': _projectId,
                            },
                          ),
                          onRequest: candidate.marketplaceListingId == null
                              ? () => _showProviderActionPending(candidate)
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
                                        ? GeneralPublicRoutes.bookingRequest
                                        : DirectorProducerRoutes.bookingRequest,
                                    arguments: {
                                      'candidateId':
                                          candidate.marketplaceListingId,
                                      if (!widget.publicBuyerMode)
                                        'projectId': _projectId,
                                      'category': candidate.category,
                                    },
                                  );
                                },
                          onShortlist: widget.publicBuyerMode
                              ? () async {
                                  _showSnack(
                                    'Saved lists for customer campaigns are coming next. Use Request to send a booking now.',
                                  );
                                  return false;
                                }
                              : candidate.marketplaceListingId == null
                                  ? () async {
                                      _showProviderActionPending(candidate);
                                      return false;
                                    }
                                  : () => _shortlistCandidate(candidate),
                        ),
                      )
                      .toList(),
                ),
              ],
            );
          },
        ),
      ],
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
          'Agencies' => 'agency',
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

class _MarketplaceHeaderActions extends StatelessWidget {
  final VoidCallback onCreateAudition;
  final VoidCallback onFilters;
  final bool showAudition;

  const _MarketplaceHeaderActions({
    required this.onCreateAudition,
    required this.onFilters,
    this.showAudition = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 310;
        final buttons = [
          if (showAudition)
            DPHolographicButton(
              label: 'Create Audition',
              icon: Icons.campaign_outlined,
              onTap: onCreateAudition,
            ),
          DPHolographicButton(
            label: 'Smart Filters',
            icon: Icons.tune_rounded,
            secondary: true,
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
    final colors = context.appColors;
    return DPGlassCard(
      accentColor: colors.warning,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off_outlined, color: colors.warning, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Could not load live marketplace',
                  style: AppTextStyles.cardTitle.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
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
  final VoidCallback onFilters;
  final VoidCallback onSaveSearch;

  const _MarketplaceSearchBar({
    required this.controller,
    this.hintText,
    required this.onChanged,
    required this.onFilters,
    required this.onSaveSearch,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              gradient: colors.searchGradient,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: colors.goldDark, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: (_) => onChanged(),
                    style: AppTextStyles.smallMeta
                        .copyWith(color: colors.textPrimary),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: hintText ?? 'Search talent, crew, locations…',
                      hintStyle: AppTextStyles.smallMeta
                          .copyWith(color: colors.textSecondary),
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
                    child: Icon(Icons.close_rounded,
                        color: colors.iconMuted, size: 18),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Save search',
          child: GestureDetector(
            onTap: onSaveSearch,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                color: colors.surface
                    .withValues(alpha: colors.isLight ? 0.7 : 0.2),
                border: Border.all(color: colors.border),
              ),
              child: Icon(Icons.bookmark_add_outlined,
                  color: colors.icon, size: 19),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Filters',
          child: GestureDetector(
            onTap: onFilters,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                color: colors.surface
                    .withValues(alpha: colors.isLight ? 0.7 : 0.2),
                border: Border.all(color: colors.border),
              ),
              child: Icon(Icons.tune_rounded, color: colors.icon, size: 19),
            ),
          ),
        ),
      ],
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
