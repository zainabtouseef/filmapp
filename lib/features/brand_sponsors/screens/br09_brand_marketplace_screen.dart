import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/director/director_discovery_models.dart';
import '../../../core/network/open_url.dart';
import '../../../core/projects/project_models.dart';
import '../../../core/projects/projects_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/tour/tour_target.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../../../shared/marketplace/marketplace_preferences.dart';
import '../../../shared/widgets/cine_animated_filter_rail.dart';
import '../../../shared/widgets/talent_profile_showcase.dart';
import '../../../shared/widgets/cine_marketplace_card.dart';
import '../widgets/brand_demo_journey.dart';
import '../widgets/brand_booking_dialog.dart';
import '../widgets/brand_sponsor_components.dart';
import '../widgets/brand_sponsor_live.dart';

const _brandDiscoveryCategories = [
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

enum _BrandMarketplaceViewMode { list, grid }

class BR09BrandMarketplaceScreen extends StatefulWidget {
  const BR09BrandMarketplaceScreen({super.key});

  @override
  State<BR09BrandMarketplaceScreen> createState() =>
      _BR09BrandMarketplaceScreenState();
}

class _BR09BrandMarketplaceScreenState
    extends State<BR09BrandMarketplaceScreen> {
  AuthController? _auth;
  ProjectsController? _projectsController;
  List<Project> _projects = const [];
  List<DirectorDiscoveryItem> _items = const [];
  String _category = 'All';
  String _query = '';
  String? _projectId;
  String? _error;
  bool _loading = false;
  bool _loaded = false;
  Timer? _searchTimer;
  _BrandMarketplaceViewMode _viewMode = _BrandMarketplaceViewMode.list;
  final _preferences = const MarketplacePreferences();

  @override
  void initState() {
    super.initState();
    _restoreViewMode();
  }

  Future<void> _restoreViewMode() async {
    final usesGrid = await _preferences.usesGrid('brand');
    if (!mounted) return;
    setState(() => _viewMode = usesGrid
        ? _BrandMarketplaceViewMode.grid
        : _BrandMarketplaceViewMode.list);
  }

  void _setViewMode(_BrandMarketplaceViewMode value) {
    setState(() => _viewMode = value);
    _preferences.setGrid('brand', value == _BrandMarketplaceViewMode.grid);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.maybeOf(context);
    final projects = ProjectsScope.maybeOf(context);
    if (identical(auth, _auth) && identical(projects, _projectsController)) {
      return;
    }
    _auth = auth;
    _projectsController = projects;
    if (auth != null && projects != null) _load(includeProjects: true);
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool includeProjects = false}) async {
    if (_auth == null || _projectsController == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final discovery = _auth!.brandDiscovery(
        category: _category,
        query: _query.trim(),
      );
      final projects = includeProjects
          ? _projectsController!.projects()
          : Future<List<Project>>.value(_projects);
      final values = await Future.wait<Object>([discovery, projects]);
      if (!mounted) return;
      final loadedProjects = values[1] as List<Project>;
      String? selectedProjectId = _projectId;
      if (selectedProjectId == null) {
        if (isBrandDemoAccount(_auth)) {
          selectedProjectId = selectBrandDemoProject(loadedProjects)?.publicId;
        }
        for (final project in loadedProjects) {
          if (selectedProjectId != null) break;
          if (!{'archived', 'cancelled', 'completed'}
              .contains(project.status)) {
            selectedProjectId = project.publicId;
            break;
          }
        }
      }
      setState(() {
        _items = (values[0] as DirectorDiscoveryBundle).items;
        _projects = loadedProjects;
        _projectId = selectedProjectId;
        _loaded = true;
      });
    } catch (error) {
      if (mounted) setState(() => _error = brandApiMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_auth == null || _projectsController == null) {
      return const CoreEmptyState(
        icon: Icons.cloud_sync_outlined,
        title: 'Sign in to browse production resources',
        message:
            'Verified talent, crew, locations and equipment load from the CineConnect backend.',
      );
    }
    final activeProjects = _projects
        .where((project) =>
            !{'archived', 'cancelled', 'completed'}.contains(project.status))
        .toList();
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 28,
        compact ? 24 : 34,
        compact ? 14 : 28,
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
          Text(
            'CINECONNECT',
            style: CineMarketplaceVisuals.of(context).archivo(
              size: compact ? 10.5 : 12,
              weight: FontWeight.w700,
              color: CineMarketplaceVisuals.of(context).gold,
              letterSpacing: compact ? 3.2 : 4.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Marketplace',
            style: CineMarketplaceVisuals.of(context).archivo(
              size: compact ? 37 : 54,
              weight: FontWeight.w700,
              height: 0.98,
              letterSpacing: -1.7,
            ),
          ),
          const SizedBox(height: 22),
          Column(
            children: [
              TourTarget(
                id: 'brand.discovery.search',
                child: _BrandMarketplaceSearch(
                  onChanged: (value) {
                    _query = value;
                    _searchTimer?.cancel();
                    _searchTimer = Timer(
                      const Duration(milliseconds: 350),
                      _load,
                    );
                  },
                  onRefresh:
                      _loading ? null : () => _load(includeProjects: true),
                ),
              ),
              const SizedBox(height: 12),
              TourTarget(
                id: 'brand.discovery.project',
                child: DropdownButtonFormField<String>(
                  key: ValueKey(_projectId),
                  initialValue: _projectId,
                  isExpanded: true,
                  dropdownColor: CineMarketplaceVisuals.of(context).surface,
                  style: CineMarketplaceVisuals.of(context).archivo(size: 13),
                  iconEnabledColor: CineMarketplaceVisuals.of(context).gold,
                  decoration: InputDecoration(
                    labelText: 'Working project',
                    labelStyle: CineMarketplaceVisuals.of(context).archivo(
                      size: 11.5,
                      color: CineMarketplaceVisuals.of(context).muted,
                    ),
                    prefixIcon: Icon(
                      Icons.movie_creation_outlined,
                      color: CineMarketplaceVisuals.of(context).gold,
                    ),
                    filled: true,
                    fillColor: CineMarketplaceVisuals.of(context).surface,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: CineMarketplaceVisuals.of(context).border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: CineMarketplaceVisuals.of(context).gold,
                      ),
                    ),
                  ),
                  items: [
                    for (final project in activeProjects)
                      DropdownMenuItem(
                        value: project.publicId,
                        child: Text(
                          project.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _projectId = value),
                ),
              ),
              const SizedBox(height: 16),
              TourTarget(
                id: 'brand.discovery.categories',
                child: CineAnimatedFilterRail<String>(
                  values: _brandDiscoveryCategories,
                  selected: _category,
                  onSelected: (category) {
                    setState(() => _category = category);
                    _load();
                  },
                  labelFor: (category) => category,
                  railColor: CineMarketplaceVisuals.of(context).surface,
                  selectedColor: CineMarketplaceVisuals.of(context).gold,
                  selectedTextColor: CineMarketplaceVisuals.of(context).onGold,
                  textColor: CineMarketplaceVisuals.of(context).secondary,
                  borderColor: CineMarketplaceVisuals.of(context).border,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            InlineNotice(
              message: _error!,
              icon: Icons.warning_amber_rounded,
              tone: CoreStatusTone.warning,
            ),
            const SizedBox(height: 12),
          ],
          if (_loading && !_loaded)
            const Column(
              children: [
                SkeletonCard(height: 144),
                SizedBox(height: 10),
                SkeletonCard(height: 144),
                SizedBox(height: 10),
                SkeletonCard(height: 144),
              ],
            )
          else if (_items.isEmpty)
            CoreEmptyState(
              icon: Icons.manage_search_outlined,
              title: 'No live listings match',
              message:
                  'Try another category or search. Only published, approved resources are shown.',
              actionLabel: 'Refresh',
              onAction: _load,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BrandResultsToolbar(
                  count: _items.length,
                  category: _category,
                  viewMode: _viewMode,
                  onViewModeChanged: _setViewMode,
                ),
                const SizedBox(height: 12),
                TourTarget(
                  id: 'brand.discovery.results',
                  child: _category == 'All'
                      ? _buildGroupedResults()
                      : CineMarketplaceResults(
                          grid: _viewMode == _BrandMarketplaceViewMode.grid,
                          cards: [
                            for (final entry in _items.indexed)
                              _buildMarketplaceCard(entry.$2, entry.$1),
                          ],
                        ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Project? get _selectedProject {
    for (final project in _projects) {
      if (project.publicId == _projectId) return project;
    }
    return null;
  }

  Widget _buildGroupedResults() {
    final grouped = <String, List<DirectorDiscoveryItem>>{};
    for (final item in _items) {
      grouped.putIfAbsent(_categoryForItem(item), () => []).add(item);
    }
    var globalIndex = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final category in _brandDiscoveryCategories.skip(1))
          if (grouped[category]?.isNotEmpty ?? false) ...[
            _BrandCategoryHeading(
              category: category,
              count: grouped[category]!.length,
              onViewAll: () {
                setState(() => _category = category);
                _load();
              },
            ),
            const SizedBox(height: 10),
            CineMarketplaceResults(
              grid: _viewMode == _BrandMarketplaceViewMode.grid,
              cards: [
                for (final item in grouped[category]!)
                  _buildMarketplaceCard(item, globalIndex++),
              ],
            ),
            const SizedBox(height: 20),
          ],
      ],
    );
  }

  Widget _buildMarketplaceCard(DirectorDiscoveryItem item, int index) {
    return CineMarketplaceCard(
      title: item.title,
      kind: item.kind,
      category: item.category,
      subtitle: item.subtitle,
      summary: item.summary,
      city: item.cityName,
      rateLabel: item.rateLabel,
      pricingMode: item.pricingMode,
      allowsBargaining: item.allowsBargaining,
      verificationStatus: item.verificationStatus,
      imageUrl: item.coverImageUrl,
      tags: item.tags,
      available: item.available,
      rating: item.ratingAverage.toDouble(),
      trustScore: item.trustMetrics?.score,
      busy: _loading,
      featured: index == 0,
      onProfile: () => _showProfile(item),
      onShortlist: () => _shortlist(item),
      onRequest: () => _request(item),
    );
  }

  Future<bool> _shortlist(DirectorDiscoveryItem item) async {
    final listingId = item.listingId;
    final project = _selectedProject;
    if (listingId == null) {
      brandSnack(
          context, 'This provider has not published a bookable listing yet');
      return false;
    }
    if (project == null) {
      brandSnack(context, 'Select or create a project first');
      return false;
    }
    setState(() => _loading = true);
    try {
      await _auth!.addToProjectShortlist(
        listingId: listingId,
        projectId: project.publicId,
        projectTitle: project.title,
      );
      if (mounted) {
        brandSnack(context, '${item.title} added to ${project.title}');
      }
      return true;
    } catch (error) {
      if (mounted) brandSnack(context, brandApiMessage(error));
      return false;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _request(DirectorDiscoveryItem item) async {
    final listingId = item.listingId;
    if (listingId == null) {
      brandSnack(
          context, 'This provider has not published a bookable listing yet');
      return;
    }
    final sent = await showBrandBookingDialog(
      context,
      listingId: listingId,
      listingTitle: item.title,
      projects: _projects,
      initialProjectId: _projectId,
      suggestedRateMinor: item.rateFromMinor,
      currency: item.currency,
      pricingMode: item.pricingMode,
      allowsBargaining: item.allowsBargaining,
    );
    if (sent && mounted) brandSnack(context, 'Booking request sent');
  }

  void _showProfile(DirectorDiscoveryItem item) {
    showBrandSheet(
      context,
      title: item.title,
      maxWidth: 980,
      child: FutureBuilder<DirectorDiscoveryItem>(
        future: _auth!.brandDiscoveryItem(
          kind: item.kind,
          publicId: item.listingId ?? item.publicId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Column(
              children: [
                SkeletonCard(height: 310),
                SizedBox(height: 12),
                SkeletonCard(height: 180),
              ],
            );
          }
          if (snapshot.hasError) {
            return InlineNotice(
              message: brandApiMessage(snapshot.error!),
              icon: Icons.error_outline_rounded,
              tone: CoreStatusTone.danger,
            );
          }
          final detail = snapshot.data!;
          final trust = detail.trustMetrics;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TalentProfileShowcase(
                name: detail.title,
                role: detail.category,
                city: detail.cityName,
                summary: detail.summary,
                portraitUrl: detail.coverImageUrl,
                verified: detail.verificationStatus == 'approved',
                available: detail.available,
                rateLabel: detail.allowsBargaining
                    ? 'Open to negotiation'
                    : 'Request terms',
                rating: trust?.ratingAverage ??
                    (detail.ratingAverage > 0
                        ? detail.ratingAverage.toDouble()
                        : null),
                reviewCount: trust?.reviewCount,
                highlights: [
                  ...detail.tags,
                  if (trust != null && trust.score > 0)
                    'Trust ${trust.score}/100',
                ],
                badge: _profileBadge(detail.kind),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  BrandLiveStatusChip(status: detail.verificationStatus),
                  Chip(label: Text(detail.cityName)),
                  Chip(
                    label: Text(
                      detail.allowsBargaining
                          ? 'Negotiation available'
                          : 'Terms shared in booking',
                    ),
                  ),
                  if (detail.trustMetrics?.score != null)
                    Chip(
                        label: Text('Trust ${detail.trustMetrics!.score}/100')),
                ],
              ),
              for (final section in detail.sections) ...[
                const SizedBox(height: 16),
                Text(
                  section.title,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                for (final row in section.rows)
                  BrandInfoRow(
                    icon: Icons.check_circle_outline_rounded,
                    label: row.label,
                    value: row.value,
                  ),
              ],
              if (detail.media.isNotEmpty) ...[
                const SizedBox(height: 18),
                TalentProfileGallery(
                  items: [
                    for (final media in detail.media)
                      TalentProfileGalleryItem(
                        label: media.caption ??
                            media.file?.originalName ??
                            'Portfolio media',
                        imageUrl: media.file?.publicUrl,
                        isVideo:
                            media.file?.mimeType.startsWith('video/') ?? false,
                      ),
                  ],
                  onOpen: (media) {
                    final url = media.imageUrl;
                    if (url != null) openUrlInNewTab(url);
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _BrandMarketplaceSearch extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback? onRefresh;

  const _BrandMarketplaceSearch({
    required this.onChanged,
    required this.onRefresh,
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
                  size: 21,
                  color: CineMarketplaceVisuals.of(context).muted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: onChanged,
                    cursorColor: CineMarketplaceVisuals.of(context).gold,
                    style:
                        CineMarketplaceVisuals.of(context).archivo(size: 13.5),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Search name, skill, city or equipment…',
                      hintStyle: CineMarketplaceVisuals.of(context).archivo(
                        size: 13.5,
                        color: CineMarketplaceVisuals.of(context).muted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 9),
        Tooltip(
          message: 'Refresh marketplace',
          child: Material(
            color: CineMarketplaceVisuals.of(context).gold,
            borderRadius: BorderRadius.circular(17),
            child: InkWell(
              onTap: onRefresh,
              borderRadius: BorderRadius.circular(17),
              child: SizedBox(
                width: 56,
                height: 56,
                child: onRefresh == null
                    ? Padding(
                        padding: const EdgeInsets.all(18),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: CineMarketplaceVisuals.of(context).onGold,
                        ),
                      )
                    : Icon(
                        Icons.refresh_rounded,
                        color: CineMarketplaceVisuals.of(context).onGold,
                        size: 21,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandResultsToolbar extends StatelessWidget {
  final int count;
  final String category;
  final _BrandMarketplaceViewMode viewMode;
  final ValueChanged<_BrandMarketplaceViewMode> onViewModeChanged;

  const _BrandResultsToolbar({
    required this.count,
    required this.category,
    required this.viewMode,
    required this.onViewModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '$count approved ${count == 1 ? 'listing' : 'listings'}'
          '${category == 'All' ? '' : ' · $category'}',
          style: CineMarketplaceVisuals.of(context).archivo(
            size: 11.5,
            weight: FontWeight.w600,
            color: CineMarketplaceVisuals.of(context).secondary,
          ),
        ),
        SizedBox(
          width: 194,
          child: CineAnimatedFilterRail<_BrandMarketplaceViewMode>(
            values: _BrandMarketplaceViewMode.values,
            selected: viewMode,
            onSelected: onViewModeChanged,
            labelFor: (mode) =>
                mode == _BrandMarketplaceViewMode.list ? 'List' : 'Grid',
            iconFor: (mode) => mode == _BrandMarketplaceViewMode.list
                ? Icons.view_agenda_outlined
                : Icons.grid_view_rounded,
            showSelectionDot: false,
            itemHeight: 38,
            selectedColor: CineMarketplaceVisuals.of(context).gold,
            selectedTextColor: CineMarketplaceVisuals.of(context).onGold,
            railColor: CineMarketplaceVisuals.of(context).surface,
            textColor: CineMarketplaceVisuals.of(context).secondary,
            borderColor: CineMarketplaceVisuals.of(context).border,
          ),
        ),
      ],
    );
  }
}

class _BrandCategoryHeading extends StatelessWidget {
  final String category;
  final int count;
  final VoidCallback onViewAll;

  const _BrandCategoryHeading({
    required this.category,
    required this.count,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final visuals = CineMarketplaceVisuals.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            '$category · $count',
            style: visuals.archivo(
              size: 15,
              weight: FontWeight.w700,
              color: visuals.ink,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onViewAll,
          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
          label: const Text('View all'),
          style: TextButton.styleFrom(
            foregroundColor: visuals.gold,
            textStyle: visuals.archivo(size: 12, weight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

String _categoryForItem(DirectorDiscoveryItem item) {
  return switch (item.kind.toLowerCase()) {
    'actor' => 'Actors',
    'model' => 'Models',
    'influencer' => 'Influencers',
    'crew' => 'Crew',
    'location' => 'Locations',
    'equipment' => 'Media & Equipment',
    'agency' => 'Agencies',
    'distribution' => 'Distribution',
    _ => item.category,
  };
}

String _profileBadge(String kind) {
  return switch (kind.toLowerCase()) {
    'actor' => 'Screen-ready actor',
    'model' => 'Campaign-ready model',
    'influencer' => 'Verified creator profile',
    'crew' => 'Production-ready crew',
    'location' => 'Camera-ready location',
    'equipment' => 'Production-ready package',
    'agency' => 'Verified casting partner',
    'distribution' => 'Release-ready partner',
    _ => 'Verified CineConnect profile',
  };
}
