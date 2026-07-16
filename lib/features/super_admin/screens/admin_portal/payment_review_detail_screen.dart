part of '../super_admin_screens.dart';

class PaymentReviewDetailScreen extends StatefulWidget {
  const PaymentReviewDetailScreen({super.key});

  @override
  State<PaymentReviewDetailScreen> createState() =>
      _PaymentReviewDetailScreenState();
}

class _PaymentReviewDetailScreenState extends State<PaymentReviewDetailScreen> {
  String _status = 'Pending Review';

  @override
  Widget build(BuildContext context) {
    return _TwoPane(
      leftFlex: 5,
      rightFlex: 4,
      left: AdminSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionHeader(
              title: 'Proof Viewer',
              icon: Icons.receipt_long_outlined,
            ),
            const SizedBox(height: 12),
            const AdminProofViewer(
              title: 'Bank transfer proof preview',
              ocrLines: [
                'Transaction ID: HBL-884120',
                'Amount: PKR 90,000',
                'Date: Jul 8, 2026',
                'Sender: Hamza Productions',
                'Receiver: Ali Khan',
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _tinyAction(context, 'Zoom',
                    () => showCoreSnack(context, 'Zoom simulated')),
                _tinyAction(context, 'Rotate',
                    () => showCoreSnack(context, 'Proof rotated')),
                _tinyAction(context, 'Download',
                    () => showCoreSnack(context, 'Proof download simulated')),
              ],
            ),
          ],
        ),
      ),
      right: AdminSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CASE DETAILS', style: AppTextStyles.panelLabel),
            const SizedBox(height: 10),
            _reviewCard(context, 'Booking Summary', [
              'BK-2048',
              'TVC Shoot - Lahore',
              'Actor',
              'Payment Under Verification',
              'Hamza / Ali Khan'
            ]),
            _reviewDivider(context),
            _reviewCard(context, 'Contract Payment Schedule', [
              'Deposit',
              'Expected PKR 90,000',
              'Due Jul 8',
              'Payee Ali Khan',
              'Bank transfer allowed'
            ]),
            _reviewDivider(context),
            _reviewCard(context, 'Uploaded Claim', [
              'Claimed PKR 90,000',
              'HBL-884120',
              'Uploaded by Hamza',
              '5h ago',
              'No notes'
            ]),
            _reviewDivider(context),
            _reviewCard(context, 'Bank Details on File', [
              'Payer HBL ****4821',
              'Payee Meezan ****9921',
              'Account title match passed'
            ]),
            const SizedBox(height: 12),
            AdminStatusBadge(
                label: _status,
                tone: switch (_status) {
                  'Verified' => AdminDecisionTone.success,
                  'Rejected' || 'Suspicious' => AdminDecisionTone.danger,
                  _ => AdminDecisionTone.warning,
                }),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                AdminActionButton(
                    icon: Icons.verified_outlined,
                    label: 'Verify Payment',
                    onTap: () {
                      setState(() => _status = 'Verified');
                      showCoreSuccessDialog(
                        context,
                        title: 'Payment verified',
                        message:
                            'Receipts generated for producer, payee and company.',
                        onDone: () {
                          showCoreSnack(context,
                              'Receipt, ledger and audit log written.');
                        },
                      );
                    }),
                AdminActionButton(
                    icon: Icons.cancel_outlined,
                    label: 'Reject with Reason',
                    secondary: true,
                    onTap: () => _noteDialog(
                          context,
                          'Payment rejection reason',
                          onSave: () => setState(() => _status = 'Rejected'),
                        )),
                AdminActionButton(
                    icon: Icons.contact_support_outlined,
                    label: 'Ask Clarification',
                    secondary: true,
                    onTap: () {
                      setState(() => _status = 'Clarification Requested');
                      _noteDialog(context, 'Clarification message');
                    }),
                AdminActionButton(
                    icon: Icons.warning_amber_rounded,
                    label: 'Mark Suspicious',
                    secondary: true,
                    onTap: () => setState(() => _status = 'Suspicious')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
