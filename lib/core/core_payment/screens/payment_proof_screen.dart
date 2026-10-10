import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../auth/auth_controller.dart';
import '../../core_ui/core_routes.dart';
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
  PaymentMilestoneDto? _liveMilestone;
  PaymentScheduleDto? _liveSchedule;
  List<PaymentScheduleDto> _liveSchedules = const [];
  List<PaymentMilestoneDto> _liveMilestones = const [];
  String _method = 'Bank Transfer';
  bool _uploaded = false;
  bool _submitting = false;
  String? _uploadedFileId;
  Future<List<PaymentScheduleDto>>? _schedulesFuture;
  String? _schedulesError;
  String _status = 'Not Paid';
  final _amount = TextEditingController();
  final _transaction = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _transaction.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final payments = PaymentsScope.maybeOf(context);
    if (payments != null) {
      _schedulesFuture ??= _loadSchedules(payments);
    } else if (_schedulesFuture == null && _schedulesError == null) {
      _schedulesError = 'Sign in to load a live payment schedule.';
    }
  }

  Future<List<PaymentScheduleDto>> _loadSchedules(
    PaymentsController payments,
  ) async {
    try {
      final schedules = await payments.schedules();
      final milestones =
          schedules.expand((schedule) => schedule.milestones).toList();
      if (!mounted) return schedules;
      if (milestones.isEmpty) {
        setState(() {
          _liveSchedules = schedules;
          _liveMilestones = const [];
          _liveMilestone = null;
          _liveSchedule = null;
          _schedulesError = 'No payable milestones are available.';
        });
        return schedules;
      }
      final requestedId = widget.milestoneId?.trim();
      PaymentMilestoneDto? requested;
      if (requestedId != null && requestedId.isNotEmpty) {
        for (final item in milestones) {
          if (item.publicId == requestedId) {
            requested = item;
            break;
          }
        }
      }
      if (requestedId != null && requestedId.isNotEmpty && requested == null) {
        setState(() {
          _liveSchedules = schedules;
          _liveMilestones = const [];
          _liveMilestone = null;
          _liveSchedule = null;
          _schedulesError = 'The requested payment milestone was not found.';
        });
        return schedules;
      }
      final selected = requested ?? milestones.first;
      setState(() {
        _liveSchedules = schedules;
        _liveMilestones = milestones;
        _liveMilestone = selected;
        _liveSchedule = _scheduleFor(schedules, selected.publicId);
        _schedulesError = null;
        _status = selected.status.replaceAll('_', ' ');
        _amount.text = '${selected.amountMinor ~/ 100}';
      });
      return schedules;
    } catch (_) {
      if (mounted) {
        setState(() {
          _liveMilestones = const [];
          _liveSchedules = const [];
          _liveMilestone = null;
          _liveSchedule = null;
          _schedulesError =
              'Payment details could not be loaded. Retry from the booking.';
        });
      }
      return const [];
    }
  }

  PaymentScheduleDto? _scheduleFor(
    List<PaymentScheduleDto> schedules,
    String milestoneId,
  ) {
    for (final schedule in schedules) {
      if (schedule.milestones.any((item) => item.publicId == milestoneId)) {
        return schedule;
      }
    }
    return null;
  }

  bool get _amountMismatch {
    final milestone = _liveMilestone;
    if (milestone == null) return false;
    return int.tryParse(_amount.text.trim()) != milestone.amountMinor ~/ 100;
  }

  Future<void> _pickProof() async {
    if (_liveMilestone == null) {
      showCoreSnack(context, 'Choose a live milestone before uploading proof.');
      return;
    }
    try {
      final auth = AuthScope.maybeOf(context);
      if (auth == null || !auth.isAuthenticated) {
        showCoreSnack(context, 'Sign in to upload payment proof.');
        return;
      }
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
        withData: true,
      );
      final file = picked?.files.single;
      final bytes = file?.bytes;
      if (file == null || bytes == null) return;
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
          method: 'bank_transfer',
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
      showCoreSnack(context,
          'Payment details are unavailable. Reload the booking before submitting proof.');
      return;
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
              if (_schedulesFuture != null || _schedulesError != null)
                const SizedBox(height: 10),
              if (_schedulesError != null) ...[
                InlineNotice(
                  message: _schedulesError!,
                  icon: Icons.info_outline_rounded,
                  tone: CoreStatusTone.warning,
                ),
                const SizedBox(height: 14),
              ],
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
                      _liveSchedule = _scheduleFor(
                        _liveSchedules,
                        value.publicId,
                      );
                      _status = value.status.replaceAll('_', ' ');
                      _amount.text = '${value.amountMinor ~/ 100}';
                    });
                  },
                )
              else
                const CoreEmptyState(
                  icon: Icons.flag_outlined,
                  title: 'No live milestone selected',
                  message:
                      'Open payment proof from a booking with an active payment schedule.',
                ),
              const SizedBox(height: 14),
              CoreTextField(
                controller: _amount,
                label: 'Amount',
                icon: Icons.money_rounded,
                keyboardType: TextInputType.number,
                enabled: _liveMilestone != null,
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
                onTap: _liveMilestone == null ? null : _pickProof,
              ),
              const SizedBox(height: 18),
              CorePrimaryButton(
                icon: Icons.verified_outlined,
                label: 'Submit Proof for Verification',
                loading: _submitting,
                onTap: _liveMilestone == null ? null : _submit,
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
    final milestone = _liveMilestone;
    final schedule = _liveSchedule;
    return CoreGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            milestone?.name ?? 'Payment schedule required',
            style: AppTextStyles.cardTitle.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusBadge(
                  label: milestone?.publicId ?? 'No milestone',
                  tone: CoreStatusTone.info),
              StatusBadge(
                  label: schedule?.bookingId ?? 'No booking',
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
            schedule == null
                ? 'Open this screen from a live booking or payment record.'
                : 'Booking ${schedule.bookingId}${schedule.contractId == null ? '' : ' · Contract ${schedule.contractId}'}',
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
