import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/marketplace/marketplace_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/tour/tour_target.dart';
import '../../../shared/cards/cine_card_system.dart';
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
  final Set<String> _selectedIds = <String>{};

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

  void _toggleBulkSelection(String publicId) {
    setState(() {
      if (!_selectedIds.add(publicId)) _selectedIds.remove(publicId);
    });
  }

  Future<void> _removeSelected() async {
    if (_selectedIds.isEmpty) return;
    final ids = _selectedIds.toList();
    setState(() {
      _mutatingId = 'bulk';
      _notice = null;
    });
    try {
      final auth = AuthScope.of(context);
      await Future.wait(ids.map(auth.deleteShortlistItem));
      if (!mounted) return;
      _selectedIds.clear();
      _refresh();
    } on ApiException catch (error) {
      if (mounted) setState(() => _notice = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _notice = 'Could not remove the selected profiles.');
      }
    } finally {
      if (mounted) setState(() => _mutatingId = null);
    }
  }

  void _openInviteQueue(MarketplaceShortlistBundle bundle) {
    final selected =
        <({MarketplaceShortlist board, MarketplaceShortlistItem item})>[];
    for (final board in bundle.shortlists) {
      for (final item in board.items) {
        if (_selectedIds.contains(item.publicId)) {
          selected.add((board: board, item: item));
        }
      }
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: DPGlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invite selected profiles',
                  style: AppTextStyles.cardTitle.copyWith(
                    color: context.appColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                dpText(
                  context,
                  'Open each prefilled booking request to confirm dates and commercial terms.',
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final entry in selected)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.person_add_alt_1_rounded),
                            title: Text(entry.item.listing.title),
                            subtitle: Text(entry.board.name),
                            trailing: const Icon(Icons.arrow_forward_rounded),
                            onTap: () {
                              Navigator.pop(sheetContext);
                              Navigator.pushNamed(
                                context,
                                DirectorProducerRoutes.bookingRequest,
                                arguments: {
                                  'candidateId': entry.item.listing.publicId,
                                  if (entry.board.projectId != null)
                                    'projectId': entry.board.projectId,
                                  'category': entry.item.listing.listingType,
                                },
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
              return const Column(
                children: [
                  SkeletonCard(height: 80),
                  SizedBox(height: 10),
                  SkeletonCard(height: 190),
                  SizedBox(height: 10),
                  SkeletonCard(height: 190),
                ],
              );
            }
            if (snapshot.hasError) {
              return CoreEmptyState(
                icon: Icons.cloud_off_rounded,
                title: 'Shortlists unavailable',
                message:
                    'Could not load saved searches and shortlist boards from the database. Check the API connection and try again.',
                actionLabel: 'Retry',
                onAction: _refresh,
              );
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
                if (_selectedIds.isNotEmpty) ...[
                  _ShortlistBulkActions(
                    count: _selectedIds.length,
                    busy: _mutatingId == 'bulk',
                    onInvite: () => _openInviteQueue(bundle),
                    onRemove: _removeSelected,
                    onClear: () => setState(_selectedIds.clear),
                  ),
                  const SizedBox(height: 12),
                ],
                TourTarget(
                  id: 'dp.shortlist.board',
                  child: _LiveShortlistColumns(
                    boards: bundle.shortlists,
                    mutatingId: _mutatingId,
                    onDelete: _deleteShortlistItem,
                    onMove: _moveShortlistItem,
                    onSelect: _selectShortlistItem,
                    selectedIds: _selectedIds,
                    onToggleSelection: _toggleBulkSelection,
                  ),
                ),
              ],
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

class _ShortlistBulkActions extends StatelessWidget {
  final int count;
  final bool busy;
  final VoidCallback onInvite;
  final VoidCallback onRemove;
  final VoidCallback onClear;

  const _ShortlistBulkActions({
    required this.count,
    required this.busy,
    required this.onInvite,
    required this.onRemove,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return DPGlassCard(
      accentColor: context.appColors.goldDark,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '$count selected',
            style: AppTextStyles.label.copyWith(
              color: context.appColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          OutlinedButton.icon(
            onPressed: busy ? null : onInvite,
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
            label: const Text('Invite selected'),
          ),
          OutlinedButton.icon(
            onPressed: busy ? null : onRemove,
            icon: busy
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline_rounded, size: 17),
            label: const Text('Remove selected'),
          ),
          TextButton(
              onPressed: busy ? null : onClear, child: const Text('Clear')),
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
  final Set<String> selectedIds;
  final ValueChanged<String> onToggleSelection;

  const _LiveShortlistColumns({
    required this.boards,
    required this.mutatingId,
    required this.onDelete,
    required this.onMove,
    required this.onSelect,
    required this.selectedIds,
    required this.onToggleSelection,
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
              for (final (index, board) in visibleBoards.indexed) ...[
                SizedBox(
                  width: width.clamp(280.0, 390.0),
                  child: index == 0
                      ? TourTarget(
                          id: 'dp.shortlist.firstGroup',
                          child: _LiveShortlistColumn(
                            board: board,
                            mutatingId: mutatingId,
                            onDelete: onDelete,
                            onMove: onMove,
                            onSelect: onSelect,
                            selectedIds: selectedIds,
                            onToggleSelection: onToggleSelection,
                            wrapFirstItem: true,
                          ),
                        )
                      : _LiveShortlistColumn(
                          board: board,
                          mutatingId: mutatingId,
                          onDelete: onDelete,
                          onMove: onMove,
                          onSelect: onSelect,
                          selectedIds: selectedIds,
                          onToggleSelection: onToggleSelection,
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
  final bool wrapFirstItem;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggleSelection;

  const _LiveShortlistColumn({
    required this.board,
    required this.mutatingId,
    required this.onDelete,
    required this.onMove,
    required this.onSelect,
    required this.selectedIds,
    required this.onToggleSelection,
    this.wrapFirstItem = false,
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
          for (final (index, item) in board.items.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: () {
                final isFirst = wrapFirstItem && index == 0;
                final card = _LiveShortlistCard(
                  item: item,
                  loading: mutatingId == item.publicId,
                  onDelete: () => onDelete(item.publicId),
                  onMoveUp: () => onMove(item, -1),
                  onMoveDown: () => onMove(item, 1),
                  onSelect: () => onSelect(item),
                  selected: selectedIds.contains(item.publicId),
                  onToggleSelection: () => onToggleSelection(item.publicId),
                  wrapActions: isFirst,
                );
                return isFirst
                    ? TourTarget(id: 'dp.shortlist.firstCard', child: card)
                    : card;
              }(),
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
  final bool wrapActions;
  final bool selected;
  final VoidCallback onToggleSelection;

  const _LiveShortlistCard({
    required this.item,
    required this.loading,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onSelect,
    required this.selected,
    required this.onToggleSelection,
    this.wrapActions = false,
  });

  @override
  Widget build(BuildContext context) {
    final candidate = item.listing.toCandidate();
    final shortlisted = item.status == 'selected';
    return DPGlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox.adaptive(
                value: selected,
                onChanged: loading ? null : (_) => onToggleSelection(),
                semanticLabel: 'Select ${candidate.name} for bulk actions',
              ),
              _ShortlistAvatar(
                imageUrl: candidate.imageUrl,
                label: candidate.avatarLabel,
              ),
              const SizedBox(width: 10),
              Expanded(child: dpText(context, candidate.name, strong: true)),
              DPStatusChip(
                label: shortlisted ? 'Selected' : '#${item.rank}',
                tone: shortlisted ? DpTone.success : DpTone.warning,
              ),
            ],
          ),
          const SizedBox(height: 6),
          dpText(
            context,
            '${candidate.category} · ${candidate.city} · ${candidate.skills.take(2).join(' · ')}',
          ),
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
              wrapActions
                  ? TourTarget(
                      id: 'dp.shortlist.select',
                      child: _MiniAction(
                        icon: shortlisted
                            ? Icons.undo_rounded
                            : Icons.check_circle_outline_rounded,
                        label: shortlisted ? 'Unselect' : 'Select',
                        loading: loading,
                        onTap: onSelect,
                      ),
                    )
                  : _MiniAction(
                      icon: shortlisted
                          ? Icons.undo_rounded
                          : Icons.check_circle_outline_rounded,
                      label: shortlisted ? 'Unselect' : 'Select',
                      loading: loading,
                      onTap: onSelect,
                    ),
              wrapActions
                  ? TourTarget(
                      id: 'dp.shortlist.remove',
                      child: _MiniAction(
                        icon: Icons.delete_outline_rounded,
                        label: 'Remove',
                        loading: loading,
                        onTap: onDelete,
                      ),
                    )
                  : _MiniAction(
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

class _ShortlistAvatar extends StatelessWidget {
  final String? imageUrl;
  final String label;

  const _ShortlistAvatar({required this.imageUrl, required this.label});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 46,
        height: 46,
        color: context.appColors.softSurface,
        child: url == null || url.isEmpty
            ? Center(
                child: Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    color: context.appColors.goldDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: context.appColors.iconMuted,
                  ),
                ),
              ),
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
