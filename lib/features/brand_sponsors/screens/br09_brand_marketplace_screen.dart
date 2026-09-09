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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TourTarget(
          id: 'brand:demo:working-project',
          child: BrandSectionCard(
            title: 'Discover verified production resources',
            icon: Icons.travel_explore_outlined,
            selected: true,
            child: Column(
              children: [
                BrandSearchField(
                  hintText: 'Search by name, skill, city or equipment...',
                  onChanged: (value) {
                    _query = value;
                    _searchTimer?.cancel();
                    _searchTimer = Timer(
                      const Duration(milliseconds: 350),
                      _load,
                    );
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey(_projectId),
                        initialValue: _projectId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Working project',
                          prefixIcon: Icon(Icons.movie_creation_outlined),
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
                        onChanged: (value) =>
                            setState(() => _projectId = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Refresh marketplace',
                      onPressed:
                          _loading ? null : () => _load(includeProjects: true),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final category in _brandDiscoveryCategories)
                        Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: FilterChip(
                            label: Text(category),
                            selected: _category == category,
                            onSelected: (_) {
                              setState(() => _category = category);
                              _load();
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_error != null) ...[
          InlineNotice(
            message: _error!,
            icon: Icons.warning_amber_rounded,
            tone: CoreStatusTone.warning,
          ),
          const SizedBox(height: 12),
        ],
        if (_loading && !_loaded)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
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
          TourTarget(
            id: 'brand:demo:discovery-results',
            child: CineMarketplaceResults(
              cards: [
                for (final entry in _items.indexed)
                  CineMarketplaceCard(
                    title: entry.$2.title,
                    kind: entry.$2.kind,
                    category: entry.$2.category,
                    subtitle: entry.$2.subtitle,
                    summary: entry.$2.summary,
                    city: entry.$2.cityName,
                    rateLabel: entry.$2.rateLabel,
                    verificationStatus: entry.$2.verificationStatus,
                    imageUrl: entry.$2.coverImageUrl,
                    tags: entry.$2.tags,
                    available: entry.$2.available,
                    rating: entry.$2.ratingAverage.toDouble(),
                    trustScore: entry.$2.trustMetrics?.score,
                    busy: _loading,
                    featured: entry.$1 == 0,
                    onProfile: () => _showProfile(entry.$2),
                    onShortlist: () => _shortlist(entry.$2),
                    onRequest: () => _request(entry.$2),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Project? get _selectedProject {
    for (final project in _projects) {
      if (project.publicId == _projectId) return project;
    }
    return null;
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
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
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
                rateLabel: detail.rateLabel,
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
                  Chip(label: Text(detail.rateLabel)),
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
