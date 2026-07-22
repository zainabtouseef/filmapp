import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../auth/auth_controller.dart';
import '../../core_ui/core_routes.dart';
import '../../core_ui/mock_data/shared_mock_data.dart';
import '../../core_ui/models/shared_models.dart';
import '../../core_ui/widgets/core_widgets.dart';
import '../../payments/payment_models.dart';
import '../../payments/payments_controller.dart';
import '../../theme/app_color_scheme.dart';
import '../../theme/app_text_styles.dart';
import '../../uploads/upload_repository.dart';

class PaymentProofUploadScreen extends StatefulWidget {
  final String? milestoneId;

  /// Called once the real submit gate (transaction ID + uploaded proof)
  /// passes — lets a caller sync its own booking/payment state without
  /// this shared screen depending on any portal-specific store.
  final VoidCallback? onSubmitted;

  /// Renders content only (no [CoreScreenScaffold]/backdrop/global
  /// controls) — use when embedding this screen inside a bottom sheet
  /// instead of navigating to it as a full page.
  final bool embedded;

  /// Shown as a close (X) action in the header when embedded.
  final VoidCallback? onClose;

  /// Replaces the default "View Ledger" action on the success dialog —
  /// use to pop back to a hosting sheet instead of navigating away.
  final VoidCallback? onDone;
  final String doneLabel;

  const PaymentProofUploadScreen({
    super.key,
    this.milestoneId,
    this.onSubmitted,
    this.embedded = false,
    this.onClose,
    this.onDone,
    this.doneLabel = 'View Ledger',
  });

  @override
  State<PaymentProofUploadScreen> createState() =>
      _PaymentProofUploadScreenState();
}

class _PaymentProofUploadScreenState extends State<PaymentProofUploadScreen> {
  PaymentMilestone _milestone = SharedMockData.milestones.first;
  PaymentMilestoneDto? _liveMilestone;
  List<PaymentMilestoneDto> _liveMilestones = const [];
  String _method = 'Bank Transfer';
  bool _uploaded = false;
  bool _submitting = false;
  String? _uploadedFileId;
  Future<List<PaymentScheduleDto>>? _schedulesFuture;
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final payments = PaymentsScope.maybeOf(context);
    if (payments != null) {
      _schedulesFuture ??= payments.schedules().then((schedules) {
        final milestones =
            schedules.expand((schedule) => schedule.milestones).toList();
        if (mounted && milestones.isNotEmpty) {
          final selected = widget.milestoneId == null
              ? milestones.first
              : milestones.firstWhere(
                  (item) => item.publicId == widget.milestoneId,
                  orElse: () => milestones.first,
                );
          setState(() {
            _liveMilestones = milestones;
            _liveMilestone = selected;
            _amount.text = '${selected.amountMinor ~/ 100}';
          });
        }
        return schedules;
      });
    }
  }

  bool get _amountMismatch =>
      int.tryParse(_amount.text.trim()) !=
      ((_liveMilestone?.amountMinor ?? (_milestone.amount * 100)) ~/ 100);

  Future<void> _pickProof() async {
    try {
      final auth = AuthScope.maybeOf(context);
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
        withData: true,
      );
      final file = picked?.files.single;
      final bytes = file?.bytes;
      if (file == null || bytes == null) return;
      if (auth == null) {
        setState(() => _uploaded = true);
        return;
      }
      final uploaded = await UploadRepository(auth.apiClient).uploadFile(
        purpose: 'payment_proof',
        file: PickedFileData(
          name: file.name,
          mimeType: _mimeFor(file.extension),
          bytes: bytes,
        ),
      );
      if (!mounted) return;
      setState(() {
        _uploaded = true;
        _uploadedFileId = uploaded.publicId;
      });
    } catch (error) {
      if (!mounted) return;
      showCoreSnack(context, '$error');
    }
  }

  Future<void> _submit() async {
    if (_transaction.text.trim().isEmpty) {
      showCoreSnack(context, 'Transaction ID is required');
      return;
    }
    final payments = PaymentsScope.maybeOf(context);
    final milestone = _liveMilestone;
    if (payments != null && milestone != null) {
      setState(() => _submitting = true);
      try {
        await payments.submitProof(
          milestoneId: milestone.publicId,
          claimedAmountMinor: (int.tryParse(_amount.text.trim()) ?? 0) * 100,
          method: _method == 'Card Sandbox' ? 'card_sandbox' : 'bank_transfer',
          idempotencyKey:
              'flutter-${milestone.publicId}-${DateTime.now().millisecondsSinceEpoch}',
          transactionReference: _transaction.text.trim(),
          fileId: _uploadedFileId,
        );
        if (!mounted) return;
        setState(() {
          _status = 'Payment Under Verification';
          _submitting = false;
        });
      } catch (error) {
        if (!mounted) return;
        setState(() => _submitting = false);
        showCoreSnack(context, '$error');
        return;
      }
    } else {
      if (!_uploaded) {
        showCoreSnack(context, 'Transaction ID and proof upload are required');
        return;
      }
      setState(() => _status = 'Payment Under Verification');
    }
    widget.onSubmitted?.call();
    showCoreSuccessDialog(
      context,
      title: 'Payment proof submitted',
      message: 'Super Admin will verify it before the booking can close.',
      buttonLabel: widget.doneLabel,
      onDone: widget.onDone ??
          () => Navigator.pushNamed(context, CoreRoutes.ledger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CoreAppHeader(
          title: 'Payment Proof Upload',
          subtitle: 'Submit payer-side proof for admin verification.',
          icon: Icons.payments_outlined,
          actions: widget.onClose == null
              ? const []
              : [
                  CoreIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Close',
                    onTap: widget.onClose!,
                  ),
                ],
        ),
        const SizedBox(height: 18),
        _summary(context),
        const SizedBox(height: 18),
        CoreGlassCard(
          child: Column(
            children: [
              if (_schedulesFuture != null)
                FutureBuilder<List<PaymentScheduleDto>>(
                  future: _schedulesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const InlineNotice(
                        message: 'Loading live payment schedule...',
                        icon: Icons.hourglass_top_rounded,
                        tone: CoreStatusTone.info,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              if (_schedulesFuture != null) const SizedBox(height: 10),
              if (_liveMilestones.isNotEmpty)
                CoreDropdownField<PaymentMilestoneDto>(
                  value: _liveMilestone ?? _liveMilestones.first,
                  values: _liveMilestones,
                  label: 'Milestone',
                  icon: Icons.flag_outlined,
                  labelBuilder: (value) =>
                      '${value.name} · ${value.amountLabel}',
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _liveMilestone = value;
                      _amount.text = '${value.amountMinor ~/ 100}';
                    });
                  },
                )
              else
                CoreDropdownField<PaymentMilestone>(
                  value: _milestone,
                  values: SharedMockData.milestones,
                  label: 'Milestone',
                  icon: Icons.flag_outlined,
                  labelBuilder: (value) =>
                      '${value.name} · PKR ${value.amount}',
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
                const InlineNotice(
                  message: 'Amount mismatch: admin may request clarification.',
                  icon: Icons.warning_amber_rounded,
                  tone: CoreStatusTone.warning,
                ),
              ],
              const SizedBox(height: 14),
              CoreDropdownField<String>(
                value: _method,
                values: const [
                  'Bank Transfer',
                  'Card Sandbox',
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
                subtitle: _uploadedFileId == null
                    ? 'Attach image or PDF receipt'
                    : 'Uploaded $_uploadedFileId',
                uploaded: _uploaded,
                onTap: _pickProof,
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
                loading: _submitting,
                onTap: _submit,
              ),
            ],
          ),
        ),
      ],
    );
    if (widget.embedded) return content;
    return CoreScreenScaffold(child: content);
  }

  Widget _summary(BuildContext context) {
    final colors = context.appColors;
    return CoreGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TVC Shoot — Lahore',
            style: AppTextStyles.cardTitle.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusBadge(
                  label: _liveMilestone?.publicId ?? 'BK-2048',
                  tone: CoreStatusTone.info),
              StatusBadge(
                  label: _liveMilestone?.status ?? 'CC-CON-2026-0041',
                  tone: CoreStatusTone.neutral),
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

  String _mimeFor(String? extension) {
    return switch ((extension ?? '').toLowerCase()) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
  }
}
