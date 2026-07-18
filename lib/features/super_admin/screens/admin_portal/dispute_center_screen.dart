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
        const _LiveDisputePanel(),
        const SizedBox(height: 16),
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

class _LiveDisputePanel extends StatefulWidget {
  const _LiveDisputePanel();

  @override
  State<_LiveDisputePanel> createState() => _LiveDisputePanelState();
}

class _LiveDisputePanelState extends State<_LiveDisputePanel> {
  late Future<List<DisputeDto>> _future;
  bool _updating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final trustSafety = TrustSafetyScope.maybeOf(context);
    _future = trustSafety == null
        ? Future.value(const <DisputeDto>[])
        : trustSafety.adminDisputes(force: true);
  }

  Future<void> _decide(DisputeDto dispute, String decision) async {
    final trustSafety = TrustSafetyScope.maybeOf(context);
    if (trustSafety == null || _updating) return;
    setState(() => _updating = true);
    try {
      await trustSafety.decideDispute(
        disputeId: dispute.publicId,
        decision: decision,
        note: 'Recorded from Flutter Super Admin dispute center.',
      );
      if (!mounted) return;
      setState(() => _future = trustSafety.adminDisputes(force: true));
      showCoreSnack(context, 'Live dispute updated');
    } catch (_) {
      if (mounted) showCoreSnack(context, 'Could not update live dispute');
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DisputeDto>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator(minHeight: 2);
        }
        if (snapshot.hasError) {
          return const InlineNotice(
            message:
                'Live dispute queue unavailable — showing preview dispute cases.',
            tone: CoreStatusTone.warning,
          );
        }
        final rows = snapshot.data ?? const <DisputeDto>[];
        if (rows.isEmpty) {
          return const InlineNotice(
            message:
                'No live disputes are open — preview dispute cases remain below.',
          );
        }
        final dispute = rows.first;
        return AdminSurface(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AdminStatusBadge(
                label: '${rows.length} live disputes',
                tone: AdminDecisionTone.warning,
              ),
              AdminStatusBadge(
                label: dispute.severity,
                tone: dispute.severity == 'high'
                    ? AdminDecisionTone.danger
                    : AdminDecisionTone.info,
              ),
              Text(
                '${dispute.publicId} · ${dispute.type} · ${dispute.status}',
                style: AppTextStyles.caption
                    .copyWith(color: context.appColors.textSecondary),
              ),
              _tinyAction(
                context,
                _updating ? 'Updating...' : 'Resolve live',
                _updating ? null : () => _decide(dispute, 'resolved'),
              ),
              _tinyAction(
                context,
                _updating ? 'Updating...' : 'Escalate live',
                _updating ? null : () => _decide(dispute, 'escalated'),
              ),
            ],
          ),
        );
      },
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
