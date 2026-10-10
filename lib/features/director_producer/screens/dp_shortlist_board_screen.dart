import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/marketplace/marketplace_models.dart';
import '../../../core/network/api_exception.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_shortlist_v3.dart';

class DPShortlistBoardScreen extends StatefulWidget {
  const DPShortlistBoardScreen({super.key});

  @override
  State<DPShortlistBoardScreen> createState() => _DPShortlistBoardScreenState();
}

class _DPShortlistBoardScreenState extends State<DPShortlistBoardScreen> {
  MarketplaceShortlistBundle? _bundle;
  bool _loading = true;
  String? _error;
  String? _notice;
  String? _activeBoardId;
  String? _mutatingId;
  final Set<String> _checkedIds = <String>{};
  final Map<String, bool> _alertState = <String, bool>{};
  final Map<String, int> _rankBumps = <String, int>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading && _bundle == null && _error == null) {
      _load();
    }
  }

  Future<void> _load() async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null || !auth.isAuthenticated) {
      setState(() {
        _loading = false;
        _error = 'Sign in to load live shortlists.';
      });
      return;
    }
    try {
      final bundle = await auth.shortlistBundle();
      if (!mounted) return;
      setState(() {
        _bundle = bundle;
        _loading = false;
        _error = null;
        _notice = null;
        if (_activeBoardId == null ||
            !bundle.shortlists.any((board) => board.publicId == _activeBoardId)) {
          _activeBoardId = bundle.shortlists.isEmpty
              ? null
              : bundle.shortlists.first.publicId;
        }
        for (final search in bundle.savedSearches) {
          _alertState.putIfAbsent(search.publicId, () => search.notifyEnabled);
        }
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load shortlists right now.';
      });
    }
  }

  MarketplaceShortlist? get _activeBoard {
    final bundle = _bundle;
    if (bundle == null || bundle.shortlists.isEmpty) return null;
    for (final board in bundle.shortlists) {
      if (board.publicId == _activeBoardId) return board;
    }
    return bundle.shortlists.first;
  }

  Future<void> _createShortlist() async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null || !auth.isAuthenticated || _mutatingId != null) return;
    final number = (_bundle?.shortlists.length ?? 0) + 1;
    setState(() {
      _mutatingId = '__new__';
      _notice = null;
    });
    try {
      final board = await auth.createShortlist(name: 'Shortlist $number');
      if (!mounted) return;
      final current = _bundle ?? const MarketplaceShortlistBundle(
        savedSearches: <MarketplaceSavedSearch>[],
        shortlists: <MarketplaceShortlist>[],
      );
      setState(() {
        _bundle = MarketplaceShortlistBundle(
          savedSearches: current.savedSearches,
          shortlists: <MarketplaceShortlist>[...current.shortlists, board],
        );
        _activeBoardId = board.publicId;
        _checkedIds.clear();
        _notice = 'New shortlist created.';
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _notice = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _notice = 'Could not create shortlist right now.');
    } finally {
      if (mounted) setState(() => _mutatingId = null);
    }
  }

  Future<void> _moveItem(MarketplaceShortlistItem item, int direction) async {
    final board = _activeBoard;
    final auth = AuthScope.maybeOf(context);
    if (board == null || auth == null || _mutatingId != null) return;
    final ordered = [...board.items]..sort((a, b) => a.rank.compareTo(b.rank));
    final index = ordered.indexWhere((entry) => entry.publicId == item.publicId);
    final nextIndex = index + direction;
    if (index < 0 || nextIndex < 0 || nextIndex >= ordered.length) return;
    final other = ordered[nextIndex];
    final itemRank = item.rank;
    final otherRank = other.rank;
    ordered[index] = _copyItem(other, rank: itemRank);
    ordered[nextIndex] = _copyItem(item, rank: otherRank);
    setState(() {
      _mutatingId = item.publicId;
      _replaceBoardItems(board, ordered);
      _rankBumps[item.publicId] = (_rankBumps[item.publicId] ?? 0) + 1;
      _rankBumps[other.publicId] = (_rankBumps[other.publicId] ?? 0) + 1;
    });
    try {
      await auth.updateShortlistItem(publicId: item.publicId, rank: otherRank);
      await auth.updateShortlistItem(publicId: other.publicId, rank: itemRank);
      if (!mounted) return;
      final normalized = <MarketplaceShortlistItem>[];
      for (var i = 0; i < ordered.length; i++) {
        final source = ordered[i];
        normalized.add(_copyItem(source, rank: i + 1));
      }
      setState(() => _replaceBoardItems(board, normalized));
    } catch (_) {
      if (!mounted) return;
      setState(() => _notice = 'Could not update ranking. Refresh and try again.');
      await _load();
    } finally {
      if (mounted) setState(() => _mutatingId = null);
    }
  }

  Future<void> _toggleSelect(MarketplaceShortlistItem item) async {
    final board = _activeBoard;
    final auth = AuthScope.maybeOf(context);
    if (board == null || auth == null || _mutatingId != null) return;
    final nextStatus = item.status == 'selected' ? 'active' : 'selected';
    setState(() {
      _mutatingId = item.publicId;
      _replaceBoardItem(board, _copyItem(item, status: nextStatus));
    });
    try {
      final updated = await auth.updateShortlistItem(
        publicId: item.publicId,
        status: nextStatus,
      );
      if (!mounted) return;
      setState(() => _replaceBoardItem(board, updated));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _replaceBoardItem(board, item);
        _notice = 'Could not update selection right now.';
      });
    } finally {
      if (mounted) setState(() => _mutatingId = null);
    }
  }

  Future<void> _removeItem(MarketplaceShortlistItem item) async {
    final board = _activeBoard;
    final auth = AuthScope.maybeOf(context);
    if (board == null || auth == null || _mutatingId != null) return;
    final previous = [...board.items];
    setState(() {
      _mutatingId = item.publicId;
      _checkedIds.remove(item.publicId);
      _replaceBoardItems(
        board,
        previous.where((entry) => entry.publicId != item.publicId).toList(),
      );
    });
    try {
      await auth.deleteShortlistItem(item.publicId);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _replaceBoardItems(board, previous);
        _notice = 'Could not remove this shortlist item.';
      });
    } finally {
      if (mounted) setState(() => _mutatingId = null);
    }
  }

  Future<void> _selectChecked() async {
    final board = _activeBoard;
    final auth = AuthScope.maybeOf(context);
    if (board == null || auth == null || _checkedIds.isEmpty || _mutatingId != null) {
      return;
    }
    final ids = {..._checkedIds};
    setState(() => _mutatingId = '__bulk_select__');
    try {
      for (final item in board.items.where((entry) => ids.contains(entry.publicId))) {
        if (item.status != 'selected') {
          await auth.updateShortlistItem(publicId: item.publicId, status: 'selected');
        }
      }
      if (!mounted) return;
      final next = board.items
          .map((item) => ids.contains(item.publicId)
              ? _copyItem(item, status: 'selected')
              : item)
          .toList();
      setState(() {
        _replaceBoardItems(board, next);
        _checkedIds.clear();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _notice = 'Could not select all checked items.');
      await _load();
    } finally {
      if (mounted) setState(() => _mutatingId = null);
    }
  }

  Future<void> _removeChecked() async {
    final board = _activeBoard;
    final auth = AuthScope.maybeOf(context);
    if (board == null || auth == null || _checkedIds.isEmpty || _mutatingId != null) {
      return;
    }
    final ids = {..._checkedIds};
    final previous = [...board.items];
    setState(() {
      _mutatingId = '__bulk_remove__';
      _replaceBoardItems(
        board,
        previous.where((entry) => !ids.contains(entry.publicId)).toList(),
      );
      _checkedIds.clear();
    });
    try {
      for (final id in ids) {
        await auth.deleteShortlistItem(id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _replaceBoardItems(board, previous);
        _notice = 'Some checked items could not be removed.';
      });
      await _load();
    } finally {
      if (mounted) setState(() => _mutatingId = null);
    }
  }

  Future<void> _deleteSavedSearch(MarketplaceSavedSearch search) async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null || _mutatingId != null) return;
    final current = _bundle;
    if (current == null) return;
    setState(() {
      _mutatingId = search.publicId;
      _bundle = MarketplaceShortlistBundle(
        savedSearches: current.savedSearches
            .where((entry) => entry.publicId != search.publicId)
            .toList(),
        shortlists: current.shortlists,
      );
      _alertState.remove(search.publicId);
    });
    try {
      await auth.deleteSavedSearch(search.publicId);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _bundle = current;
        _alertState[search.publicId] = search.notifyEnabled;
        _notice = 'Could not remove saved search.';
      });
    } finally {
      if (mounted) setState(() => _mutatingId = null);
    }
  }

  void _replaceBoardItems(
    MarketplaceShortlist board,
    List<MarketplaceShortlistItem> items,
  ) {
    final bundle = _bundle;
    if (bundle == null) return;
    final sorted = [...items]..sort((a, b) => a.rank.compareTo(b.rank));
    _bundle = MarketplaceShortlistBundle(
      savedSearches: bundle.savedSearches,
      shortlists: bundle.shortlists
          .map((entry) => entry.publicId == board.publicId
              ? MarketplaceShortlist(
                  publicId: entry.publicId,
                  projectId: entry.projectId,
                  requirementId: entry.requirementId,
                  name: entry.name,
                  items: sorted,
                  createdAt: entry.createdAt,
                )
              : entry)
          .toList(),
    );
  }

  void _replaceBoardItem(
    MarketplaceShortlist board,
    MarketplaceShortlistItem replacement,
  ) {
    _replaceBoardItems(
      board,
      board.items
          .map((item) => item.publicId == replacement.publicId ? replacement : item)
          .toList(),
    );
  }

  MarketplaceShortlistItem _copyItem(
    MarketplaceShortlistItem item, {
    int? rank,
    String? status,
  }) {
    return MarketplaceShortlistItem(
      publicId: item.publicId,
      listing: item.listing,
      rank: rank ?? item.rank,
      notes: item.notes,
      status: status ?? item.status,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DPShortlistV3(
      loading: _loading,
      error: _error,
      notice: _notice,
      bundle: _bundle,
      activeBoardId: _activeBoardId,
      mutatingId: _mutatingId,
      checkedIds: _checkedIds,
      alertState: _alertState,
      rankBumps: _rankBumps,
      onRetry: _load,
      onDiscover: () => Navigator.pushNamed(
        context,
        DirectorProducerRoutes.marketplace,
      ),
      onCreateShortlist: _createShortlist,
      onBoardChanged: (id) {
        setState(() {
          _activeBoardId = id;
          _checkedIds.clear();
        });
      },
      onCheckItem: (id, checked) {
        setState(() {
          if (checked) {
            _checkedIds.add(id);
          } else {
            _checkedIds.remove(id);
          }
        });
      },
      onToggleAll: () {
        final board = _activeBoard;
        if (board == null) return;
        setState(() {
          final allOn = board.items.isNotEmpty &&
              board.items.every((item) => _checkedIds.contains(item.publicId));
          if (allOn) {
            for (final item in board.items) {
              _checkedIds.remove(item.publicId);
            }
          } else {
            for (final item in board.items) {
              _checkedIds.add(item.publicId);
            }
          }
        });
      },
      onMoveUp: (item) => _moveItem(item, -1),
      onMoveDown: (item) => _moveItem(item, 1),
      onToggleSelect: _toggleSelect,
      onRemoveItem: _removeItem,
      onSelectChecked: _selectChecked,
      onRemoveChecked: _removeChecked,
      onClearChecked: () => setState(_checkedIds.clear),
      onToggleAlert: (search) {
        setState(() {
          final current = _alertState[search.publicId] ?? search.notifyEnabled;
          _alertState[search.publicId] = !current;
        });
      },
      onRunSearch: (search) {
        Navigator.pushNamed(
          context,
          DirectorProducerRoutes.marketplace,
          arguments: <String, String>{
            if (search.listingType != null) 'category': search.listingType!,
          },
        );
      },
      onDeleteSearch: _deleteSavedSearch,
    );
  }
}
