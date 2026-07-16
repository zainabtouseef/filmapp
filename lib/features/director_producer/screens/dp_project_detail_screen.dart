import 'package:flutter/material.dart';

import '../data/director_producer_demo_data.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_booking_status_spine.dart';
import '../widgets/dp_budget_health_bar.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_requirement_card.dart';
import '../widgets/dp_status_chip.dart';

class DPProjectDetailScreen extends StatelessWidget {
  final String? projectId;

  const DPProjectDetailScreen({super.key, this.projectId});

  @override
  Widget build(BuildContext context) {
    final projects = DirectorProducerDemoData.projects;
    final project = projects.firstWhere(
      (item) => item.id == projectId,
      orElse: () => projects.first,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DPGlassCard(
          selected: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: dpText(context, project.title, strong: true)),
                  DPStatusChip(label: project.status, tone: DpTone.warning),
                ],
              ),
              const SizedBox(height: 8),
              dpText(
                context,
                '${project.type} - ${project.city} - ${project.dateRange} - PKR ${project.estimatedBudget}',
              ),
              const SizedBox(height: 12),
              DPBudgetHealthBar(value: project.budgetHealth, label: 'Budget'),
              const SizedBox(height: 12),
              const DPBookingStatusSpine(activeIndex: 9),
            ],
          ),
        ),
        const SizedBox(height: 14),
        DPTwoColumn(
          left: DPSectionCard(
            title: 'Open Requirements',
            icon: Icons.rule_folder_outlined,
            actionText: 'Builder',
            onActionTap: () => Navigator.pushNamed(
                context, DirectorProducerRoutes.requirements),
            child: Column(
              children: DirectorProducerDemoData.requirements
                  .take(3)
                  .map(
                    (req) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: DPRequirementCard(
                        requirement: req,
                        onFindMatches: () => Navigator.pushNamed(
                            context, DirectorProducerRoutes.marketplace),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          right: DPSectionCard(
            title: 'Command Actions',
            icon: Icons.bolt_rounded,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                DPHolographicButton(
                  label: 'Send Booking',
                  icon: Icons.send_rounded,
                  onTap: () => Navigator.pushNamed(
                      context, DirectorProducerRoutes.bookingRequest),
                ),
                DPHolographicButton(
                  label: 'Contracts',
                  icon: Icons.article_outlined,
                  onTap: () => Navigator.pushNamed(
                      context, DirectorProducerRoutes.contracts),
                  secondary: true,
                ),
                DPHolographicButton(
                  label: 'Room',
                  icon: Icons.forum_outlined,
                  onTap: () =>
                      Navigator.pushNamed(context, DirectorProducerRoutes.room),
                  secondary: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
