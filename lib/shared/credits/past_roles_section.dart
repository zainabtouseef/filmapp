import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/core_ui/widgets/core_widgets.dart';
import '../../core/credits/credit_models.dart';
import '../../core/credits/credits_controller.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/uploads/upload_repository.dart';
import '../../features/actor_talent/widgets/actor_talent_components.dart';
import '../cards/cine_card_system.dart';

/// Shared "past roles / credits" section — a resume-style list of prior
/// productions with an optional cover photo. Wired into every portfolio
/// screen (Actor/Talent, Model, Location Owner, Media/Equipment, Crew
/// Services), each supplying its own `profileType` and section copy.
class PastRolesSection extends StatefulWidget {
  final String profileType;
  final String sectionTitle;
  final String emptyMessage;

  const PastRolesSection({
    super.key,
    required this.profileType,
    required this.sectionTitle,
    required this.emptyMessage,
  });

  @override
  State<PastRolesSection> createState() => _PastRolesSectionState();
}

class _PastRolesSectionState extends State<PastRolesSection> {
  Future<List<CreditEntry>>? _future;
  String? _busyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<List<CreditEntry>> _load() {
    final controller = CreditsScope.maybeOf(context);
    if (controller == null) return Future.value(const []);
    return controller.list(widget.profileType);
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return ActorSectionCard(
      title: widget.sectionTitle,
      icon: Icons.movie_creation_outlined,
      actionText: 'Add credit',
      onActionTap: () => _openForm(),
      child: FutureBuilder<List<CreditEntry>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ActorResponsiveGrid(
              minWidth: 220,
              children: [SkeletonCard(height: 180), SkeletonCard(height: 180)],
            );
          }
          if (snapshot.hasError) {
            return CoreEmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load credits',
              message: snapshot.error is ApiException
                  ? (snapshot.error! as ApiException).message
                  : 'Check your connection and retry.',
              actionLabel: 'Try again',
              onAction: _reload,
            );
          }
          final entries = snapshot.data ?? const <CreditEntry>[];
          if (entries.isEmpty) {
            return CoreEmptyState(
              icon: Icons.local_movies_outlined,
              title: 'No credits yet',
              message: widget.emptyMessage,
            );
          }
          return ActorResponsiveGrid(
            minWidth: 220,
            children: [
              for (final entry in entries)
                _CreditCard(
                  entry: entry,
                  busy: _busyId == entry.publicId,
                  onEdit: () => _openForm(existing: entry),
                  onDelete: () => _delete(entry),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openForm({CreditEntry? existing}) async {
    final result = await showDialog<_CreditFormResult>(
      context: context,
      builder: (_) => _CreditFormDialog(existing: existing),
    );
    if (result == null || !mounted) return;
    final auth = AuthScope.maybeOf(context);
    final credits = CreditsScope.maybeOf(context);
    if (auth == null || credits == null) return;
    final busyKey = existing?.publicId ?? 'new';
    setState(() => _busyId = busyKey);
    try {
      String? coverFileId;
      if (result.coverFile != null) {
        final uploaded = await auth.uploadFile(
          purpose: 'profile_media',
          file: result.coverFile!,
        );
        coverFileId = uploaded.publicId;
      }
      if (existing == null) {
        await credits.create(
          profileType: widget.profileType,
          title: result.title,
          productionName: result.productionName,
          roleLabel: result.roleLabel,
          year: result.year,
          description: result.description,
          coverFileId: coverFileId,
        );
      } else {
        await credits.update(existing.publicId, {
          'title': result.title,
          'production_name': result.productionName,
          'role_label': result.roleLabel ?? '',
          if (result.year != null) 'year': result.year,
          'description': result.description ?? '',
          if (coverFileId != null) 'cover_file_id': coverFileId,
        });
      }
      if (!mounted) return;
      actorSnack(context, existing == null ? 'Credit added' : 'Credit updated');
      _reload();
    } on ApiException catch (error) {
      if (mounted) actorSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _delete(CreditEntry entry) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Remove this credit?'),
            content: Text('${entry.title} will be removed from your profile.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    final credits = CreditsScope.maybeOf(context);
    if (credits == null) return;
    setState(() => _busyId = entry.publicId);
    try {
      await credits.delete(entry.publicId);
      if (!mounted) return;
      actorSnack(context, 'Credit removed');
      _reload();
    } on ApiException catch (error) {
      if (mounted) actorSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }
}

class _CreditCard extends StatelessWidget {
  final CreditEntry entry;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CreditCard({
    required this.entry,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final coverUrl = entry.coverFile?.publicUrl;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: colors.softSurface,
                image: coverUrl != null
                    ? DecorationImage(
                        image: NetworkImage(coverUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: busy
                  ? const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : coverUrl == null
                      ? Icon(
                          Icons.theaters_outlined,
                          color: colors.goldDark,
                          size: 26,
                        )
                      : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            entry.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.cardLabel.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            [
              entry.productionName,
              if (entry.year != null) '${entry.year}',
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
          ),
          if ((entry.roleLabel ?? '').isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              entry.roleLabel!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.smallMeta.copyWith(color: colors.goldDark),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Edit',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: busy ? null : onEdit,
              ),
              IconButton(
                tooltip: 'Remove',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                onPressed: busy ? null : onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreditFormResult {
  final String title;
  final String productionName;
  final String? roleLabel;
  final int? year;
  final String? description;
  final PickedFileData? coverFile;

  const _CreditFormResult({
    required this.title,
    required this.productionName,
    required this.roleLabel,
    required this.year,
    required this.description,
    required this.coverFile,
  });
}

class _CreditFormDialog extends StatefulWidget {
  final CreditEntry? existing;

  const _CreditFormDialog({this.existing});

  @override
  State<_CreditFormDialog> createState() => _CreditFormDialogState();
}

class _CreditFormDialogState extends State<_CreditFormDialog> {
  late final TextEditingController _title;
  late final TextEditingController _productionName;
  late final TextEditingController _roleLabel;
  late final TextEditingController _year;
  late final TextEditingController _description;
  PickedFileData? _pickedCover;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _title = TextEditingController(text: existing?.title ?? '');
    _productionName = TextEditingController(text: existing?.productionName ?? '');
    _roleLabel = TextEditingController(text: existing?.roleLabel ?? '');
    _year = TextEditingController(text: existing?.year?.toString() ?? '');
    _description = TextEditingController(text: existing?.description ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _productionName.dispose();
    _roleLabel.dispose();
    _year.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    final coverUrl = existing?.coverFile?.publicUrl;
    return AlertDialog(
      title: Text(existing == null ? 'Add a credit' : 'Edit credit'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _pickCover,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: context.appColors.softSurface,
                      border: Border.all(color: context.appColors.border),
                      image: _pickedCover != null
                          ? DecorationImage(
                              image: MemoryImage(_pickedCover!.bytes),
                              fit: BoxFit.cover,
                            )
                          : coverUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(coverUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                    ),
                    child: _pickedCover == null && coverUrl == null
                        ? Icon(
                            Icons.add_a_photo_outlined,
                            color: context.appColors.goldDark,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: _title,
                label: 'Title (e.g. Lead Role — Hero)',
                icon: Icons.badge_outlined,
                errorText: _error,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: _productionName,
                label: 'Production name',
                icon: Icons.movie_outlined,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: _roleLabel,
                label: 'Role label (optional)',
                icon: Icons.theater_comedy_outlined,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: _year,
                label: 'Year (optional)',
                icon: Icons.calendar_today_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: _description,
                label: 'Description (optional)',
                icon: Icons.notes_outlined,
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(existing == null ? 'Add credit' : 'Save changes'),
        ),
      ],
    );
  }

  Future<void> _pickCover() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    final item = result?.files.single;
    final bytes = item?.bytes;
    if (item == null || bytes == null) return;
    setState(() {
      _pickedCover = PickedFileData(
        name: item.name,
        mimeType: switch (item.extension?.toLowerCase()) {
          'png' => 'image/png',
          'webp' => 'image/webp',
          _ => 'image/jpeg',
        },
        bytes: bytes,
      );
    });
  }

  void _submit() {
    final title = _title.text.trim();
    if (title.length < 2) {
      setState(() => _error = 'Add a short title');
      return;
    }
    final productionName = _productionName.text.trim();
    if (productionName.length < 2) {
      actorSnack(context, 'Add the production name');
      return;
    }
    final yearText = _year.text.trim();
    final year = yearText.isEmpty ? null : int.tryParse(yearText);
    if (yearText.isNotEmpty && year == null) {
      actorSnack(context, 'Enter a valid year');
      return;
    }
    Navigator.pop(
      context,
      _CreditFormResult(
        title: title,
        productionName: productionName,
        roleLabel: _roleLabel.text.trim().isEmpty ? null : _roleLabel.text.trim(),
        year: year,
        description:
            _description.text.trim().isEmpty ? null : _description.text.trim(),
        coverFile: _pickedCover,
      ),
    );
  }
}
