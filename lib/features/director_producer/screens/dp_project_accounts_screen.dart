import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/director_producer_demo_data.dart';
import '../widgets/dp_budget_health_bar.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_status_chip.dart';

class DPProjectAccountsScreen extends StatelessWidget {
  const DPProjectAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projects = DirectorProducerDemoData.projects;
    final totalBudget =
        projects.fold<int>(0, (sum, project) => sum + project.estimatedBudget);
    final confirmed =
        projects.fold<int>(0, (sum, project) => sum + project.confirmedCost);
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
                  value: confirmed / totalBudget,
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
