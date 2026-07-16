import 'package:flutter/material.dart';

import '../../theme/app_color_scheme.dart';
import '../../theme/app_text_styles.dart';
import '../core_routes.dart';
import '../mock_data/shared_mock_data.dart';
import '../models/shared_models.dart';
import '../widgets/core_widgets.dart';

class KycVerificationScreen extends StatefulWidget {
  final String selectedRole;

  const KycVerificationScreen({
    super.key,
    required this.selectedRole,
  });

  @override
  State<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends State<KycVerificationScreen> {
  int _step = 0;
  bool _frontUploaded = false;
  bool _backUploaded = false;
  bool _selfieCaptured = false;
  bool _roleDocUploaded = false;
  bool _ownsAccount = false;
  final _documentNumber = TextEditingController();
  final _expiry = TextEditingController();
  final _accountTitle = TextEditingController();
  final _bankName = TextEditingController(text: 'HBL');
  final _iban = TextEditingController();
  final _receivingName = TextEditingController();

  @override
  void dispose() {
    _documentNumber.dispose();
    _expiry.dispose();
    _accountTitle.dispose();
    _bankName.dispose();
    _iban.dispose();
    _receivingName.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 3) {
      setState(() => _step++);
      return;
    }
    showCoreSuccessDialog(
      context,
      title: 'Submitted for Verification',
      message: 'Your KYC submission has been sent to CineConnect Admin review.',
      buttonLabel: 'View Status',
      onDone: () => Navigator.pushNamed(
        context,
        CoreRoutes.verificationStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CoreScreenScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CoreAppHeader(
            title: 'Complete Verification',
            subtitle:
                'CineConnect verifies users to keep bookings, contracts and payments safe.',
            icon: Icons.verified_user_outlined,
          ),
          const SizedBox(height: 20),
          StepWizardIndicator(currentStep: _step, totalSteps: 4),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _stepBody(context),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (_step > 0) ...[
                Expanded(
                  child: CoreSecondaryButton(
                    icon: Icons.arrow_back_rounded,
                    label: 'Back',
                    onTap: () => setState(() => _step--),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: CorePrimaryButton(
                  icon: _step == 3
                      ? Icons.outbox_outlined
                      : Icons.arrow_forward_rounded,
                  label: _step == 3 ? 'Submit for Verification' : 'Continue',
                  onTap: _next,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepBody(BuildContext context) {
    return switch (_step) {
      0 => _identityStep(),
      1 => _selfieStep(context),
      2 => _roleDocumentsStep(),
      _ => _bankStep(context),
    };
  }

  Widget _identityStep() {
    return CoreGlassCard(
      key: const ValueKey('identity'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(text: 'Identity Document'),
          const SizedBox(height: 14),
          UploadCard(
            title: 'CNIC/passport front',
            subtitle: 'Upload a clear front-side image',
            uploaded: _frontUploaded,
            onTap: () => setState(() => _frontUploaded = true),
          ),
          const SizedBox(height: 12),
          UploadCard(
            title: 'CNIC/passport back',
            subtitle: 'Upload a clear back-side image',
            uploaded: _backUploaded,
            onTap: () => setState(() => _backUploaded = true),
          ),
          const SizedBox(height: 14),
          CoreTextField(
            controller: _documentNumber,
            label: 'Document number',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 14),
          CoreTextField(
            controller: _expiry,
            label: 'Expiry date optional',
            icon: Icons.event_outlined,
          ),
        ],
      ),
    );
  }

  Widget _selfieStep(BuildContext context) {
    final colors = context.appColors;
    return CoreGlassCard(
      key: const ValueKey('selfie'),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: _selfieCaptured ? colors.success : colors.border),
              color: colors.surface.withValues(alpha: 0.42),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (_selfieCaptured ? colors.success : colors.goldMid)
                        .withValues(alpha: 0.13),
                  ),
                  child: Icon(
                    _selfieCaptured
                        ? Icons.face_retouching_natural
                        : Icons.face_outlined,
                    color: _selfieCaptured ? colors.success : colors.goldMid,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selfieCaptured
                        ? 'Selfie captured'
                        : 'Selfie / liveness capture',
                    style: AppTextStyles.label.copyWith(
                      color: _selfieCaptured
                          ? colors.success
                          : colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CorePrimaryButton(
            icon: Icons.camera_alt_outlined,
            label: 'Capture Selfie',
            onTap: () => setState(() => _selfieCaptured = true),
          ),
        ],
      ),
    );
  }

  Widget _roleDocumentsStep() {
    final documents = SharedMockData.roleDocuments(widget.selectedRole);
    return CoreGlassCard(
      key: const ValueKey('role-docs'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(text: '${widget.selectedRole} Documents'),
          const SizedBox(height: 10),
          ...documents.map(
            (doc) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: UploadCard(
                title: doc,
                subtitle: 'Attach PDF, image or portfolio link proof',
                uploaded: _roleDocUploaded,
                onTap: () => setState(() => _roleDocUploaded = true),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bankStep(BuildContext context) {
    final colors = context.appColors;
    return CoreGlassCard(
      key: const ValueKey('bank'),
      child: Column(
        children: [
          CoreTextField(
            controller: _accountTitle,
            label: 'Account title',
            icon: Icons.account_balance_outlined,
          ),
          const SizedBox(height: 14),
          CoreTextField(
            controller: _bankName,
            label: 'Bank/wallet name',
            icon: Icons.wallet_outlined,
          ),
          const SizedBox(height: 14),
          CoreTextField(
            controller: _iban,
            label: 'IBAN/account number',
            icon: Icons.numbers_outlined,
          ),
          const SizedBox(height: 14),
          CoreTextField(
            controller: _receivingName,
            label: 'Payment receiving name',
            icon: Icons.person_pin_outlined,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _ownsAccount,
            activeColor: colors.goldMid,
            onChanged: (value) => setState(() => _ownsAccount = value ?? false),
            title: Text(
              'I confirm this account belongs to me',
              style:
                  AppTextStyles.caption.copyWith(color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

String _statusLabel(VerificationStatus status) {
  return switch (status) {
    VerificationStatus.pending => 'Pending',
    VerificationStatus.needsResubmission => 'Needs Resubmission',
    VerificationStatus.approved => 'Approved',
  };
}

class VerificationStatusScreen extends StatefulWidget {
  const VerificationStatusScreen({super.key});

  @override
  State<VerificationStatusScreen> createState() =>
      _VerificationStatusScreenState();
}

class _VerificationStatusScreenState extends State<VerificationStatusScreen> {
  VerificationStatus status = VerificationStatus.pending;

  @override
  Widget build(BuildContext context) {
    return CoreScreenScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CoreAppHeader(
            title: 'Verification Status',
            subtitle: 'Track your admin review state and next actions.',
            icon: Icons.fact_check_outlined,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              CoreChip(
                label: 'Pending',
                selected: status == VerificationStatus.pending,
                onTap: () =>
                    setState(() => status = VerificationStatus.pending),
              ),
              CoreChip(
                label: 'Needs Resubmission',
                selected: status == VerificationStatus.needsResubmission,
                onTap: () => setState(
                    () => status = VerificationStatus.needsResubmission),
              ),
              CoreChip(
                label: 'Approved',
                selected: status == VerificationStatus.approved,
                onTap: () =>
                    setState(() => status = VerificationStatus.approved),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _statusCard(context),
        ],
      ),
    );
  }

  Widget _statusCard(BuildContext context) {
    final colors = context.appColors;
    final data = switch (status) {
      VerificationStatus.pending => (
          Icons.hourglass_top_rounded,
          'Verification Under Review',
          'Our team is reviewing your documents. You will be notified once approved.',
          CoreStatusTone.warning,
        ),
      VerificationStatus.needsResubmission => (
          Icons.error_outline_rounded,
          'Resubmission Required',
          'CNIC image is unclear. Please upload a clearer front-side image.',
          CoreStatusTone.danger,
        ),
      VerificationStatus.approved => (
          Icons.verified_outlined,
          'Verification Approved',
          'Your CineConnect profile is verified and ready for full marketplace access.',
          CoreStatusTone.success,
        ),
    };

    return CoreGlassCard(
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.goldMid.withValues(alpha: 0.12),
            ),
            child: Icon(data.$1, color: colors.goldMid, size: 44),
          ),
          const SizedBox(height: 18),
          StatusBadge(label: _statusLabel(status), tone: data.$4),
          const SizedBox(height: 14),
          Text(
            data.$2,
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionTitle
                .copyWith(color: colors.textPrimary, fontSize: 19),
          ),
          const SizedBox(height: 10),
          Text(
            data.$3,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted.copyWith(
              color: colors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          if (status == VerificationStatus.pending) ...[
            CorePrimaryButton(
              icon: Icons.storefront_outlined,
              label: 'Browse Preview Marketplace',
              onTap: () => Navigator.pushNamed(context, CoreRoutes.dashboard),
            ),
            const SizedBox(height: 12),
            CoreSecondaryButton(
              icon: Icons.refresh_rounded,
              label: 'Check Status',
              onTap: () => showCoreSnack(context, 'Still pending admin review'),
            ),
          ] else if (status == VerificationStatus.needsResubmission)
            CorePrimaryButton(
              icon: Icons.upload_file_outlined,
              label: 'Resubmit Documents',
              onTap: () => Navigator.pushNamed(context, CoreRoutes.kyc),
            )
          else
            CorePrimaryButton(
              icon: Icons.person_outline_rounded,
              label: 'Continue to Profile Setup',
              onTap: () => Navigator.pushNamed(context, CoreRoutes.dashboard),
            ),
        ],
      ),
    );
  }
}
