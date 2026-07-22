import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/director_producer_demo_data.dart';
import '../models/dp_candidate.dart';
import '../models/dp_project.dart';
import '../models/dp_requirement.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_candidate_card.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_status_chip.dart';

const _categoryKeys = [
  'All',
  'Talent',
  'Models',
  'Crew',
  'Locations',
  'Media & Equipment',
  'Agencies',
];

class DPMarketplaceDiscoveryScreen extends StatefulWidget {
  final String? initialCategory;
  final String? projectId;

  const DPMarketplaceDiscoveryScreen({
    super.key,
    this.initialCategory,
    this.projectId,
  });

  @override
  State<DPMarketplaceDiscoveryScreen> createState() =>
      _DPMarketplaceDiscoveryScreenState();
}

class _DPMarketplaceDiscoveryScreenState
    extends State<DPMarketplaceDiscoveryScreen> {
  late String _category = widget.initialCategory ?? 'All';
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
    final type = switch (_category) {
      'Talent' => 'talent',
      _ => null,
    };
    final listings =
        await AuthScope.of(context).marketplaceListings(type: type);
    return listings.map((item) => item.toCandidate()).toList();
  }

  List<DpCandidate> _fallbackRows() {
    final rows = DirectorProducerDemoData.candidates.where(_matchesFilters);
    return rows.toList()
      ..sort((a, b) {
        final verified = b.verified.toString().compareTo(a.verified.toString());
        if (verified != 0) return verified;
        final rating = b.rating.compareTo(a.rating);
        if (rating != 0) return rating;
        return a.joinedDaysAgo.compareTo(b.joinedDaysAgo);
      });
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
      _category = category;
      _candidatesFuture = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = DirectorProducerDemoData.candidates.length;
    final verifiedCount =
        DirectorProducerDemoData.candidates.where((c) => c.verified).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DPPageHeader(
          eyebrow: '$total listings · $verifiedCount verified',
          title: 'Marketplace',
          actionLabel: 'Smart Filters',
          actionIcon: Icons.tune_rounded,
          onActionTap: () =>
              Navigator.pushNamed(context, DirectorProducerRoutes.filters),
        ),
        const SizedBox(height: 14),
        _MarketplaceSearchBar(
          controller: _search,
          onChanged: () => setState(() {}),
          onFilters: () =>
              Navigator.pushNamed(context, DirectorProducerRoutes.filters),
          onSaveSearch: _saveCurrentSearch,
        ),
        const SizedBox(height: 10),
        if (_projectId != null) ...[
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
              for (final category in _categoryKeys)
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
        Row(
          children: [
            DpDotChip(
              label: 'Verified only',
              active: _verifiedOnly,
              onTap: () => setState(() => _verifiedOnly = !_verifiedOnly),
            ),
            const SizedBox(width: 8),
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
            final usingFallback = snapshot.hasError ||
                (snapshot.connectionState == ConnectionState.done &&
                    (snapshot.data ?? const []).isEmpty);
            final candidates = usingFallback
                ? _fallbackRows()
                : (snapshot.data ?? const <DpCandidate>[])
                    .where(_matchesFilters)
                    .toList();
            if (snapshot.connectionState != ConnectionState.done &&
                candidates.isEmpty) {
              return const DPGlassCard(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (usingFallback && snapshot.error is ApiException) ...[
                  DPStatusChip(
                    label:
                        'Live marketplace unavailable — showing preview data',
                    tone: DpTone.warning,
                  ),
                  const SizedBox(height: 10),
                ],
                DPResponsiveGrid(
                  minWidth: 300,
                  children: candidates
                      .map(
                        (candidate) => DPCandidateCard(
                          candidate: candidate,
                          onProfile: () => Navigator.pushNamed(
                            context,
                            DirectorProducerRoutes.profile,
                            arguments: {
                              'candidateId': candidate.id,
                              'type': candidate.category,
                              'projectId': _projectId,
                            },
                          ),
                          onRequest: () => Navigator.pushNamed(
                            context,
                            DirectorProducerRoutes.bookingRequest,
                            arguments: {
                              'candidateId': candidate.id,
                              'projectId': _projectId,
                              'category': candidate.category,
                            },
                          ),
                          onShortlist: () => _shortlistCandidate(candidate),
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
        listingType: _category == 'Talent' ? 'talent' : null,
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
      await auth.addToDefaultShortlist(candidate.id);
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

  String _projectTitle(String? projectId) {
    if (projectId == null) return 'All projects';
    return DirectorProducerDemoData.projects
        .firstWhere(
          (project) => project.id == projectId,
          orElse: () => DirectorProducerDemoData.projects.first,
        )
        .title;
  }

  Future<_ShortlistTarget?> _pickShortlistTarget(DpCandidate candidate) {
    var selectedProjectId =
        _projectId ?? DirectorProducerDemoData.projects.first.id;
    final initialRequirements = DirectorProducerDemoData.requirements
        .where((requirement) => requirement.projectId == selectedProjectId)
        .toList();
    String? selectedRequirementId =
        initialRequirements.isEmpty ? null : initialRequirements.first.id;
    return showModalBottomSheet<_ShortlistTarget>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final project = DirectorProducerDemoData.projects.firstWhere(
              (item) => item.id == selectedProjectId,
            );
            final requirements = DirectorProducerDemoData.requirements
                .where((item) => item.projectId == selectedProjectId)
                .toList();
            if (!requirements.any((item) => item.id == selectedRequirementId)) {
              selectedRequirementId =
                  requirements.isEmpty ? null : requirements.first.id;
            }
            final requirement = selectedRequirementId == null
                ? null
                : requirements.firstWhere(
                    (item) => item.id == selectedRequirementId,
                  );
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
                        for (final item in DirectorProducerDemoData.projects)
                          DropdownMenuItem(
                            value: item.id,
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
                          final projectRequirements = DirectorProducerDemoData
                              .requirements
                              .where((item) => item.projectId == value)
                              .toList();
                          selectedRequirementId = projectRequirements.isEmpty
                              ? null
                              : projectRequirements.first.id;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      key:
                          ValueKey('$selectedProjectId-$selectedRequirementId'),
                      initialValue: selectedRequirementId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Requirement',
                        prefixIcon: Icon(Icons.rule_folder_outlined),
                      ),
                      items: [
                        for (final item in requirements)
                          DropdownMenuItem<String?>(
                            value: item.id,
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setSheetState(() => selectedRequirementId = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    DPHolographicButton(
                      label: 'Add to project shortlist',
                      icon: Icons.favorite_rounded,
                      onTap: requirement == null
                          ? null
                          : () => Navigator.pop(
                                sheetContext,
                                _ShortlistTarget(project, requirement),
                              ),
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
  final DpProject project;
  final DpRequirement requirement;

  const _ShortlistTarget(this.project, this.requirement);
}

class _MarketplaceSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;
  final VoidCallback onFilters;
  final VoidCallback onSaveSearch;

  const _MarketplaceSearchBar({
    required this.controller,
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
                      hintText: 'Search talent, crew, locations…',
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
