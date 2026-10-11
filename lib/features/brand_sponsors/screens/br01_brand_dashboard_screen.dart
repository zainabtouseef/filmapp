import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/director/director_dashboard_models.dart';
import '../../../core/marketplace/marketplace_models.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/tour/tour_target.dart';
import '../../../shared/dashboard/dashboard_kit.dart';
import '../routes/brand_sponsor_routes.dart';
import '../widgets/brand_sponsor_components.dart';
import '../widgets/brand_demo_journey.dart';
import '../widgets/brand_sponsor_live.dart';
import '../widgets/brand_sponsor_shell.dart' show startBrandFullWalkthrough;

class BR01BrandDashboardScreen extends StatefulWidget {
  const BR01BrandDashboardScreen({super.key});

  @override
  State<BR01BrandDashboardScreen> createState() =>
      _BR01BrandDashboardScreenState();
}

class _BR01BrandDashboardScreenState extends State<BR01BrandDashboardScreen> {
  SpecialistController? _specialist;
  BookingsController? _bookingsController;
  AuthController? _auth;
  BrandProfileDto? _profile;
  List<BrandOpportunityDto> _opportunities = const [];
  List<BrandApplicationDto> _applications = const [];
  List<CampaignDeliverableDto> _deliverables = const [];
  DirectorDashboard? _productionDashboard;
  List<Booking> _productionBookings = const [];
  MarketplaceShortlistBundle? _shortlistBundle;
  bool _loading = false;
  bool _loaded = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final specialist = SpecialistScope.maybeOf(context);
    final bookings = BookingsScope.maybeOf(context);
    final auth = AuthScope.maybeOf(context);
    if (identical(specialist, _specialist) &&
        identical(bookings, _bookingsController) &&
        identical(auth, _auth)) {
      return;
    }
    _specialist = specialist;
    _bookingsController = bookings;
    _auth = auth;
    if (specialist != null) _load(force: true);
  }

  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _specialist!.brandProfile(force: force);
      List<BrandOpportunityDto> opportunities = const [];
      List<BrandApplicationDto> applications = const [];
      List<CampaignDeliverableDto> deliverables = const [];
      if (profile != null) {
        final values = await Future.wait<Object>([
          _specialist!.brandOpportunities(force: force),
          _specialist!.ownerBrandApplications(force: force),
          _specialist!.campaignDeliverables(force: force),
        ]);
        opportunities = values[0] as List<BrandOpportunityDto>;
        applications = values[1] as List<BrandApplicationDto>;
        deliverables = values[2] as List<CampaignDeliverableDto>;
      }
      DirectorDashboard? productionDashboard;
      List<Booking> productionBookings = const [];
      MarketplaceShortlistBundle? shortlistBundle;
      if (_auth?.isAuthenticated == true) {
        final productionValues = await Future.wait<Object>([
          _auth!.brandProductionDashboard(),
          _auth!.shortlistBundle(),
          if (_bookingsController != null)
            _bookingsController!.bookings(force: force)
          else
            Future<List<Booking>>.value(const []),
        ]);
        productionDashboard = productionValues[0] as DirectorDashboard;
        shortlistBundle = productionValues[1] as MarketplaceShortlistBundle;
        productionBookings = productionValues[2] as List<Booking>;
      }
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _opportunities = opportunities;
        _applications = applications;
        _deliverables = deliverables;
        _productionDashboard = productionDashboard;
        _shortlistBundle = shortlistBundle;
        _productionBookings = productionBookings;
        _loaded = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = brandApiMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_specialist == null) {
      return const CoreEmptyState(
        icon: Icons.cloud_sync_outlined,
        title: 'Sign in to load brand data',
        message:
            'This dashboard only shows live opportunities, applications, deliverables and payments fetched from the backend.',
      );
    }
    if (_loading && !_loaded) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_error != null && !_loaded) {
      return CoreEmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Workspace unavailable',
        message: _error!,
        actionLabel: 'Try again',
        onAction: () => _load(force: true),
      );
    }
    if (_profile == null) {
      return CoreEmptyState(
        icon: Icons.business_center_outlined,
        title: 'Create your brand profile',
        message:
            'Add the organization identity used on opportunities, applications and campaign records.',
        actionLabel: 'Create profile',
        onAction: () =>
            Navigator.pushNamed(context, BrandSponsorRoutes.profile),
      );
    }

    final openOpportunities = _opportunities
        .where((item) => item.status == 'published' || item.status == 'paused')
        .length;
    final pendingApplications = _applications
        .where((item) => {
              'submitted',
              'reviewing',
              'shortlisted',
              'negotiating',
            }.contains(item.status))
        .length;
    final reviewDeliverables = _deliverables
        .where((item) =>
            item.status == 'submitted' || item.status == 'revision_requested')
        .length;
    final active = activeBrandOpportunity(_opportunities);
    final production = _productionDashboard?.summary;
    final demoProject = isBrandDemoAccount(_auth)
        ? selectBrandDemoProject(_productionDashboard?.projects ?? const [])
        : null;
    return PortalDashboardPage(
      children: [
        TourTarget(
          id: 'brand.dashboard.hero',
          child: PortalHeroCard(
            initials: _brandInitials(_profile!.name),
            name: _profile!.name,
            badgeLabel: readableBrandStatus(_profile!.trustStatus),
            stats: [
              PortalHeroStat(
                value: '$openOpportunities',
                label: 'Live opportunities',
              ),
              PortalHeroStat(
                value: brandMoney(
                  production?.committedBudgetMinor,
                  currency: production?.currency ?? 'PKR',
                ),
                label: 'Committed budget',
              ),
              PortalHeroStat(
                value: '${production?.securedBookings ?? 0}',
                label: 'Confirmed bookings',
              ),
            ],
            ctaLabel: 'New opportunity',
            onCta: () =>
                Navigator.pushNamed(context, BrandSponsorRoutes.composer),
          ),
        ),
        if (_error != null)
          InlineNotice(
            message: _error!,
            icon: Icons.warning_amber_rounded,
            tone: CoreStatusTone.warning,
          ),
        if (demoProject != null)
          BrandDemoJourneyCard(
            project: demoProject,
            shortlistCount: (_shortlistBundle?.shortlists ?? const [])
                .where((board) => board.projectId == demoProject.publicId)
                .fold<int>(0, (total, board) => total + board.items.length),
            requestCount: _productionBookings
                .where((booking) => booking.projectId == demoProject.publicId)
                .length,
            confirmedCount: _productionBookings
                .where((booking) =>
                    booking.projectId == demoProject.publicId &&
                    {'accepted', 'secured', 'completed'}
                        .contains(booking.status))
                .length,
            onPlay: () => startBrandFullWalkthrough(context),
          ),
        TourTarget(
          id: 'brand.dashboard.commandCentre',
          child: PortalCommandCenter(
            eyebrow: 'Brand operations',
            title: 'Campaign Command Centre',
            subtitle: 'Brief progress, approvals and organization readiness.',
            icon: Icons.campaign_outlined,
            primaryTitle:
                active == null ? 'Opportunity portfolio' : 'Active brief',
            actionLabel:
                active == null ? 'Create opportunity' : 'Open applications',
            onAction: () => Navigator.pushNamed(
              context,
              active == null
                  ? BrandSponsorRoutes.composer
                  : BrandSponsorRoutes.applications,
            ),
            primary: active == null
                ? const CoreEmptyState(
                    icon: Icons.campaign_outlined,
                    title: 'No opportunities yet',
                    message:
                        'Create a clear brief with budget, usage, eligibility and deliverables.',
                  )
                : _ActiveOpportunity(
                    opportunity: active,
                    onApplications: () => Navigator.pushNamed(
                      context,
                      BrandSponsorRoutes.applications,
                    ),
                  ),
            actions: [
              PortalCommandAction(
                icon: Icons.inbox_outlined,
                title: 'Applications to review',
                subtitle: 'Shortlist and respond to creator submissions',
                value: '$pendingApplications',
                onTap: () => Navigator.pushNamed(
                  context,
                  BrandSponsorRoutes.applications,
                ),
              ),
              PortalCommandAction(
                icon: Icons.fact_check_outlined,
                title: 'Deliverable approvals',
                subtitle: 'Review submitted campaign work',
                value: '$reviewDeliverables',
                onTap: () => Navigator.pushNamed(
                  context,
                  BrandSponsorRoutes.tracker,
                ),
              ),
              PortalCommandAction(
                icon: Icons.edit_note_outlined,
                title: 'Draft opportunities',
                subtitle: 'Complete and publish pending briefs',
                value:
                    '${_opportunities.where((item) => item.status == 'draft').length}',
                onTap: () => Navigator.pushNamed(
                  context,
                  BrandSponsorRoutes.composer,
                ),
              ),
              PortalCommandAction(
                icon: Icons.verified_user_outlined,
                title: 'Organization profile',
                subtitle:
                    '${_profile!.category ?? 'Category not set'} · ${readableBrandStatus(_profile!.trustStatus)}',
                onTap: () => Navigator.pushNamed(
                  context,
                  BrandSponsorRoutes.profile,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActiveOpportunity extends StatelessWidget {
  final BrandOpportunityDto opportunity;
  final VoidCallback onApplications;

  const _ActiveOpportunity({
    required this.opportunity,
    required this.onApplications,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandMediaFrame(
          imageUrl: opportunity.coverUrl,
          title: opportunity.title,
          badge: readableBrandStatus(opportunity.category),
          fallbackIcon: Icons.campaign_outlined,
          aspectRatio: 16 / 8.8,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                opportunity.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.metricNumberCompact.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            BrandLiveStatusChip(status: opportunity.status),
          ],
        ),
        const SizedBox(height: 10),
        BrandResponsiveGrid(
          minWidth: 190,
          children: [
            BrandInfoRow(
              icon: Icons.payments_outlined,
              label: 'Budget',
              value: brandMoney(
                opportunity.budgetMinor,
                currency: opportunity.currency,
              ),
            ),
            BrandInfoRow(
              icon: Icons.event_outlined,
              label: 'Applications close',
              value: brandDate(opportunity.applicationDueAt),
            ),
            BrandInfoRow(
              icon: Icons.inbox_outlined,
              label: 'Applications',
              value: '${opportunity.applicationCount}',
            ),
          ],
        ),
        if (opportunity.deliverables.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            opportunity.deliverables,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CoreSecondaryButton(
                icon: Icons.edit_outlined,
                label: 'Edit brief',
                compact: true,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    BrandSponsorRoutes.composer,
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CorePrimaryButton(
                icon: Icons.inbox_outlined,
                label: 'Applications',
                compact: true,
                onTap: onApplications,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _brandInitials(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}
