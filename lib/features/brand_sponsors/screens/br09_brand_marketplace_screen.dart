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
import '../models/brand_sponsor_models.dart';
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
            child: BrandResponsiveGrid(
              minWidth: 300,
              children: [
                for (final item in _items)
                  _DiscoveryCard(
                    item: item,
                    busy: _loading,
                    onProfile: () => _showProfile(item),
                    onShortlist: () => _shortlist(item),
                    onRequest: () => _request(item),
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

  Future<void> _shortlist(DirectorDiscoveryItem item) async {
    final listingId = item.listingId;
    final project = _selectedProject;
    if (listingId == null) {
      brandSnack(
          context, 'This provider has not published a bookable listing yet');
      return;
    }
    if (project == null) {
      brandSnack(context, 'Select or create a project first');
      return;
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
    } catch (error) {
      if (mounted) brandSnack(context, brandApiMessage(error));
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
          final talentProfile = {'actor', 'model', 'influencer'}
              .contains(detail.kind.toLowerCase());
          final trust = detail.trustMetrics;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (talentProfile)
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
                  badge: detail.kind == 'model'
                      ? 'Campaign-ready model'
                      : 'Screen-ready talent',
                )
              else
                Text(detail.summary),
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
              if (talentProfile && detail.media.isNotEmpty) ...[
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

class _DiscoveryCard extends StatelessWidget {
  final DirectorDiscoveryItem item;
  final bool busy;
  final VoidCallback onProfile;
  final VoidCallback onShortlist;
  final VoidCallback onRequest;

  const _DiscoveryCard({
    required this.item,
    required this.busy,
    required this.onProfile,
    required this.onShortlist,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return BrandSectionCard(
      title: item.title,
      icon: _discoveryIcon(item.kind),
      tone: item.verificationStatus == 'approved'
          ? BrandTone.green
          : BrandTone.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandMediaFrame(
            imageUrl: item.coverImageUrl ?? '',
            title: item.title,
            badge: item.verificationStatus == 'approved'
                ? 'Verified ${item.kind}'
                : readableBrandStatus(item.kind),
            fallbackIcon: _discoveryIcon(item.kind),
            aspectRatio: {'actor', 'model', 'influencer'}.contains(item.kind)
                ? 4 / 3
                : 16 / 9,
          ),
          const SizedBox(height: 12),
          Text(
            item.subtitle.isEmpty ? item.category : item.subtitle,
            style: AppTextStyles.smallMeta.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.summary,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              BrandLiveStatusChip(status: item.verificationStatus),
              Chip(label: Text(item.cityName)),
              Chip(label: Text(item.rateLabel)),
              if (item.trustMetrics?.score != null)
                Chip(label: Text('Trust ${item.trustMetrics!.score}/100')),
            ],
          ),
          if (item.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.tags.take(4).join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.smallMeta.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              TextButton.icon(
                onPressed: busy ? null : onProfile,
                icon: const Icon(Icons.person_search_outlined),
                label: const Text('Profile'),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : onShortlist,
                icon: const Icon(Icons.favorite_border_rounded),
                label: const Text('Shortlist'),
              ),
              FilledButton.icon(
                onPressed: busy ? null : onRequest,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Request'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

IconData _discoveryIcon(String kind) {
  return switch (kind) {
    'actor' => Icons.theater_comedy_outlined,
    'model' => Icons.accessibility_new_outlined,
    'influencer' => Icons.campaign_outlined,
    'crew' => Icons.groups_outlined,
    'location' => Icons.location_on_outlined,
    'equipment' => Icons.videocam_outlined,
    _ => Icons.storefront_outlined,
  };
}
