import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/projects/project_models.dart';
import '../../../core/projects/projects_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/uploads/upload_repository.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_status_chip.dart';

class DPProjectRoomScreen extends StatefulWidget {
  final String? projectId;

  const DPProjectRoomScreen({super.key, this.projectId});

  @override
  State<DPProjectRoomScreen> createState() => _DPProjectRoomScreenState();
}

class _DPProjectRoomScreenState extends State<DPProjectRoomScreen> {
  Future<ProjectRoom>? _roomFuture;
  bool _started = false;
  bool _savingDecision = false;
  bool _uploadingFile = false;
  String? _uploadingFolder;
  String? _uploadStatus;
  double _uploadProgress = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _reload();
    }
  }

  void _reload() {
    final controller = ProjectsScope.maybeOf(context);
    final projectId = widget.projectId;
    setState(() {
      _roomFuture = controller == null || projectId == null
          ? Future<ProjectRoom>.error(
              const ApiException(
                code: 'project.missing',
                message: 'Project id is required.',
              ),
            )
          : controller.room(projectId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProjectRoom>(
      future: _roomFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return DPSectionCard(
            title: 'Project Room',
            icon: Icons.hourglass_top_rounded,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: CircularProgressIndicator(
                  color: context.appColors.goldMid,
                ),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return CoreEmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Project room unavailable',
            message:
                'Could not load the live project room from the database. Open a real project and retry.',
            actionLabel: 'Retry',
            onAction: _reload,
          );
        }
        final room = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            dpHeaderAction(
              context,
              icon: Icons.campaign_outlined,
              label: _savingDecision ? 'Pinning...' : 'Pin Decision',
              onTap: _savingDecision ? () {} : _pinDecision,
            ),
            const SizedBox(height: 8),
            DPTwoColumn(
              left: DPSectionCard(
                title: 'Team Feed',
                icon: Icons.chat_bubble_outline_rounded,
                child: Column(
                  children: [
                    if (room.items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: dpText(
                          context,
                          'No room decisions yet. Pin one for the team.',
                        ),
                      )
                    else
                      for (var i = 0; i < room.items.length; i++)
                        _RoomFeedItem(
                          author: room.items[i].creatorName ?? 'CineConnect',
                          text: room.items[i].body?.isNotEmpty == true
                              ? room.items[i].body!
                              : room.items[i].title,
                          time: _timeLabel(room.items[i].createdAt),
                          showDivider: i != room.items.length - 1,
                        ),
                  ],
                ),
              ),
              right: DPSectionCard(
                title: 'Files & Decisions',
                icon: Icons.folder_copy_outlined,
                child: Column(
                  children: [
                    _ProjectMediaUploadPanel(
                      uploadingFolder: _uploadingFolder,
                      uploadStatus: _uploadStatus,
                      uploadProgress: _uploadProgress,
                      onUploadTrailer: _uploadingFolder == null
                          ? () => _uploadProjectMedia('trailer')
                          : null,
                      onUploadOst: _uploadingFolder == null
                          ? () => _uploadProjectMedia('ost')
                          : null,
                    ),
                    const SizedBox(height: 10),
                    for (var i = 0; i < room.files.length; i++)
                      _RoomFileItem(
                        kind: room.files[i].folder,
                        title: room.files[i].label,
                        status: room.files[i].file.processingStatus,
                        showDivider: i != room.files.length - 1,
                      ),
                    for (final item
                        in room.items.where((item) => item.pinnedAt != null))
                      _RoomFileItem(
                        kind: 'Decision',
                        title: item.title,
                        status: 'Pinned',
                      ),
                    const SizedBox(height: 8),
                    DPHolographicButton(
                      label: _uploadingFile ? 'Uploading File' : 'Upload File',
                      icon: Icons.upload_file_rounded,
                      onTap: _uploadingFile ? null : _uploadFile,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pinDecision() async {
    final controller = ProjectsScope.maybeOf(context);
    final projectId = widget.projectId;
    if (controller == null || projectId == null) {
      dpSnack(context, 'Open a live project before pinning decisions');
      return;
    }
    setState(() => _savingDecision = true);
    try {
      await controller.createRoomItem(
        projectId: projectId,
        title: 'Production decision',
        body: 'Decision pinned from the Director/Producer project room.',
      );
      if (!mounted) return;
      dpSnack(context, 'Decision pinned');
      _reload();
    } on ApiException catch (error) {
      if (!mounted) return;
      dpSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _savingDecision = false);
    }
  }

  Future<void> _uploadFile() async {
    final auth = AuthScope.maybeOf(context);
    final projects = ProjectsScope.maybeOf(context);
    final projectId = widget.projectId;
    if (auth == null || projects == null || projectId == null) {
      dpSnack(context, 'Open a live project before uploading files');
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    final picked = result?.files.single;
    final bytes = picked?.bytes;
    if (picked == null || bytes == null) return;
    setState(() => _uploadingFile = true);
    try {
      final uploaded = await auth.uploadFile(
        purpose: 'project_document',
        file: PickedFileData(
          name: picked.name,
          mimeType: _mimeTypeFor(picked),
          bytes: bytes,
        ),
      );
      await _linkFileWhenReady(
        controller: projects,
        projectId: projectId,
        fileId: uploaded.publicId,
        label: picked.name,
      );
      if (!mounted) return;
      dpSnack(context, 'Project file linked');
      _reload();
    } on ApiException catch (error) {
      if (!mounted) return;
      dpSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _uploadingFile = false);
    }
  }

  Future<void> _uploadProjectMedia(String folder) async {
    final auth = AuthScope.maybeOf(context);
    final projects = ProjectsScope.maybeOf(context);
    final projectId = widget.projectId;
    if (auth == null || projects == null || projectId == null) {
      dpSnack(context, 'Open a live project before uploading media');
      return;
    }
    final isTrailer = folder == 'trailer';
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: isTrailer
          ? const ['mp4', 'mov', 'webm']
          : const ['mp3', 'm4a', 'aac', 'wav'],
      withData: true,
    );
    final picked = result?.files.single;
    final bytes = picked?.bytes;
    if (picked == null || bytes == null) return;
    setState(() {
      _uploadingFolder = folder;
      _uploadStatus = 'Preparing ${isTrailer ? 'trailer' : 'OST'} upload...';
      _uploadProgress = 0;
    });
    try {
      final uploaded = await auth.uploadFile(
        purpose: 'project_media',
        file: PickedFileData(
          name: picked.name,
          mimeType: _mimeTypeFor(picked),
          bytes: bytes,
        ),
        onProgress: (sent, total) {
          if (!mounted || total <= 0) return;
          setState(() => _uploadProgress = sent / total);
        },
        onStatus: (status) {
          if (!mounted) return;
          setState(() => _uploadStatus = status);
        },
      );
      await _linkFileWhenReady(
        controller: projects,
        projectId: projectId,
        fileId: uploaded.publicId,
        label: picked.name,
        folder: folder,
      );
      if (!mounted) return;
      dpSnack(context, isTrailer ? 'Trailer published' : 'OST published');
      _reload();
    } on ApiException catch (error) {
      if (!mounted) return;
      dpSnack(context, error.message);
    } finally {
      if (mounted) {
        setState(() {
          _uploadingFolder = null;
          _uploadStatus = null;
          _uploadProgress = 0;
        });
      }
    }
  }

  Future<void> _linkFileWhenReady({
    required ProjectsController controller,
    required String projectId,
    required String fileId,
    required String label,
    String folder = 'briefs',
  }) async {
    for (var attempt = 0; attempt < 6; attempt += 1) {
      try {
        await controller.linkProjectFile(
          projectId: projectId,
          fileId: fileId,
          label: label,
          folder: folder,
        );
        return;
      } on ApiException catch (error) {
        final waitingForScan = error.fields.containsKey('file_id') ||
            error.message.toLowerCase().contains('clean') ||
            error.message.toLowerCase().contains('ready');
        if (!waitingForScan || attempt == 5) rethrow;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
  }

  String _mimeTypeFor(PlatformFile file) {
    final extension = (file.extension ?? '').toLowerCase();
    return switch (extension) {
      'pdf' => 'application/pdf',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      'webm' => 'video/webm',
      'mp3' => 'audio/mpeg',
      'm4a' => 'audio/mp4',
      'aac' => 'audio/aac',
      'wav' => 'audio/wav',
      _ => 'application/octet-stream',
    };
  }

  String _timeLabel(DateTime? date) {
    if (date == null) return 'now';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class _RoomFeedItem extends StatelessWidget {
  final String author;
  final String text;
  final String time;
  final bool showDivider;

  const _RoomFeedItem({
    required this.author,
    required this.text,
    required this.time,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.borderMuted))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: colors.goldGlow.withValues(alpha: 0.18),
            child: Text(
              author.isEmpty ? '?' : author[0].toUpperCase(),
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                dpText(context, author, strong: true),
                const SizedBox(height: 3),
                dpText(context, text),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style:
                AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ProjectMediaUploadPanel extends StatelessWidget {
  final String? uploadingFolder;
  final String? uploadStatus;
  final double uploadProgress;
  final VoidCallback? onUploadTrailer;
  final VoidCallback? onUploadOst;

  const _ProjectMediaUploadPanel({
    required this.uploadingFolder,
    required this.uploadStatus,
    required this.uploadProgress,
    required this.onUploadTrailer,
    required this.onUploadOst,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final busy = uploadingFolder != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.movie_creation_outlined, color: colors.goldDark),
              const SizedBox(width: 8),
              Expanded(
                child: dpText(
                  context,
                  'Public Project Media',
                  strong: true,
                ),
              ),
              DPStatusChip(label: 'Cinema feed', tone: DpTone.info),
            ],
          ),
          const SizedBox(height: 8),
          dpText(
            context,
            'Upload trailers and OST tracks here. Clean, ready files appear in the General Public Cinema page.',
          ),
          if (busy) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: uploadProgress <= 0 ? null : uploadProgress,
              color: colors.goldMid,
              backgroundColor: colors.borderMuted,
            ),
            const SizedBox(height: 6),
            dpText(
              context,
              '${uploadingFolder == 'ost' ? 'OST' : 'Trailer'} · ${uploadStatus ?? 'Uploading...'}',
              strong: true,
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              DPHolographicButton(
                label: 'Upload Trailer',
                icon: Icons.play_circle_outline_rounded,
                onTap: onUploadTrailer,
              ),
              DPHolographicButton(
                label: 'Upload OST',
                icon: Icons.library_music_outlined,
                onTap: onUploadOst,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomFileItem extends StatelessWidget {
  final String kind;
  final String title;
  final String status;
  final bool showDivider;

  const _RoomFileItem({
    required this.kind,
    required this.title,
    required this.status,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.borderMuted))
            : null,
      ),
      child: Row(
        children: [
          Icon(
            kind == 'Decision'
                ? Icons.push_pin_outlined
                : Icons.insert_drive_file_outlined,
            size: 18,
            color: colors.textSecondary,
          ),
          const SizedBox(width: 9),
          Expanded(child: dpText(context, title, strong: true)),
          const SizedBox(width: 10),
          DPStatusChip(
            label: status,
            tone: kind == 'Decision' ? DpTone.success : DpTone.info,
          ),
        ],
      ),
    );
  }
}
