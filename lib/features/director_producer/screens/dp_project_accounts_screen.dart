import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_controller.dart';
import '../../../core/analytics/csv_download.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/projects/projects_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/tour/tour_target.dart';
import '../../../shared/formatters/cine_format.dart';
import '../models/dp_project.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_status_chip.dart';

class DPProjectAccountsScreen extends StatefulWidget {
  const DPProjectAccountsScreen({super.key});

  @override
  State<DPProjectAccountsScreen> createState() =>
      _DPProjectAccountsScreenState();
}

class _DPProjectAccountsScreenState extends State<DPProjectAccountsScreen> {
  Future<List<DpProject>>? _accountsFuture;
  bool _showGraph = true;
  bool _exporting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final projects = ProjectsScope.maybeOf(context);
    final bookings = BookingsScope.maybeOf(context);
    if (projects != null && bookings != null) {
      _accountsFuture ??= _loadAccounts(projects, bookings);
    }
  }

  Future<List<DpProject>> _loadAccounts(
    ProjectsController projects,
    BookingsController bookings,
  ) async {
    final rows = await projects.projects(force: true);
    final liveBookings = await bookings.bookings(force: true);
    final committedByProject = <String, int>{};
    for (final booking in liveBookings) {
      if (booking.status != 'accepted' && booking.status != 'secured') continue;
      committedByProject.update(
        booking.projectId,
        (amount) => amount + (booking.agreedAmountMinor ?? 0) ~/ 100,
        ifAbsent: () => (booking.agreedAmountMinor ?? 0) ~/ 100,
      );
    }
    return rows.map((row) {
      final project = row.toDpProject();
      final committed = committedByProject[row.publicId] ?? 0;
      return project.copyWith(
        confirmedCost: committed,
        budgetHealth: project.estimatedBudget == 0
            ? 0
            : (committed / project.estimatedBudget).clamp(0.0, 1.0).toDouble(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final future = _accountsFuture;
    if (future == null) {
      return const CoreEmptyState(
        icon: Icons.lock_outline_rounded,
        title: 'Sign in required',
        message: 'Connect a live Director account to view project accounts.',
      );
    }
    return FutureBuilder<List<DpProject>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CoreEmptyState(
            icon: Icons.hourglass_top_rounded,
            title: 'Loading project accounts',
            message: 'Fetching live project budgets from the database.',
          );
        }
        if (snapshot.hasError) {
          return CoreEmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Project accounts unavailable',
            message:
                'Could not load live project budgets from the database. Check the API connection and try again.',
            actionLabel: 'Retry',
            onAction: _reload,
          );
        }
        final projects = snapshot.data ?? const <DpProject>[];
        if (projects.isEmpty) {
          return const CoreEmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'No project accounts yet',
            message:
                'Create a project with an approved budget to populate this screen from the database.',
          );
        }
        final totalBudget = projects.fold<int>(
          0,
          (sum, project) => sum + project.estimatedBudget,
        );
        final confirmed = projects.fold<int>(
          0,
          (sum, project) => sum + project.confirmedCost,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            dpHeaderAction(
              context,
              icon: Icons.download_outlined,
              label: _exporting ? 'Exporting…' : 'Export ledger',
              onTap: _exporting ? null : _exportLedger,
            ),
            const SizedBox(height: 10),
            TourTarget(
              id: 'dp.accounts.projectSplit',
              child: TourTarget(
                id: 'dp.accounts.budgetOverview',
                child: DPSectionCard(
                  title: 'Budget overview',
                  icon: Icons.stacked_bar_chart_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AccountsViewSwitch(
                        showGraph: _showGraph,
                        onChanged: (value) =>
                            setState(() => _showGraph = value),
                      ),
                      const SizedBox(height: 18),
                      _BudgetSummary(
                        totalBudget: totalBudget,
                        committed: confirmed,
                      ),
                      const SizedBox(height: 18),
                      if (_showGraph)
                        _BudgetDistribution(projects: projects)
                      else
                        _ProjectAllocationGrid(projects: projects),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _reload() {
    final projects = ProjectsScope.maybeOf(context);
    final bookings = BookingsScope.maybeOf(context);
    if (projects == null || bookings == null) return;
    setState(() => _accountsFuture = _loadAccounts(projects, bookings));
  }

  Future<void> _exportLedger() async {
    final analytics = AnalyticsScope.maybeOf(context);
    if (analytics == null) {
      dpSnack(context, 'Sign in to export the ledger.');
      return;
    }
    setState(() => _exporting = true);
    try {
      final job = await analytics.createExport('ledger');
      if (!mounted) return;
      final csv = job.csvContent;
      final downloaded = csv != null &&
          csv.isNotEmpty &&
          downloadCsv('cineconnect_ledger_${job.publicId}.csv', csv);
      dpSnack(
        context,
        downloaded
            ? 'Ledger downloaded (${job.rowCount} rows).'
            : 'Ledger ready in Reports (${job.rowCount} rows).',
      );
    } catch (_) {
      if (mounted) dpSnack(context, 'Could not export the ledger. Try again.');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}

class _BudgetDistribution extends StatelessWidget {
  final List<DpProject> projects;

  const _BudgetDistribution({required this.projects});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final plotted = projects
        .where((project) =>
            project.estimatedBudget > 0 || project.confirmedCost > 0)
        .toList()
      ..sort((a, b) => b.estimatedBudget.compareTo(a.estimatedBudget));
    final unbudgetedCount = projects.length - plotted.length;
    final maxBudget = plotted.fold<int>(
      1,
      (current, project) {
        final amount = project.estimatedBudget > project.confirmedCost
            ? project.estimatedBudget
            : project.confirmedCost;
        return amount > current ? amount : current;
      },
    );
    if (plotted.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No approved budgets yet. Add a budget to a production to see the chart.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            _LegendDot(color: colors.goldMid, label: 'Approved budget'),
            _LegendDot(color: colors.infoBlue, label: 'Committed bookings'),
          ],
        ),
        const SizedBox(height: 12),
        for (final project in plotted) ...[
          _BudgetBar(project: project, maxBudget: maxBudget),
          if (project != plotted.last)
            Divider(height: 18, color: colors.borderMuted),
        ],
        if (unbudgetedCount > 0) ...[
          const SizedBox(height: 12),
          Text(
            '$unbudgetedCount productions have no approved budget or committed bookings. View all in List.',
            style:
                AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
          ),
        ],
      ],
    );
  }
}

class _AccountsViewSwitch extends StatelessWidget {
  final bool showGraph;
  final ValueChanged<bool> onChanged;

  const _AccountsViewSwitch({required this.showGraph, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final view in const [true, false])
          Semantics(
            button: true,
            selected: showGraph == view,
            child: InkWell(
              onTap: () => onChanged(view),
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  color:
                      showGraph == view ? colors.goldMid : colors.softSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: showGraph == view ? colors.goldMid : colors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      view ? Icons.bar_chart_rounded : Icons.view_list_rounded,
                      size: 17,
                      color: showGraph == view
                          ? colors.onGold
                          : colors.textSecondary,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      view ? 'Graph' : 'List',
                      style: AppTextStyles.cardLabel.copyWith(
                        color: showGraph == view
                            ? colors.onGold
                            : colors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _BudgetSummary extends StatelessWidget {
  final int totalBudget;
  final int committed;

  const _BudgetSummary({required this.totalBudget, required this.committed});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 520 ? 1 : 3;
        const gap = 8.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            _SummaryValue(width: width, label: 'Approved', amount: totalBudget),
            _SummaryValue(width: width, label: 'Committed', amount: committed),
            _SummaryValue(
              width: width,
              label: 'Available',
              amount: (totalBudget - committed).clamp(0, totalBudget),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryValue extends StatelessWidget {
  final double width;
  final String label;
  final int amount;

  const _SummaryValue(
      {required this.width, required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: colors.softSurface.withValues(alpha: colors.isLight ? .7 : .35),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: colors.borderMuted),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style:
                  AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
            ),
          ),
          Text(
            CineFormat.currency(amount, compact: true),
            style: AppTextStyles.cardLabel.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetBar extends StatelessWidget {
  final DpProject project;
  final int maxBudget;

  const _BudgetBar({required this.project, required this.maxBudget});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final approved = (project.estimatedBudget / maxBudget).clamp(0.0, 1.0);
    final committed = (project.confirmedCost / maxBudget).clamp(0.0, 1.0);
    return Tooltip(
      message:
          '${project.title}\nApproved ${CineFormat.currency(project.estimatedBudget)}\nCommitted ${CineFormat.currency(project.confirmedCost)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  project.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${CineFormat.currency(project.confirmedCost, compact: true)} committed',
                style: AppTextStyles.smallMeta.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _BarTrack(value: approved, color: colors.goldMid),
          const SizedBox(height: 4),
          _BarTrack(value: committed, color: colors.infoBlue),
          const SizedBox(height: 4),
          Text(
            'Approved ${CineFormat.currency(project.estimatedBudget, compact: true)}',
            style: AppTextStyles.micro.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _BarTrack extends StatelessWidget {
  final double value;
  final Color color;

  const _BarTrack({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      height: 7,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.borderMuted,
                borderRadius: BorderRadius.circular(9),
              ),
              child: SizedBox(width: constraints.maxWidth, height: 7),
            ),
            if (value > 0)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: SizedBox(width: constraints.maxWidth * value, height: 7),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProjectAllocationGrid extends StatelessWidget {
  final List<DpProject> projects;

  const _ProjectAllocationGrid({required this.projects});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 2 : 1;
        const gap = 12.0;
        final width = (constraints.maxWidth - (columns - 1) * gap) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final project in projects)
              SizedBox(
                width: width,
                child: _ProjectBudgetRow(project: project),
              ),
          ],
        );
      },
    );
  }
}

class _ProjectBudgetRow extends StatelessWidget {
  final DpProject project;

  const _ProjectBudgetRow({required this.project});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      decoration: BoxDecoration(
        color: colors.softSurface.withValues(alpha: colors.isLight ? .7 : .28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: dpText(context, project.title, strong: true)),
              DPStatusChip(
                label:
                    '${CineFormat.currency(project.confirmedCost, compact: true)} committed',
                tone: DpTone.warning,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${project.type} · ${project.city}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Committed of approved',
                  style: AppTextStyles.smallMeta
                      .copyWith(color: colors.textSecondary),
                ),
              ),
              Text(
                '${(project.budgetHealth * 100).round()}%',
                style: AppTextStyles.smallMeta
                    .copyWith(color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _BarTrack(value: project.budgetHealth, color: colors.infoBlue),
          const SizedBox(height: 5),
          Text(
            'Approved ${CineFormat.currency(project.estimatedBudget, compact: true)}',
            style:
                AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.smallMeta.copyWith(
            color: context.appColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
