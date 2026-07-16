part of '../super_admin_screens.dart';

class DisputeCenterScreen extends StatefulWidget {
  const DisputeCenterScreen({super.key});

  @override
  State<DisputeCenterScreen> createState() => _DisputeCenterScreenState();
}

class _DisputeCenterScreenState extends State<DisputeCenterScreen> {
  String _tab = 'All';
  final Set<String> _urgent = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ResponsiveGrid(
          minTileWidth: 190,
          childAspectRatio: 2.6,
          children: const [
            AdminMetricTile(
                label: 'New cases',
                value: '11',
                icon: Icons.fiber_new_outlined,
                tone: AdminDecisionTone.warning),
            AdminMetricTile(
                label: 'Evidence gathering',
                value: '9',
                icon: Icons.folder_copy_outlined,
                tone: AdminDecisionTone.info),
            AdminMetricTile(
                label: 'Decision pending',
                value: '7',
                icon: Icons.gavel_outlined,
                tone: AdminDecisionTone.danger),
            AdminMetricTile(
                label: 'Resolved this month',
                value: '48',
                icon: Icons.check_circle_outline,
                tone: AdminDecisionTone.success),
            AdminMetricTile(
                label: 'Safety cases',
                value: '2',
                icon: Icons.health_and_safety_outlined,
                tone: AdminDecisionTone.danger),
          ],
        ),
        const SizedBox(height: 18),
        AdminFilterBar(
          filters: const [
            'All',
            'Payment',
            'Completion',
            'Cancellation',
            'Location Damage',
            'Equipment Damage',
            'Harassment / Safety'
          ],
          selected: _tab,
          onSelected: (value) => setState(() => _tab = value),
        ),
        const SizedBox(height: 16),
        ...AdminMockData.disputes.map((d) {
          final severity = _urgent.contains(d.caseId) ? 'Urgent' : d.severity;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DisputeRow(
              dispute: d,
              severity: severity,
              onOpen: () =>
                  Navigator.pushNamed(context, SuperAdminRoutes.disputeCase),
              onAssign: () => _staffSheet(context),
              onUrgent: () => setState(() => _urgent.add(d.caseId)),
            ),
          );
        }),
      ],
    );
  }
}

class _DisputeRow extends StatelessWidget {
  final AdminDispute dispute;
  final String severity;
  final VoidCallback onOpen;
  final VoidCallback onAssign;
  final VoidCallback onUrgent;

  const _DisputeRow({
    required this.dispute,
    required this.severity,
    required this.onOpen,
    required this.onAssign,
    required this.onUrgent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final urgent = severity.contains('Safety') || severity == 'Urgent';
    return GestureDetector(
      onTap: onOpen,
      child: AdminSurface(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${dispute.caseId} - ${dispute.type}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                AdminSlaBadge(age: dispute.age),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              '${dispute.parties} - ${dispute.bookingId} - ${dispute.value}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.micro.copyWith(
                color: colors.textSecondary,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                AdminStatusBadge(
                    label: dispute.status, tone: AdminDecisionTone.warning),
                AdminRiskBadge(
                  label: severity,
                  risk: urgent ? AdminRiskTone.high : AdminRiskTone.medium,
                ),
                AdminStatusBadge(
                    label: 'Assigned: ${dispute.assignedTo}',
                    tone: AdminDecisionTone.neutral),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _tinyAction(context, 'Open', onOpen),
                _tinyAction(context, 'Assign', onAssign),
                _tinyAction(context, 'Urgent', onUrgent),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
