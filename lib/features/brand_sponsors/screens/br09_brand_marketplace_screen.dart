import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/director/director_discovery_models.dart';
import '../../../core/marketplace/marketplace_models.dart';
import '../../../core/network/open_url.dart';
import '../../../core/projects/project_models.dart';
import '../../../core/projects/projects_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/tour/tour_target.dart';
import '../../../core/trust_safety/trust_safety_controller.dart';
import '../../../core/trust_safety/trust_safety_models.dart';
import '../../../shared/widgets/talent_profile_showcase.dart';
import '../../../shared/widgets/cine_marketplace_card.dart';
import '../../../shared/widgets/cine_v3_motion.dart';
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
  BookingsController? _bookingsController;
  List<Project> _projects = const [];
  List<DirectorDiscoveryItem> _items = const [];
  List<Booking> _bookings = const [];
  String _category = 'All';
  String _query = '';
  String? _projectId;
  String _city = 'All cities';
  bool _verifiedOnly = true;
  bool _availableOnly = false;
  String? _error;
  bool _loading = false;
  bool _loaded = false;
  Timer? _searchTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.maybeOf(context);
    final projects = ProjectsScope.maybeOf(context);
    final bookings = BookingsScope.maybeOf(context);
    if (identical(auth, _auth) &&
        identical(projects, _projectsController) &&
        identical(bookings, _bookingsController)) {
      return;
    }
    _auth = auth;
    _projectsController = projects;
    _bookingsController = bookings;
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
      final bookings = includeProjects && _bookingsController != null
          ? _bookingsController!.bookings()
          : Future<List<Booking>>.value(_bookings);
      final values = await Future.wait<Object>([discovery, projects, bookings]);
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
        _bookings = values[2] as List<Booking>;
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
    final cities = _items
        .map((item) => item.cityName)
        .where((city) => city.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final visibleItems = _items.where((item) {
      final isVerified = const {'approved', 'verified', 'published', 'active'}
          .contains(item.verificationStatus.toLowerCase());
      return (!_verifiedOnly || isVerified) &&
          (!_availableOnly || item.available) &&
          (_city == 'All cities' || item.cityName == _city);
    }).toList();
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
                CineV3SlidingFilterBar(
                  labels: _brandDiscoveryCategories,
                  selected: _category,
                  onChanged: (category) {
                    setState(() => _category = category);
                    _load();
                  },
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        initialValue:
                            cities.contains(_city) ? _city : 'All cities',
                        decoration: const InputDecoration(
                          labelText: 'City',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'All cities',
                            child: Text('All cities'),
                          ),
                          for (final city in cities)
                            DropdownMenuItem(value: city, child: Text(city)),
                        ],
                        onChanged: (value) =>
                            setState(() => _city = value ?? 'All cities'),
                      ),
                    ),
                    FilterChip(
                      avatar: const Icon(Icons.verified_outlined, size: 18),
                      label: const Text('Verified only'),
                      selected: _verifiedOnly,
                      onSelected: (value) =>
                          setState(() => _verifiedOnly = value),
                    ),
                    FilterChip(
                      avatar:
                          const Icon(Icons.event_available_outlined, size: 18),
                      label: const Text('Available now'),
                      selected: _availableOnly,
                      onSelected: (value) =>
                          setState(() => _availableOnly = value),
                    ),
                    Text(
                      '${visibleItems.length} results',
                      style: AppTextStyles.smallMeta.copyWith(
                        color: context.appColors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
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
        else if (visibleItems.isEmpty)
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
                for (final entry in visibleItems.indexed)
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
                    onQuickView: () => _showQuickView(entry.$2),
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

  void _showQuickView(DirectorDiscoveryItem item) {
    showBrandSheet(
      context,
      title: 'Quick view',
      maxWidth: 680,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BrandMediaFrame(
            imageUrl: item.coverImageUrl ?? '',
            title: item.title,
            badge: item.verificationStatus == 'approved'
                ? 'Verified'
                : readableBrandStatus(item.verificationStatus),
            fallbackIcon: _categoryIcon(item.kind),
            aspectRatio: 16 / 10,
          ),
          const SizedBox(height: 16),
          Text(
            item.title,
            style: AppTextStyles.sectionTitle.copyWith(
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.summary.trim().isEmpty
                ? 'Open the full profile for portfolio, documents and booking history.'
                : item.summary,
            style: AppTextStyles.body.copyWith(
              color: context.appColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.verified_rounded, size: 18),
                label: Text(readableBrandStatus(item.verificationStatus)),
              ),
              Chip(
                avatar: const Icon(Icons.location_on_outlined, size: 18),
                label: Text(item.cityName),
              ),
              Chip(
                avatar: const Icon(Icons.payments_outlined, size: 18),
                label: Text(item.rateLabel),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showProfile(item);
                },
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open full profile'),
              ),
              OutlinedButton.icon(
                onPressed: () => _shortlist(item),
                icon: const Icon(Icons.favorite_border_rounded),
                label: const Text('Shortlist'),
              ),
              OutlinedButton.icon(
                onPressed: () => _request(item),
                icon: const Icon(Icons.send_outlined),
                label: const Text('Request'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showProfile(DirectorDiscoveryItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(
            name: '/brand/discover/${item.kind}/${item.publicId}'),
        builder: (_) => BrandMarketplaceProfileScreen(
          title: item.title,
          detail: _auth!.brandDiscoveryItem(
            kind: item.kind,
            publicId: item.listingId ?? item.publicId,
          ),
          bookings: _bookings,
          onShortlist: _shortlist,
          onRequest: _request,
        ),
      ),
    );
  }
}

class BrandMarketplaceProfileScreen extends StatelessWidget {
  final String title;
  final Future<DirectorDiscoveryItem> detail;
  final List<Booking> bookings;
  final Future<bool> Function(DirectorDiscoveryItem)? onShortlist;
  final ValueChanged<DirectorDiscoveryItem> onRequest;

  const BrandMarketplaceProfileScreen({
    super.key,
    required this.title,
    required this.detail,
    required this.bookings,
    this.onShortlist,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: FutureBuilder<DirectorDiscoveryItem>(
        future: detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: InlineNotice(
                  message: brandApiMessage(snapshot.error!),
                  icon: Icons.error_outline_rounded,
                  tone: CoreStatusTone.danger,
                ),
              ),
            );
          }
          final item = snapshot.data!;
          Booking? reviewBooking;
          for (final booking in bookings) {
            if (booking.listingId == item.listingId &&
                booking.status == 'secured') {
              reviewBooking = booking;
              break;
            }
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: _MarketplaceProfileContent(
                  detail: item,
                  reviewBooking: reviewBooking,
                  onShortlist:
                      onShortlist == null ? null : () => onShortlist!(item),
                  onRequest: () => onRequest(item),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MarketplaceProfileContent extends StatelessWidget {
  final DirectorDiscoveryItem detail;
  final Booking? reviewBooking;
  final Future<bool> Function()? onShortlist;
  final VoidCallback onRequest;

  const _MarketplaceProfileContent({
    required this.detail,
    required this.reviewBooking,
    required this.onShortlist,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final trust = detail.trustMetrics;
    final isLocation = detail.kind.toLowerCase() == 'location';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TalentProfileShowcase(
          name: detail.title,
          role: detail.category,
          city: detail.cityName,
          summary: detail.summary,
          portraitUrl: detail.ownerAvatarUrl,
          coverUrl: detail.coverImageUrl,
          verified: detail.verificationStatus == 'approved' ||
              detail.verificationStatus == 'verified',
          available: detail.available,
          rateLabel: detail.rateLabel,
          rating: trust?.ratingAverage ??
              (detail.ratingAverage > 0
                  ? detail.ratingAverage.toDouble()
                  : null),
          reviewCount: trust?.reviewCount,
          highlights: [
            ...detail.tags,
            if (trust != null && trust.score > 0) 'Trust ${trust.score}/100',
          ],
          badge: _profileBadge(detail.kind),
          actions: [
            FilledButton.icon(
              onPressed: onRequest,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Request booking'),
            ),
            if (onShortlist != null)
              OutlinedButton.icon(
                onPressed: onShortlist,
                icon: const Icon(Icons.favorite_border_rounded),
                label: const Text('Add to shortlist'),
              ),
          ],
        ),
        if (detail.media.isNotEmpty) ...[
          const SizedBox(height: 20),
          TalentProfileGallery(
            items: [
              for (final media in detail.media)
                TalentProfileGalleryItem(
                  label: media.caption ??
                      media.file?.originalName ??
                      (isLocation ? 'Property photo' : 'Portfolio media'),
                  imageUrl: media.file?.publicUrl,
                  isVideo: media.file?.mimeType.startsWith('video/') ?? false,
                ),
            ],
            onOpen: (media) {
              final url = media.imageUrl;
              if (url != null) openUrlInNewTab(url);
            },
          ),
        ],
        const SizedBox(height: 20),
        BrandTwoColumn(
          left: BrandSectionCard(
            title: isLocation ? 'About this location' : 'Profile details',
            icon: isLocation
                ? Icons.location_city_outlined
                : Icons.badge_outlined,
            selected: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.summary.trim().isEmpty
                      ? 'The provider has not added a description yet.'
                      : detail.summary,
                  style: AppTextStyles.body.copyWith(
                    color: context.appColors.textSecondary,
                    height: 1.55,
                  ),
                ),
                for (final section in detail.sections) ...[
                  const SizedBox(height: 18),
                  Text(
                    section.title,
                    style: AppTextStyles.cardLabel.copyWith(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final row in section.rows)
                    BrandInfoRow(
                      icon: Icons.check_circle_outline_rounded,
                      label: row.label,
                      value: row.value,
                    ),
                ],
              ],
            ),
          ),
          right: Column(
            children: [
              BrandSectionCard(
                title: 'Trust & documents',
                icon: Icons.verified_user_outlined,
                tone: BrandTone.green,
                child: Column(
                  children: [
                    BrandInfoRow(
                      icon: Icons.verified_rounded,
                      label: 'Verification',
                      value: readableBrandStatus(detail.verificationStatus),
                    ),
                    BrandInfoRow(
                      icon: Icons.star_outline_rounded,
                      label: 'Reviews',
                      value: trust == null || trust.reviewCount == 0
                          ? 'No reviews yet'
                          : '${trust.ratingAverage.toStringAsFixed(1)} from ${trust.reviewCount}',
                    ),
                    BrandInfoRow(
                      icon: Icons.shield_outlined,
                      label: 'Trust score',
                      value: trust == null ? 'Building' : '${trust.score}/100',
                    ),
                    if (detail.resumeFile?.publicUrl != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              openUrlInNewTab(detail.resumeFile!.publicUrl!),
                          icon: const Icon(Icons.description_outlined),
                          label: const Text('Open CV / profile document'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _MarketplaceReviews(
                ownerPublicId: detail.ownerPublicId,
                booking: reviewBooking,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MarketplaceReviews extends StatefulWidget {
  final String? ownerPublicId;
  final Booking? booking;

  const _MarketplaceReviews({
    required this.ownerPublicId,
    required this.booking,
  });

  @override
  State<_MarketplaceReviews> createState() => _MarketplaceReviewsState();
}

class _MarketplaceReviewsState extends State<_MarketplaceReviews> {
  Future<UserReviewsDto>? _reviews;
  Future<Map<String, dynamic>>? _eligibility;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final trust = TrustSafetyScope.maybeOf(context);
    if (trust == null) return;
    final ownerId = widget.ownerPublicId;
    if (_reviews == null && ownerId?.isNotEmpty == true) {
      _reviews = trust.userReviews(ownerId!);
    }
    final booking = widget.booking;
    if (_eligibility == null && booking != null) {
      _eligibility = trust.reviewEligibility(booking.publicId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BrandSectionCard(
      title: 'Verified booking reviews',
      icon: Icons.reviews_outlined,
      tone: BrandTone.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_reviews == null)
            const Text('Reviews will appear after verified bookings.')
          else
            FutureBuilder<UserReviewsDto>(
              future: _reviews,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LinearProgressIndicator();
                }
                final reviews = snapshot.data?.reviews ?? const <ReviewDto>[];
                if (reviews.isEmpty) {
                  return const Text('No published reviews yet.');
                }
                return Column(
                  children: [
                    for (final review in reviews.take(4))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          child: Text('${review.rating}'),
                        ),
                        title: Text(review.reviewer.displayName),
                        subtitle: Text(
                          review.text?.trim().isNotEmpty == true
                              ? review.text!
                              : '${review.rating} out of 5 stars',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.verified_outlined),
                      ),
                  ],
                );
              },
            ),
          if (_eligibility != null) ...[
            const SizedBox(height: 10),
            FutureBuilder<Map<String, dynamic>>(
              future: _eligibility,
              builder: (context, snapshot) {
                final eligible = snapshot.data?['eligible'] == true;
                final reviewed = snapshot.data?['already_reviewed'] == true;
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox.shrink();
                }
                if (eligible) {
                  return FilledButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      CoreRoutes.review,
                      arguments: widget.booking!.publicId,
                    ),
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('Write a verified review'),
                  );
                }
                return Text(
                  reviewed
                      ? 'You already reviewed this booking.'
                      : 'Reviews unlock after a booking is secured.',
                  style: AppTextStyles.smallMeta.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

IconData _categoryIcon(String category) {
  return switch (category.toLowerCase()) {
    'actor' || 'actors' => Icons.theater_comedy_outlined,
    'model' || 'models' => Icons.person_search_outlined,
    'location' || 'locations' => Icons.location_city_outlined,
    'equipment' || 'media & equipment' => Icons.videocam_outlined,
    'crew' => Icons.groups_outlined,
    'agency' || 'agencies' => Icons.business_outlined,
    'distribution' => Icons.hub_outlined,
    _ => Icons.auto_awesome_outlined,
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
