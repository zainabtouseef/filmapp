import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/projects/project_models.dart';
import '../../../core/projects/projects_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../director_producer/widgets/dp_glass_card.dart';
import '../../director_producer/widgets/dp_holographic_button.dart';
import '../../director_producer/widgets/dp_layout_helpers.dart';
import '../../director_producer/widgets/dp_status_chip.dart';
import '../widgets/cinema_native_player_stub.dart'
    if (dart.library.html) '../widgets/cinema_native_player_web.dart';

class GeneralPublicCinemaScreen extends StatefulWidget {
  const GeneralPublicCinemaScreen({super.key});

  @override
  State<GeneralPublicCinemaScreen> createState() =>
      _GeneralPublicCinemaScreenState();
}

class _GeneralPublicCinemaScreenState extends State<GeneralPublicCinemaScreen> {
  final _searchController = TextEditingController();
  Future<List<PublicCinemaItem>>? _future;
  String _kind = 'all';
  String _type = 'all';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<PublicCinemaItem>> _load() async {
    final controller = ProjectsScope.maybeOf(context);
    if (controller == null) {
      throw const ApiException(
        code: 'projects.scope_missing',
        message: 'Project service is not available in this session.',
      );
    }
    return controller.publicCinema();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PublicCinemaItem>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const DPGlassCard(
            child: SizedBox(
              height: 260,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        if (snapshot.hasError) {
          return DPGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _friendlyError(snapshot.error),
                  style: AppTextStyles.cardTitle.copyWith(
                    color: context.appColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                DPHolographicButton(
                  label: 'Retry',
                  icon: Icons.refresh_rounded,
                  onTap: () => setState(() => _future = _load()),
                ),
              ],
            ),
          );
        }
        final allItems = snapshot.data ?? const <PublicCinemaItem>[];
        final items = _filtered(allItems);
        final featured = items.isNotEmpty
            ? items.first
            : (allItems.isNotEmpty ? allItems.first : null);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CinemaHero(
              item: featured,
              onPlay: featured == null ? null : () => _play(featured),
            ),
            const SizedBox(height: 14),
            _CinemaToolbar(
              controller: _searchController,
              kind: _kind,
              type: _type,
              types: _typesFor(allItems),
              onChanged: () => setState(() {}),
              onKindChanged: (kind) => setState(() => _kind = kind),
              onTypeChanged: (type) => setState(() => _type = type),
            ),
            const SizedBox(height: 14),
            if (allItems.isEmpty)
              _CinemaEmptyState(
                  onRefresh: () => setState(() => _future = _load()))
            else if (items.isEmpty)
              _CinemaNoResults(onClear: _clearFilters)
            else
              _CinemaRows(items: items, onPlay: _play),
          ],
        );
      },
    );
  }

  List<PublicCinemaItem> _filtered(List<PublicCinemaItem> items) {
    final query = _searchController.text.trim().toLowerCase();
    return items.where((item) {
      if (_kind != 'all' && item.kind != _kind) return false;
      if (_type != 'all' && item.project.projectType != _type) return false;
      if (query.isEmpty) return true;
      final haystack = [
        item.title,
        item.project.title,
        item.project.projectType,
        item.cityLabel,
        item.uploadedByName ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  List<String> _typesFor(List<PublicCinemaItem> items) {
    final types = items.map((item) => item.project.projectType).toSet().toList()
      ..sort();
    return types;
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _kind = 'all';
      _type = 'all';
    });
  }

  void _play(PublicCinemaItem item) {
    final rawUrl = item.mediaUrl;
    if (rawUrl == null || rawUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('This media file is not publicly playable yet.')),
      );
      return;
    }
    final url = _absoluteUrl(rawUrl);
    showDialog<void>(
      context: context,
      builder: (context) => _CinemaPlayerDialog(item: item, mediaUrl: url),
    );
  }

  String _absoluteUrl(String value) {
    final uri = Uri.parse(value);
    if (uri.hasScheme) return value;
    return Uri.base.resolve(value).toString();
  }

  String _friendlyError(Object? error) {
    if (error is ApiException) return error.message;
    return 'Could not load the public cinema feed from the database.';
  }
}

class _CinemaHero extends StatelessWidget {
  final PublicCinemaItem? item;
  final VoidCallback? onPlay;

  const _CinemaHero({required this.item, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF080808),
            colors.goldDark.withValues(alpha: 0.78),
            const Color(0xFF16110A),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CINECONNECT CINEMA',
            style: AppTextStyles.smallMeta.copyWith(
              color: Colors.white70,
              letterSpacing: 2.4,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item?.project.title ?? 'Trailers, OSTs and campaign films',
            style: AppTextStyles.sectionHeaderStyle.copyWith(
              color: Colors.white,
              fontSize: 34,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(_subtitle,
              style: AppTextStyles.cardLabel.copyWith(color: Colors.white70)),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              DPHolographicButton(
                label: item?.isOst == true ? 'Play OST' : 'Play trailer',
                icon: item?.isOst == true
                    ? Icons.library_music_rounded
                    : Icons.play_arrow_rounded,
                onTap: onPlay,
              ),
              const DPStatusChip(
                label: 'Live from project uploads',
                tone: DpTone.success,
                icon: Icons.storage_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _subtitle {
    final media = item;
    if (media == null) {
      return 'When directors upload project trailers or soundtrack tracks, they appear here from the live database.';
    }
    return '${media.displayKind} · ${media.cityLabel} · ${_titleCase(media.project.projectType)}';
  }
}

class _CinemaToolbar extends StatelessWidget {
  final TextEditingController controller;
  final String kind;
  final String type;
  final List<String> types;
  final VoidCallback onChanged;
  final ValueChanged<String> onKindChanged;
  final ValueChanged<String> onTypeChanged;

  const _CinemaToolbar({
    required this.controller,
    required this.kind,
    required this.type,
    required this.types,
    required this.onChanged,
    required this.onKindChanged,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DPGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'Search trailers, OSTs, cities or project titles...',
              filled: true,
              fillColor: colors.surface.withValues(alpha: 0.62),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: colors.border),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'All',
                selected: kind == 'all',
                onTap: () => onKindChanged('all'),
              ),
              _FilterChip(
                label: 'Trailers',
                selected: kind == 'trailer',
                onTap: () => onKindChanged('trailer'),
              ),
              _FilterChip(
                label: 'OST',
                selected: kind == 'ost',
                onTap: () => onKindChanged('ost'),
              ),
              for (final item in types)
                _FilterChip(
                  label: _titleCase(item),
                  selected: type == item,
                  onTap: () => onTypeChanged(type == item ? 'all' : item),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CinemaRows extends StatelessWidget {
  final List<PublicCinemaItem> items;
  final ValueChanged<PublicCinemaItem> onPlay;

  const _CinemaRows({required this.items, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final trailers = items.where((item) => item.isTrailer).toList();
    final ost = items.where((item) => item.isOst).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (trailers.isNotEmpty) ...[
          _CinemaShelf(
              title: 'Now streaming trailers', items: trailers, onPlay: onPlay),
          const SizedBox(height: 18),
        ],
        if (ost.isNotEmpty) ...[
          _CinemaShelf(
              title: 'Soundtrack / OST lounge', items: ost, onPlay: onPlay),
          const SizedBox(height: 18),
        ],
        _CinemaShelf(title: 'All cinema media', items: items, onPlay: onPlay),
      ],
    );
  }
}

class _CinemaShelf extends StatelessWidget {
  final String title;
  final List<PublicCinemaItem> items;
  final ValueChanged<PublicCinemaItem> onPlay;

  const _CinemaShelf({
    required this.title,
    required this.items,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.cardTitle.copyWith(
            color: context.appColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 236,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => SizedBox(
              width: 280,
              child: _CinemaCard(
                  item: items[index], onPlay: () => onPlay(items[index])),
            ),
          ),
        ),
      ],
    );
  }
}

class _CinemaCard extends StatelessWidget {
  final PublicCinemaItem item;
  final VoidCallback onPlay;

  const _CinemaCard({required this.item, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final thumbnailUrl = item.externalThumbnailUrl;
    return GestureDetector(
      onTap: onPlay,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  image: thumbnailUrl == null || thumbnailUrl.isEmpty
                      ? null
                      : DecorationImage(
                          image: NetworkImage(thumbnailUrl),
                          fit: BoxFit.cover,
                        ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black,
                      item.isOst
                          ? colors.goldDark.withValues(alpha: 0.78)
                          : const Color(0xFF202020),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        item.isOst
                            ? Icons.graphic_eq_rounded
                            : Icons.play_circle_fill_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 54,
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: DPStatusChip(
                        label: item.displayKind,
                        tone: item.isOst ? DpTone.warning : DpTone.success,
                      ),
                    ),
                    if (item.externalDurationSeconds != null)
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.62),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _durationLabel(item.externalDurationSeconds!),
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  AppTextStyles.cardTitle.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              '${item.project.title} · ${item.cityLabel}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _CinemaPlayerDialog extends StatelessWidget {
  final PublicCinemaItem item;
  final String mediaUrl;

  const _CinemaPlayerDialog({required this.item, required this.mediaUrl});

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.sectionHeaderStyle.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${item.displayKind} · ${item.project.title} · ${item.cityLabel}',
                          style: AppTextStyles.smallMeta.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    color: Colors.white,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.92),
                    child: CinemaNativePlayer(
                      mediaUrl: mediaUrl,
                      video: item.isTrailer,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CinemaEmptyState extends StatelessWidget {
  final VoidCallback onRefresh;

  const _CinemaEmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return DPGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No trailers or OSTs published yet',
            style: AppTextStyles.cardTitle.copyWith(
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          dpText(
            context,
            'Ask a director to open a project room and upload a Trailer or OST. Once the file passes processing, it appears here automatically.',
          ),
          const SizedBox(height: 12),
          DPHolographicButton(
            label: 'Refresh cinema feed',
            icon: Icons.refresh_rounded,
            onTap: onRefresh,
          ),
        ],
      ),
    );
  }
}

class _CinemaNoResults extends StatelessWidget {
  final VoidCallback onClear;

  const _CinemaNoResults({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return DPGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No cinema matches',
            style: AppTextStyles.cardTitle.copyWith(
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          DPHolographicButton(
            label: 'Clear filters',
            icon: Icons.filter_alt_off_rounded,
            onTap: onClear,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected
              ? colors.activeChipGradient
              : colors.inactiveChipGradient,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? colors.goldMid : colors.border),
        ),
        child: Text(
          label,
          style: AppTextStyles.smallMeta.copyWith(
            color: selected ? colors.textPrimary : colors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return value
      .split(RegExp(r'[_\s-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _durationLabel(int seconds) {
  final minutes = seconds ~/ 60;
  final remaining = seconds % 60;
  return '$minutes:${remaining.toString().padLeft(2, '0')}';
}
