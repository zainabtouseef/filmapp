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
import '../../actor_talent/widgets/actor_talent_components.dart';

class MD03PortfolioCategoriesScreen extends StatefulWidget {
  const MD03PortfolioCategoriesScreen({super.key});

  @override
  State<MD03PortfolioCategoriesScreen> createState() =>
      _MD03PortfolioCategoriesScreenState();
}

class _MD03PortfolioCategoriesScreenState
    extends State<MD03PortfolioCategoriesScreen> {
  String _filter = 'All';
  Future<List<MarketplacePortfolioItem>>? _itemsFuture;
  bool _uploading = false;
  String? _busyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_itemsFuture != null) return;
    final auth = AuthScope.maybeOf(context);
    _itemsFuture = auth?.portfolioItems(profileType: 'model');
  }

  void _reload() {
    final auth = AuthScope.maybeOf(context);
    if (auth == null) return;
    _itemsFuture = auth.portfolioItems(profileType: 'model');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ActorSectionCard(
          title: 'Model Portfolio Standard',
          icon: Icons.photo_camera_front_outlined,
          selected: true,
          child: ActorTwoColumn(
            left: const ActorMediaFrame(
              imageUrl: '',
              title: 'Director-facing model profile',
              badge: 'Backend media',
              fallbackIcon: Icons.style_outlined,
              aspectRatio: 16 / 10,
            ),
            right: const Column(
              children: [
                ActorInfoRow(
                  icon: Icons.verified_user_outlined,
                  label: 'Identity',
                  value: 'Linked to talent KYC',
                ),
                ActorInfoRow(
                  icon: Icons.visibility_outlined,
                  label: 'Visibility',
                  value: 'Publish each asset separately',
                ),
                ActorInfoRow(
                  icon: Icons.category_outlined,
                  label: 'Director use',
                  value: 'Casting filters and shortlist media',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ActorSectionCard(
          title: 'Portfolio Library',
          icon: Icons.photo_library_outlined,
          actionText: _uploading ? 'Uploading...' : 'Upload',
          onActionTap: _uploading ? null : _uploadMedia,
          child: _itemsFuture == null
              ? const CoreEmptyState(
                  icon: Icons.cloud_sync_outlined,
                  title: 'Sign in to load model portfolio',
                  message:
                      'Portfolio media is fetched from backend model portfolio records.',
                )
              : FutureBuilder<List<MarketplacePortfolioItem>>(
                  future: _itemsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const InlineNotice(
                        message: 'Loading live model portfolio...',
                        icon: Icons.hourglass_top_rounded,
                      );
                    }
                    if (snapshot.hasError) {
                      return CoreEmptyState(
                        icon: Icons.cloud_off_outlined,
                        title: 'Portfolio unavailable',
                        message: 'Could not load live model portfolio media.',
                        actionLabel: 'Try again',
                        onAction: () => setState(_reload),
                      );
                    }
                    final all = snapshot.data ?? const [];
                    final categories = <String>{
                      'All',
                      ...all.map((item) => item.displayCategory),
                    }.toList();
                    final items = all
                        .where((item) =>
                            _filter == 'All' || item.displayCategory == _filter)
                        .toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CategoryFilters(
                          categories: categories,
                          selected: _filter,
                          onSelected: _setFilter,
                        ),
                        const SizedBox(height: 12),
                        if (items.isEmpty)
                          CoreEmptyState(
                            icon: Icons.photo_library_outlined,
                            title: all.isEmpty
                                ? 'Portfolio is empty'
                                : 'No assets in this category',
                            message:
                                'Upload current headshots, full-length frames, editorial work, or campaign stills.',
                            actionLabel: all.isEmpty ? 'Upload asset' : null,
                            onAction: all.isEmpty ? _uploadMedia : null,
                          )
                        else
                          ActorResponsiveGrid(
                            minWidth: 230,
                            children: [
                              for (final item in items)
                                _LivePortfolioCard(
                                  item: item,
                                  busy: _busyId == item.publicId,
                                  onVisibility: () => _updateItem(
                                    item,
                                    status: item.status == 'published'
                                        ? 'draft'
                                        : 'published',
                                  ),
                                  onCover: () =>
                                      _updateItem(item, isCover: true),
                                ),
                            ],
                          ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _setFilter(String value) => setState(() => _filter = value);

  Future<void> _updateItem(
    MarketplacePortfolioItem item, {
    String? status,
    bool? isCover,
  }) async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null) return;
    setState(() => _busyId = item.publicId);
    try {
      await auth.updatePortfolioItem(
        publicId: item.publicId,
        status: status,
        isCover: isCover,
      );
      if (!mounted) return;
      setState(_reload);
      actorSnack(
        context,
        isCover == true
            ? '${item.title} set as model cover'
            : '${item.title} visibility updated',
      );
    } catch (error) {
      if (mounted) actorSnack(context, _friendlyError(error));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _uploadMedia() async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null) {
      actorSnack(context, 'Sign in to upload model portfolio media');
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'mp4'],
      withData: true,
    );
    final file = result?.files.single;
    if (file == null || file.bytes == null) return;
    final mimeType = _mimeTypeFor(file);
    setState(() => _uploading = true);
    try {
      final uploaded = await auth.uploadFile(
        purpose: 'profile_media',
        file: PickedFileData(
          name: file.name,
          mimeType: mimeType,
          bytes: file.bytes!,
        ),
      );
      await _createWhenReady(
        auth: auth,
        fileId: uploaded.publicId,
        title: _titleFor(file.name),
        category: _categoryFor(file.name, mimeType),
      );
      if (!mounted) return;
      setState(_reload);
      actorSnack(context, 'Portfolio asset uploaded for model discovery');
    } catch (error) {
      if (mounted) actorSnack(context, _friendlyError(error));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _createWhenReady({
    required AuthController auth,
    required String fileId,
    required String title,
    required String category,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt < 6; attempt += 1) {
      try {
        await auth.createPortfolioItem(
          profileType: 'model',
          title: title,
          category: category,
          fileId: fileId,
          status: 'published',
        );
        return;
      } on ApiException catch (error) {
        lastError = error;
        final waiting = error.fields.containsKey('file_id') ||
            error.message.toLowerCase().contains('ready') ||
            error.message.toLowerCase().contains('clean');
        if (!waiting || attempt == 5) rethrow;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
    throw lastError ?? StateError('Portfolio upload failed');
  }
}

class _CategoryFilters extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const _CategoryFilters({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final category in categories)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CoreChip(
                label: category,
                selected: selected == category,
                onTap: () => onSelected(category),
              ),
            ),
        ],
      ),
    );
  }
}

class _LivePortfolioCard extends StatelessWidget {
  final MarketplacePortfolioItem item;
  final bool busy;
  final VoidCallback onVisibility;
  final VoidCallback onCover;

  const _LivePortfolioCard({
    required this.item,
    required this.busy,
    required this.onVisibility,
    required this.onCover,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final imageUrl = item.thumbnailFile?.publicUrl ??
        item.file?.publicUrl ??
        item.thumbnailFile?.downloadUrl ??
        item.file?.downloadUrl ??
        '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ActorMediaFrame(
          imageUrl: imageUrl,
          title: item.title,
          badge: item.displayCategory,
          fallbackIcon:
              item.isImage ? Icons.photo_outlined : Icons.movie_outlined,
          aspectRatio: item.displayCategory == 'Headshots' ? 4 / 5 : 16 / 10,
          compact: true,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardLabel.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (item.isCover) StatusChip(label: 'Cover', color: colors.goldMid),
          ],
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            StatusChip(
              label: item.displayStatus,
              color:
                  item.status == 'published' ? colors.success : colors.goldMid,
            ),
            StatusChip(
              label: _titleCase(item.moderationStatus),
              color: colors.infoBlue,
            ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: CoreSecondaryButton(
                icon: Icons.visibility_outlined,
                label: item.status == 'published' ? 'Unpublish' : 'Publish',
                compact: true,
                onTap: busy ? null : onVisibility,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CorePrimaryButton(
                icon: Icons.star_outline_rounded,
                label: item.isCover ? 'Cover' : 'Set cover',
                compact: true,
                onTap: busy || item.isCover ? null : onCover,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _mimeTypeFor(PlatformFile file) {
  return switch ((file.extension ?? '').toLowerCase()) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'mp4' => 'video/mp4',
    _ => 'application/octet-stream',
  };
}

String _categoryFor(String filename, String mimeType) {
  final name = filename.toLowerCase();
  if (mimeType.startsWith('video/')) return 'campaign_video';
  if (name.contains('head')) return 'headshots';
  if (name.contains('full')) return 'full_length';
  if (name.contains('beauty')) return 'beauty';
  if (name.contains('product')) return 'product';
  if (name.contains('bridal') || name.contains('ethnic')) return 'ethnic_wear';
  return 'editorial';
}

String _titleFor(String filename) {
  final clean = filename
      .replaceFirst(RegExp(r'\.[^.]+$'), '')
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .trim();
  return clean.length >= 2 ? clean : 'Model portfolio asset';
}

String _friendlyError(Object error) {
  if (error is ApiException) {
    return switch (error.code) {
      'auth.required' ||
      'auth.invalid_token' =>
        'Sign in to manage model portfolio media.',
      'validation.invalid' =>
        'Complete the talent and model profile before uploading media.',
      'network.offline' => 'Portfolio is unavailable offline.',
      _ => error.message,
    };
  }
  return 'Could not update model portfolio. Try again.';
}

String _titleCase(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
