import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/marketplace/marketplace_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/director_producer_demo_data.dart';
import '../models/dp_candidate.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_status_chip.dart';

class DPShortlistBoardScreen extends StatefulWidget {
  const DPShortlistBoardScreen({super.key});

  @override
  State<DPShortlistBoardScreen> createState() => _DPShortlistBoardScreenState();
}

class _DPShortlistBoardScreenState extends State<DPShortlistBoardScreen> {
  Future<MarketplaceShortlistBundle>? _bundleFuture;
  String? _notice;
  String? _mutatingId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bundleFuture ??= _load();
  }

  Future<MarketplaceShortlistBundle> _load() async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null || !auth.isAuthenticated) {
      throw const ApiException(
        code: 'auth.required',
        message: 'Sign in to load live shortlists.',
      );
    }
    return auth.shortlistBundle();
  }

  void _refresh() {
    setState(() {
      _notice = null;
      _bundleFuture = _load();
    });
  }

  Future<void> _deleteSavedSearch(String publicId) async {
    await _mutate(
        publicId, () => AuthScope.of(context).deleteSavedSearch(publicId));
  }

  Future<void> _deleteShortlistItem(String publicId) async {
    await _mutate(
        publicId, () => AuthScope.of(context).deleteShortlistItem(publicId));
  }

  Future<void> _moveShortlistItem(
    MarketplaceShortlistItem item,
    int direction,
  ) async {
    final nextRank = (item.rank + direction).clamp(1, 999);
    await _mutate(
      item.publicId,
      () => AuthScope.of(context).updateShortlistItem(
        publicId: item.publicId,
        rank: nextRank,
      ),
    );
  }

  Future<void> _selectShortlistItem(MarketplaceShortlistItem item) async {
    await _mutate(
      item.publicId,
      () => AuthScope.of(context).updateShortlistItem(
        publicId: item.publicId,
        status: item.status == 'selected' ? 'active' : 'selected',
      ),
    );
  }

  Future<void> _mutate(String id, Future<void> Function() action) async {
    setState(() {
      _mutatingId = id;
      _notice = null;
    });
    try {
      await action();
      if (!mounted) return;
      _refresh();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _notice = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _notice = 'Could not update shortlist right now.');
    } finally {
      if (mounted) setState(() => _mutatingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dpHeaderAction(
          context,
          icon: Icons.manage_search_rounded,
          label: 'Discover',
          onTap: () =>
              Navigator.pushNamed(context, DirectorProducerRoutes.marketplace),
        ),
        const SizedBox(height: 8),
        FutureBuilder<MarketplaceShortlistBundle>(
          future: _bundleFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const DPGlassCard(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return _fallbackBoard(context);
            }
            final bundle = snapshot.data!;
            final hasLiveRows = bundle.savedSearches.isNotEmpty ||
                bundle.shortlists.any((board) => board.items.isNotEmpty);
            if (!hasLiveRows) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DPGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No saved shortlists yet',
                          style: AppTextStyles.sectionHeaderStyle.copyWith(
                            color: context.appColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        dpText(
                          context,
                          'Save searches and shortlist candidates from marketplace discovery.',
                        ),
                        const SizedBox(height: 12),
                        DPHolographicButton(
                          label: 'Open Marketplace',
                          icon: Icons.storefront_outlined,
                          onTap: () => Navigator.pushNamed(
                            context,
                            DirectorProducerRoutes.marketplace,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _fallbackBoard(context, compact: true),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_notice != null) ...[
                  DPStatusChip(label: _notice!, tone: DpTone.warning),
                  const SizedBox(height: 10),
                ],
                _SavedSearchStrip(
                  searches: bundle.savedSearches,
                  mutatingId: _mutatingId,
                  onDelete: _deleteSavedSearch,
                ),
                const SizedBox(height: 12),
                _LiveShortlistColumns(
                  boards: bundle.shortlists,
                  mutatingId: _mutatingId,
                  onDelete: _deleteShortlistItem,
                  onMove: _moveShortlistItem,
                  onSelect: _selectShortlistItem,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _fallbackBoard(BuildContext context, {bool compact = false}) {
    final columns = const ['Talent', 'Models', 'Crew', 'Locations'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
          DPStatusChip(
            label: 'Live shortlists unavailable — showing preview data',
            tone: DpTone.warning,
          ),
          const SizedBox(height: 10),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final width = context.isDesktopWidth
                ? (constraints.maxWidth - 36) / 4
                : 278.0;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final column in columns) ...[
                    SizedBox(
                        width: width,
                        child: _DemoShortlistColumn(category: column)),
                    if (column != columns.last) const SizedBox(width: 12),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SavedSearchStrip extends StatelessWidget {
  final List<MarketplaceSavedSearch> searches;
  final String? mutatingId;
  final ValueChanged<String> onDelete;

  const _SavedSearchStrip({
    required this.searches,
    required this.mutatingId,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DPGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SAVED SEARCHES',
            style: AppTextStyles.sectionHeaderStyle.copyWith(
              color: colors.textPrimary,
              fontSize: 14,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          if (searches.isEmpty)
            dpText(context, 'No saved searches yet.')
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: searches
                  .map(
                    (search) => _SavedSearchPill(
                      search: search,
                      loading: mutatingId == search.publicId,
                      onDelete: () => onDelete(search.publicId),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _SavedSearchPill extends StatelessWidget {
  final MarketplaceSavedSearch search;
  final bool loading;
  final VoidCallback onDelete;

  const _SavedSearchPill({
    required this.search,
    required this.loading,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: colors.surface.withValues(alpha: 0.44),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.manage_search_rounded, color: colors.goldDark, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  search.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      AppTextStyles.label.copyWith(color: colors.textPrimary),
                ),
                Text(
                  search.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Delete search',
            onPressed: loading ? null : onDelete,
            icon: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _LiveShortlistColumns extends StatelessWidget {
  final List<MarketplaceShortlist> boards;
  final String? mutatingId;
  final ValueChanged<String> onDelete;
  final void Function(MarketplaceShortlistItem item, int direction) onMove;
  final ValueChanged<MarketplaceShortlistItem> onSelect;

  const _LiveShortlistColumns({
    required this.boards,
    required this.mutatingId,
    required this.onDelete,
    required this.onMove,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final visibleBoards =
        boards.where((board) => board.items.isNotEmpty).toList();
    if (visibleBoards.isEmpty) {
      return DPGlassCard(
          child: dpText(context, 'No shortlist candidates yet.'));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = context.isDesktopWidth
            ? (constraints.maxWidth - 24) / visibleBoards.length.clamp(1, 3)
            : 300.0;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final board in visibleBoards) ...[
                SizedBox(
                  width: width.clamp(280.0, 390.0),
                  child: _LiveShortlistColumn(
                    board: board,
                    mutatingId: mutatingId,
                    onDelete: onDelete,
                    onMove: onMove,
                    onSelect: onSelect,
                  ),
                ),
                if (board != visibleBoards.last) const SizedBox(width: 12),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _LiveShortlistColumn extends StatelessWidget {
  final MarketplaceShortlist board;
  final String? mutatingId;
  final ValueChanged<String> onDelete;
  final void Function(MarketplaceShortlistItem item, int direction) onMove;
  final ValueChanged<MarketplaceShortlistItem> onSelect;

  const _LiveShortlistColumn({
    required this.board,
    required this.mutatingId,
    required this.onDelete,
    required this.onMove,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DPGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  board.name.toUpperCase(),
                  style: AppTextStyles.sectionHeaderStyle.copyWith(
                    color: colors.textPrimary,
                    fontSize: 14,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              DPStatusChip(label: '${board.items.length}', tone: DpTone.info),
            ],
          ),
          const SizedBox(height: 10),
          ...board.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LiveShortlistCard(
                item: item,
                loading: mutatingId == item.publicId,
                onDelete: () => onDelete(item.publicId),
                onMoveUp: () => onMove(item, -1),
                onMoveDown: () => onMove(item, 1),
                onSelect: () => onSelect(item),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveShortlistCard extends StatelessWidget {
  final MarketplaceShortlistItem item;
  final bool loading;
  final VoidCallback onDelete;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onSelect;

  const _LiveShortlistCard({
    required this.item,
    required this.loading,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final candidate = item.listing.toCandidate();
    final selected = item.status == 'selected';
    return DPGlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: dpText(context, candidate.name, strong: true)),
              DPStatusChip(
                label: selected ? 'Selected' : '#${item.rank}',
                tone: selected ? DpTone.success : DpTone.warning,
              ),
            ],
          ),
          const SizedBox(height: 6),
          dpText(context, '${candidate.city} · ${candidate.rateRange}'),
          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            dpText(context, item.notes!),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniAction(
                icon: Icons.keyboard_arrow_up_rounded,
                label: 'Rank up',
                loading: loading,
                onTap: onMoveUp,
              ),
              _MiniAction(
                icon: Icons.keyboard_arrow_down_rounded,
                label: 'Rank down',
                loading: loading,
                onTap: onMoveDown,
              ),
              _MiniAction(
                icon: selected
                    ? Icons.undo_rounded
                    : Icons.check_circle_outline_rounded,
                label: selected ? 'Unselect' : 'Select',
                loading: loading,
                onTap: onSelect,
              ),
              _MiniAction(
                icon: Icons.delete_outline_rounded,
                label: 'Remove',
                loading: loading,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool loading;
  final VoidCallback onTap;

  const _MiniAction({
    required this.icon,
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DPHolographicButton(
      label: label,
      icon: icon,
      onTap: loading ? null : onTap,
      secondary: true,
    );
  }
}

class _DemoShortlistColumn extends StatelessWidget {
  final String category;

  const _DemoShortlistColumn({required this.category});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final items = DirectorProducerDemoData.candidates
        .where((candidate) => candidate.category == category)
        .take(4)
        .toList();
    return DPGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.toUpperCase(),
            style: AppTextStyles.sectionHeaderStyle.copyWith(
              color: colors.textPrimary,
              fontSize: 14,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DemoShortlistCard(item: item),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoShortlistCard extends StatelessWidget {
  final DpCandidate item;

  const _DemoShortlistCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return DPGlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: dpText(context, item.name, strong: true)),
              DPStatusChip(label: '${item.rating}', tone: DpTone.warning),
            ],
          ),
          const SizedBox(height: 6),
          dpText(context, '${item.city} · ${item.rateRange}'),
          const SizedBox(height: 10),
          DPHolographicButton(
            label: 'Compare',
            icon: Icons.compare_arrows_rounded,
            onTap: () => Navigator.pushNamed(
              context,
              DirectorProducerRoutes.profile,
              arguments: item.id,
            ),
            secondary: true,
          ),
        ],
      ),
    );
  }
}
