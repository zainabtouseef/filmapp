import 'package:flutter/material.dart';

import '../../core_ui/core_routes.dart';
import '../../core_ui/mock_data/shared_mock_data.dart';
import '../../core_ui/models/shared_models.dart';
import '../../core_ui/widgets/core_widgets.dart';
import '../../theme/app_color_scheme.dart';
import '../../theme/app_text_styles.dart';

class PaymentProofUploadScreen extends StatefulWidget {
  const PaymentProofUploadScreen({super.key});

  @override
  State<PaymentProofUploadScreen> createState() =>
      _PaymentProofUploadScreenState();
}

class _PaymentProofUploadScreenState extends State<PaymentProofUploadScreen> {
  PaymentMilestone _milestone = SharedMockData.milestones.first;
  String _method = 'Bank Transfer';
  bool _uploaded = false;
  String _status = 'Not Paid';
  final _amount = TextEditingController(text: '72000');
  final _transaction = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _transaction.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _amountMismatch =>
      int.tryParse(_amount.text.trim()) != _milestone.amount;

  void _submit() {
    if (_transaction.text.trim().isEmpty || !_uploaded) {
      showCoreSnack(context, 'Transaction ID and proof upload are required');
      return;
    }
    setState(() => _status = 'Payment Under Verification');
    showCoreSuccessDialog(
      context,
      title: 'Payment proof submitted',
      message: 'Super Admin will verify it before the booking can close.',
      buttonLabel: 'View Ledger',
      onDone: () => Navigator.pushNamed(context, CoreRoutes.ledger),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CoreScreenScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CoreAppHeader(
            title: 'Payment Proof Upload',
            subtitle: 'Submit payer-side proof for admin verification.',
            icon: Icons.payments_outlined,
          ),
          const SizedBox(height: 18),
          _summary(context),
          const SizedBox(height: 18),
          CoreGlassCard(
            child: Column(
              children: [
                CoreDropdownField<PaymentMilestone>(
                  value: _milestone,
                  values: SharedMockData.milestones,
                  label: 'Milestone',
                  icon: Icons.flag_outlined,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _milestone = value;
                      _amount.text = value.amount.toString();
                    });
                  },
                ),
                const SizedBox(height: 14),
                CoreTextField(
                  controller: _amount,
                  label: 'Amount',
                  icon: Icons.money_rounded,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
                if (_amountMismatch) ...[
                  const SizedBox(height: 10),
                  const StatusBadge(
                    label: 'Amount mismatch: admin may request clarification.',
                    icon: Icons.warning_amber_rounded,
                    tone: CoreStatusTone.warning,
                  ),
                ],
                const SizedBox(height: 14),
                CoreDropdownField<String>(
                  value: _method,
                  values: const [
                    'Bank Transfer',
                    'Wallet',
                    'Gateway Reference'
                  ],
                  label: 'Payment method',
                  icon: Icons.account_balance_wallet_outlined,
                  onChanged: (value) =>
                      setState(() => _method = value ?? _method),
                ),
                const SizedBox(height: 14),
                CoreTextField(
                  controller: _transaction,
                  label: 'Transaction ID',
                  icon: Icons.receipt_long_outlined,
                ),
                const SizedBox(height: 14),
                UploadCard(
                  title: 'Proof upload',
                  subtitle: 'Attach image or PDF receipt',
                  uploaded: _uploaded,
                  onTap: () => setState(() => _uploaded = true),
                ),
                const SizedBox(height: 14),
                CoreTextField(
                  controller: _notes,
                  label: 'Notes',
                  icon: Icons.notes_outlined,
                  maxLines: 4,
                ),
                const SizedBox(height: 18),
                CorePrimaryButton(
                  icon: Icons.verified_outlined,
                  label: 'Submit Proof for Verification',
                  onTap: _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary(BuildContext context) {
    final colors = context.appColors;
    return CoreGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TVC Shoot — Lahore',
            style:
                AppTextStyles.sectionTitle.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const StatusBadge(label: 'BK-2048', tone: CoreStatusTone.info),
              const StatusBadge(
                  label: 'CC-CON-2026-0041', tone: CoreStatusTone.neutral),
              StatusBadge(
                  label: _status,
                  tone: _status == 'Not Paid'
                      ? CoreStatusTone.neutral
                      : CoreStatusTone.warning),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Payee: Ali Khan',
            style: AppTextStyles.body.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
