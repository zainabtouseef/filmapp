import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/marketplace/marketplace_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/open_url.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/uploads/upload_repository.dart';
import '../../../shared/credits/past_roles_section.dart';
import '../../actor_talent/widgets/actor_talent_components.dart';

const _maxPerKind = 3;
const _profileType = 'model';

enum _SlotKind {
  image,
  video;

  String get label => this == _SlotKind.image ? 'Photo' : 'Video';
}

/// MD-03 Portfolio
///
/// Same 3-photo + 3-video slot pattern as the Actor/Talent portfolio
/// screen (AT-03), backed by the same generic PortfolioItem API with
/// `profile_type: 'model'`.
class MD03PortfolioCategoriesScreen extends StatefulWidget {
  const MD03PortfolioCategoriesScreen({super.key});

  @override
  State<MD03PortfolioCategoriesScreen> createState() =>
      _MD03PortfolioCategoriesScreenState();
}

class _MD03PortfolioCategoriesScreenState
    extends State<MD03PortfolioCategoriesScreen> {
  Future<List<MarketplacePortfolioItem>>? _itemsFuture;
  bool _started = false;
  String? _busySlotKey;

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
          : controller.portfolioItems(profileType: _profileType);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ActorSectionCard(
          title: 'Portfolio',
          icon: Icons.video_library_outlined,
          child: _buildPortfolioBody(context),
        ),
        const SizedBox(height: 12),
        const PastRolesSection(
          profileType: 'model',
          sectionTitle: 'Past Roles',
          emptyMessage:
              'Add your past roles — campaigns, productions and a cover photo.',
        ),
      ],
    );
  }

  Widget _buildPortfolioBody(BuildContext context) {
    return FutureBuilder<List<MarketplacePortfolioItem>>(
      future: _itemsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _PortfolioLoadingState();
        }
        if (snapshot.hasError) {
          return _PortfolioError(
            message: _friendlyError(snapshot.error),
            onRetry: _reload,
          );
        }
        final items = List<MarketplacePortfolioItem>.from(
          snapshot.data ?? const [],
        )..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        final images = items.where((item) => item.isImage).toList();
        final videos = items.where((item) => !item.isImage).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add up to 3 photos and 3 videos. Directors and brands see these on your public profile.',
              style: AppTextStyles.smallMeta.copyWith(
                color: context.appColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            _SlotSectionLabel(label: 'Photos', count: images.length),
            const SizedBox(height: 8),
            _SlotRow(
              kind: _SlotKind.image,
              items: images,
              busySlotKey: _busySlotKey,
              onAdd: (index) => _addSlot(_SlotKind.image, index),
              onReplace: (item, index) =>
                  _replaceSlot(_SlotKind.image, item, index),
              onRemove: (item, index) =>
                  _removeSlot(_SlotKind.image, item, index),
            ),
            const SizedBox(height: 18),
            _SlotSectionLabel(label: 'Videos', count: videos.length),
            const SizedBox(height: 8),
            _SlotRow(
              kind: _SlotKind.video,
              items: videos,
              busySlotKey: _busySlotKey,
              onAdd: (index) => _addSlot(_SlotKind.video, index),
              onReplace: (item, index) =>
                  _replaceSlot(_SlotKind.video, item, index),
              onRemove: (item, index) =>
                  _removeSlot(_SlotKind.video, item, index),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addSlot(_SlotKind kind, int index) async {
    final controller = AuthScope.maybeOf(context);
    if (controller == null) {
      actorSnack(context, 'Sign in to upload portfolio media');
      return;
    }
    final picked = await _pickFile(kind);
    if (picked == null) return;
    final slotKey = '${kind.name}-$index';
    setState(() => _busySlotKey = slotKey);
    try {
      final uploaded = await controller.uploadFile(
        purpose: 'profile_media',
        file: picked,
      );
      await _createWhenReady(
        controller: controller,
        kind: kind,
        index: index,
        fileId: uploaded.publicId,
      );
      if (!mounted) return;
      actorSnack(context, '${kind.label} added to your portfolio');
      _reload();
    } on ApiException catch (error) {
      if (!mounted) return;
      actorSnack(context, _friendlyError(error));
    } finally {
      if (mounted) setState(() => _busySlotKey = null);
    }
  }

  Future<void> _replaceSlot(
    _SlotKind kind,
    MarketplacePortfolioItem item,
    int index,
  ) async {
    final controller = AuthScope.maybeOf(context);
    if (controller == null) return;
    final picked = await _pickFile(kind);
    if (picked == null) return;
    final slotKey = '${kind.name}-$index';
    setState(() => _busySlotKey = slotKey);
    try {
      final uploaded = await controller.uploadFile(
        purpose: 'profile_media',
        file: picked,
      );
      await controller.updatePortfolioItem(
        publicId: item.publicId,
        fileId: uploaded.publicId,
        title: picked.name,
      );
      if (!mounted) return;
      actorSnack(context, '${kind.label} replaced');
      _reload();
    } on ApiException catch (error) {
      if (!mounted) return;
      actorSnack(context, _friendlyError(error));
    } finally {
      if (mounted) setState(() => _busySlotKey = null);
    }
  }

  Future<void> _removeSlot(
    _SlotKind kind,
    MarketplacePortfolioItem item,
    int index,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove ${kind.label.toLowerCase()}?'),
        content: Text(
          '${item.title} will be removed from your public portfolio.',
        ),
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
    );
    if (confirmed != true || !mounted) return;
    final controller = AuthScope.maybeOf(context);
    if (controller == null) return;
    final slotKey = '${kind.name}-$index';
    setState(() => _busySlotKey = slotKey);
    try {
      await controller.deletePortfolioItem(item.publicId);
      if (!mounted) return;
      actorSnack(context, '${kind.label} removed');
      _reload();
    } on ApiException catch (error) {
      if (!mounted) return;
      actorSnack(context, _friendlyError(error));
    } finally {
      if (mounted) setState(() => _busySlotKey = null);
    }
  }

  Future<void> _createWhenReady({
    required AuthController controller,
    required _SlotKind kind,
    required int index,
    required String fileId,
  }) async {
    ApiException? lastError;
    for (var attempt = 0; attempt < 6; attempt += 1) {
      try {
        await controller.createPortfolioItem(
          profileType: _profileType,
          title: '${kind.label} ${index + 1}',
          category: kind.name,
          fileId: fileId,
          sortOrder: (index + 1) * 10,
        );
        return;
      } on ApiException catch (error) {
        lastError = error;
        final waitingForScan = error.fields.containsKey('file_id') &&
            (error.message.toLowerCase().contains('clean') ||
                error.message.toLowerCase().contains('ready'));
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

  Future<PickedFileData?> _pickFile(_SlotKind kind) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: kind == _SlotKind.image
          ? const ['jpg', 'jpeg', 'png', 'webp']
          : const ['mp4'],
      withData: true,
    );
    final item = result?.files.single;
    final bytes = item?.bytes;
    if (item == null || bytes == null) return null;
    return PickedFileData(
      name: item.name,
      mimeType: kind == _SlotKind.image
          ? switch (item.extension?.toLowerCase()) {
              'png' => 'image/png',
              'webp' => 'image/webp',
              _ => 'image/jpeg',
            }
          : 'video/mp4',
      bytes: bytes,
    );
  }

  String _friendlyError(Object? error) {
    if (error is ApiException) {
      return switch (error.code) {
        'auth.required' ||
        'auth.invalid_token' =>
          'Sign in to manage portfolio media.',
        'validation.invalid' => error.fields['file_id']?.join(' ') ??
            'Complete your model profile before adding portfolio media.',
        'network.offline' =>
          'Portfolio media is unavailable offline. Check your connection and retry.',
        _ => 'Could not load portfolio media. Try again.',
      };
    }
    return 'Could not load portfolio media. Try again.';
  }
}

class _SlotSectionLabel extends StatelessWidget {
  final String label;
  final int count;

  const _SlotSectionLabel({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Text(
      '$label ($count/$_maxPerKind)',
      style: AppTextStyles.cardLabel.copyWith(
        color: colors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  final _SlotKind kind;
  final List<MarketplacePortfolioItem> items;
  final String? busySlotKey;
  final void Function(int index) onAdd;
  final void Function(MarketplacePortfolioItem item, int index) onReplace;
  final void Function(MarketplacePortfolioItem item, int index) onRemove;

  const _SlotRow({
    required this.kind,
    required this.items,
    required this.busySlotKey,
    required this.onAdd,
    required this.onReplace,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < _maxPerKind; index += 1) ...[
          if (index > 0) const SizedBox(width: 10),
          Expanded(
            child: _SlotTile(
              kind: kind,
              index: index,
              item: index < items.length ? items[index] : null,
              busy: busySlotKey == '${kind.name}-$index',
              onAdd: () => onAdd(index),
              onReplace: () => onReplace(items[index], index),
              onRemove: () => onRemove(items[index], index),
            ),
          ),
        ],
      ],
    );
  }
}

class _SlotTile extends StatelessWidget {
  final _SlotKind kind;
  final int index;
  final MarketplacePortfolioItem? item;
  final bool busy;
  final VoidCallback onAdd;
  final VoidCallback onReplace;
  final VoidCallback onRemove;

  const _SlotTile({
    required this.kind,
    required this.index,
    required this.item,
    required this.busy,
    required this.onAdd,
    required this.onReplace,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final current = item;
    final filled = current != null;
    final imageUrl =
        current?.thumbnailFile?.publicUrl ?? current?.file?.publicUrl;
    return GestureDetector(
      onTap: busy
          ? null
          : filled
              ? () => _showSlotActions(context)
              : onAdd,
      child: AspectRatio(
        aspectRatio: kind == _SlotKind.image ? 3 / 4 : 16 / 10,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: colors.softSurface,
            border: Border.all(color: colors.border),
            image: filled && kind == _SlotKind.image && imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(imageUrl),
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
              : !filled
                  ? Icon(
                      kind == _SlotKind.image
                          ? Icons.add_a_photo_outlined
                          : Icons.video_call_outlined,
                      color: colors.goldDark,
                      size: 22,
                    )
                  : kind == _SlotKind.video
                      ? Center(
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        )
                      : null,
        ),
      ),
    );
  }

  void _showSlotActions(BuildContext context) {
    final current = item;
    if (current == null) return;
    final url = current.file?.publicUrl;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${kind.label} ${index + 1}'),
        content: Text(current.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          if (url != null)
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                openUrlInNewTab(url);
              },
              child: const Text('View'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onRemove();
            },
            child: const Text('Remove'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onReplace();
            },
            child: const Text('Replace'),
          ),
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

class _PortfolioError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PortfolioError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CoreEmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Could not load portfolio',
          message: message,
        ),
        const SizedBox(height: 10),
        CoreSecondaryButton(
          icon: Icons.refresh_rounded,
          label: 'Try again',
          compact: true,
          onTap: onRetry,
        ),
      ],
    );
  }
}
