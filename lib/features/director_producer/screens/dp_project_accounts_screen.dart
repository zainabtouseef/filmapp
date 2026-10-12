import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/projects/project_models.dart';
import '../../../core/projects/projects_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/tour/tour_target.dart';
import '../models/dp_project.dart';
import '../widgets/dp_budget_health_bar.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_status_chip.dart';

class DPProjectAccountsScreen extends StatefulWidget {
  const DPProjectAccountsScreen({super.key});

  @override
  State<DPProjectAccountsScreen> createState() =>
      _DPProjectAccountsScreenState();
}

class _DPProjectAccountsScreenState extends State<DPProjectAccountsScreen> {
  Future<List<Project>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final projects = ProjectsScope.maybeOf(context);
    if (projects != null) _future ??= projects.projects(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
    if (future == null) {
      return const CoreEmptyState(
        icon: Icons.lock_outline_rounded,
        title: 'Sign in required',
        message: 'Connect a live Director account to view project accounts.',
      );
    }
    return FutureBuilder<List<Project>>(
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
        final projects =
            (snapshot.data ?? const []).map((p) => p.toDpProject()).toList();
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
        final budgetHealth = totalBudget == 0
            ? 0.0
            : (confirmed / totalBudget).clamp(0.0, 1.0).toDouble();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            dpHeaderAction(
              context,
              icon: Icons.download_outlined,
              label: 'Export ledger',
              onTap: () => dpSnack(context, 'Budget export ready'),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final chart = TourTarget(
                  id: 'dp.accounts.projectSplit',
                  child: DPSectionCard(
                    title: 'Budget distribution',
                    icon: Icons.stacked_bar_chart_rounded,
                    child: _BudgetDistribution(projects: projects),
                  ),
                );
                final balance = TourTarget(
                  id: 'dp.accounts.budgetOverview',
                  child: DPSectionCard(
                    title: 'Portfolio balance',
                    icon: Icons.donut_large_rounded,
                    child: _PortfolioBalance(
                      totalBudget: totalBudget,
                      confirmed: confirmed,
                      health: budgetHealth,
                    ),
                  ),
                );
                if (constraints.maxWidth < 900) {
                  return Column(
                    children: [
                      chart,
                      const SizedBox(height: 12),
                      balance,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: chart),
                    const SizedBox(width: 12),
                    Expanded(flex: 3, child: balance),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            DPSectionCard(
              title: 'Project allocation',
              icon: Icons.account_tree_outlined,
              child: _ProjectAllocationGrid(projects: projects),
            ),
          ],
        );
      },
    );
  }

  void _reload() {
    final projects = ProjectsScope.maybeOf(context);
    if (projects == null) return;
    setState(() => _future = projects.projects(force: true));
  }
}

class _BudgetDistribution extends StatelessWidget {
  final List<DpProject> projects;

  const _BudgetDistribution({required this.projects});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final maxBudget = projects.fold<int>(
      1,
      (current, project) =>
          project.estimatedBudget > current ? project.estimatedBudget : current,
    );
    final visible = projects.take(8).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _LegendDot(color: colors.goldMid, label: 'Approved'),
            const SizedBox(width: 16),
            _LegendDot(color: colors.infoBlue, label: 'Committed'),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 220,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final project in visible) ...[
                Expanded(
                  child: _BudgetBar(
                    project: project,
                    maxBudget: maxBudget,
                  ),
                ),
                if (project != visible.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
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
    final approved = (project.estimatedBudget / maxBudget).clamp(0.03, 1.0);
    final committed = project.estimatedBudget == 0
        ? 0.0
        : (project.confirmedCost / project.estimatedBudget).clamp(0.0, 1.0);
    return Tooltip(
      message:
          '${project.title}\nApproved PKR ${(project.estimatedBudget / 1000000).toStringAsFixed(1)}M\nCommitted PKR ${(project.confirmedCost / 1000000).toStringAsFixed(1)}M',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '${(project.confirmedCost / 1000000).toStringAsFixed(1)}M',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.micro.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: approved,
                widthFactor: .72,
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.goldMid.withValues(alpha: .16),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                    border: Border.all(
                      color: colors.goldMid.withValues(alpha: .34),
                    ),
                  ),
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: committed == 0 ? .025 : committed,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [colors.infoBlue, colors.goldMid],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(9),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            project.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.micro.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioBalance extends StatelessWidget {
  final int totalBudget;
  final int confirmed;
  final double health;

  const _PortfolioBalance({
    required this.totalBudget,
    required this.confirmed,
    required this.health,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        SizedBox(
          width: 178,
          height: 178,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: health),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => CustomPaint(
              painter: _BudgetDonutPainter(
                value: value,
                track: colors.borderMuted,
                start: colors.infoBlue,
                end: colors.goldMid,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(value * 100).round()}%',
                      style: AppTextStyles.metricNumber.copyWith(
                        color: colors.textPrimary,
                        fontSize: 28,
                      ),
                    ),
                    Text(
                      'committed',
                      style: AppTextStyles.smallMeta.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _BudgetAmount(label: 'Approved', amount: totalBudget),
        const SizedBox(height: 8),
        _BudgetAmount(label: 'Committed', amount: confirmed),
        const SizedBox(height: 8),
        _BudgetAmount(
          label: 'Available',
          amount: (totalBudget - confirmed).clamp(0, totalBudget),
        ),
      ],
    );
  }
}

class _BudgetAmount extends StatelessWidget {
  final String label;
  final int amount;

  const _BudgetAmount({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Expanded(child: dpText(context, label)),
        Text(
          'PKR ${(amount / 1000000).toStringAsFixed(1)}M',
          style: AppTextStyles.cardLabel.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
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
                    'PKR ${(project.confirmedCost / 1000000).toStringAsFixed(1)}M',
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
          DPBudgetHealthBar(
              value: project.budgetHealth, label: 'Budget health'),
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

class _BudgetDonutPainter extends CustomPainter {
  final double value;
  final Color track;
  final Color start;
  final Color end;

  const _BudgetDonutPainter({
    required this.value,
    required this.track,
    required this.start,
    required this.end,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 15.0;
    final rect = Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(rect, -1.5708, 6.2832, false, trackPaint);
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -1.5708,
        endAngle: 4.7124,
        colors: [start, end],
      ).createShader(rect);
    canvas.drawArc(
      rect,
      -1.5708,
      6.2832 * value.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BudgetDonutPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.track != track ||
      oldDelegate.start != start ||
      oldDelegate.end != end;
}
