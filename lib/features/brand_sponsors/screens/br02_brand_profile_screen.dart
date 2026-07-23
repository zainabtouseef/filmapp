import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/uploads/upload_repository.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/brand_sponsor_demo_data.dart';
import '../models/brand_sponsor_models.dart';
import '../widgets/brand_sponsor_components.dart';
import '../widgets/brand_sponsor_live.dart';

class BR02BrandProfileScreen extends StatefulWidget {
  const BR02BrandProfileScreen({super.key});

  @override
  State<BR02BrandProfileScreen> createState() => _BR02BrandProfileScreenState();
}

class _BR02BrandProfileScreenState extends State<BR02BrandProfileScreen> {
  final _name = TextEditingController();
  final _category = TextEditingController();
  final _representative = TextEditingController();
  final _description = TextEditingController();
  final _billingDetails = TextEditingController();

  SpecialistController? _specialist;
  BrandProfileDto? _profile;
  String? _logoFileId;
  String? _logoFileName;
  String _logoUrl = '';
  bool _loaded = false;
  bool _loading = false;
  bool _saving = false;
  bool _uploading = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final specialist = SpecialistScope.maybeOf(context);
    if (specialist == null || identical(specialist, _specialist)) return;
    _specialist = specialist;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _specialist!.brandProfile(force: true);
      if (profile != null) _applyProfile(profile);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loaded = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = brandApiMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyProfile(BrandProfileDto profile) {
    _name.text = profile.name;
    _category.text = profile.category ?? '';
    _representative.text = profile.representative ?? '';
    _description.text = profile.description ?? '';
    _logoUrl = profile.logoUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _representative.dispose();
    _description.dispose();
    _billingDetails.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_specialist == null && !_loaded) _seedPreview();
    if (_loading && !_loaded) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_error != null && !_loaded) {
      return CoreEmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Profile unavailable',
        message: _error!,
        actionLabel: 'Try again',
        onAction: _load,
      );
    }
    final colors = context.appColors;
    return BrandTwoColumn(
      left: BrandSectionCard(
        title: _profile == null ? 'Create brand identity' : 'Brand identity',
        icon: Icons.business_center_outlined,
        selected: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BrandMediaFrame(
              imageUrl: _logoUrl,
              title: _name.text.trim().isEmpty ? 'Brand name' : _name.text,
              badge: _category.text.trim().isEmpty
                  ? 'Organization category'
                  : _category.text,
              fallbackIcon: Icons.campaign_outlined,
              aspectRatio: 16 / 8.5,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                BrandLiveStatusChip(
                  status: _profile?.trustStatus ?? 'profile_required',
                ),
                if (_logoFileName != null)
                  StatusChip(
                    label: 'NEW LOGO',
                    icon: Icons.image_outlined,
                    color: colors.infoBlue,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            CoreTextField(
              controller: _name,
              label: 'Legal or trading name',
              icon: Icons.business_outlined,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            CoreTextField(
              controller: _category,
              label: 'Industry category',
              icon: Icons.category_outlined,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            CoreTextField(
              controller: _representative,
              label: 'Authorized representative',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 10),
            CoreTextField(
              controller: _description,
              label: 'Organization and sponsorship description',
              icon: Icons.notes_outlined,
              maxLines: 4,
            ),
            const SizedBox(height: 10),
            UploadCard(
              title: _uploading ? 'Uploading logo...' : 'Brand logo',
              subtitle: _logoFileName ??
                  (_logoUrl.isEmpty
                      ? 'Upload a square PNG, JPG or WebP'
                      : 'Current logo is connected'),
              uploaded: _logoFileName != null || _logoUrl.isNotEmpty,
              onTap: _uploading ? null : _pickLogo,
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              InlineNotice(
                message: _error!,
                icon: Icons.error_outline_rounded,
                tone: CoreStatusTone.danger,
              ),
            ],
            const SizedBox(height: 14),
            CorePrimaryButton(
              icon: Icons.save_outlined,
              label: _saving ? 'Saving...' : 'Save brand profile',
              onTap: _saving ? null : _save,
            ),
          ],
        ),
      ),
      right: Column(
        children: [
          BrandSectionCard(
            title: 'Organization trust',
            icon: Icons.verified_user_outlined,
            tone: BrandTone.green,
            child: Column(
              children: [
                BrandInfoRow(
                  icon: Icons.verified_outlined,
                  label: 'KYB status',
                  value: readableBrandStatus(
                    _profile?.trustStatus ?? 'not_started',
                  ),
                ),
                BrandInfoRow(
                  icon: Icons.account_circle_outlined,
                  label: 'Representative',
                  value: _representative.text.trim().isEmpty
                      ? 'Not set'
                      : _representative.text,
                ),
                BrandInfoRow(
                  icon: Icons.image_outlined,
                  label: 'Logo',
                  value: _logoUrl.isEmpty && _logoFileId == null
                      ? 'Missing'
                      : 'Connected',
                ),
                const SizedBox(height: 10),
                CoreSecondaryButton(
                  icon: Icons.verified_user_outlined,
                  label: 'Open verification',
                  compact: true,
                  onTap: () => Navigator.pushNamed(
                    context,
                    CoreRoutes.kyc,
                    arguments: 'Brand / Sponsor',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          BrandSectionCard(
            title: 'Billing identity',
            icon: Icons.receipt_long_outlined,
            tone: BrandTone.blue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Billing details are tokenized by the backend and are not returned to the portal after saving.',
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: _billingDetails,
                  label: 'Replace billing details (optional)',
                  icon: Icons.lock_outline_rounded,
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                InlineNotice(
                  message:
                      'Use organization billing details only. Campaign payments remain in the payment schedule and ledger.',
                  icon: Icons.security_outlined,
                  tone: CoreStatusTone.info,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          BrandSectionCard(
            title: 'Profile readiness',
            icon: Icons.checklist_outlined,
            tone: BrandTone.purple,
            child: Column(
              children: [
                _ReadinessRow(
                  label: 'Organization name',
                  complete: _name.text.trim().length >= 2,
                ),
                _ReadinessRow(
                  label: 'Industry category',
                  complete: _category.text.trim().isNotEmpty,
                ),
                _ReadinessRow(
                  label: 'Representative',
                  complete: _representative.text.trim().isNotEmpty,
                ),
                _ReadinessRow(
                  label: 'Sponsorship description',
                  complete: _description.text.trim().length >= 20,
                ),
                _ReadinessRow(
                  label: 'Brand logo',
                  complete: _logoUrl.isNotEmpty || _logoFileId != null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickLogo() async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null) {
      brandSnack(context, 'Sign in to upload a brand logo');
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    if (file == null || file.bytes == null) return;
    setState(() => _uploading = true);
    try {
      final uploaded = await auth.uploadFile(
        purpose: 'brand_logo',
        file: PickedFileData(
          name: file.name,
          mimeType: _imageMimeType(file.extension),
          bytes: file.bytes!,
        ),
      );
      if (!mounted) return;
      setState(() {
        _logoFileId = uploaded.publicId;
        _logoFileName = file.name;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = brandApiMessage(error));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().length < 2) {
      brandSnack(context, 'Enter the organization name');
      return;
    }
    if (_category.text.trim().isEmpty) {
      brandSnack(context, 'Enter the industry category');
      return;
    }
    if (_description.text.trim().length < 20) {
      brandSnack(context, 'Add a description of at least 20 characters');
      return;
    }
    if (_specialist == null) {
      brandSnack(context, 'Preview profile saved');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final body = <String, dynamic>{
        'name': _name.text.trim(),
        'category': _category.text.trim(),
        'representative': _representative.text.trim(),
        'description': _description.text.trim(),
        if (_billingDetails.text.trim().isNotEmpty)
          'billing_details': _billingDetails.text.trim(),
        if (_logoFileId != null) 'logo_file_id': _logoFileId,
      };
      final profile = await _saveWithMediaRetry(body);
      if (!mounted) return;
      _applyProfile(profile);
      setState(() {
        _profile = profile;
        _logoFileId = null;
        _logoFileName = null;
        _billingDetails.clear();
      });
      brandSnack(context, 'Brand profile saved');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = brandApiMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<BrandProfileDto> _saveWithMediaRetry(
    Map<String, dynamic> body,
  ) async {
    ApiException? lastError;
    for (var attempt = 0; attempt < 6; attempt += 1) {
      try {
        return await _specialist!.upsertBrandProfile(body);
      } on ApiException catch (error) {
        lastError = error;
        final waitingForMedia = _logoFileId != null &&
            (error.fields.containsKey('logo_file_id') ||
                error.message.toLowerCase().contains('ready') ||
                error.message.toLowerCase().contains('clean'));
        if (!waitingForMedia || attempt == 5) rethrow;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
    throw lastError ??
        const ApiException(
          code: 'brand.profile_failed',
          message: 'The brand profile could not be saved.',
        );
  }

  void _seedPreview() {
    final profile = BrandSponsorDemoData.profile;
    _name.text = profile.name;
    _category.text = profile.category;
    _representative.text = profile.representative;
    _description.text = profile.description;
    _logoUrl = profile.imageUrl;
    _loaded = true;
  }

  String _imageMimeType(String? extension) {
    return switch (extension?.toLowerCase()) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}

class _ReadinessRow extends StatelessWidget {
  final String label;
  final bool complete;

  const _ReadinessRow({
    required this.label,
    required this.complete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(
            complete
                ? Icons.check_circle_outline_rounded
                : Icons.radio_button_unchecked_rounded,
            color: complete ? colors.success : colors.iconMuted,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.cardLabel.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
