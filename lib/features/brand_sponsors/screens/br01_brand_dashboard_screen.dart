import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/director/director_dashboard_models.dart';
import '../../../core/marketplace/marketplace_models.dart';
import '../../../core/payments/payment_models.dart';
import '../../../core/payments/payments_controller.dart';
import '../../../core/profile/profile_models.dart';
import '../../../core/projects/project_models.dart';
import '../../../core/projects/projects_controller.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/brand_sponsor_models.dart';
import '../routes/brand_sponsor_routes.dart';
import '../widgets/brand_sponsor_components.dart';
import '../widgets/brand_demo_journey.dart';
import '../widgets/brand_sponsor_live.dart';
import '../widgets/brand_sponsor_shell.dart' show startBrandTour;
import 'br08_brand_projects_screen.dart' show showBrandProjectDialog;

class BR01BrandDashboardScreen extends StatefulWidget {
  const BR01BrandDashboardScreen({super.key});

  @override
  State<BR01BrandDashboardScreen> createState() =>
      _BR01BrandDashboardScreenState();
}

class _BR01BrandDashboardScreenState extends State<BR01BrandDashboardScreen> {
  SpecialistController? _specialist;
  PaymentsController? _payments;
  BookingsController? _bookingsController;
  ProjectsController? _projectsController;
  AuthController? _auth;
  BrandProfileDto? _profile;
  List<BrandOpportunityDto> _opportunities = const [];
  List<BrandApplicationDto> _applications = const [];
  List<CampaignDeliverableDto> _deliverables = const [];
  PaymentDashboardDto? _paymentDashboard;
  DirectorDashboard? _productionDashboard;
  List<Booking> _productionBookings = const [];
  MarketplaceShortlistBundle? _shortlistBundle;
  List<ProfileCity> _cities = const [];
  bool _loading = false;
  bool _loaded = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final specialist = SpecialistScope.maybeOf(context);
    final payments = PaymentsScope.maybeOf(context);
    final bookings = BookingsScope.maybeOf(context);
    final projects = ProjectsScope.maybeOf(context);
    final auth = AuthScope.maybeOf(context);
    if (identical(specialist, _specialist) &&
        identical(payments, _payments) &&
        identical(bookings, _bookingsController) &&
        identical(projects, _projectsController) &&
        identical(auth, _auth)) {
      return;
    }
    _specialist = specialist;
    _payments = payments;
    _bookingsController = bookings;
    _projectsController = projects;
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
      PaymentDashboardDto? paymentDashboard;
      if (_payments != null) {
        paymentDashboard = await _payments!.dashboard(force: force);
      }
      DirectorDashboard? productionDashboard;
      List<Booking> productionBookings = const [];
      MarketplaceShortlistBundle? shortlistBundle;
      if (_auth?.isAuthenticated == true) {
        final productionValues = await Future.wait<Object>([
          _auth!.brandProductionDashboard(),
          _auth!.shortlistBundle(),
          _auth!.cities(),
          if (_bookingsController != null)
            _bookingsController!.bookings(force: force)
          else
            Future<List<Booking>>.value(const []),
        ]);
        productionDashboard = productionValues[0] as DirectorDashboard;
        shortlistBundle = productionValues[1] as MarketplaceShortlistBundle;
        _cities = productionValues[2] as List<ProfileCity>;
        productionBookings = productionValues[3] as List<Booking>;
      }
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _opportunities = opportunities;
        _applications = applications;
        _deliverables = deliverables;
        _paymentDashboard = paymentDashboard;
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
    final metrics = [
      BrandMetric(
        label: 'Live opportunities',
        value: '$openOpportunities',
        delta: '${_opportunities.length} total briefs',
        icon: Icons.campaign_outlined,
        tone: BrandTone.gold,
        route: BrandSponsorRoutes.composer,
      ),
      BrandMetric(
        label: 'Applications',
        value: '${_applications.length}',
        delta: '$pendingApplications require review',
        icon: Icons.inbox_outlined,
        tone: BrandTone.blue,
        route: BrandSponsorRoutes.applications,
      ),
      BrandMetric(
        label: 'Delivery review',
        value: '$reviewDeliverables',
        delta: '${_deliverables.length} deliverables',
        icon: Icons.fact_check_outlined,
        tone: BrandTone.purple,
        route: BrandSponsorRoutes.tracker,
      ),
      BrandMetric(
        label: 'Recorded spend',
        value: brandMoney(_paymentDashboard?.debitMinor),
        delta: 'Posted ledger debits',
        icon: Icons.account_balance_wallet_outlined,
        tone: BrandTone.green,
        route: BrandSponsorRoutes.payments,
      ),
    ];
    final active = activeBrandOpportunity(_opportunities);
    final production = _productionDashboard?.summary;
    final projects = _productionDashboard?.projects ?? const <Project>[];
    final demoProject = isBrandDemoAccount(_auth)
        ? selectBrandDemoProject(_productionDashboard?.projects ?? const [])
        : null;
    final productionMetrics = [
      BrandMetric(
        label: 'Active projects',
        value: '${production?.activeProjects ?? 0}',
        delta: '${production?.projectCount ?? 0} projects total',
        icon: Icons.movie_creation_outlined,
        tone: BrandTone.gold,
        route: BrandSponsorRoutes.projects,
      ),
      BrandMetric(
        label: 'Confirmed bookings',
        value: '${production?.securedBookings ?? 0}',
        delta: 'Accepted and secured resources',
        icon: Icons.verified_outlined,
        tone: BrandTone.green,
        route: BrandSponsorRoutes.bookings,
      ),
      BrandMetric(
        label: 'Production actions',
        value: '${production?.attentionCount ?? 0}',
        delta: 'Requests and payments needing attention',
        icon: Icons.priority_high_rounded,
        tone: BrandTone.purple,
        route: BrandSponsorRoutes.bookings,
      ),
      BrandMetric(
        label: 'Committed budget',
        value: brandMoney(
          production?.committedBudgetMinor,
          currency: production?.currency ?? 'PKR',
        ),
        delta: brandMoney(
          production?.pendingPaymentMinor,
          currency: production?.currency ?? 'PKR',
        ),
        icon: Icons.account_balance_wallet_outlined,
        tone: BrandTone.blue,
        route: BrandSponsorRoutes.payments,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_error != null) ...[
          InlineNotice(
            message: _error!,
            icon: Icons.warning_amber_rounded,
            tone: CoreStatusTone.warning,
          ),
          const SizedBox(height: 12),
        ],
        _DashboardHero(
          projectCount: projects.length,
          busy: _loading,
          onCreate: _createProject,
          onBrowse: () => Navigator.pushNamed(
            context,
            BrandSponsorRoutes.marketplace,
          ),
          onDemo: demoProject == null ? null : () => startBrandTour(context),
        ),
        const SizedBox(height: 14),
        BrandKpiRail(metrics: productionMetrics),
        const SizedBox(height: 12),
        BrandKpiRail(metrics: metrics),
        const SizedBox(height: 12),
        _ProjectOverview(
          projects: projects,
          bookings: _productionBookings,
          shortlists: _shortlistBundle?.shortlists ?? const [],
          onCreate: _createProject,
          onOpenAll: () => Navigator.pushNamed(
            context,
            BrandSponsorRoutes.projects,
          ),
        ),
        const SizedBox(height: 12),
        if (demoProject != null) ...[
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
            onPlay: () => startBrandTour(context),
          ),
          const SizedBox(height: 12),
        ],
        BrandTwoColumn(
          left: BrandSectionCard(
            title: active == null ? 'Opportunity portfolio' : 'Active brief',
            icon: Icons.campaign_outlined,
            selected: true,
            child: active == null
                ? CoreEmptyState(
                    icon: Icons.campaign_outlined,
                    title: 'No opportunities yet',
                    message:
                        'Create a clear brief with budget, usage, eligibility and deliverables.',
                    actionLabel: 'Create opportunity',
                    onAction: () => Navigator.pushNamed(
                      context,
                      BrandSponsorRoutes.composer,
                    ),
                  )
                : _ActiveOpportunity(
                    opportunity: active,
                    onApplications: () {
                      Navigator.pushNamed(
                        context,
                        BrandSponsorRoutes.applications,
                      );
                    },
                  ),
          ),
          right: Column(
            children: [
              BrandSectionCard(
                title: 'Action required',
                icon: Icons.priority_high_rounded,
                tone: BrandTone.purple,
                child: _ActionQueue(
                  applications: pendingApplications,
                  deliverables: reviewDeliverables,
                  draftOpportunities: _opportunities
                      .where((item) => item.status == 'draft')
                      .length,
                ),
              ),
              const SizedBox(height: 12),
              BrandSectionCard(
                title: 'Organization readiness',
                icon: Icons.verified_user_outlined,
                tone: BrandTone.green,
                child: Column(
                  children: [
                    BrandInfoRow(
                      icon: Icons.business_outlined,
                      label: 'Organization',
                      value: _profile!.name,
                    ),
                    BrandInfoRow(
                      icon: Icons.category_outlined,
                      label: 'Category',
                      value: _profile!.category ?? 'Not set',
                    ),
                    BrandInfoRow(
                      icon: Icons.verified_outlined,
                      label: 'KYB status',
                      value: readableBrandStatus(_profile!.trustStatus),
                    ),
                    const SizedBox(height: 8),
                    CoreSecondaryButton(
                      icon: Icons.edit_outlined,
                      label: 'Review brand profile',
                      compact: true,
                      onTap: () => Navigator.pushNamed(
                        context,
                        BrandSponsorRoutes.profile,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _createProject() async {
    final controller = _projectsController;
    if (controller == null) {
      Navigator.pushNamed(context, BrandSponsorRoutes.projects);
      return;
    }
    final draft = await showBrandProjectDialog(context, cities: _cities);
    if (draft == null || !mounted) return;
    setState(() => _loading = true);
    try {
      await controller.createProject(
        title: draft.title,
        projectType: draft.type,
        description: draft.description,
        cityId: draft.cityId.isEmpty ? null : draft.cityId,
        startDate: draft.startDate,
        endDate: draft.endDate,
        estimatedBudgetMinor: draft.budgetMinor,
        status: draft.status,
      );
      await _load(force: true);
      if (mounted) brandSnack(context, 'Campaign created');
    } catch (error) {
      if (mounted) setState(() => _error = brandApiMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _DashboardHero extends StatelessWidget {
  final int projectCount;
  final bool busy;
  final VoidCallback onCreate;
  final VoidCallback onBrowse;
  final VoidCallback? onDemo;

  const _DashboardHero({
    required this.projectCount,
    required this.busy,
    required this.onCreate,
    required this.onBrowse,
    required this.onDemo,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colors.goldMid.withValues(alpha: 0.7)),
        gradient: LinearGradient(
          colors: [
            colors.goldMid.withValues(alpha: colors.isLight ? 0.16 : 0.24),
            colors.softSurface,
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CAMPAIGN COMMAND CENTER',
                style: AppTextStyles.micro.copyWith(
                  color: colors.goldDark,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create, cast and deliver your next campaign.',
                style: AppTextStyles.heroSerifNumber.copyWith(
                  color: colors.textPrimary,
                  fontSize: compact ? 32 : 40,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$projectCount project${projectCount == 1 ? '' : 's'} in this workspace. Build the brief, shortlist verified production resources and manage every request in one place.',
                style: AppTextStyles.body.copyWith(
                  color: colors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  key: const ValueKey('brand-create-project-primary'),
                  onPressed: busy ? null : onCreate,
                  icon: const Icon(Icons.add_rounded, size: 24),
                  label: const Text('Create project'),
                ),
              ),
              SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: onBrowse,
                  icon: const Icon(Icons.travel_explore_outlined),
                  label: const Text('Browse marketplace'),
                ),
              ),
              if (onDemo != null)
                SizedBox(
                  height: 56,
                  child: TextButton.icon(
                    onPressed: onDemo,
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    label: const Text('How to create a campaign'),
                  ),
                ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [copy, const SizedBox(height: 20), actions],
            );
          }
          return Row(
            children: [
              Expanded(flex: 6, child: copy),
              const SizedBox(width: 24),
              Expanded(flex: 4, child: actions),
            ],
          );
        },
      ),
    );
  }
}

class _ProjectOverview extends StatelessWidget {
  final List<Project> projects;
  final List<Booking> bookings;
  final List<MarketplaceShortlist> shortlists;
  final VoidCallback onCreate;
  final VoidCallback onOpenAll;

  const _ProjectOverview({
    required this.projects,
    required this.bookings,
    required this.shortlists,
    required this.onCreate,
    required this.onOpenAll,
  });

  @override
  Widget build(BuildContext context) {
    return BrandSectionCard(
      title: 'All projects',
      icon: Icons.view_list_outlined,
      selected: true,
      actionText: projects.isEmpty ? null : 'Open project workspace',
      onActionTap: projects.isEmpty ? null : onOpenAll,
      child: projects.isEmpty
          ? CoreEmptyState(
              icon: Icons.movie_creation_outlined,
              title: 'No campaign projects yet',
              message:
                  'Create a project, add the production brief, then shortlist actors, models, locations, crew and equipment.',
              actionLabel: 'Create first project',
              onAction: onCreate,
            )
          : BrandResponsiveGrid(
              minWidth: 280,
              children: [
                for (final project in projects)
                  _DashboardProjectCard(
                    project: project,
                    shortlistCount: shortlists
                        .where((row) => row.projectId == project.publicId)
                        .fold<int>(0, (sum, row) => sum + row.items.length),
                    bookingCount: bookings
                        .where((row) => row.projectId == project.publicId)
                        .length,
                    onTap: onOpenAll,
                  ),
              ],
            ),
    );
  }
}

class _DashboardProjectCard extends StatelessWidget {
  final Project project;
  final int shortlistCount;
  final int bookingCount;
  final VoidCallback onTap;

  const _DashboardProjectCard({
    required this.project,
    required this.shortlistCount,
    required this.bookingCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  BrandLiveStatusChip(status: project.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${readableBrandStatus(project.projectType)} · ${project.city?.name ?? 'City not set'}',
                style: AppTextStyles.smallMeta.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('${project.requirementCount} needs')),
                  Chip(label: Text('$shortlistCount shortlisted')),
                  Chip(label: Text('$bookingCount requests')),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: project.progressPercent.clamp(0, 100) / 100,
                minHeight: 7,
                borderRadius: BorderRadius.circular(99),
              ),
              const SizedBox(height: 7),
              Text(
                '${project.progressPercent}% complete',
                style: AppTextStyles.caption.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
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

class _ActionQueue extends StatelessWidget {
  final int applications;
  final int deliverables;
  final int draftOpportunities;

  const _ActionQueue({
    required this.applications,
    required this.deliverables,
    required this.draftOpportunities,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        icon: Icons.inbox_outlined,
        title: '$applications applications',
        subtitle: 'Review proposals and selection status',
        route: BrandSponsorRoutes.applications,
      ),
      (
        icon: Icons.fact_check_outlined,
        title: '$deliverables proof reviews',
        subtitle: 'Approve delivery or request a revision',
        route: BrandSponsorRoutes.tracker,
      ),
      (
        icon: Icons.drafts_outlined,
        title: '$draftOpportunities draft briefs',
        subtitle: 'Complete or publish opportunity details',
        route: BrandSponsorRoutes.composer,
      ),
    ];
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(item.icon, color: context.appColors.goldDark),
              title: Text(item.title),
              subtitle: Text(item.subtitle),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.pushNamed(context, item.route),
            ),
          ),
      ],
    );
  }
}
