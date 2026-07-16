part of '../super_admin_screens.dart';

class ContractTemplateDetailScreen extends StatelessWidget {
  const ContractTemplateDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headline(context, 'Actor Booking Agreement'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  AdminStatusBadge(label: 'v1.0', tone: AdminDecisionTone.info),
                  AdminStatusBadge(
                      label: 'Published', tone: AdminDecisionTone.success),
                  AdminStatusBadge(
                      label: 'Updated Jul 7, 2026',
                      tone: AdminDecisionTone.neutral),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AdminSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _reviewCard(context, 'Clause List', const [
                'Parties',
                'Project',
                'Dates',
                'Payment Schedule',
                'Deliverables',
                'Usage Rights',
                'Cancellation',
              ]),
              _reviewDivider(context),
              _reviewCard(context, 'Mandatory Rule Checks', const [
                'Usage rights block present',
                'Payment schedule matches booking milestones',
                'Cancellation terms defined',
              ]),
              _reviewDivider(context),
              const AdminSectionHeader(title: 'Placeholder Tokens'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  AdminStatusBadge(
                      label: '{{fee}}', tone: AdminDecisionTone.neutral),
                  AdminStatusBadge(
                      label: '{{dates}}', tone: AdminDecisionTone.neutral),
                  AdminStatusBadge(
                      label: '{{usage_rights}}',
                      tone: AdminDecisionTone.neutral),
                  AdminStatusBadge(
                      label: '{{payment_schedule}}',
                      tone: AdminDecisionTone.neutral),
                  AdminStatusBadge(
                      label: '{{deliverables}}',
                      tone: AdminDecisionTone.neutral),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AdminSurface(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AdminActionButton(
                icon: Icons.publish_outlined,
                label: 'Publish',
                onTap: () => showCoreSnack(context, 'Template published'),
              ),
              AdminActionButton(
                icon: Icons.save_outlined,
                label: 'Save',
                secondary: true,
                onTap: () => showCoreSnack(context, 'Draft saved'),
              ),
              AdminActionButton(
                icon: Icons.copy_all_outlined,
                label: 'Duplicate',
                secondary: true,
                onTap: () => showCoreSnack(context, 'Template duplicated'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
