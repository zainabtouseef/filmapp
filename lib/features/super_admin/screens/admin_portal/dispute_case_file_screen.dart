part of '../super_admin_screens.dart';

class DisputeCaseFileScreen extends StatefulWidget {
  const DisputeCaseFileScreen({super.key});

  @override
  State<DisputeCaseFileScreen> createState() => _DisputeCaseFileScreenState();
}

class _DisputeCaseFileScreenState extends State<DisputeCaseFileScreen> {
  String _tab = 'Contract Versions';
  bool _notify = true;
  final _ruling = TextEditingController();

  @override
  void dispose() {
    _ruling.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            AdminStatusBadge(label: 'DSP-441', tone: AdminDecisionTone.info),
            AdminStatusBadge(
                label: 'Payment dispute', tone: AdminDecisionTone.warning),
            AdminStatusBadge(
                label: 'Decision Pending', tone: AdminDecisionTone.danger),
            AdminStatusBadge(
                label: 'PKR 350,000', tone: AdminDecisionTone.warning),
            AdminStatusBadge(
                label: 'Assigned: Basit', tone: AdminDecisionTone.neutral),
            AdminStatusBadge(
                label: 'SLA 9h left', tone: AdminDecisionTone.danger),
          ],
        ),
        const SizedBox(height: 14),
        _ThreePane(
          left: const AdminSurface(
            child: AdminTimeline(
              items: [
                'Booking created - Jul 2, 10:12 - system',
                'Offer sent - producer',
                'Counteroffer submitted - model',
                'Terms approved - both parties',
                'Contract signed - OTP signature',
                'Payment proof uploaded - payer',
                'Shoot completed - stakeholder',
                'Complaint filed - payee',
                'Evidence requested - admin',
              ],
            ),
          ),
          center: AdminSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminFilterBar(
                  filters: const [
                    'Contract Versions',
                    'Negotiation Timeline',
                    'Booking Chat',
                    'Payment Proofs & Ledger',
                    'Completion Proofs',
                    'Inspection / Handover Photos',
                    'Report Forms',
                    'Prior History',
                  ],
                  selected: _tab,
                  onSelected: (value) => setState(() => _tab = value),
                ),
                const SizedBox(height: 14),
                if (_tab == 'Booking Chat')
                  const ChatBubble(
                    message: ChatMessage(
                      sender: 'Sara',
                      message:
                          'Payment was not released after approved deliverables.',
                      time: 'Jul 7',
                      mine: false,
                    ),
                  )
                else if (_tab == 'Payment Proofs & Ledger')
                  LedgerRowCard(
                    row: AdminMockDataProxy.ledgerRow,
                    onTap: () =>
                        Navigator.pushNamed(context, CoreRoutes.ledger),
                  )
                else
                  AdminEvidenceViewer(
                    title: _tab,
                    icon: Icons.folder_copy_outlined,
                    details: const [
                      'Verified source',
                      'Linked booking',
                      'Audit available'
                    ],
                  ),
                const SizedBox(height: 12),
                AdminActionButton(
                  icon: Icons.open_in_new_rounded,
                  label: 'Open linked shared screen',
                  secondary: true,
                  onTap: () => Navigator.pushNamed(
                    context,
                    _tab == 'Booking Chat'
                        ? CoreRoutes.chat
                        : _tab == 'Payment Proofs & Ledger'
                            ? CoreRoutes.ledger
                            : CoreRoutes.contract,
                  ),
                ),
              ],
            ),
          ),
          right: AdminSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AdminSectionHeader(
                  title: 'Decision Panel',
                  icon: Icons.gavel_outlined,
                ),
                const SizedBox(height: 12),
                CoreTextField(
                  controller: _ruling,
                  label: 'Admin ruling text',
                  icon: Icons.gavel_outlined,
                  maxLines: 4,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _notify,
                  onChanged: (value) => setState(() => _notify = value),
                  title: const Text('Notify both parties'),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _decisionButton(context, 'Release payment'),
                    _decisionButton(context, 'Refund payer'),
                    _decisionButton(context, 'Partial refund'),
                    _decisionButton(context, 'Penalize party'),
                    _decisionButton(context, 'Request more evidence'),
                    _decisionButton(context, 'Close as resolved'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _decisionButton(BuildContext context, String label) {
    return AdminActionButton(
      icon: Icons.gavel_outlined,
      label: label,
      secondary: label != 'Close as resolved',
      onTap: () {
        if (_ruling.text.trim().isEmpty) {
          showCoreSnack(
              context, 'Write a ruling before recording a decision.');
          return;
        }
        showCoreSuccessDialog(
          context,
          title: 'Decision confirmed',
          message:
              '$label written to audit log with ruling: "${_ruling.text.trim()}". '
              'Refund/release ledger updates queued. Parties notified: $_notify.',
        );
      },
    );
  }
}
