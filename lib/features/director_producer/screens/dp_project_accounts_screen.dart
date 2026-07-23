import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/projects/project_models.dart';
import '../../../core/projects/projects_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
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
            0, (sum, project) => sum + project.estimatedBudget);
        final confirmed = projects.fold<int>(
            0, (sum, project) => sum + project.confirmedCost);
        final budgetHealth = totalBudget == 0
            ? 0.0
            : (confirmed / totalBudget).clamp(0.0, 1.0).toDouble();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            dpHeaderAction(
              context,
              icon: Icons.download_outlined,
              label: 'Export',
              onTap: () => dpSnack(context, 'Budget export ready'),
            ),
            const SizedBox(height: 8),
            DPTwoColumn(
              left: DPSectionCard(
                title: 'Budget Overview',
                icon: Icons.pie_chart_outline_rounded,
                child: Column(
                  children: [
                    _BudgetTotal(label: 'Approved budget', amount: totalBudget),
                    _BudgetTotal(
                      label: 'Confirmed cost',
                      amount: confirmed,
                      showDivider: false,
                    ),
                    const SizedBox(height: 10),
                    DPBudgetHealthBar(
                      value: budgetHealth,
                      label: 'Total committed budget',
                    ),
                  ],
                ),
              ),
              right: DPSectionCard(
                title: 'Project Split',
                icon: Icons.bar_chart_rounded,
                child: Column(
                  children: [
                    for (var i = 0; i < projects.length; i++)
                      _ProjectBudgetRow(
                        title: projects[i].title,
                        budget: projects[i].estimatedBudget,
                        committed: projects[i].confirmedCost,
                        health: projects[i].budgetHealth,
                        showDivider: i != projects.length - 1,
                      ),
                  ],
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
    if (projects == null) return;
    setState(() => _future = projects.projects(force: true));
  }
}

class _BudgetTotal extends StatelessWidget {
  final String label;
  final int amount;
  final bool showDivider;

  const _BudgetTotal({
    required this.label,
    required this.amount,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.borderMuted))
            : null,
      ),
      child: Row(
        children: [
          Expanded(child: dpText(context, label)),
          Text(
            'PKR ${(amount / 1000000).toStringAsFixed(1)}M',
            style: AppTextStyles.metricNumberCompact
                .copyWith(color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _ProjectBudgetRow extends StatelessWidget {
  final String title;
  final int budget;
  final int committed;
  final double health;
  final bool showDivider;

  const _ProjectBudgetRow({
    required this.title,
    required this.budget,
    required this.committed,
    required this.health,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.borderMuted))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: dpText(context, title, strong: true)),
              DPStatusChip(
                label: 'PKR ${(committed / 1000000).toStringAsFixed(1)}M',
                tone: DpTone.warning,
              ),
            ],
          ),
          const SizedBox(height: 8),
          DPBudgetHealthBar(value: health, label: 'Health'),
        ],
      ),
    );
  }
}
