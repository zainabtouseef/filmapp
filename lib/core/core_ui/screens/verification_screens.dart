import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/auth_controller.dart';
import '../../auth/role_mapper.dart';
import '../../network/api_exception.dart';
import '../../theme/app_color_scheme.dart';
import '../../theme/app_text_styles.dart';
import '../../uploads/upload_repository.dart';
import '../../verification/verification_models.dart';
import '../core_routes.dart';
import '../mock_data/shared_mock_data.dart';
import '../models/shared_models.dart';
import '../widgets/core_widgets.dart';
import 'live_selfie_capture_screen.dart';

class KycVerificationScreen extends StatefulWidget {
  final String selectedRole;

  const KycVerificationScreen({super.key, required this.selectedRole});

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
  bool _submitting = false;
  String? _loadingUpload;
  String? _formError;
  final Map<String, double> _uploadProgress = {};
  final Map<String, String> _uploadStatus = {};
  UploadedFile? _frontFile;
  UploadedFile? _backFile;
  UploadedFile? _selfieFile;
  UploadedFile? _roleDocFile;
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

  Future<void> _uploadPickedFile({
    required String slot,
    required PickedFileData file,
  }) async {
    setState(() {
      _loadingUpload = slot;
      _formError = null;
      _uploadProgress[slot] = 0;
      _uploadStatus[slot] =
          'Preparing ${_friendlyFileSize(file.sizeBytes)} image upload...';
    });
    try {
      final uploadedFile = await AuthScope.of(context).uploadFile(
        purpose: 'kyc_document',
        file: file,
        onStatus: (status) {
          if (!mounted) return;
          setState(() => _uploadStatus[slot] = status);
        },
        onProgress: (sentBytes, totalBytes) {
          if (!mounted || totalBytes <= 0) return;
          final progress = sentBytes / totalBytes;
          final percent = (progress * 100).clamp(0, 100).round();
          setState(() {
            _uploadProgress[slot] = progress;
            _uploadStatus[slot] = sentBytes >= totalBytes
                ? 'Upload sent. Waiting for server confirmation...'
                : 'Uploading image... $percent%';
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _uploadProgress.remove(slot);
        _uploadStatus[slot] = 'Upload saved for admin review.';
        switch (slot) {
          case 'front':
            _frontFile = uploadedFile;
            _frontUploaded = true;
          case 'back':
            _backFile = uploadedFile;
            _backUploaded = true;
          case 'selfie':
            _selfieFile = uploadedFile;
            _selfieCaptured = true;
          case 'role':
            _roleDocFile = uploadedFile;
            _roleDocUploaded = true;
        }
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _uploadProgress.remove(slot);
        _uploadStatus[slot] = 'Upload failed.';
        _formError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _uploadProgress.remove(slot);
        _uploadStatus[slot] = 'Upload failed.';
        _formError =
            'Could not upload this image. Please retry with a smaller clear image.';
      });
    } finally {
      if (mounted) setState(() => _loadingUpload = null);
    }
  }

  Future<void> _pickDocumentForSlot(String slot) async {
    try {
      final isIdentitySide = slot == 'front' || slot == 'back';
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: isIdentitySide
            ? const ['jpg', 'jpeg', 'png', 'webp']
            : const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final picked = result.files.single;
      final bytes = picked.bytes;
      if (bytes == null || bytes.isEmpty) {
        setState(() => _formError = 'Could not read the selected file.');
        return;
      }
      await _uploadPickedFile(
        slot: slot,
        file: PickedFileData(
          name: picked.name,
          mimeType: _mimeTypeForName(picked.name),
          bytes: bytes,
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _formError = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _formError = 'Could not open the file picker.');
    }
  }

  Future<void> _captureSelfie() async {
    try {
      // A dedicated live camera view (no gallery/file picker affordance)
      // rather than `image_picker`'s ImageSource.camera — on desktop web
      // that falls back to a plain file picker, which would defeat the
      // point of a liveness selfie.
      final image = await Navigator.push<XFile>(
        context,
        MaterialPageRoute(builder: (_) => const LiveSelfieCaptureScreen()),
      );
      if (image == null) return;
      if (!mounted) return;
      final bytes = await image.readAsBytes();
      if (bytes.isEmpty) {
        setState(() => _formError = 'Could not read the captured selfie.');
        return;
      }
      await _uploadPickedFile(
        slot: 'selfie',
        file: PickedFileData(
          name: image.name.isEmpty ? 'selfie-liveness.jpg' : image.name,
          mimeType: image.mimeType ?? _mimeTypeForName(image.name),
          bytes: bytes,
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _formError = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _formError = 'Could not open the camera.');
    }
  }

  Future<void> _next() async {
    setState(() => _formError = null);
    if (_step == 0 &&
        (_frontFile == null ||
            _backFile == null ||
            _documentNumber.text.trim().isEmpty)) {
      final missing = <String>[
        if (_frontFile == null) 'CNIC/passport front image',
        if (_backFile == null) 'CNIC/passport back image',
        if (_documentNumber.text.trim().isEmpty) 'document number',
      ];
      setState(() => _formError = 'Missing: ${missing.join(', ')}.');
      return;
    }
    if (_step == 1 && _selfieFile == null) {
      setState(() => _formError = 'Capture a selfie before continuing.');
      return;
    }
    if (_step == 2 && _roleDocFile == null) {
      setState(() => _formError = 'Upload at least one role proof document.');
      return;
    }
    if (_step < 3) {
      setState(() => _step++);
      return;
    }
    if (!_ownsAccount) {
      setState(
          () => _formError = 'Confirm the payment account belongs to you.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await AuthScope.of(context).createAndSubmitKyc(
        roleCode: RoleMapper.codeForLabel(widget.selectedRole),
        documents: [
          KycDocumentDraft(
            documentType: 'national_id_front',
            fileId: _frontFile?.publicId,
          ),
          KycDocumentDraft(
            documentType: 'national_id_back',
            fileId: _backFile?.publicId,
          ),
          KycDocumentDraft(
            documentType: 'selfie_liveness',
            fileId: _selfieFile?.publicId,
          ),
          KycDocumentDraft(
            documentType: 'role_proof',
            fileId: _roleDocFile?.publicId,
          ),
        ],
      );
      if (!mounted) return;
      showCoreSuccessDialog(
        context,
        title: 'Submitted for Verification',
        message:
            'Your KYC submission has been sent to CineConnect Admin review.',
        buttonLabel: 'View Status',
        onDone: () =>
            Navigator.pushNamed(context, CoreRoutes.verificationStatus),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _formError = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // The account already exists at this point (registration creates the
  // session before KYC starts) — skipping just defers verification rather
  // than blocking account creation on it. `KycStatusBanner` keeps nudging
  // the user afterward, and actions that require a verified account (like
  // sending a booking request) are gated separately at the point of use.
  void _skipForNow() {
    final auth = AuthScope.of(context);
    Navigator.pushReplacementNamed(context, auth.initialAuthenticatedRoute);
  }

  @override
  Widget build(BuildContext context) {
    return CoreScreenScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CoreAppHeader(
            title: 'Complete Verification',
            subtitle:
                'CineConnect verifies users to keep bookings, contracts and payments safe.',
            icon: Icons.verified_user_outlined,
            actions: [
              TextButton(
                onPressed: _skipForNow,
                child: const Text('Skip for now'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          StepWizardIndicator(currentStep: _step, totalSteps: 4),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _stepBody(context),
          ),
          if (_formError != null) ...[
            const SizedBox(height: 12),
            InlineNotice(
              message: _formError!,
              icon: Icons.info_outline_rounded,
              tone: CoreStatusTone.warning,
            ),
          ],
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
                  loading: _submitting,
                  onTap: _submitting ? null : _next,
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
            subtitle: _uploadSubtitle(
              slot: 'front',
              idle: 'Upload a clear front-side image',
              file: _frontFile,
            ),
            uploaded: _frontUploaded,
            loading: _loadingUpload == 'front',
            progress: _uploadProgress['front'],
            onTap: _loadingUpload == null
                ? () => _pickDocumentForSlot('front')
                : null,
          ),
          const SizedBox(height: 12),
          UploadCard(
            title: 'CNIC/passport back',
            subtitle: _uploadSubtitle(
              slot: 'back',
              idle: 'Upload a clear back-side image',
              file: _backFile,
            ),
            uploaded: _backUploaded,
            loading: _loadingUpload == 'back',
            progress: _uploadProgress['back'],
            onTap: _loadingUpload == null
                ? () => _pickDocumentForSlot('back')
                : null,
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
                color: _selfieCaptured ? colors.success : colors.border,
              ),
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
                      color:
                          _selfieCaptured ? colors.success : colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CorePrimaryButton(
            icon: Icons.camera_alt_outlined,
            label: _selfieFile == null ? 'Capture Selfie' : 'Selfie Saved',
            loading: _loadingUpload == 'selfie',
            onTap: _loadingUpload == null ? _captureSelfie : null,
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
                subtitle: _uploadSubtitle(
                  slot: 'role',
                  idle: 'Attach PDF, image or portfolio link proof',
                  file: _roleDocFile,
                ),
                uploaded: _roleDocUploaded,
                loading: _loadingUpload == 'role',
                progress: _uploadProgress['role'],
                onTap: _loadingUpload == null
                    ? () => _pickDocumentForSlot('role')
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _uploadSubtitle({
    required String slot,
    required String idle,
    required UploadedFile? file,
  }) {
    if (_loadingUpload == slot) {
      return _uploadStatus[slot] ?? 'Uploading image...';
    }
    if (file == null) return idle;
    return 'Saved: ${file.originalName} · ${file.scanStatus}';
  }

  String _friendlyFileSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).round()} KB';
    return '$bytes bytes';
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
              style: AppTextStyles.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _mimeTypeForName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.pdf')) return 'application/pdf';
  return 'application/octet-stream';
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
  late Future<List<KycSubmission>> _submissionsFuture;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _submissionsFuture =
          AuthScope.of(context).myKycSubmissionsAndRefreshStatus();
      _loaded = true;
    }
  }

  void _refresh() {
    setState(() {
      _submissionsFuture =
          AuthScope.of(context).myKycSubmissionsAndRefreshStatus();
    });
  }

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
          FutureBuilder<List<KycSubmission>>(
            future: _submissionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const CoreGlassCard(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return CoreGlassCard(
                  child: Column(
                    children: [
                      const CoreEmptyState(
                        icon: Icons.cloud_off_outlined,
                        title: 'Could not load verification status',
                        message: 'Check your connection and try again.',
                      ),
                      const SizedBox(height: 12),
                      CoreSecondaryButton(
                        icon: Icons.refresh_rounded,
                        label: 'Retry',
                        onTap: _refresh,
                      ),
                    ],
                  ),
                );
              }
              final submissions = snapshot.data ?? const <KycSubmission>[];
              if (submissions.isEmpty) {
                return CoreGlassCard(
                  child: Column(
                    children: [
                      const CoreEmptyState(
                        icon: Icons.fact_check_outlined,
                        title: 'No verification submitted yet',
                        message:
                            'Complete KYC to unlock full booking, contract and payment access.',
                      ),
                      const SizedBox(height: 12),
                      CorePrimaryButton(
                        icon: Icons.upload_file_outlined,
                        label: 'Start Verification',
                        onTap: () =>
                            Navigator.pushNamed(context, CoreRoutes.kyc),
                      ),
                    ],
                  ),
                );
              }
              return _statusCard(context, submissions.first);
            },
          ),
        ],
      ),
    );
  }

  VerificationStatus _statusFor(String value) {
    return switch (value) {
      'approved' => VerificationStatus.approved,
      'needs_resubmission' ||
      'rejected' =>
        VerificationStatus.needsResubmission,
      _ => VerificationStatus.pending,
    };
  }

  Widget _statusCard(BuildContext context, KycSubmission submission) {
    final colors = context.appColors;
    final status = _statusFor(submission.status);
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
            style: AppTextStyles.sectionTitle.copyWith(
              color: colors.textPrimary,
              fontSize: 19,
            ),
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
          if (submission.decisionReason != null) ...[
            const SizedBox(height: 12),
            InlineNotice(
              message: submission.decisionReason!,
              icon: Icons.info_outline_rounded,
              tone: CoreStatusTone.warning,
            ),
          ],
          if (submission.files.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '${submission.files.length} verification file(s) attached · scan pending',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 22),
          if (status == VerificationStatus.pending) ...[
            // Opens the user's real portal, not a generic marketplace
            // preview — the KycStatusBanner + ensureKycApproved() guard
            // keep booking/contract actions locked until this is approved,
            // so it's safe to let them look around their own account.
            CorePrimaryButton(
              icon: Icons.dashboard_outlined,
              label: 'Open My Account',
              onTap: () => Navigator.pushNamed(
                context,
                AuthScope.of(context).initialAuthenticatedRoute,
              ),
            ),
            const SizedBox(height: 12),
            CoreSecondaryButton(
              icon: Icons.refresh_rounded,
              label: 'Check Status',
              onTap: _refresh,
            ),
          ] else if (status == VerificationStatus.needsResubmission)
            CorePrimaryButton(
              icon: Icons.upload_file_outlined,
              label: 'Resubmit Documents',
              onTap: () => Navigator.pushNamed(context, CoreRoutes.kyc),
            )
          else
            CorePrimaryButton(
              icon: Icons.dashboard_outlined,
              label: 'Go to My Dashboard',
              onTap: () => Navigator.pushNamed(
                context,
                AuthScope.of(context).initialAuthenticatedRoute,
              ),
            ),
        ],
      ),
    );
  }
}
