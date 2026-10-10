import 'package:flutter/material.dart';

import '../../core/projects/project_models.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';

/// Readiness reports saved planning information, never inferred shoot progress.
class ProjectReadinessSummary extends StatelessWidget {
  final Project project;
  final List<ProjectRequirement> requirements;

  const ProjectReadinessSummary({
    super.key,
    required this.project,
    required this.requirements,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final checks = <String, bool>{
      'Project title': project.title.trim().isNotEmpty,
      'Production brief': project.description?.trim().isNotEmpty ?? false,
      'Production city': project.city != null,
      'Shoot dates': project.startDate != null && project.endDate != null,
      'Estimated budget': (project.estimatedBudgetMinor ?? 0) > 0,
      'Resource requirements': requirements.isNotEmpty,
    };
    final completed = checks.entries
        .where((item) => item.value)
        .map((item) => item.key)
        .toList();
    final missing = checks.entries
        .where((item) => !item.value)
        .map((item) => item.key)
        .toList();
    final pending = requirements
        .where((item) => !{'filled', 'completed', 'cancelled', 'closed'}
            .contains(item.status))
        .map((item) => '${item.title} · ${item.status.replaceAll('_', ' ')}')
        .toList();
    return Container(
      key: const ValueKey('project-readiness-summary'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.elevatedSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Project status summary',
              style:
                  AppTextStyles.cardTitle.copyWith(color: colors.textPrimary)),
          const SizedBox(height: 6),
          Text(
              '${completed.length} of ${checks.length} planning details saved. This is setup readiness, not production completion.',
              style: AppTextStyles.smallMeta
                  .copyWith(color: colors.textSecondary)),
          const SizedBox(height: 10),
          LinearProgressIndicator(
              value: completed.length / checks.length,
              color: colors.goldMid,
              backgroundColor: colors.borderMuted),
          const SizedBox(height: 12),
          _group(context, 'Completed', completed, colors.success,
              'No planning details saved.'),
          _group(context, 'Missing', missing, colors.warning,
              'All planning details provided.'),
          _group(context, 'Pending', pending, colors.infoBlue,
              'No open resource requirements.'),
        ],
      ),
    );
  }

  Widget _group(BuildContext context, String label, List<String> items,
      Color color, String empty) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label (${items.length})',
              style: AppTextStyles.label.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(items.isEmpty ? empty : items.join(' • '),
              style: AppTextStyles.body
                  .copyWith(color: context.appColors.textSecondary)),
        ],
      ),
    );
  }
}
