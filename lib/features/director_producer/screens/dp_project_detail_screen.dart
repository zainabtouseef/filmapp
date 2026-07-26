import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/casting/casting_controller.dart';
import '../../../core/casting/casting_models.dart';
import '../../../core/contracts/contract_models.dart';
import '../../../core/contracts/contracts_controller.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/open_url.dart';
import '../../../core/opportunities/opportunities_controller.dart';
import '../../../core/opportunities/opportunities_models.dart';
import '../../../core/payments/payment_models.dart';
import '../../../core/payments/payments_controller.dart';
import '../../../core/projects/project_models.dart';
import '../../../core/projects/projects_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/cine_card_system.dart'
    show EntityAvatar, AvatarStack;
import '../../../shared/scheduling/meeting_negotiation_panel.dart';
import '../models/dp_booking.dart';
import '../models/dp_contract.dart';
import '../models/dp_payment.dart';
import '../models/dp_project.dart';
import '../models/dp_requirement.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_booking_status_spine.dart';
import '../widgets/dp_budget_health_bar.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_project_console_widgets.dart';
import '../widgets/dp_status_chip.dart';

class DPProjectDetailScreen extends StatefulWidget {
  final String? projectId;
  final String? initialTab;

  const DPProjectDetailScreen({
    super.key,
    this.projectId,
    this.initialTab,
  });

  @override
  State<DPProjectDetailScreen> createState() => _DPProjectDetailScreenState();
}

class _DPProjectDetailScreenState extends State<DPProjectDetailScreen> {
  late int _tab = _tabIndex(widget.initialTab);
  Future<_ProjectHubData>? _future;

  static const _tabs = [
    'Overview',
    'Budget & Costs',
    'Shortlists',
    'Casting',
    'Applications',
    'Bookings',
    'Contracts',
    'Payments',
    'Schedule',
    'Files',
    'Team',
  ];

  int _tabIndex(String? tab) {
    if (tab == null) return 0;
    final normalized = tab.toLowerCase().replaceAll('-', ' ');
    final index = _tabs.indexWhere(
      (item) => item.toLowerCase().startsWith(normalized),
    );
    return index < 0 ? 0 : index;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<_ProjectHubData> _load() async {
    final projects = ProjectsScope.maybeOf(context);
    final bookingsController = BookingsScope.maybeOf(context);
    final contractsController = ContractsScope.maybeOf(context);
    final castingController = CastingScope.maybeOf(context);
    final opportunitiesController = OpportunitiesScope.maybeOf(context);
    final paymentsController = PaymentsScope.maybeOf(context);
    if (projects == null) {
      throw Exception('Projects scope is missing.');
    }
    final projectId = widget.projectId;
    final project = projectId == null
        ? (await projects.projects(force: true)).first
        : await projects.project(projectId);
    final requirements = await projects
        .requirements(project.publicId)
        .catchError((_) => <ProjectRequirement>[]);

    final liveBookings = bookingsController == null
        ? <Booking>[]
        : await bookingsController.bookings(force: true).catchError(
              (_) => <Booking>[],
            );
    final bookings = liveBookings
        .where((booking) => booking.projectId == project.publicId)
        .map(_toDpBooking)
        .toList();

    final liveContracts = contractsController == null
        ? <CineContract>[]
        : await contractsController.contracts(force: true).catchError(
              (_) => <CineContract>[],
            );
    final contracts = liveContracts
        .where((contract) => contract.projectId == project.publicId)
        .map((contract) => _toDpContract(contract, project.title))
        .toList();

    PaymentDashboardDto? liveDashboard;
    if (paymentsController != null) {
      try {
        liveDashboard = await paymentsController.dashboard(force: true);
      } catch (_) {
        liveDashboard = null;
      }
    }
    final bookingIds = bookings.map((booking) => booking.id).toSet();
    final contractIds = contracts.map((contract) => contract.id).toSet();
    final payments = (liveDashboard?.schedules ?? const <PaymentScheduleDto>[])
        .where(
          (schedule) =>
              bookingIds.contains(schedule.bookingId) ||
              (schedule.contractId != null &&
                  contractIds.contains(schedule.contractId)),
        )
        .expand(_toDpPayments)
        .toList();
    final castingApplications = castingController == null
        ? <CastingApplication>[]
        : await castingController
            .directorApplications(project.publicId)
            .catchError((_) => <CastingApplication>[]);
    final opportunityApplications = opportunitiesController == null
        ? <OpportunityApplication>[]
        : await opportunitiesController
            .directorApplications(project.publicId)
            .catchError((_) => <OpportunityApplication>[]);

    return _ProjectHubData(
      project: _toDpProject(
        project,
        bookings: bookings,
        contracts: contracts,
        payments: payments,
      ),
      requirements: requirements
          .map((requirement) => requirement.toDpRequirement())
          .toList(),
      bookings: bookings,
      contracts: contracts,
      payments: payments,
      castingApplications: castingApplications,
      opportunityApplications: opportunityApplications,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ProjectHubData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CoreEmptyState(
            icon: Icons.hourglass_top_rounded,
            title: 'Loading project hub',
            message: 'Fetching live project, bookings, contracts and payments.',
          );
        }
        if (snapshot.hasError) {
          return CoreEmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Project hub unavailable',
            message:
                'Could not load this project from the database. Open a real project and retry.',
            actionLabel: 'Retry',
            onAction: () => setState(() => _future = _load()),
          );
        }
        final data = snapshot.data!;
        final project = data.project;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DPProjectBreadcrumbs(project: project, current: _tabs[_tab]),
            const SizedBox(height: 6),
            DPPageHeader(
              eyebrow: '${project.status} · ${project.city}',
              title: 'Project Hub',
              actionLabel: 'Open Room',
              actionIcon: Icons.forum_outlined,
              onActionTap: () => Navigator.pushNamed(
                context,
                DirectorProducerRoutes.room,
                arguments: project.id,
              ),
            ),
            const SizedBox(height: 10),
            _ProjectHeader(
              project: project,
              bookings: data.bookings,
              contracts: data.contracts,
              payments: data.payments,
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < _tabs.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: DpDotChip(
                        label: _tabs[i],
                        active: _tab == i,
                        onTap: () => setState(() => _tab = i),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _ProjectTabBody(
              tab: _tabs[_tab],
              project: project,
              requirements: data.requirements,
              bookings: data.bookings,
              contracts: data.contracts,
              payments: data.payments,
              castingApplications: data.castingApplications,
              opportunityApplications: data.opportunityApplications,
            ),
          ],
        );
      },
    );
  }

  DpProject _toDpProject(
    Project project, {
    required List<DpBooking> bookings,
    required List<DpContract> contracts,
    required List<DpPayment> payments,
  }) {
    final estimated = project.estimatedBudgetMinor == null
        ? 0
        : project.estimatedBudgetMinor! ~/ 100;
    final committed = contracts.fold<int>(
        0, (sum, contract) => sum + dpMoneyFromLabel(contract.value));
    final paid = payments
        .where((payment) => payment.status == 'Verified')
        .fold<int>(0, (sum, payment) => sum + payment.amount);
    final progress = (project.progressPercent.clamp(0, 100)) / 100;
    return DpProject(
      id: project.publicId,
      title: project.title,
      type: _titleCase(project.projectType),
      city: project.city?.name ?? 'Pakistan',
      dateRange: _dateRange(project.startDate, project.endDate),
      status: _titleCase(project.status),
      estimatedBudget: estimated,
      confirmedCost: committed,
      budgetHealth: estimated == 0
          ? 0
          : (committed / estimated).clamp(0.0, 1.0).toDouble(),
      pendingActions: project.requirementCount,
      shootDate: _shortDate(project.startDate),
      bookingsCount: bookings.length,
      contractsCount: contracts.length,
      paymentsStatus:
          paid == 0 ? 'No verified payments' : 'PKR ${_short(paid)} paid',
      team: project.members.map((member) => member.displayName).toList(),
      progress: progress.toDouble(),
      coverImageUrl: project.coverFile?.publicUrl,
    );
  }

  DpBooking _toDpBooking(Booking booking) {
    return DpBooking(
      id: booking.publicId,
      projectId: booking.projectId,
      requirement: booking.requirementId ?? _titleCase(booking.category),
      candidate: booking.provider.displayName,
      statusIndex: _bookingStatusIndex(booking.status),
      fee: booking.activeOffer?.feeLabel ??
          (booking.agreedAmountMinor == null
              ? 'Rate TBD'
              : '${booking.currency} ${_short(booking.agreedAmountMinor! ~/ 100)}'),
      dateRange: _dateRange(booking.startAt, booking.endAt),
      stage: _titleCase(booking.status),
      expiry:
          booking.expiresAt == null ? 'Open' : _shortDate(booking.expiresAt),
    );
  }

  DpContract _toDpContract(CineContract contract, String projectTitle) {
    return DpContract(
      id: contract.publicId,
      title: contract.title,
      project: projectTitle,
      candidate: contract.counterpartySummary,
      value: contract.displayValue,
      status: _titleCase(contract.status),
      signatureProgress: contract.signatureProgress,
      createdDate: contract.effectiveDate ?? 'Draft',
    );
  }

  Iterable<DpPayment> _toDpPayments(PaymentScheduleDto schedule) {
    return schedule.milestones.map((milestone) {
      return DpPayment(
        id: milestone.publicId,
        booking: schedule.bookingId,
        stakeholder: schedule.contractId ?? 'Contract pending',
        amount: milestone.amountMinor ~/ 100,
        dueDate: _shortDate(milestone.dueAt),
        stage: milestone.name,
        status: _paymentStatus(milestone.status),
      );
    });
  }

  int _bookingStatusIndex(String status) {
    return switch (status) {
      'accepted' || 'secured' => 9,
      'under_negotiation' => 5,
      'sent' => 3,
      'rejected' || 'cancelled' => 1,
      _ => 2,
    };
  }

  String _paymentStatus(String status) {
    return switch (status) {
      'proof_submitted' => 'Proof Uploaded',
      'verified' => 'Verified',
      'rejected' => 'Rejected',
      _ => 'Due',
    };
  }

  String _titleCase(String value) {
    return value
        .replaceAll('_', ' ')
        .split(RegExp(r'\\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  String _dateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return 'Dates TBD';
    if (start == null) return 'Until ${_shortDate(end)}';
    if (end == null) return 'From ${_shortDate(start)}';
    return '${_shortDate(start)} - ${_shortDate(end)}';
  }

  String _shortDate(DateTime? value) {
    if (value == null) return 'TBD';
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  String _short(int amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return '$amount';
  }
}

class _ProjectHubData {
  final DpProject project;
  final List<DpRequirement> requirements;
  final List<DpBooking> bookings;
  final List<DpContract> contracts;
  final List<DpPayment> payments;
  final List<CastingApplication> castingApplications;
  final List<OpportunityApplication> opportunityApplications;

  const _ProjectHubData({
    required this.project,
    required this.requirements,
    required this.bookings,
    required this.contracts,
    required this.payments,
    required this.castingApplications,
    required this.opportunityApplications,
  });
}

class _ProjectHeader extends StatelessWidget {
  final DpProject project;
  final List<DpBooking> bookings;
  final List<DpContract> contracts;
  final List<DpPayment> payments;

  const _ProjectHeader({
    required this.project,
    required this.bookings,
    required this.contracts,
    required this.payments,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final signed =
        contracts.where((contract) => contract.status == 'Signed').length;
    final paid = payments
        .where((payment) => payment.status == 'Verified')
        .fold<int>(0, (sum, payment) => sum + payment.amount);
    return DPGlassCard(
      selected: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final poster = Container(
                width: 74,
                height: 92,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: colors.goldGradient,
                  border: Border.all(color: colors.border),
                ),
                child: Icon(
                  Icons.movie_filter_rounded,
                  color: colors.onGold,
                  size: 34,
                ),
              );
              final titleBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: colors.textPrimary,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      DpDotLabel(label: project.type, tone: DpTone.warning),
                      DpDotLabel(label: project.status, tone: DpTone.info),
                    ],
                  ),
                ],
              );

              if (constraints.maxWidth < 340) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        poster,
                        const SizedBox(width: 14),
                        Expanded(child: titleBlock),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _ProgressRing(value: project.progress),
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  poster,
                  const SizedBox(width: 14),
                  Expanded(child: titleBlock),
                  const SizedBox(width: 10),
                  _ProgressRing(value: project.progress),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DPStatusChip(label: project.city, tone: DpTone.neutral),
              DPStatusChip(
                label: project.dateRange,
                tone: DpTone.neutral,
                icon: Icons.date_range_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: colors.borderMuted),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Wrap(
                spacing: 18,
                runSpacing: 10,
                children: [
                  _BudgetStat(
                    label: 'Budget',
                    value:
                        'PKR ${(project.estimatedBudget / 1000000).toStringAsFixed(1)}M',
                  ),
                  _BudgetStat(
                    label: 'Committed',
                    value:
                        'PKR ${(project.confirmedCost / 1000000).toStringAsFixed(1)}M',
                    color: colors.goldDark,
                  ),
                  _BudgetStat(
                    label: 'Paid',
                    value: 'PKR ${(paid / 1000).round()}K',
                    color: colors.success,
                  ),
                  _BudgetStat(
                    label: 'Signed',
                    value: '$signed/${contracts.length}',
                  ),
                ],
              ),
              AvatarStack(
                avatars: [
                  for (final member in project.team.take(4))
                    EntityAvatar(label: member, size: 26),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _BudgetStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.cardLabel.copyWith(
            color: color ?? colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ProjectTabBody extends StatelessWidget {
  final String tab;
  final DpProject project;
  final List<DpRequirement> requirements;
  final List<DpBooking> bookings;
  final List<DpContract> contracts;
  final List<DpPayment> payments;
  final List<CastingApplication> castingApplications;
  final List<OpportunityApplication> opportunityApplications;

  const _ProjectTabBody({
    required this.tab,
    required this.project,
    required this.requirements,
    required this.bookings,
    required this.contracts,
    required this.payments,
    required this.castingApplications,
    required this.opportunityApplications,
  });

  @override
  Widget build(BuildContext context) {
    return switch (tab) {
      'Overview' => _OverviewTab(
          project: project,
          requirements: requirements,
          bookings: bookings,
        ),
      'Budget & Costs' =>
        _BudgetTab(project: project, bookings: bookings, contracts: contracts),
      'Shortlists' => DPProjectScopedShortlists(project: project),
      'Casting' => _CastingApplicationsTab(
          projectId: project.id,
          applications: castingApplications,
        ),
      'Applications' =>
        _OpportunityApplicationsTab(applications: opportunityApplications),
      'Bookings' => _BookingsTab(bookings: bookings),
      'Contracts' => _ContractsTab(project: project, contracts: contracts),
      'Payments' => _PaymentsTab(payments: payments),
      'Schedule' => ProductionCalendar(
          projectId: project.id,
          initialMode: ProductionCalendarMode.list,
        ),
      'Files' => _FilesTab(project: project),
      'Team' => _TeamTab(project: project),
      _ => const SizedBox.shrink(),
    };
  }
}

class _OverviewTab extends StatelessWidget {
  final DpProject project;
  final List<DpRequirement> requirements;
  final List<DpBooking> bookings;

  const _OverviewTab({
    required this.project,
    required this.requirements,
    required this.bookings,
  });

  @override
  Widget build(BuildContext context) {
    return DPTwoColumn(
      left: DPSectionCard(
        title: 'Build your production',
        icon: Icons.fact_check_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DPGlassCard(
              padding: const EdgeInsets.all(12),
              accentColor: context.appColors.infoBlue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  dpText(
                    context,
                    'Need actors, models, crew, locations or equipment?',
                    strong: true,
                  ),
                  const SizedBox(height: 6),
                  dpText(
                    context,
                    'Create an audition/casting requirement for this project so providers can apply from their opportunity screens.',
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        icon: const Icon(Icons.video_camera_front_outlined),
                        label: const Text('Create audition call'),
                        onPressed: () => Navigator.pushNamed(
                          context,
                          DirectorProducerRoutes.requirements,
                          arguments: {'id': project.id},
                        ),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.assignment_outlined),
                        label: const Text('Open applications'),
                        onPressed: () => Navigator.pushNamed(
                          context,
                          DirectorProducerRoutes.projectDetail,
                          arguments: {
                            'id': project.id,
                            'tab': 'Casting',
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            DPProductionChecklist(
              project: project,
              requirements: requirements,
              bookings: bookings,
            ),
          ],
        ),
      ),
      right: DPSectionCard(
        title: 'Today for this project',
        icon: Icons.today_outlined,
        child: ProductionCalendar(projectId: project.id),
      ),
    );
  }
}

class _BudgetTab extends StatelessWidget {
  final DpProject project;
  final List<DpBooking> bookings;
  final List<DpContract> contracts;

  const _BudgetTab({
    required this.project,
    required this.bookings,
    required this.contracts,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DPSectionCard(
          title: 'Estimated vs committed vs paid',
          icon: Icons.account_balance_wallet_outlined,
          child: Column(
            children: [
              DPBudgetHealthBar(
                value: project.estimatedBudget == 0
                    ? 0
                    : (project.confirmedCost / project.estimatedBudget)
                        .clamp(0.0, 1.0)
                        .toDouble(),
                label: 'Committed against estimate',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  DPStatusChip(
                    label:
                        'Estimated PKR ${(project.estimatedBudget / 1000000).toStringAsFixed(1)}M',
                    tone: DpTone.info,
                  ),
                  DPStatusChip(
                    label:
                        'Committed PKR ${(project.confirmedCost / 1000000).toStringAsFixed(1)}M',
                    tone: DpTone.warning,
                  ),
                  const DPStatusChip(
                    label: 'Pending milestones visible below',
                    tone: DpTone.neutral,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DPSectionCard(
          title: 'Booking cost rows',
          icon: Icons.receipt_long_outlined,
          child: Column(
            children: [
              for (final booking in bookings)
                _BudgetBookingRow(
                  booking: booking,
                  contract: contracts.firstWhere(
                    (contract) => contract.candidate == booking.candidate,
                    orElse: () => DpContract(
                      id: 'none-${booking.id}',
                      title: 'No contract',
                      project: project.title,
                      candidate: booking.candidate,
                      value: booking.fee,
                      status: 'No contract',
                      signatureProgress: 0,
                      createdDate: '-',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BudgetBookingRow extends StatelessWidget {
  final DpBooking booking;
  final DpContract contract;

  const _BudgetBookingRow({required this.booking, required this.contract});

  @override
  Widget build(BuildContext context) {
    return DPGlassCard(
      padding: const EdgeInsets.all(11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: dpText(context, booking.candidate, strong: true)),
              DPStatusChip(label: booking.fee, tone: DpTone.warning),
            ],
          ),
          const SizedBox(height: 7),
          dpText(context, '${booking.requirement} • ${booking.dateRange}'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DPStatusChip(
                label: contract.status,
                tone: dpToneForStatus(contract.status),
              ),
              DPStatusChip(
                label: booking.stage,
                tone: dpToneForStatus(booking.stage),
              ),
              DPStatusChip(
                label: booking.statusIndex >= 9 ? 'Secured' : 'Not secured',
                tone:
                    booking.statusIndex >= 9 ? DpTone.success : DpTone.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CastingApplicationsTab extends StatefulWidget {
  final String projectId;
  final List<CastingApplication> applications;

  const _CastingApplicationsTab({
    required this.projectId,
    required this.applications,
  });

  @override
  State<_CastingApplicationsTab> createState() =>
      _CastingApplicationsTabState();
}

class _CastingApplicationsTabState extends State<_CastingApplicationsTab> {
  late List<CastingApplication> _rows = [...widget.applications];
  String _filter = 'All';
  String? _workingId;

  @override
  void didUpdateWidget(covariant _CastingApplicationsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.applications != widget.applications) {
      _rows = [...widget.applications];
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows.where(_matchesFilter).toList();
    final total = _rows.length;
    final requested =
        _rows.where((item) => item.status == 'self_tape_requested').length;
    final received = _rows.where((item) => item.selfTapeFile != null).length;
    final reviewed = _rows.where((item) => item.review.hasReview).length;
    return DPSectionCard(
      title: 'Self-tape Audition Room',
      icon: Icons.video_camera_front_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DPGlassCard(
            padding: const EdgeInsets.all(12),
            accentColor: context.appColors.infoPurple,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                dpText(
                  context,
                  'Send self-tape briefs, collect uploads, score performances and keep team comments in one project room.',
                  strong: true,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    DPStatusChip(label: '$total applicants', tone: DpTone.info),
                    DPStatusChip(
                      label: '$requested tape requests',
                      tone: DpTone.warning,
                    ),
                    DPStatusChip(
                      label: '$received received',
                      tone: DpTone.success,
                    ),
                    DPStatusChip(
                      label: '$reviewed scored',
                      tone: reviewed == 0 ? DpTone.neutral : DpTone.purple,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in const [
                  'All',
                  'New',
                  'Shortlisted',
                  'Auditions',
                  'Self-tapes',
                  'Scored',
                  'Offers',
                  'Closed',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: DpDotChip(
                      label: filter,
                      active: _filter == filter,
                      onTap: () => setState(() => _filter = filter),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            CoreEmptyState(
              icon: Icons.person_search_outlined,
              title: 'No casting applications yet',
              message:
                  'Create an audition/casting requirement for this project, then actors can apply from their Opportunities screen.',
              actionLabel: 'Create audition call',
              onAction: () => Navigator.pushNamed(
                context,
                DirectorProducerRoutes.requirements,
                arguments: {'id': widget.projectId},
              ),
            )
          else
            for (var index = 0; index < rows.length; index++) ...[
              _DirectorCastingApplicationCard(
                application: rows[index],
                working: _workingId == rows[index].publicId,
                onStatus: (status) => _updateStatus(rows[index], status),
                onMessage: () => _openConversation(rows[index]),
                onReview: () => _reviewApplication(rows[index]),
                onSendOffer: rows[index].marketplaceListingId == null ||
                        const {'rejected', 'withdrawn'}
                            .contains(rows[index].status)
                    ? null
                    : () => Navigator.pushNamed(
                          context,
                          DirectorProducerRoutes.bookingRequest,
                          arguments: {
                            'candidateId': rows[index].marketplaceListingId,
                            'projectId': rows[index].role.project.publicId,
                          },
                        ),
                onProposeMeeting: ({
                  required meetingAt,
                  location,
                  onlineUrl,
                  instructions,
                  contact,
                  message,
                }) =>
                    _proposeMeeting(
                  rows[index],
                  meetingAt: meetingAt,
                  location: location,
                  onlineUrl: onlineUrl,
                  instructions: instructions,
                  contact: contact,
                  message: message,
                ),
                onAcceptMeeting: (roundId) =>
                    _acceptMeeting(rows[index], roundId),
                onDeclineMeeting: (roundId, reason) =>
                    _declineMeeting(rows[index], roundId, reason),
              ),
              if (index != rows.length - 1) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  bool _matchesFilter(CastingApplication item) {
    return switch (_filter) {
      'New' => const {'submitted', 'viewed'}.contains(item.status),
      'Shortlisted' => item.status == 'shortlisted',
      'Auditions' => item.isAudition,
      'Self-tapes' =>
        item.status == 'self_tape_requested' || item.selfTapeFile != null,
      'Scored' => item.review.hasReview,
      'Offers' => const {'offer_received', 'selected'}.contains(item.status),
      'Closed' => const {'rejected', 'withdrawn'}.contains(item.status),
      _ => true,
    };
  }

  Future<void> _updateStatus(
    CastingApplication application,
    String status,
  ) async {
    Map<String, dynamic> body = {'status': status};
    if (status == 'audition_requested' ||
        status == 'self_tape_requested' ||
        status == 'callback') {
      final details = await _auditionDialog(status);
      if (details == null || !mounted) return;
      body = {...body, ...details};
    } else if (status == 'rejected') {
      final reason = await _rejectionDialog();
      if (reason == null || !mounted) return;
      body['rejection_reason'] = reason;
    }
    final casting = CastingScope.maybeOf(context);
    if (casting == null) return;
    setState(() => _workingId = application.publicId);
    try {
      final updated = await casting.updateDirectorApplication(
        application.publicId,
        body,
      );
      if (!mounted) return;
      setState(() {
        final index = _rows.indexWhere(
          (item) => item.publicId == updated.publicId,
        );
        if (index >= 0) _rows[index] = updated;
      });
      dpSnack(context, 'Application updated to ${updated.statusLabel}');
    } on ApiException catch (error) {
      if (mounted) dpSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _workingId = null);
    }
  }

  void _replaceRow(CastingApplication updated) {
    final index = _rows.indexWhere((item) => item.publicId == updated.publicId);
    if (index >= 0) setState(() => _rows[index] = updated);
  }

  Future<void> _reviewApplication(CastingApplication application) async {
    final review = await _selfTapeReviewDialog(application);
    if (review == null || !mounted) return;
    final casting = CastingScope.maybeOf(context);
    if (casting == null) return;
    setState(() => _workingId = application.publicId);
    try {
      final updated = await casting.updateDirectorApplication(
        application.publicId,
        {
          'review_score': review.score,
          'review_comment': review.comment,
        },
      );
      if (!mounted) return;
      _replaceRow(updated);
      dpSnack(context, 'Self-tape review saved');
    } on ApiException catch (error) {
      if (mounted) dpSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _workingId = null);
    }
  }

  Future<void> _proposeMeeting(
    CastingApplication application, {
    required DateTime meetingAt,
    String? location,
    String? onlineUrl,
    String? instructions,
    String? contact,
    String? message,
  }) async {
    final casting = CastingScope.maybeOf(context);
    if (casting == null) return;
    setState(() => _workingId = application.publicId);
    try {
      final updated = await casting.proposeDirectorMeeting(
        application.publicId,
        {
          'meeting_at': meetingAt.toUtc().toIso8601String(),
          if (location != null) 'location': location,
          if (onlineUrl != null) 'online_url': onlineUrl,
          if (instructions != null) 'instructions': instructions,
          if (contact != null) 'contact': contact,
          if (message != null) 'message': message,
        },
      );
      if (!mounted) return;
      _replaceRow(updated);
      dpSnack(context, 'Meeting proposal sent');
    } on ApiException catch (error) {
      if (mounted) dpSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _workingId = null);
    }
  }

  Future<void> _acceptMeeting(
    CastingApplication application,
    String roundId,
  ) async {
    final casting = CastingScope.maybeOf(context);
    if (casting == null) return;
    setState(() => _workingId = application.publicId);
    try {
      final updated = await casting.acceptDirectorMeetingRound(
          application.publicId, roundId);
      if (!mounted) return;
      _replaceRow(updated);
      dpSnack(context, 'Meeting confirmed');
    } on ApiException catch (error) {
      if (mounted) dpSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _workingId = null);
    }
  }

  Future<void> _declineMeeting(
    CastingApplication application,
    String roundId,
    String? reason,
  ) async {
    final casting = CastingScope.maybeOf(context);
    if (casting == null) return;
    setState(() => _workingId = application.publicId);
    try {
      final updated = await casting.declineDirectorMeetingRound(
        application.publicId,
        roundId,
        reason: reason,
      );
      if (!mounted) return;
      _replaceRow(updated);
      dpSnack(context, 'Meeting proposal declined');
    } on ApiException catch (error) {
      if (mounted) dpSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _workingId = null);
    }
  }

  Future<void> _openConversation(CastingApplication application) async {
    final casting = CastingScope.maybeOf(context);
    if (casting == null) return;
    setState(() => _workingId = application.publicId);
    try {
      final conversationId = application.conversationId ??
          await casting.ensureConversation(application.publicId);
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        CoreRoutes.chat,
        arguments: conversationId,
      );
    } on ApiException catch (error) {
      if (mounted) dpSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _workingId = null);
    }
  }

  Future<Map<String, dynamic>?> _auditionDialog(String status) async {
    final date = TextEditingController();
    final location = TextEditingController();
    final onlineUrl = TextEditingController();
    final instructions = TextEditingController();
    final contact = TextEditingController();
    final callback = status == 'callback';
    final selfTape = status == 'self_tape_requested';
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          callback
              ? 'Schedule callback'
              : selfTape
                  ? 'Request self-tape'
                  : 'Schedule audition',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CoreTextField(
                controller: date,
                label: selfTape
                    ? 'Deadline (ISO date/time)'
                    : 'Date and time (ISO)',
                icon: Icons.schedule_outlined,
                keyboardType: TextInputType.datetime,
              ),
              if (!selfTape) ...[
                const SizedBox(height: 10),
                CoreTextField(
                  controller: location,
                  label: 'Location',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: onlineUrl,
                  label: 'Online meeting link',
                  icon: Icons.link_outlined,
                  keyboardType: TextInputType.url,
                ),
              ],
              const SizedBox(height: 10),
              CoreTextField(
                controller: instructions,
                label: 'Instructions',
                icon: Icons.assignment_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: contact,
                label: 'Contact details',
                icon: Icons.contact_mail_outlined,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = DateTime.tryParse(date.text.trim());
              if (parsed == null) {
                dpSnack(context, 'Enter a valid ISO date and time');
                return;
              }
              Navigator.pop(
                dialogContext,
                {
                  if (callback)
                    'callback_at': parsed.toUtc().toIso8601String()
                  else if (selfTape)
                    'audition_due_at': parsed.toUtc().toIso8601String()
                  else
                    'audition_at': parsed.toUtc().toIso8601String(),
                  if (location.text.trim().isNotEmpty)
                    'audition_location': location.text.trim(),
                  if (onlineUrl.text.trim().isNotEmpty)
                    'audition_online_url': onlineUrl.text.trim(),
                  if (callback)
                    'callback_details': instructions.text.trim()
                  else
                    'audition_instructions': instructions.text.trim(),
                  if (contact.text.trim().isNotEmpty)
                    'audition_contact': contact.text.trim(),
                },
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
    date.dispose();
    location.dispose();
    onlineUrl.dispose();
    instructions.dispose();
    contact.dispose();
    return result;
  }

  Future<String?> _rejectionDialog() async {
    final reason = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Close application'),
        content: CoreTextField(
          controller: reason,
          label: 'Actor-facing reason',
          icon: Icons.notes_outlined,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (reason.text.trim().isEmpty) {
                dpSnack(context, 'Add a short reason for the actor');
                return;
              }
              Navigator.pop(dialogContext, reason.text.trim());
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    reason.dispose();
    return result;
  }

  Future<_SelfTapeReview?> _selfTapeReviewDialog(
    CastingApplication application,
  ) async {
    var score = application.review.score ?? 8;
    final comment = TextEditingController(text: application.review.comment);
    final result = await showDialog<_SelfTapeReview>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Score ${application.screenName}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Self-tape score',
                    style: AppTextStyles.cardLabel.copyWith(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Slider(
                    value: score.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '$score / 10',
                    onChanged: (value) =>
                        setDialogState(() => score = value.round()),
                  ),
                  Center(
                    child: Text(
                      '$score / 10',
                      style: AppTextStyles.metricNumberCompact.copyWith(
                        color: context.appColors.goldDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CoreTextField(
                    controller: comment,
                    label: 'Team comment',
                    icon: Icons.rate_review_outlined,
                    maxLines: 4,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.check_circle_outline_rounded),
                onPressed: () => Navigator.pop(
                  dialogContext,
                  _SelfTapeReview(
                    score: score,
                    comment: comment.text.trim(),
                  ),
                ),
                label: const Text('Save review'),
              ),
            ],
          );
        },
      ),
    );
    comment.dispose();
    return result;
  }
}

class _SelfTapeReview {
  final int score;
  final String comment;

  const _SelfTapeReview({
    required this.score,
    required this.comment,
  });
}

class _SelfTapeRoomPanel extends StatelessWidget {
  final CastingApplication application;

  const _SelfTapeRoomPanel({required this.application});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final dueAt = application.audition.dueAt;
    final instructions = application.audition.instructions?.trim();
    final comment = application.review.comment?.trim();
    return DPGlassCard(
      padding: const EdgeInsets.all(11),
      accentColor: colors.infoPurple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.video_camera_front_outlined,
                  color: colors.infoPurple, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Self-tape room',
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (dueAt != null)
                DPStatusChip(
                  label: 'Due ${_compactDate(dueAt)}',
                  tone: DpTone.warning,
                ),
            ],
          ),
          if (instructions?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              instructions!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DPStatusChip(
                label: application.selfTapeFile == null
                    ? 'Awaiting upload'
                    : 'Tape uploaded',
                tone: application.selfTapeFile == null
                    ? DpTone.warning
                    : DpTone.success,
                icon: application.selfTapeFile == null
                    ? Icons.hourglass_top_rounded
                    : Icons.cloud_done_outlined,
              ),
              if (application.review.reviewedByName != null)
                DPStatusChip(
                  label: 'Reviewed by ${application.review.reviewedByName}',
                  tone: DpTone.info,
                  icon: Icons.person_outline_rounded,
                ),
              if (application.review.reviewedAt != null)
                DPStatusChip(
                  label: _compactDate(application.review.reviewedAt!),
                  tone: DpTone.neutral,
                  icon: Icons.schedule_outlined,
                ),
            ],
          ),
          if (comment?.isNotEmpty == true) ...[
            const SizedBox(height: 9),
            Text(
              'Team comment',
              style: AppTextStyles.caption.copyWith(
                color: colors.textTertiary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              comment!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: colors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _compactDate(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }
}

class _DirectorCastingApplicationCard extends StatefulWidget {
  final CastingApplication application;
  final bool working;
  final ValueChanged<String> onStatus;
  final VoidCallback onMessage;
  final VoidCallback onReview;
  final VoidCallback? onSendOffer;
  final Future<void> Function({
    required DateTime meetingAt,
    String? location,
    String? onlineUrl,
    String? instructions,
    String? contact,
    String? message,
  }) onProposeMeeting;
  final Future<void> Function(String roundId) onAcceptMeeting;
  final Future<void> Function(String roundId, String? reason) onDeclineMeeting;

  const _DirectorCastingApplicationCard({
    required this.application,
    required this.working,
    required this.onStatus,
    required this.onMessage,
    required this.onReview,
    required this.onSendOffer,
    required this.onProposeMeeting,
    required this.onAcceptMeeting,
    required this.onDeclineMeeting,
  });

  @override
  State<_DirectorCastingApplicationCard> createState() =>
      _DirectorCastingApplicationCardState();
}

class _DirectorCastingApplicationCardState
    extends State<_DirectorCastingApplicationCard> {
  bool _meetingExpanded = false;

  CastingApplication get application => widget.application;
  bool get working => widget.working;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final selfTape = application.selfTapeFile;
    final statusOptions = _statusOptions(application.status);
    return DPGlassCard(
      selected: const {
        'submitted',
        'viewed',
        'audition_requested',
        'self_tape_requested',
      }.contains(application.status),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              EntityAvatar(
                label: application.screenName,
                image: application.actorAvatarUrl == null
                    ? null
                    : NetworkImage(application.actorAvatarUrl!),
                size: 44,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.screenName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      application.role.title,
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
              DPStatusChip(
                label: application.statusLabel,
                tone: _tone(application.status),
              ),
              const SizedBox(width: 6),
              PopupMenuButton<String>(
                tooltip: 'Update application',
                enabled: !working && statusOptions.isNotEmpty,
                onSelected: widget.onStatus,
                itemBuilder: (_) => [
                  for (final option in statusOptions)
                    PopupMenuItem(
                      value: option.$1,
                      child: Text(option.$2),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          if ((application.coverNote ?? '').isNotEmpty)
            Text(
              application.coverNote!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: colors.textSecondary,
                height: 1.35,
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DPStatusChip(
                label: '${application.portfolioItemIds.length} portfolio items',
                tone: DpTone.info,
              ),
              if (application.audition.confirmedAt != null)
                const DPStatusChip(
                  label: 'Audition confirmed',
                  tone: DpTone.success,
                ),
              if (selfTape != null)
                const DPStatusChip(
                  label: 'Self-tape received',
                  tone: DpTone.success,
                ),
              if (application.review.score != null)
                DPStatusChip(
                  label: 'Score ${application.review.score}/10',
                  tone: DpTone.purple,
                  icon: Icons.star_rounded,
                ),
            ],
          ),
          if (application.audition.dueAt != null ||
              (application.audition.instructions ?? '').isNotEmpty ||
              application.review.hasReview) ...[
            const SizedBox(height: 10),
            _SelfTapeRoomPanel(application: application),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 154,
                child: CoreSecondaryButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Message',
                  compact: true,
                  onTap: working ? null : widget.onMessage,
                ),
              ),
              SizedBox(
                width: 154,
                child: CoreSecondaryButton(
                  icon: Icons.event_available_outlined,
                  label: application.status == 'callback'
                      ? 'Callback'
                      : 'Audition meeting',
                  compact: true,
                  onTap: () =>
                      setState(() => _meetingExpanded = !_meetingExpanded),
                ),
              ),
              if (widget.onSendOffer != null)
                SizedBox(
                  width: 190,
                  child: CorePrimaryButton(
                    icon: Icons.send_outlined,
                    label: 'Send booking offer',
                    compact: true,
                    onTap: working ? null : widget.onSendOffer,
                  ),
                ),
              if (selfTape != null)
                SizedBox(
                  width: 170,
                  child: CorePrimaryButton(
                    icon: Icons.play_circle_outline_rounded,
                    label: 'View self-tape',
                    compact: true,
                    onTap: () async {
                      final auth = AuthScope.maybeOf(context);
                      if (auth == null) return;
                      try {
                        final url = await auth.authorizedDownloadUrl(
                          selfTape.publicId,
                        );
                        openUrlInNewTab(url);
                      } on ApiException catch (error) {
                        if (context.mounted) dpSnack(context, error.message);
                      }
                    },
                  ),
                ),
              SizedBox(
                width: 170,
                child: CoreSecondaryButton(
                  icon: Icons.rate_review_outlined,
                  label: application.review.hasReview
                      ? 'Edit score'
                      : 'Score tape',
                  compact: true,
                  onTap: working ? null : widget.onReview,
                ),
              ),
            ],
          ),
          if (_meetingExpanded) ...[
            const SizedBox(height: 12),
            MeetingNegotiationPanel(
              thread: application.meetingThread,
              meetingLabel:
                  application.status == 'callback' ? 'Callback' : 'Audition',
              currentUserId: AuthScope.maybeOf(context)?.user?.publicId ?? '',
              working: working,
              onPropose: widget.onProposeMeeting,
              onAccept: widget.onAcceptMeeting,
              onDecline: widget.onDeclineMeeting,
            ),
          ],
        ],
      ),
    );
  }

  DpTone _tone(String status) {
    return switch (status) {
      'selected' || 'offer_received' => DpTone.success,
      'rejected' || 'withdrawn' => DpTone.danger,
      'shortlisted' || 'callback' => DpTone.warning,
      'audition_requested' || 'self_tape_requested' => DpTone.info,
      _ => DpTone.neutral,
    };
  }

  List<(String, String)> _statusOptions(String status) {
    return switch (status) {
      'submitted' || 'viewed' => const [
          ('shortlisted', 'Shortlist'),
          ('self_tape_requested', 'Request self-tape'),
          ('audition_requested', 'Schedule audition'),
          ('rejected', 'Reject application'),
        ],
      'shortlisted' => const [
          ('self_tape_requested', 'Request self-tape'),
          ('audition_requested', 'Schedule audition'),
          ('callback', 'Schedule callback'),
          ('selected', 'Select actor'),
          ('rejected', 'Reject application'),
        ],
      'audition_requested' => const [
          ('self_tape_requested', 'Request self-tape'),
          ('callback', 'Schedule callback'),
          ('selected', 'Select actor'),
          ('rejected', 'Reject application'),
        ],
      'self_tape_requested' => const [
          ('audition_requested', 'Schedule audition'),
          ('callback', 'Schedule callback'),
          ('selected', 'Select actor'),
          ('rejected', 'Reject application'),
        ],
      'callback' || 'offer_received' => const [
          ('selected', 'Select actor'),
          ('rejected', 'Reject application'),
        ],
      _ => const [],
    };
  }
}

String _meetingLabelForCategory(String category) {
  return switch (category) {
    'model' => 'Meeting',
    'location' => 'Site Visit',
    'equipment' => 'Viewing',
    'crew' => 'Interview',
    _ => 'Meeting',
  };
}

String _meetingKindForCategory(String category) {
  return switch (category) {
    'model' => 'meeting',
    'location' => 'site_visit',
    'equipment' => 'viewing',
    'crew' => 'interview',
    _ => 'meeting',
  };
}

class _OpportunityApplicationsTab extends StatefulWidget {
  final List<OpportunityApplication> applications;

  const _OpportunityApplicationsTab({required this.applications});

  @override
  State<_OpportunityApplicationsTab> createState() =>
      _OpportunityApplicationsTabState();
}

class _OpportunityApplicationsTabState
    extends State<_OpportunityApplicationsTab> {
  late List<OpportunityApplication> _rows = [...widget.applications];
  String _filter = 'All';
  String? _workingId;

  @override
  void didUpdateWidget(covariant _OpportunityApplicationsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.applications != widget.applications) {
      _rows = [...widget.applications];
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows.where(_matchesFilter).toList();
    return DPSectionCard(
      title: 'Applications',
      icon: Icons.assignment_ind_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in const [
                  'All',
                  'New',
                  'Shortlisted',
                  'Meetings',
                  'Selected',
                  'Closed',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: DpDotChip(
                      label: filter,
                      active: _filter == filter,
                      onTap: () => setState(() => _filter = filter),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            const CoreEmptyState(
              icon: Icons.assignment_ind_outlined,
              title: 'No applications',
              message:
                  'Applications appear here when providers apply to an open requirement on this project.',
            )
          else
            for (var index = 0; index < rows.length; index++) ...[
              _DirectorOpportunityApplicationCard(
                application: rows[index],
                working: _workingId == rows[index].publicId,
                onStatus: (status) => _updateStatus(rows[index], status),
                onProposeMeeting: ({
                  required meetingAt,
                  location,
                  onlineUrl,
                  instructions,
                  contact,
                  message,
                }) =>
                    _proposeMeeting(
                  rows[index],
                  meetingAt: meetingAt,
                  location: location,
                  onlineUrl: onlineUrl,
                  instructions: instructions,
                  contact: contact,
                  message: message,
                ),
                onAcceptMeeting: (roundId) =>
                    _acceptMeeting(rows[index], roundId),
                onDeclineMeeting: (roundId, reason) =>
                    _declineMeeting(rows[index], roundId, reason),
              ),
              if (index != rows.length - 1) const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }

  bool _matchesFilter(OpportunityApplication item) {
    return switch (_filter) {
      'New' => const {'submitted', 'viewed'}.contains(item.status),
      'Shortlisted' => item.status == 'shortlisted',
      'Meetings' => item.status == 'meeting_requested',
      'Selected' => item.status == 'selected',
      'Closed' => const {'rejected', 'withdrawn'}.contains(item.status),
      _ => true,
    };
  }

  Future<void> _updateStatus(
    OpportunityApplication application,
    String status,
  ) async {
    Map<String, dynamic> body = {'status': status};
    if (status == 'meeting_requested') {
      final details = await _meetingRequestDialog(application.role.category);
      if (details == null || !mounted) return;
      body = {...body, ...details};
    } else if (status == 'rejected') {
      final reason = await _rejectionDialog();
      if (reason == null || !mounted) return;
      body['note'] = reason;
    }
    final opportunities = OpportunitiesScope.maybeOf(context);
    if (opportunities == null) return;
    setState(() => _workingId = application.publicId);
    try {
      final updated = await opportunities.updateDirectorApplication(
        application.publicId,
        body,
      );
      if (!mounted) return;
      _replaceRow(updated);
      dpSnack(context, 'Application updated to ${updated.statusLabel}');
    } on ApiException catch (error) {
      if (mounted) dpSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _workingId = null);
    }
  }

  void _replaceRow(OpportunityApplication updated) {
    final index = _rows.indexWhere((item) => item.publicId == updated.publicId);
    if (index >= 0) setState(() => _rows[index] = updated);
  }

  Future<void> _proposeMeeting(
    OpportunityApplication application, {
    required DateTime meetingAt,
    String? location,
    String? onlineUrl,
    String? instructions,
    String? contact,
    String? message,
  }) async {
    final opportunities = OpportunitiesScope.maybeOf(context);
    if (opportunities == null) return;
    setState(() => _workingId = application.publicId);
    try {
      final updated = await opportunities.proposeDirectorMeeting(
        application.publicId,
        {
          'meeting_at': meetingAt.toUtc().toIso8601String(),
          if (location != null) 'location': location,
          if (onlineUrl != null) 'online_url': onlineUrl,
          if (instructions != null) 'instructions': instructions,
          if (contact != null) 'contact': contact,
          if (message != null) 'message': message,
        },
      );
      if (!mounted) return;
      _replaceRow(updated);
      dpSnack(context, 'Meeting proposal sent');
    } on ApiException catch (error) {
      if (mounted) dpSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _workingId = null);
    }
  }

  Future<void> _acceptMeeting(
    OpportunityApplication application,
    String roundId,
  ) async {
    final opportunities = OpportunitiesScope.maybeOf(context);
    if (opportunities == null) return;
    setState(() => _workingId = application.publicId);
    try {
      final updated = await opportunities.acceptDirectorMeetingRound(
        application.publicId,
        roundId,
      );
      if (!mounted) return;
      _replaceRow(updated);
      dpSnack(context, 'Meeting confirmed');
    } on ApiException catch (error) {
      if (mounted) dpSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _workingId = null);
    }
  }

  Future<void> _declineMeeting(
    OpportunityApplication application,
    String roundId,
    String? reason,
  ) async {
    final opportunities = OpportunitiesScope.maybeOf(context);
    if (opportunities == null) return;
    setState(() => _workingId = application.publicId);
    try {
      final updated = await opportunities.declineDirectorMeetingRound(
        application.publicId,
        roundId,
        reason: reason,
      );
      if (!mounted) return;
      _replaceRow(updated);
      dpSnack(context, 'Meeting proposal declined');
    } on ApiException catch (error) {
      if (mounted) dpSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _workingId = null);
    }
  }

  Future<Map<String, dynamic>?> _meetingRequestDialog(String category) async {
    final date = TextEditingController();
    final location = TextEditingController();
    final onlineUrl = TextEditingController();
    final instructions = TextEditingController();
    final contact = TextEditingController();
    final label = _meetingLabelForCategory(category);
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Schedule $label'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CoreTextField(
                controller: date,
                label: 'Date and time (ISO)',
                icon: Icons.schedule_outlined,
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: location,
                label: 'Location',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: onlineUrl,
                label: 'Online meeting link',
                icon: Icons.link_outlined,
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: instructions,
                label: 'Instructions',
                icon: Icons.assignment_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: contact,
                label: 'Contact details',
                icon: Icons.contact_mail_outlined,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = DateTime.tryParse(date.text.trim());
              if (parsed == null) {
                dpSnack(context, 'Enter a valid ISO date and time');
                return;
              }
              Navigator.pop(
                dialogContext,
                {
                  'meeting_at': parsed.toUtc().toIso8601String(),
                  if (location.text.trim().isNotEmpty)
                    'meeting_location': location.text.trim(),
                  if (onlineUrl.text.trim().isNotEmpty)
                    'meeting_online_url': onlineUrl.text.trim(),
                  if (instructions.text.trim().isNotEmpty)
                    'meeting_instructions': instructions.text.trim(),
                  if (contact.text.trim().isNotEmpty)
                    'meeting_contact': contact.text.trim(),
                  'meeting_kind': _meetingKindForCategory(category),
                },
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
    date.dispose();
    location.dispose();
    onlineUrl.dispose();
    instructions.dispose();
    contact.dispose();
    return result;
  }

  Future<String?> _rejectionDialog() async {
    final reason = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Close application'),
        content: CoreTextField(
          controller: reason,
          label: 'Applicant-facing reason',
          icon: Icons.notes_outlined,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (reason.text.trim().isEmpty) {
                dpSnack(context, 'Add a short reason for the applicant');
                return;
              }
              Navigator.pop(dialogContext, reason.text.trim());
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    reason.dispose();
    return result;
  }
}

class _DirectorOpportunityApplicationCard extends StatefulWidget {
  final OpportunityApplication application;
  final bool working;
  final ValueChanged<String> onStatus;
  final Future<void> Function({
    required DateTime meetingAt,
    String? location,
    String? onlineUrl,
    String? instructions,
    String? contact,
    String? message,
  }) onProposeMeeting;
  final Future<void> Function(String roundId) onAcceptMeeting;
  final Future<void> Function(String roundId, String? reason) onDeclineMeeting;

  const _DirectorOpportunityApplicationCard({
    required this.application,
    required this.working,
    required this.onStatus,
    required this.onProposeMeeting,
    required this.onAcceptMeeting,
    required this.onDeclineMeeting,
  });

  @override
  State<_DirectorOpportunityApplicationCard> createState() =>
      _DirectorOpportunityApplicationCardState();
}

class _DirectorOpportunityApplicationCardState
    extends State<_DirectorOpportunityApplicationCard> {
  bool _meetingExpanded = false;

  OpportunityApplication get application => widget.application;
  bool get working => widget.working;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final statusOptions =
        _statusOptions(application.status, application.role.category);
    final meetingLabel = _meetingLabelForCategory(application.role.category);
    return DPGlassCard(
      selected: const {
        'submitted',
        'viewed',
        'meeting_requested',
      }.contains(application.status),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              EntityAvatar(
                label: application.applicant.displayName,
                size: 44,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.applicant.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      application.role.title,
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
              DPStatusChip(
                label: application.statusLabel,
                tone: _tone(application.status),
              ),
              const SizedBox(width: 6),
              PopupMenuButton<String>(
                tooltip: 'Update application',
                enabled: !working && statusOptions.isNotEmpty,
                onSelected: widget.onStatus,
                itemBuilder: (_) => [
                  for (final option in statusOptions)
                    PopupMenuItem(
                      value: option.$1,
                      child: Text(option.$2),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          if ((application.coverNote ?? '').isNotEmpty)
            Text(
              application.coverNote!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: colors.textSecondary,
                height: 1.35,
              ),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DPStatusChip(
                label: '${application.attachmentFiles.length} attachment(s)',
                tone: DpTone.info,
              ),
              if (application.meeting?.confirmedAt != null)
                DPStatusChip(
                  label: '$meetingLabel confirmed',
                  tone: DpTone.success,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 154,
                child: CoreSecondaryButton(
                  icon: Icons.event_available_outlined,
                  label: meetingLabel,
                  compact: true,
                  onTap: () =>
                      setState(() => _meetingExpanded = !_meetingExpanded),
                ),
              ),
            ],
          ),
          if (_meetingExpanded) ...[
            const SizedBox(height: 12),
            MeetingNegotiationPanel(
              thread: application.meetingThread,
              meetingLabel: meetingLabel,
              currentUserId: AuthScope.maybeOf(context)?.user?.publicId ?? '',
              working: working,
              onPropose: widget.onProposeMeeting,
              onAccept: widget.onAcceptMeeting,
              onDecline: widget.onDeclineMeeting,
            ),
          ],
        ],
      ),
    );
  }

  DpTone _tone(String status) {
    return switch (status) {
      'selected' => DpTone.success,
      'rejected' || 'withdrawn' => DpTone.danger,
      'shortlisted' || 'meeting_requested' => DpTone.warning,
      _ => DpTone.neutral,
    };
  }

  List<(String, String)> _statusOptions(String status, String category) {
    final meetingLabel = _meetingLabelForCategory(category);
    return switch (status) {
      'submitted' || 'viewed' => [
          ('shortlisted', 'Shortlist'),
          ('meeting_requested', 'Schedule $meetingLabel'),
          ('selected', 'Select applicant'),
          ('rejected', 'Reject application'),
        ],
      'shortlisted' => [
          ('meeting_requested', 'Schedule $meetingLabel'),
          ('selected', 'Select applicant'),
          ('rejected', 'Reject application'),
        ],
      'meeting_requested' => const [
          ('selected', 'Select applicant'),
          ('rejected', 'Reject application'),
        ],
      _ => const [],
    };
  }
}

class _BookingsTab extends StatelessWidget {
  final List<DpBooking> bookings;

  const _BookingsTab({required this.bookings});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final booking in bookings)
          DPSectionCard(
            title: booking.candidate,
            icon: Icons.handshake_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DPBookingStatusSpine(activeIndex: booking.statusIndex),
                const SizedBox(height: 10),
                DPDetailRow(label: 'Requirement', value: booking.requirement),
                DPDetailRow(label: 'Dates', value: booking.dateRange),
                DPDetailRow(label: 'Fee', value: booking.fee),
                DPDetailRow(label: 'Expiry', value: booking.expiry),
              ],
            ),
          ),
      ],
    );
  }
}

class _ContractsTab extends StatelessWidget {
  final DpProject project;
  final List<DpContract> contracts;

  const _ContractsTab({required this.project, required this.contracts});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final contract in contracts)
          DPGlassCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DPProjectBreadcrumbs(
                        project: project,
                        current: contract.id,
                      ),
                      const SizedBox(height: 6),
                      dpText(context, contract.title, strong: true),
                      const SizedBox(height: 4),
                      dpText(
                        context,
                        '${contract.candidate} • ${contract.value} • ${contract.createdDate}',
                      ),
                    ],
                  ),
                ),
                DPStatusChip(
                  label: contract.status,
                  tone: dpToneForStatus(contract.status),
                ),
                IconButton(
                  tooltip: 'Open contract',
                  onPressed: () => Navigator.pushNamed(
                    context,
                    CoreRoutes.contract,
                    arguments: {'contract_id': contract.id},
                  ),
                  icon: const Icon(Icons.open_in_new_rounded),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  final List<DpPayment> payments;

  const _PaymentsTab({required this.payments});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final payment in payments)
          DPGlassCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      dpText(context, payment.stage, strong: true),
                      const SizedBox(height: 4),
                      dpText(
                        context,
                        '${payment.stakeholder} • PKR ${payment.amount} • ${payment.dueDate}',
                      ),
                      if (payment.rejectedReason != null) ...[
                        const SizedBox(height: 4),
                        dpText(context, payment.rejectedReason!),
                      ],
                    ],
                  ),
                ),
                DPStatusChip(
                  label: payment.status,
                  tone: dpToneForStatus(payment.status),
                ),
                IconButton(
                  tooltip: 'Upload proof',
                  onPressed: () => Navigator.pushNamed(
                    context,
                    CoreRoutes.paymentProof,
                    arguments: {'milestone_id': payment.id},
                  ),
                  icon: const Icon(Icons.upload_file_outlined),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FilesTab extends StatelessWidget {
  final DpProject project;

  const _FilesTab({required this.project});

  @override
  Widget build(BuildContext context) {
    final files = [
      '${project.title.replaceAll(' ', '_')}_Script_v1.pdf',
      '${project.title.replaceAll(' ', '_')}_Moodboard.zip',
      '${project.title.replaceAll(' ', '_')}_Call_Sheet_v3.pdf',
      'Contracts vault',
    ];
    return DPSectionCard(
      title: 'Project document vault',
      icon: Icons.folder_copy_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DPStatusChip(
            label: 'Scripts visible only to invited team',
            tone: DpTone.warning,
          ),
          const SizedBox(height: 10),
          for (final file in files)
            DPDetailRow(
              label: file,
              value: file.contains('Script') ? 'Versioned' : 'Shared',
              icon: Icons.description_outlined,
            ),
        ],
      ),
    );
  }
}

class _TeamTab extends StatelessWidget {
  final DpProject project;

  const _TeamTab({required this.project});

  @override
  Widget build(BuildContext context) {
    return DPSectionCard(
      title: 'Team & permissions',
      icon: Icons.groups_2_outlined,
      child: Column(
        children: [
          for (final member in project.team)
            DPDetailRow(
              label: member,
              value: member == project.team.first
                  ? 'Owner'
                  : 'Can view schedule, room, files',
              icon: Icons.person_outline_rounded,
            ),
          const SizedBox(height: 12),
          DPHolographicButton(
            label: 'Invite co-producer',
            icon: Icons.person_add_alt_1_outlined,
            onTap: () {},
            secondary: true,
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final double value;

  const _ProgressRing({required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 5,
            color: colors.goldMid,
            backgroundColor: colors.borderMuted,
          ),
          Center(
            child: Text(
              '${(value * 100).round()}%',
              style: AppTextStyles.caption.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
