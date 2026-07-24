import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/uploads/upload_repository.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../../../shared/widgets/status_chip.dart';
import '../models/brand_sponsor_models.dart';
import '../routes/brand_sponsor_routes.dart';
import '../widgets/brand_sponsor_components.dart';
import '../widgets/brand_sponsor_live.dart';

class BR03OpportunityComposerScreen extends StatefulWidget {
  const BR03OpportunityComposerScreen({super.key});

  @override
  State<BR03OpportunityComposerScreen> createState() =>
      _BR03OpportunityComposerScreenState();
}

class _BR03OpportunityComposerScreenState
    extends State<BR03OpportunityComposerScreen> {
  final _title = TextEditingController();
  final _budget = TextEditingController();
  final _usage = TextEditingController();
  final _eligibility = TextEditingController();
  final _deliverables = TextEditingController();

  SpecialistController? _specialist;
  BrandProfileDto? _profile;
  List<BrandOpportunityDto> _opportunities = const [];
  String _category = 'Product placement';
  String? _selectedId;
  String? _coverFileId;
  String? _coverFileName;
  String _coverUrl = '';
  DateTime? _dueAt;
  bool _loading = false;
  bool _loaded = false;
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
      final opportunities = profile == null
          ? const <BrandOpportunityDto>[]
          : await _specialist!.brandOpportunities(force: true);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _opportunities = opportunities;
        _loaded = true;
      });
      final active = activeBrandOpportunity(opportunities);
      if (active != null) _selectOpportunity(active);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = brandApiMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _budget.dispose();
    _usage.dispose();
    _eligibility.dispose();
    _deliverables.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_specialist == null) {
      return const CoreEmptyState(
        icon: Icons.cloud_sync_outlined,
        title: 'Sign in to manage opportunities',
        message:
            'Opportunity drafts, covers, publishing status and application counts are loaded from the backend.',
      );
    }
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
        title: 'Opportunities unavailable',
        message: _error!,
        actionLabel: 'Try again',
        onAction: _load,
      );
    }
    if (_specialist != null && _profile == null) {
      return CoreEmptyState(
        icon: Icons.business_center_outlined,
        title: 'Brand profile required',
        message:
            'Create the organization profile before publishing a sponsorship opportunity.',
        actionLabel: 'Create profile',
        onAction: () =>
            Navigator.pushNamed(context, BrandSponsorRoutes.profile),
      );
    }
    final colors = context.appColors;
    final selected = _selectedOpportunity;
    return BrandTwoColumn(
      left: BrandSectionCard(
        title: selected == null ? 'Create opportunity' : 'Edit opportunity',
        icon: Icons.campaign_outlined,
        selected: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                BrandLiveStatusChip(status: selected?.status ?? 'new'),
                StatusChip(
                  label: 'PUBLIC BRIEF',
                  icon: Icons.public_outlined,
                  color: colors.infoBlue,
                ),
                if (_coverFileName != null)
                  StatusChip(
                    label: 'NEW COVER',
                    icon: Icons.image_outlined,
                    color: colors.infoPurple,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            CoreTextField(
              controller: _title,
              label: 'Opportunity title',
              icon: Icons.title_rounded,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            CoreDropdownField<String>(
              value: _category,
              values: const [
                'Product placement',
                'Sponsorship',
                'Branded content',
                'Social campaign',
                'Event partnership',
                'Other',
              ],
              label: 'Opportunity category',
              icon: Icons.category_outlined,
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 10),
            CoreTextField(
              controller: _budget,
              label: 'Total budget (PKR)',
              icon: Icons.payments_outlined,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            CoreTextField(
              controller: _usage,
              label: 'Usage rights and territory',
              icon: Icons.policy_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            CoreTextField(
              controller: _eligibility,
              label: 'Eligible projects or applicants',
              icon: Icons.rule_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            CoreTextField(
              controller: _deliverables,
              label: 'Required deliverables',
              icon: Icons.fact_check_outlined,
              maxLines: 4,
            ),
            const SizedBox(height: 10),
            UploadCard(
              title: _uploading ? 'Uploading cover...' : 'Opportunity cover',
              subtitle: _coverFileName ??
                  (_coverUrl.isEmpty
                      ? 'Optional campaign or product image'
                      : 'Current cover is connected'),
              uploaded: _coverFileName != null || _coverUrl.isNotEmpty,
              onTap: _uploading ? null : _pickCover,
            ),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.event_outlined,
                color: colors.goldDark,
              ),
              title: const Text('Application deadline'),
              subtitle: Text(brandDate(_dueAt)),
              trailing: IconButton(
                tooltip: 'Choose deadline',
                icon: const Icon(Icons.edit_calendar_outlined),
                onPressed: _pickDeadline,
              ),
              onTap: _pickDeadline,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              InlineNotice(
                message: _error!,
                icon: Icons.error_outline_rounded,
                tone: CoreStatusTone.danger,
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: CoreSecondaryButton(
                    icon: Icons.save_outlined,
                    label: _saving ? 'Saving...' : 'Save draft',
                    compact: true,
                    onTap: _saving ? null : () => _save(publish: false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CorePrimaryButton(
                    icon: Icons.publish_outlined,
                    label: _saving ? 'Publishing...' : 'Publish',
                    compact: true,
                    onTap: _saving ? null : () => _save(publish: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      right: Column(
        children: [
          BrandSectionCard(
            title: 'Public brief view',
            icon: Icons.visibility_outlined,
            tone: BrandTone.blue,
            child: Column(
              children: [
                BrandMediaFrame(
                  imageUrl: _coverUrl,
                  title:
                      _title.text.trim().isEmpty ? 'Opportunity' : _title.text,
                  badge: _category,
                  fallbackIcon: Icons.campaign_outlined,
                  aspectRatio: 16 / 9,
                  compact: true,
                ),
                const SizedBox(height: 10),
                BrandInfoRow(
                  icon: Icons.payments_outlined,
                  label: 'Budget',
                  value: brandMoney(_budgetMinor),
                ),
                BrandInfoRow(
                  icon: Icons.event_outlined,
                  label: 'Applications close',
                  value: brandDate(_dueAt),
                ),
                BrandInfoRow(
                  icon: Icons.policy_outlined,
                  label: 'Usage',
                  value: _usage.text.trim().isEmpty ? 'Not set' : _usage.text,
                ),
                BrandInfoRow(
                  icon: Icons.fact_check_outlined,
                  label: 'Deliverables',
                  value: _deliverables.text.trim().isEmpty
                      ? 'Not set'
                      : _deliverables.text,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          BrandSectionCard(
            title: 'Opportunity portfolio',
            icon: Icons.view_list_outlined,
            tone: BrandTone.purple,
            actionText: 'New',
            onActionTap: _newOpportunity,
            child: _opportunities.isEmpty
                ? Text(
                    'No saved opportunities.',
                    style: AppTextStyles.smallMeta.copyWith(
                      color: colors.textSecondary,
                    ),
                  )
                : Column(
                    children: [
                      for (final opportunity in _opportunities)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: _OpportunityRow(
                            opportunity: opportunity,
                            selected: opportunity.publicId == _selectedId,
                            onTap: () => _selectOpportunity(opportunity),
                            onStatus: (status) =>
                                _changeStatus(opportunity, status),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  BrandOpportunityDto? get _selectedOpportunity {
    for (final opportunity in _opportunities) {
      if (opportunity.publicId == _selectedId) return opportunity;
    }
    return null;
  }

  int? get _budgetMinor {
    final digits = _budget.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = int.tryParse(digits);
    return amount == null ? null : amount * 100;
  }

  void _selectOpportunity(BrandOpportunityDto opportunity) {
    setState(() {
      _selectedId = opportunity.publicId;
      _title.text = opportunity.title;
      _category = _displayCategory(opportunity.category);
      _budget.text = opportunity.budgetMinor == null
          ? ''
          : '${opportunity.budgetMinor! ~/ 100}';
      _usage.text = opportunity.usageSummary;
      _eligibility.text = opportunity.eligibility;
      _deliverables.text = opportunity.deliverables;
      _dueAt = opportunity.applicationDueAt;
      _coverUrl = opportunity.coverUrl;
      _coverFileId = null;
      _coverFileName = null;
      _error = null;
    });
  }

  void _newOpportunity() {
    setState(() {
      _selectedId = null;
      _title.clear();
      _category = 'Product placement';
      _budget.clear();
      _usage.clear();
      _eligibility.clear();
      _deliverables.clear();
      _dueAt = DateTime.now().add(const Duration(days: 14));
      _coverUrl = '';
      _coverFileId = null;
      _coverFileName = null;
      _error = null;
    });
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _dueAt?.isAfter(now) == true
          ? _dueAt!
          : now.add(const Duration(days: 14)),
    );
    if (date != null) {
      setState(
          () => _dueAt = DateTime(date.year, date.month, date.day, 23, 59));
    }
  }

  Future<void> _pickCover() async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null) {
      brandSnack(context, 'Sign in to upload an opportunity cover');
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
        purpose: 'brand_opportunity_cover',
        file: PickedFileData(
          name: file.name,
          mimeType: _imageMimeType(file.extension),
          bytes: file.bytes!,
        ),
      );
      if (!mounted) return;
      setState(() {
        _coverFileId = uploaded.publicId;
        _coverFileName = file.name;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = brandApiMessage(error));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save({required bool publish}) async {
    if (_title.text.trim().length < 4) {
      brandSnack(context, 'Enter a clear opportunity title');
      return;
    }
    if (publish &&
        ((_budgetMinor ?? 0) <= 0 ||
            _usage.text.trim().length < 8 ||
            _deliverables.text.trim().length < 8 ||
            _dueAt == null)) {
      brandSnack(
        context,
        'Publishing requires budget, usage, deliverables and a deadline',
      );
      return;
    }
    if (_specialist == null) {
      brandSnack(context, 'Sign in to save opportunities');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final body = <String, dynamic>{
        'title': _title.text.trim(),
        'category': _apiCategory(_category),
        'budget_minor': _budgetMinor,
        'currency': 'PKR',
        'usage_summary': _usage.text.trim(),
        'eligibility': _eligibility.text.trim(),
        'deliverables': _deliverables.text.trim(),
        'application_due_at': _dueAt?.toUtc().toIso8601String(),
        'status': publish ? 'published' : 'draft',
        if (_coverFileId != null) 'cover_file_id': _coverFileId,
      };
      final opportunity = await _saveWithMediaRetry(body);
      final opportunities = await _specialist!.brandOpportunities(force: true);
      if (!mounted) return;
      setState(() => _opportunities = opportunities);
      _selectOpportunity(opportunity);
      brandSnack(
        context,
        publish ? 'Opportunity published' : 'Opportunity draft saved',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = brandApiMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<BrandOpportunityDto> _saveWithMediaRetry(
    Map<String, dynamic> body,
  ) async {
    ApiException? lastError;
    for (var attempt = 0; attempt < 6; attempt += 1) {
      try {
        if (_selectedId == null) {
          return await _specialist!.createBrandOpportunity(body);
        }
        return await _specialist!.updateBrandOpportunity(_selectedId!, body);
      } on ApiException catch (error) {
        lastError = error;
        final waitingForMedia = _coverFileId != null &&
            (error.fields.containsKey('cover_file_id') ||
                error.message.toLowerCase().contains('ready') ||
                error.message.toLowerCase().contains('clean'));
        if (!waitingForMedia || attempt == 5) rethrow;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
    throw lastError ??
        const ApiException(
          code: 'brand.opportunity_failed',
          message: 'The opportunity could not be saved.',
        );
  }

  Future<void> _changeStatus(
    BrandOpportunityDto opportunity,
    String status,
  ) async {
    if (_specialist == null) {
      brandSnack(context, 'Sign in to update opportunity status');
      return;
    }
    try {
      await _specialist!.updateBrandOpportunity(
        opportunity.publicId,
        {'status': status},
      );
      final rows = await _specialist!.brandOpportunities(force: true);
      if (!mounted) return;
      setState(() => _opportunities = rows);
      final refreshed = rows.firstWhere(
        (item) => item.publicId == opportunity.publicId,
      );
      if (_selectedId == opportunity.publicId) _selectOpportunity(refreshed);
      brandSnack(context, 'Opportunity ${readableBrandStatus(status)}');
    } catch (error) {
      if (!mounted) return;
      brandSnack(context, brandApiMessage(error));
    }
  }

  String _apiCategory(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  String _displayCategory(String value) {
    final readable = readableBrandStatus(value);
    const categories = {
      'Product Placement',
      'Sponsorship',
      'Branded Content',
      'Social Campaign',
      'Event Partnership',
      'Other',
    };
    return categories.contains(readable) ? readable : 'Other';
  }

  String _imageMimeType(String? extension) {
    return switch (extension?.toLowerCase()) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}

class _OpportunityRow extends StatelessWidget {
  final BrandOpportunityDto opportunity;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<String> onStatus;

  const _OpportunityRow({
    required this.opportunity,
    required this.selected,
    required this.onTap,
    required this.onStatus,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? colors.softSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? colors.goldMid : colors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.campaign_outlined,
              color: selected ? colors.goldDark : colors.iconMuted,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    opportunity.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardLabel.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${brandMoney(opportunity.budgetMinor)} · '
                    '${opportunity.applicationCount} applications',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.smallMeta.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            BrandLiveStatusChip(status: opportunity.status),
            CardMenu<String>(
              items: const [
                CardMenuItem(
                  value: 'published',
                  label: 'Publish',
                  icon: Icons.publish_outlined,
                ),
                CardMenuItem(
                  value: 'paused',
                  label: 'Pause',
                  icon: Icons.pause_circle_outline,
                ),
                CardMenuItem(
                  value: 'closed',
                  label: 'Close',
                  icon: Icons.stop_circle_outlined,
                ),
              ],
              onSelected: onStatus,
            ),
          ],
        ),
      ),
    );
  }
}
