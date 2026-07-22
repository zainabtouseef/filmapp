import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/director_producer_demo_data.dart';
import '../../models/dp_project.dart';
import '../../routes/director_producer_routes.dart';
import '../dp_budget_health_bar.dart';
import '../dp_glass_card.dart';
import '../dp_holographic_button.dart';
import '../dp_status_chip.dart';

/// The "Project Command Deck" — a dossier-style rail of active
/// productions with budget health, next milestone and pending-action
/// signal at a glance.
class DPProjectDeck extends StatelessWidget {
  const DPProjectDeck({super.key});

  @override
  Widget build(BuildContext context) {
    final projects = DirectorProducerDemoData.projects;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final project in projects) ...[
            SizedBox(width: 268, child: _ProjectDossierCard(project: project)),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

DpTone _statusTone(String status) {
  return switch (status) {
    'Shooting' => DpTone.success,
    'Casting' || 'Negotiating' => DpTone.warning,
    'Draft' => DpTone.neutral,
    _ => DpTone.info,
  };
}

class _ProjectDossierCard extends StatelessWidget {
  final DpProject project;

  const _ProjectDossierCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DPGlassCard(
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  project.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle
                      .copyWith(color: colors.textPrimary),
                ),
              ),
              DPStatusChip(
                  label: project.status, tone: _statusTone(project.status)),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '${project.type} • ${project.city}',
            style:
                AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 10),
          DPBudgetHealthBar(
              value: project.budgetHealth, label: 'Budget health'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              DPStatusChip(
                label: '${project.contractsCount} signed/active',
                tone: DpTone.success,
              ),
              DPStatusChip(
                label: 'Next ${project.shootDate}',
                tone: DpTone.warning,
              ),
              if (project.pendingActions > 0)
                DPStatusChip(
                  label: '${project.pendingActions} pending',
                  tone: DpTone.danger,
                ),
            ],
          ),
          const SizedBox(height: 11),
          DPHolographicButton(
            label: 'Open Project',
            icon: Icons.open_in_new_rounded,
            secondary: true,
            onTap: () => Navigator.pushNamed(
              context,
              DirectorProducerRoutes.projectDetail,
              arguments: project.id,
            ),
          ),
        ],
      ),
    );
  }
}
