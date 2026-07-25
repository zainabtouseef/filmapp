import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/casting/casting_controller.dart';
import '../../../core/casting/casting_models.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/marketplace/marketplace_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/open_url.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/uploads/upload_repository.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../models/actor_talent_models.dart';
import '../routes/actor_talent_routes.dart';
import '../widgets/actor_casting_widgets.dart';
import '../widgets/actor_talent_components.dart';

class AT13RoleDetailApplyScreen extends StatefulWidget {
  final String? roleId;

  const AT13RoleDetailApplyScreen({super.key, this.roleId});

  @override
  State<AT13RoleDetailApplyScreen> createState() =>
      _AT13RoleDetailApplyScreenState();
}

class _AT13RoleDetailApplyScreenState extends State<AT13RoleDetailApplyScreen> {
  final _coverNote = TextEditingController();
  final _availability = TextEditingController();
  final Map<String, TextEditingController> _answers = {};
  final Set<String> _selectedPortfolio = {};
  Future<_RoleApplyData>? _future;
  bool _saving = false;
  bool _uploadingSelfTape = false;
  double? _selfTapeProgress;
  String? _selfTapeFileId;
  String? _selfTapeFileName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  @override
  void dispose() {
    _coverNote.dispose();
    _availability.dispose();
    for (final controller in _answers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<_RoleApplyData> _load() async {
    final id = widget.roleId;
    final casting = CastingScope.maybeOf(context);
    if (id == null || id.isEmpty || casting == null) {
      throw const ApiException(
        code: 'casting.role_missing',
        message: 'Open this screen from a live casting role.',
      );
    }
    final auth = AuthScope.maybeOf(context);
    final role = await casting.role(id);
    final portfolio = auth == null || !auth.isAuthenticated
        ? <MarketplacePortfolioItem>[]
        : await auth.portfolioItems();
    for (final question in role.castingQuestions) {
      _answers.putIfAbsent(question, TextEditingController.new);
    }
    return _RoleApplyData(role: role, portfolio: portfolio);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_RoleApplyData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SkeletonCard(height: 560);
        }
        if (snapshot.hasError || snapshot.data == null) {
          return CoreEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Role details unavailable',
            message: snapshot.error is ApiException
                ? (snapshot.error! as ApiException).message
                : 'Could not load this casting role.',
            actionLabel: 'Try again',
            onAction: () => setState(() => _future = _load()),
          );
        }
        final data = snapshot.data!;
        if (data.role.applicationId != null) {
          return CoreEmptyState(
            icon: Icons.assignment_turned_in_outlined,
            title: 'Application already started',
            message:
                'Continue from your application tracker to avoid duplicate submissions.',
            actionLabel: 'Open application',
            onAction: () => Navigator.pushNamed(
              context,
              ActorTalentRoutes.applicationDetail,
              arguments: data.role.applicationId,
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RoleHero(role: data.role),
            const SizedBox(height: 12),
            ActorTwoColumn(
              left: Column(
                children: [
                  _RoleBrief(role: data.role),
                  const SizedBox(height: 12),
                  _ApplicationForm(
                    role: data.role,
                    coverNote: _coverNote,
                    availability: _availability,
                    answers: _answers,
                  ),
                ],
              ),
              right: Column(
                children: [
                  _PortfolioPicker(
                    items: data.portfolio,
                    selected: _selectedPortfolio,
                    onChanged: (id, selected) {
                      setState(() {
                        selected
                            ? _selectedPortfolio.add(id)
                            : _selectedPortfolio.remove(id);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _InitialSelfTapeCard(
                    fileName: _selfTapeFileName,
                    uploading: _uploadingSelfTape,
                    progress: _selfTapeProgress,
                    onPick:
                        _uploadingSelfTape || _saving ? null : _pickSelfTape,
                    onRemove: _uploadingSelfTape || _saving
                        ? null
                        : () => setState(() {
                              _selfTapeFileId = null;
                              _selfTapeFileName = null;
                              _selfTapeProgress = null;
                            }),
                  ),
                  const SizedBox(height: 12),
                  ActorSectionCard(
                    title: 'Submit Application',
                    icon: Icons.send_outlined,
                    selected: true,
                    child: Column(
                      children: [
                        const ActorInfoRow(
                          icon: Icons.fact_check_outlined,
                          label: 'Before sending',
                          value:
                              'Review your profile, selected media and availability.',
                        ),
                        const SizedBox(height: 10),
                        CorePrimaryButton(
                          icon: Icons.send_rounded,
                          label: 'Submit application',
                          loading: _saving,
                          onTap: _saving || _uploadingSelfTape
                              ? null
                              : () => _save(data.role, submit: true),
                        ),
                        const SizedBox(height: 8),
                        CoreSecondaryButton(
                          icon: Icons.save_outlined,
                          label: 'Save draft',
                          onTap: _saving || _uploadingSelfTape
                              ? null
                              : () => _save(data.role, submit: false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _save(CastingRole role, {required bool submit}) async {
    if (submit && _coverNote.text.trim().length < 20) {
      actorSnack(
        context,
        'Add a short note explaining why you fit this role.',
      );
      return;
    }
    final unanswered = _answers.entries
        .where((entry) => entry.value.text.trim().isEmpty)
        .map((entry) => entry.key)
        .toList();
    if (submit && unanswered.isNotEmpty) {
      actorSnack(context, 'Answer every casting question before submitting.');
      return;
    }
    final casting = CastingScope.maybeOf(context);
    if (casting == null) return;
    setState(() => _saving = true);
    try {
      final application = await casting.createApplication(
        role.publicId,
        coverNote: _coverNote.text.trim(),
        availabilityNote: _availability.text.trim(),
        answers: {
          for (final entry in _answers.entries)
            entry.key: entry.value.text.trim(),
        },
        portfolioItemIds: _selectedPortfolio.toList(),
        selfTapeFileId: _selfTapeFileId,
        submit: submit,
      );
      if (!mounted) return;
      actorSnack(
        context,
        submit ? 'Application submitted' : 'Application draft saved',
      );
      Navigator.pushReplacementNamed(
        context,
        ActorTalentRoutes.applicationDetail,
        arguments: application.publicId,
      );
    } on ApiException catch (error) {
      if (mounted) actorSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickSelfTape() async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null || !auth.isAuthenticated) {
      actorSnack(context, 'Sign in to upload a self-tape');
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp4'],
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return;
    setState(() {
      _uploadingSelfTape = true;
      _selfTapeProgress = 0;
    });
    try {
      final uploaded = await auth.uploadFile(
        purpose: 'self_tape',
        file: PickedFileData(
          name: file.name,
          mimeType: 'video/mp4',
          bytes: bytes,
        ),
        onProgress: (sent, total) {
          if (mounted && total > 0) {
            setState(() => _selfTapeProgress = sent / total);
          }
        },
      );
      if (!mounted) return;
      setState(() {
        _selfTapeFileId = uploaded.publicId;
        _selfTapeFileName = uploaded.originalName;
        _selfTapeProgress = 1;
      });
      actorSnack(context, 'Self-tape ready to attach');
    } on ApiException catch (error) {
      if (mounted) actorSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _uploadingSelfTape = false);
    }
  }
}

class _RoleApplyData {
  final CastingRole role;
  final List<MarketplacePortfolioItem> portfolio;

  const _RoleApplyData({required this.role, required this.portfolio});
}

class _RoleHero extends StatelessWidget {
  final CastingRole role;

  const _RoleHero({required this.role});

  @override
  Widget build(BuildContext context) {
    return ActorSectionCard(
      title: role.project.title,
      icon: Icons.movie_creation_outlined,
      tone: ActorTone.purple,
      child: ActorTwoColumn(
        left: ActorMediaFrame(
          imageUrl: role.project.coverFile?.publicUrl ?? '',
          title: role.project.title,
          badge: role.project.projectType,
          fallbackIcon: Icons.movie_filter_outlined,
        ),
        right: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              role.title,
              style: AppTextStyles.sectionHeading.copyWith(
                color: context.appColors.textPrimary,
                fontSize: 22,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            ActorInfoRow(
              icon: Icons.apartment_outlined,
              label: 'Production',
              value: role.project.ownerName,
            ),
            ActorInfoRow(
              icon: Icons.location_on_outlined,
              label: 'Work location',
              value: role.workLocation ??
                  role.project.city?.name ??
                  'To be confirmed',
            ),
            ActorInfoRow(
              icon: Icons.payments_outlined,
              label: 'Fee',
              value: role.feeLabel,
            ),
            ActorInfoRow(
              icon: Icons.event_outlined,
              label: 'Application deadline',
              value: actorCastingDate(role.applicationDueAt),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleBrief extends StatelessWidget {
  final CastingRole role;

  const _RoleBrief({required this.role});

  @override
  Widget build(BuildContext context) {
    return ActorSectionCard(
      title: 'Role Brief',
      icon: Icons.description_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            role.summary ?? 'The production has not added a longer summary.',
            style: AppTextStyles.body.copyWith(
              color: context.appColors.textSecondary,
              height: 1.45,
            ),
          ),
          if (role.skills.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final skill in role.skills) Chip(label: Text(skill.name)),
              ],
            ),
          ],
          if (role.eligibility.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final item in role.eligibility)
              ActorInfoRow(
                icon: Icons.check_circle_outline_rounded,
                label: 'Eligibility',
                value: item,
              ),
          ],
          if ((role.instructions ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            ActorInfoRow(
              icon: Icons.assignment_outlined,
              label: 'Instructions',
              value: role.instructions!,
            ),
          ],
          if (role.sidesFile != null) ...[
            const SizedBox(height: 10),
            CoreSecondaryButton(
              icon: Icons.download_outlined,
              label: 'Open script or sides',
              compact: true,
              onTap: () async {
                final auth = AuthScope.maybeOf(context);
                if (auth == null) return;
                try {
                  final url = await auth.authorizedDownloadUrl(
                    role.sidesFile!.publicId,
                  );
                  openUrlInNewTab(url);
                } on ApiException catch (error) {
                  if (context.mounted) actorSnack(context, error.message);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ApplicationForm extends StatelessWidget {
  final CastingRole role;
  final TextEditingController coverNote;
  final TextEditingController availability;
  final Map<String, TextEditingController> answers;

  const _ApplicationForm({
    required this.role,
    required this.coverNote,
    required this.availability,
    required this.answers,
  });

  @override
  Widget build(BuildContext context) {
    return ActorSectionCard(
      title: 'Application',
      icon: Icons.edit_document,
      child: Column(
        children: [
          CoreTextField(
            controller: coverNote,
            label: 'Why are you right for this role?',
            icon: Icons.notes_rounded,
            maxLines: 5,
          ),
          const SizedBox(height: 10),
          CoreTextField(
            controller: availability,
            label: 'Availability and travel notes',
            icon: Icons.calendar_month_outlined,
            maxLines: 3,
          ),
          for (final question in role.castingQuestions) ...[
            const SizedBox(height: 10),
            CoreTextField(
              controller: answers[question]!,
              label: question,
              icon: Icons.question_answer_outlined,
              maxLines: 3,
            ),
          ],
        ],
      ),
    );
  }
}

class _PortfolioPicker extends StatelessWidget {
  final List<MarketplacePortfolioItem> items;
  final Set<String> selected;
  final void Function(String id, bool selected) onChanged;

  const _PortfolioPicker({
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ActorSectionCard(
      title: 'Portfolio Selection',
      icon: Icons.video_library_outlined,
      child: items.isEmpty
          ? CoreEmptyState(
              icon: Icons.video_call_outlined,
              title: 'No published portfolio media',
              message:
                  'Add headshots, clips or a showreel before attaching media.',
              actionLabel: 'Open portfolio',
              onAction: () => Navigator.pushNamed(
                context,
                ActorTalentRoutes.portfolio,
              ),
            )
          : Column(
              children: [
                for (final item in items.where(
                  (item) => item.status == 'published',
                ))
                  CheckboxListTile(
                    value: selected.contains(item.publicId),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(item.title),
                    subtitle:
                        Text('${item.displayCategory} · ${item.durationLabel}'),
                    onChanged: (value) =>
                        onChanged(item.publicId, value ?? false),
                  ),
              ],
            ),
    );
  }
}

class _InitialSelfTapeCard extends StatelessWidget {
  final String? fileName;
  final bool uploading;
  final double? progress;
  final VoidCallback? onPick;
  final VoidCallback? onRemove;

  const _InitialSelfTapeCard({
    required this.fileName,
    required this.uploading,
    required this.progress,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ActorSectionCard(
      title: 'Self-Tape',
      icon: Icons.video_camera_front_outlined,
      tone: ActorTone.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fileName ??
                'Attach an optional MP4 audition clip tailored to this role.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(
              color: context.appColors.textSecondary,
              height: 1.35,
            ),
          ),
          if (uploading) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 5),
            Text(
              progress == null
                  ? 'Preparing upload'
                  : '${(progress! * 100).round()}% uploaded',
              style: AppTextStyles.caption.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 180,
                child: CoreSecondaryButton(
                  icon: Icons.upload_file_outlined,
                  label: fileName == null ? 'Upload self-tape' : 'Replace tape',
                  compact: true,
                  onTap: onPick,
                ),
              ),
              if (fileName != null)
                IconButton(
                  tooltip: 'Remove self-tape',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
