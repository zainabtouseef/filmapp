import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/marketplace/marketplace_models.dart';
import '../../../core/projects/project_models.dart';
import '../../../core/projects/projects_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/tour/tour_target.dart';
import '../models/brand_sponsor_models.dart';
import '../widgets/brand_booking_dialog.dart';
import '../widgets/brand_demo_journey.dart';
import '../widgets/brand_sponsor_components.dart';
import '../widgets/brand_sponsor_live.dart';

class BR10BrandShortlistsScreen extends StatefulWidget {
  const BR10BrandShortlistsScreen({super.key});

  @override
  State<BR10BrandShortlistsScreen> createState() =>
      _BR10BrandShortlistsScreenState();
}

class _BR10BrandShortlistsScreenState extends State<BR10BrandShortlistsScreen> {
  AuthController? _auth;
  ProjectsController? _projectsController;
  MarketplaceShortlistBundle? _bundle;
  List<Project> _projects = const [];
  String _projectId = '';
  String? _error;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = AuthScope.maybeOf(context);
    final projects = ProjectsScope.maybeOf(context);
    if (identical(auth, _auth) && identical(projects, _projectsController)) {
      return;
    }
    _auth = auth;
    _projectsController = projects;
    if (auth != null && projects != null) _load();
  }

  Future<void> _load() async {
    if (_auth == null || _projectsController == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait<Object>([
        _auth!.shortlistBundle(),
        _projectsController!.projects(),
      ]);
      if (!mounted) return;
      final bundle = values[0] as MarketplaceShortlistBundle;
      final projects = values[1] as List<Project>;
      var selectedProjectId = _projectId;
      if (selectedProjectId.isEmpty && isBrandDemoAccount(_auth)) {
        final demoProject = selectBrandDemoProject(projects);
        final hasDemoBoard = bundle.shortlists
            .any((board) => board.projectId == demoProject?.publicId);
        if (hasDemoBoard) selectedProjectId = demoProject!.publicId;
      }
      setState(() {
        _bundle = bundle;
        _projects = projects;
        _projectId = selectedProjectId;
      });
    } catch (error) {
      if (mounted) setState(() => _error = brandApiMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<MarketplaceShortlist> get _boards {
    final boards = _bundle?.shortlists ?? const <MarketplaceShortlist>[];
    if (_projectId.isEmpty) return boards;
    return boards.where((board) => board.projectId == _projectId).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_auth == null || _projectsController == null) {
      return const CoreEmptyState(
        icon: Icons.cloud_sync_outlined,
        title: 'Sign in to view project shortlists',
        message:
            'Your saved production candidates live in the CineConnect backend.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandSectionCard(
          title: 'Project shortlists',
          icon: Icons.favorite_outline_rounded,
          selected: true,
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _projectId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Filter by project',
                    prefixIcon: Icon(Icons.account_tree_outlined),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('All projects'),
                    ),
                    for (final project in _projects)
                      DropdownMenuItem(
                        value: project.publicId,
                        child: Text(
                          project.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _projectId = value ?? ''),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Refresh shortlists',
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_error != null) ...[
          InlineNotice(
            message: _error!,
            icon: Icons.warning_amber_rounded,
            tone: CoreStatusTone.warning,
          ),
          const SizedBox(height: 12),
        ],
        if (_loading && _bundle == null)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_boards.isEmpty)
          const CoreEmptyState(
            icon: Icons.favorite_border_rounded,
            title: 'No shortlist items yet',
            message:
                'Open Discover, select a working project, then shortlist talent, crew, locations or equipment.',
          )
        else
          TourTarget(
            id: 'brand:demo:shortlist-board',
            child: Column(
              children: [
                for (final board in _boards) ...[
                  _ShortlistBoard(
                    board: board,
                    projectTitle: _projectTitle(board.projectId),
                    busy: _loading,
                    onStatus: _setStatus,
                    onNotes: _editNotes,
                    onRemove: _remove,
                    onRequest: (item) => _request(board, item),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
      ],
    );
  }

  String _projectTitle(String? id) {
    for (final project in _projects) {
      if (project.publicId == id) return project.title;
    }
    return 'Unassigned project';
  }

  Future<void> _setStatus(
    MarketplaceShortlistItem item,
    String status,
  ) async {
    setState(() => _loading = true);
    try {
      await _auth!.updateShortlistItem(
        publicId: item.publicId,
        status: status,
      );
      await _load();
      if (mounted) {
        brandSnack(context, 'Candidate marked ${readableBrandStatus(status)}');
      }
    } catch (error) {
      if (mounted) brandSnack(context, brandApiMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editNotes(MarketplaceShortlistItem item) async {
    final controller = TextEditingController(text: item.notes ?? '');
    final notes = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Notes for ${item.listing.title}'),
        content: CoreTextField(
          controller: controller,
          label: 'Private shortlist notes',
          icon: Icons.edit_note_outlined,
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim(),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (notes == null || !mounted) return;
    setState(() => _loading = true);
    try {
      await _auth!.updateShortlistItem(
        publicId: item.publicId,
        notes: notes,
      );
      await _load();
    } catch (error) {
      if (mounted) brandSnack(context, brandApiMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remove(MarketplaceShortlistItem item) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Remove shortlist item?'),
            content:
                Text('${item.listing.title} will be removed from this board.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Keep'),
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
    setState(() => _loading = true);
    try {
      await _auth!.deleteShortlistItem(item.publicId);
      await _load();
      if (mounted) brandSnack(context, 'Shortlist item removed');
    } catch (error) {
      if (mounted) brandSnack(context, brandApiMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _request(
    MarketplaceShortlist board,
    MarketplaceShortlistItem item,
  ) async {
    final sent = await showBrandBookingDialog(
      context,
      listingId: item.listing.publicId,
      listingTitle: item.listing.title,
      projects: _projects,
      initialProjectId: board.projectId,
      suggestedRateMinor: item.listing.priceFromMinor,
      currency: item.listing.currency,
    );
    if (sent && mounted) brandSnack(context, 'Booking request sent');
  }
}

class _ShortlistBoard extends StatelessWidget {
  final MarketplaceShortlist board;
  final String projectTitle;
  final bool busy;
  final void Function(MarketplaceShortlistItem, String) onStatus;
  final ValueChanged<MarketplaceShortlistItem> onNotes;
  final ValueChanged<MarketplaceShortlistItem> onRemove;
  final ValueChanged<MarketplaceShortlistItem> onRequest;

  const _ShortlistBoard({
    required this.board,
    required this.projectTitle,
    required this.busy,
    required this.onStatus,
    required this.onNotes,
    required this.onRemove,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return BrandSectionCard(
      title: board.name,
      icon: Icons.view_kanban_outlined,
      tone: BrandTone.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$projectTitle · ${board.items.length} candidates',
            style: AppTextStyles.smallMeta.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          if (board.items.isEmpty)
            const Text('This shortlist is empty.')
          else
            BrandResponsiveGrid(
              minWidth: 260,
              children: [
                for (final item in board.items)
                  _ShortlistCandidate(
                    item: item,
                    busy: busy,
                    onStatus: (status) => onStatus(item, status),
                    onNotes: () => onNotes(item),
                    onRemove: () => onRemove(item),
                    onRequest: () => onRequest(item),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ShortlistCandidate extends StatelessWidget {
  final MarketplaceShortlistItem item;
  final bool busy;
  final ValueChanged<String> onStatus;
  final VoidCallback onNotes;
  final VoidCallback onRemove;
  final VoidCallback onRequest;

  const _ShortlistCandidate({
    required this.item,
    required this.busy,
    required this.onStatus,
    required this.onNotes,
    required this.onRemove,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final listing = item.listing;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    listing.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardLabel.copyWith(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  enabled: !busy,
                  tooltip: 'Shortlist actions',
                  onSelected: (value) {
                    if (value == 'notes') return onNotes();
                    if (value == 'remove') return onRemove();
                    onStatus(value);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: 'selected', child: Text('Mark selected')),
                    PopupMenuItem(value: 'active', child: Text('Keep active')),
                    PopupMenuItem(
                        value: 'rejected', child: Text('Mark rejected')),
                    PopupMenuDivider(),
                    PopupMenuItem(value: 'notes', child: Text('Edit notes')),
                    PopupMenuItem(value: 'remove', child: Text('Remove')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            BrandLiveStatusChip(status: item.status),
            const SizedBox(height: 8),
            Text('${listing.cityName} · ${listing.toCandidate().rateRange}'),
            const SizedBox(height: 5),
            Text(
              listing.summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.smallMeta.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
            if (item.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 7),
              Text(
                'Notes: ${item.notes}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: busy ? null : onRequest,
                icon: const Icon(Icons.send_rounded),
                label: const Text('Request booking'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
