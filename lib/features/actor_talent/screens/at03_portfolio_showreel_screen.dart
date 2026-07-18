import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/marketplace/marketplace_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/uploads/upload_repository.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/actor_talent_demo_data.dart';
import '../models/actor_talent_models.dart';
import '../widgets/actor_talent_components.dart';

/// AT-03 Portfolio & Showreel Manager
class AT03PortfolioShowreelScreen extends StatefulWidget {
  const AT03PortfolioShowreelScreen({super.key});

  @override
  State<AT03PortfolioShowreelScreen> createState() =>
      _AT03PortfolioShowreelScreenState();
}

class _AT03PortfolioShowreelScreenState
    extends State<AT03PortfolioShowreelScreen> {
  String query = '';
  String filter = 'All';
  Future<List<MarketplacePortfolioItem>>? _itemsFuture;
  bool _started = false;
  bool _uploading = false;
  String? _busyItemId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _reload();
    }
  }

  void _reload() {
    final controller = AuthScope.maybeOf(context);
    setState(() {
      _itemsFuture = controller == null
          ? Future<List<MarketplacePortfolioItem>>.error(
              const ApiException(
                code: 'auth.required',
                message: 'Sign in to manage portfolio media.',
              ),
            )
          : controller.portfolioItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ActorSearchFilterBar(
          query: query,
          onQueryChanged: (value) => setState(() => query = value),
          filters: const [
            'All',
            'Headshots',
            'Drama Clips',
            'Ads',
            'Voice Samples',
          ],
          selectedFilter: filter,
          onFilterChanged: (value) => setState(() => filter = value),
        ),
        const SizedBox(height: 12),
        ActorSectionCard(
          title: 'Media Library',
          icon: Icons.video_library_outlined,
          actionText: _uploading ? 'Uploading...' : 'Upload',
          onActionTap: _uploading ? null : _uploadMedia,
          child: FutureBuilder<List<MarketplacePortfolioItem>>(
            future: _itemsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _PortfolioLoadingState();
              }
              if (snapshot.hasError) {
                return AnimatedBuilder(
                  animation: ActorTalentDemoStore.instance,
                  builder: (context, _) => _PortfolioFallbackGrid(
                    query: query,
                    filter: filter,
                    warning: _friendlyError(snapshot.error),
                  ),
                );
              }
              final items = _filterRemoteItems(snapshot.data ?? const []);
              if (items.isEmpty) {
                return CoreEmptyState(
                  icon: Icons.collections_outlined,
                  title: 'No media found',
                  message: query.trim().isEmpty && filter == 'All'
                      ? 'Upload a headshot, reel, ad, or voice sample to start your live portfolio.'
                      : 'Change the filter or upload a new clip.',
                );
              }
              return ActorResponsiveGrid(
                minWidth: 230,
                children: [
                  for (final item in items)
                    _PortfolioCard(
                      title: item.title,
                      category: item.displayCategory,
                      duration: item.durationLabel,
                      status: item.displayStatus,
                      imageUrl: item.thumbnailFile?.downloadUrl ??
                          item.file?.downloadUrl ??
                          '',
                      cover: item.isCover,
                      isImage: item.isImage,
                      busy: _busyItemId == item.publicId,
                      onPreview: () => _showPreview(
                        title: item.title,
                        category: item.displayCategory,
                        duration: item.durationLabel,
                        imageUrl: item.thumbnailFile?.downloadUrl ??
                            item.file?.downloadUrl ??
                            '',
                        isImage: item.isImage,
                      ),
                      onCover: () => _setCover(item),
                      onMoveUp: () => _moveItem(item, -10),
                      onMoveDown: () => _moveItem(item, 10),
                      onDelete: () => _deleteItem(item),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  List<MarketplacePortfolioItem> _filterRemoteItems(
    List<MarketplacePortfolioItem> items,
  ) {
    return items.where((item) {
      final haystack = '${item.title} ${item.displayCategory}'.toLowerCase();
      final matchQuery =
          query.trim().isEmpty || haystack.contains(query.toLowerCase());
      final matchFilter = filter == 'All' || item.displayCategory == filter;
      return matchQuery && matchFilter;
    }).toList();
  }

  Future<void> _uploadMedia() async {
    final controller = AuthScope.maybeOf(context);
    if (controller == null) {
      actorSnack(context, 'Sign in to upload portfolio media');
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'mp4'],
      withData: true,
    );
    final picked = result?.files.single;
    final bytes = picked?.bytes;
    if (picked == null || bytes == null) return;

    final mimeType = _mimeTypeFor(picked);
    final title = _titleFor(picked.name);
    final category = _categoryFor(mimeType);
    setState(() => _uploading = true);
    try {
      final uploaded = await controller.uploadFile(
        purpose: 'profile_media',
        file: PickedFileData(
          name: picked.name,
          mimeType: mimeType,
          bytes: bytes,
        ),
      );
      await _createPortfolioItemWhenReady(
        controller: controller,
        title: title,
        category: category,
        fileId: uploaded.publicId,
      );
      if (!mounted) return;
      actorSnack(context, '$title added to your live portfolio');
      _reload();
    } on ApiException catch (error) {
      if (!mounted) return;
      actorSnack(context, _friendlyError(error));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _createPortfolioItemWhenReady({
    required AuthController controller,
    required String title,
    required String category,
    required String fileId,
  }) async {
    ApiException? lastError;
    for (var attempt = 0; attempt < 6; attempt += 1) {
      try {
        await controller.createPortfolioItem(
          title: title,
          category: category,
          fileId: fileId,
          sortOrder: 100,
        );
        return;
      } on ApiException catch (error) {
        lastError = error;
        final waitingForScan = error.fields.containsKey('file_id') ||
            error.message.toLowerCase().contains('clean') ||
            error.message.toLowerCase().contains('ready');
        if (!waitingForScan || attempt == 5) rethrow;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
    throw lastError ??
        const ApiException(
          code: 'portfolio.create_failed',
          message: 'Portfolio media could not be added.',
        );
  }

  Future<void> _setCover(MarketplacePortfolioItem item) async {
    await _mutateItem(
      item,
      () => AuthScope.of(context).updatePortfolioItem(
        publicId: item.publicId,
        isCover: true,
      ),
      '${item.title} is now public cover',
    );
  }

  Future<void> _moveItem(MarketplacePortfolioItem item, int delta) async {
    await _mutateItem(
      item,
      () => AuthScope.of(context).updatePortfolioItem(
        publicId: item.publicId,
        sortOrder: item.sortOrder + delta,
      ),
      'Portfolio order updated',
    );
  }

  Future<void> _deleteItem(MarketplacePortfolioItem item) async {
    await _mutateItem(
      item,
      () => AuthScope.of(context).deletePortfolioItem(item.publicId),
      '${item.title} removed from portfolio',
    );
  }

  Future<void> _mutateItem(
    MarketplacePortfolioItem item,
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() => _busyItemId = item.publicId);
    try {
      await action();
      if (!mounted) return;
      actorSnack(context, successMessage);
      _reload();
    } on ApiException catch (error) {
      if (!mounted) return;
      actorSnack(context, _friendlyError(error));
    } finally {
      if (mounted) setState(() => _busyItemId = null);
    }
  }

  void _showPreview({
    required String title,
    required String category,
    required String duration,
    required String imageUrl,
    required bool isImage,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ActorMediaFrame(
                imageUrl: imageUrl,
                title: title,
                badge: duration,
                fallbackIcon: isImage
                    ? Icons.photo_camera_back_outlined
                    : Icons.movie_creation_outlined,
                aspectRatio: category == 'Headshots' ? 4 / 5 : 16 / 10,
              ),
              const SizedBox(height: 12),
              CoreSecondaryButton(
                icon: Icons.close_rounded,
                label: 'Close',
                compact: true,
                onTap: () => Navigator.pop(dialogContext),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _mimeTypeFor(PlatformFile file) {
    final extension = (file.extension ?? '').toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'mp4' => 'video/mp4',
      _ => 'application/octet-stream',
    };
  }

  String _categoryFor(String mimeType) {
    if (mimeType.startsWith('image/')) return 'headshot';
    return 'showreel';
  }

  String _titleFor(String filename) {
    final withoutExtension = filename.replaceFirst(RegExp(r'\.[^.]+$'), '');
    final cleaned = withoutExtension.replaceAll(RegExp(r'[_-]+'), ' ').trim();
    if (cleaned.length >= 2) return cleaned;
    return 'Portfolio media';
  }

  String _friendlyError(Object? error) {
    if (error is ApiException) {
      return switch (error.code) {
        'auth.required' ||
        'auth.invalid_token' =>
          'Sign in to manage portfolio media.',
        'validation.invalid' =>
          'Live data unavailable — showing preview data. Complete your talent profile before adding portfolio media.',
        'network.offline' =>
          'Live data unavailable — showing preview data. Check your connection and retry.',
        _ => 'Live data unavailable — showing preview data.',
      };
    }
    return 'Live data unavailable — showing preview data.';
  }
}

class _PortfolioFallbackGrid extends StatelessWidget {
  final String query;
  final String filter;
  final String warning;

  const _PortfolioFallbackGrid({
    required this.query,
    required this.filter,
    required this.warning,
  });

  @override
  Widget build(BuildContext context) {
    final store = ActorTalentDemoStore.instance;
    final items = store.portfolioItems.where((item) {
      final matchQuery = query.trim().isEmpty ||
          item.title.toLowerCase().contains(query.toLowerCase()) ||
          item.category.toLowerCase().contains(query.toLowerCase());
      final matchFilter = filter == 'All' || item.category == filter;
      return matchQuery && matchFilter;
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InlineWarning(message: warning),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const CoreEmptyState(
            icon: Icons.collections_outlined,
            title: 'No media found',
            message: 'Change the filter or upload a new clip.',
          )
        else
          ActorResponsiveGrid(
            minWidth: 230,
            children: [
              for (final item in items)
                _DemoPortfolioCard(
                  item: item,
                  onCover: () {
                    store.setCover(item.id);
                    actorSnack(context, '${item.title} is now preview cover');
                  },
                ),
            ],
          ),
      ],
    );
  }
}

class _DemoPortfolioCard extends StatelessWidget {
  final ActorPortfolioItem item;
  final VoidCallback onCover;

  const _DemoPortfolioCard({
    required this.item,
    required this.onCover,
  });

  @override
  Widget build(BuildContext context) {
    return _PortfolioCard(
      title: item.title,
      category: item.category,
      duration: item.duration,
      status: item.status,
      imageUrl: item.imageUrl,
      cover: item.cover,
      isImage: item.category == 'Headshots',
      onPreview: () => _showDemoPreview(context, item),
      onCover: onCover,
    );
  }

  void _showDemoPreview(BuildContext context, ActorPortfolioItem item) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ActorMediaFrame(
                imageUrl: item.imageUrl,
                title: item.title,
                badge: item.duration,
                fallbackIcon: Icons.movie_creation_outlined,
                aspectRatio: item.category == 'Headshots' ? 4 / 5 : 16 / 10,
              ),
              const SizedBox(height: 12),
              CoreSecondaryButton(
                icon: Icons.close_rounded,
                label: 'Close',
                compact: true,
                onTap: () => Navigator.pop(dialogContext),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortfolioCard extends StatelessWidget {
  final String title;
  final String category;
  final String duration;
  final String status;
  final String imageUrl;
  final bool cover;
  final bool isImage;
  final bool busy;
  final VoidCallback onPreview;
  final VoidCallback onCover;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback? onDelete;

  const _PortfolioCard({
    required this.title,
    required this.category,
    required this.duration,
    required this.status,
    required this.imageUrl,
    required this.cover,
    required this.isImage,
    required this.onPreview,
    required this.onCover,
    this.busy = false,
    this.onMoveUp,
    this.onMoveDown,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Opacity(
      opacity: busy ? 0.62 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ActorMediaFrame(
            imageUrl: imageUrl,
            title: title,
            badge: duration,
            fallbackIcon: isImage
                ? Icons.photo_camera_back_outlined
                : Icons.movie_creation_outlined,
            aspectRatio: category == 'Headshots' ? 4 / 5 : 16 / 10,
            compact: true,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (cover) StatusChip(label: 'Cover', color: colors.goldMid),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              StatusChip(label: category, color: colors.infoBlue),
              StatusChip(
                label: status,
                color: status == 'Public' ? colors.success : colors.goldMid,
              ),
              StatusChip(label: 'Watermarked', color: colors.infoPurple),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.visibility_outlined,
                  label: 'Preview',
                  compact: true,
                  onTap: busy ? null : onPreview,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: Icons.star_outline_rounded,
                  label: cover ? 'Cover' : 'Cover',
                  compact: true,
                  loading: busy,
                  onTap: busy ? null : onCover,
                ),
              ),
            ],
          ),
          if (onMoveUp != null || onMoveDown != null || onDelete != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onMoveUp != null)
                  CoreSecondaryButton(
                    icon: Icons.keyboard_arrow_up_rounded,
                    label: 'Up',
                    compact: true,
                    onTap: busy ? null : onMoveUp,
                  ),
                if (onMoveDown != null)
                  CoreSecondaryButton(
                    icon: Icons.keyboard_arrow_down_rounded,
                    label: 'Down',
                    compact: true,
                    onTap: busy ? null : onMoveDown,
                  ),
                if (onDelete != null)
                  CoreSecondaryButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Remove',
                    compact: true,
                    onTap: busy ? null : onDelete,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PortfolioLoadingState extends StatelessWidget {
  const _PortfolioLoadingState();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: colors.goldMid),
            const SizedBox(height: 12),
            Text(
              'Loading live portfolio...',
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineWarning extends StatelessWidget {
  final String message;

  const _InlineWarning({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.goldMid.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.goldMid.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: colors.goldMid, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
