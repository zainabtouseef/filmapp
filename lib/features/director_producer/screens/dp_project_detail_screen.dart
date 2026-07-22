import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/dp_booking.dart';
import '../models/dp_contract.dart';
import '../models/dp_payment.dart';
import '../models/dp_project.dart';
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

  static const _tabs = [
    'Overview',
    'Budget & Costs',
    'Shortlists',
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
  Widget build(BuildContext context) {
    final project = dpProjectForId(widget.projectId);
    final bookings = dpBookingsForProject(project.id);
    final contracts = dpContractsForProject(project.title);
    final payments = dpPaymentsForProject(project.title);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DPProjectBreadcrumbs(project: project, current: _tabs[_tab]),
        const SizedBox(height: 10),
        _ProjectHeader(
          project: project,
          bookings: bookings,
          contracts: contracts,
          payments: payments,
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _tab = i),
                    child: DPStatusChip(
                      label: _tabs[i],
                      tone: _tab == i ? DpTone.warning : DpTone.neutral,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _ProjectTabBody(
          tab: _tabs[_tab],
          project: project,
          bookings: bookings,
          contracts: contracts,
          payments: payments,
        ),
      ],
    );
  }
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 74,
                height: 92,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: colors.goldGradient,
                  border: Border.all(color: colors.border),
                ),
                child: Icon(Icons.movie_filter_rounded,
                    color: colors.onGold, size: 34),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
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
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        DPStatusChip(label: project.type, tone: DpTone.warning),
                        DPStatusChip(label: project.status, tone: DpTone.info),
                        DPStatusChip(label: project.city, tone: DpTone.neutral),
                        DPStatusChip(
                          label: project.dateRange,
                          tone: DpTone.neutral,
                          icon: Icons.date_range_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _ProgressRing(value: project.progress),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DPStatusChip(
                label:
                    'Budget PKR ${(project.estimatedBudget / 1000000).toStringAsFixed(1)}M',
                tone: DpTone.purple,
              ),
              DPStatusChip(
                label:
                    'Committed PKR ${(project.confirmedCost / 1000000).toStringAsFixed(1)}M',
                tone: DpTone.warning,
              ),
              DPStatusChip(
                label: 'Paid PKR ${(paid / 1000).round()}k',
                tone: DpTone.success,
              ),
              DPStatusChip(
                label: 'Signed $signed/${contracts.length}',
                tone: DpTone.success,
              ),
              for (final member in project.team.take(4))
                DPStatusChip(label: member, tone: DpTone.neutral),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProjectTabBody extends StatelessWidget {
  final String tab;
  final DpProject project;
  final List<DpBooking> bookings;
  final List<DpContract> contracts;
  final List<DpPayment> payments;

  const _ProjectTabBody({
    required this.tab,
    required this.project,
    required this.bookings,
    required this.contracts,
    required this.payments,
  });

  @override
  Widget build(BuildContext context) {
    return switch (tab) {
      'Overview' => _OverviewTab(project: project, bookings: bookings),
      'Budget & Costs' =>
        _BudgetTab(project: project, bookings: bookings, contracts: contracts),
      'Shortlists' => DPProjectScopedShortlists(project: project),
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
  final List<DpBooking> bookings;

  const _OverviewTab({required this.project, required this.bookings});

  @override
  Widget build(BuildContext context) {
    final requirements = dpRequirementsForProject(project.id);
    return DPTwoColumn(
      left: DPSectionCard(
        title: 'Build your production',
        icon: Icons.fact_check_outlined,
        child: DPProductionChecklist(
          project: project,
          requirements: requirements,
          bookings: bookings,
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
                value: project.confirmedCost / project.estimatedBudget,
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
