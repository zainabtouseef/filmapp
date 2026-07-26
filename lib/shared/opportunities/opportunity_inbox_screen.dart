import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/core_ui/widgets/core_widgets.dart';
import '../../core/network/api_exception.dart';
import '../../core/opportunities/opportunities_controller.dart';
import '../../core/opportunities/opportunities_models.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/actor_talent/models/actor_talent_models.dart';
import '../../features/actor_talent/widgets/actor_casting_widgets.dart';
import '../../features/actor_talent/widgets/actor_talent_components.dart';
import '../cards/cine_card_system.dart';
import '../widgets/status_chip.dart';

/// Generic "browse open requirements + apply" screen shared across the
/// Model, Location Owner, Media/Equipment and Crew Services portals — each
/// just points it at its own `category`. Reuses the Actor/Talent portal's
/// shared card/section widgets so it matches the rest of the app visually.
class OpportunityInboxScreen extends StatefulWidget {
  final String category;
  final String sectionTitle;
  final String emptyMessage;
  final String? detailRoute;

  const OpportunityInboxScreen({
    super.key,
    required this.category,
    this.sectionTitle = 'Opportunities',
    this.emptyMessage =
        'New opportunities matching your profile will appear here.',
    this.detailRoute,
  });

  @override
  State<OpportunityInboxScreen> createState() =>
      _OpportunityInboxScreenState();
}

class _OpportunityInboxScreenState extends State<OpportunityInboxScreen> {
  String _query = '';
  Future<OpportunityRolePage>? _rolesFuture;
  Future<List<OpportunityApplication>>? _applicationsFuture;
  Timer? _searchDebounce;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rolesFuture ??= _loadRoles();
    _applicationsFuture ??= _loadApplications();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<OpportunityRolePage> _loadRoles() {
    final controller = OpportunitiesScope.maybeOf(context);
    if (controller == null) {
      return Future<OpportunityRolePage>.error(
        const ApiException(
          code: 'opportunities.scope_missing',
          message: 'Sign in to discover open opportunities.',
        ),
      );
    }
    return controller.roles(category: widget.category, query: _query);
  }

  Future<List<OpportunityApplication>> _loadApplications() {
    final controller = OpportunitiesScope.maybeOf(context);
    if (controller == null) return Future.value(const []);
    return controller.myApplications();
  }

  void _reload() {
    setState(() {
      _rolesFuture = _loadRoles();
      _applicationsFuture = _loadApplications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ActorSearchFilterBar(
          query: _query,
          onQueryChanged: (value) {
            _query = value;
            _searchDebounce?.cancel();
            _searchDebounce = Timer(const Duration(milliseconds: 350), _reload);
          },
          filters: const ['All'],
          selectedFilter: 'All',
          onFilterChanged: (_) {},
        ),
        const SizedBox(height: 12),
        ActorSectionCard(
          title: widget.sectionTitle,
          icon: Icons.manage_search_outlined,
          actionText: 'Refresh',
          onActionTap: _reload,
          child: FutureBuilder<OpportunityRolePage>(
            future: _rolesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ActorResponsiveGrid(
                  minWidth: 285,
                  children: [
                    SkeletonCard(height: 220),
                    SkeletonCard(height: 220),
                  ],
                );
              }
              if (snapshot.hasError) {
                return CoreEmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Opportunities unavailable',
                  message: snapshot.error is ApiException
                      ? (snapshot.error! as ApiException).message
                      : 'Could not load opportunities. Check your connection.',
                  actionLabel: 'Try again',
                  onAction: _reload,
                );
              }
              final roles = snapshot.data?.roles ?? const <OpportunityRole>[];
              if (roles.isEmpty) {
                return CoreEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No open opportunities',
                  message: widget.emptyMessage,
                );
              }
              return ActorResponsiveGrid(
                minWidth: 285,
                children: [
                  for (final role in roles)
                    _OpportunityRoleCard(
                      role: role,
                      onSave: () => _toggleSaved(role),
                      onApply: () => _openApplyDialog(role),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        ActorSectionCard(
          title: 'My Applications',
          icon: Icons.assignment_turned_in_outlined,
          tone: ActorTone.blue,
          child: FutureBuilder<List<OpportunityApplication>>(
            future: _applicationsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SkeletonCard(height: 120);
              }
              final rows = snapshot.data ?? const <OpportunityApplication>[];
              if (rows.isEmpty) {
                return const CoreEmptyState(
                  icon: Icons.assignment_outlined,
                  title: 'No applications yet',
                  message: 'Applications you submit will be tracked here.',
                );
              }
              return Column(
                children: [
                  for (final application in rows.take(6))
                    _ApplicationRow(
                      application: application,
                      onWithdraw: application.status == 'submitted' ||
                              application.status == 'viewed' ||
                              application.status == 'shortlisted'
                          ? () => _withdraw(application)
                          : null,
                      onTap: widget.detailRoute == null
                          ? null
                          : () => Navigator.pushNamed(
                                context,
                                widget.detailRoute!,
                                arguments: application.publicId,
                              ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _toggleSaved(OpportunityRole role) async {
    final controller = OpportunitiesScope.maybeOf(context);
    if (controller == null) return;
    try {
      await controller.setSaved(role, !role.saved);
      if (!mounted) return;
      actorSnack(context, role.saved ? 'Removed from saved' : 'Saved');
      _reload();
    } on ApiException catch (error) {
      if (mounted) actorSnack(context, error.message);
    }
  }

  Future<void> _withdraw(OpportunityApplication application) async {
    final controller = OpportunitiesScope.maybeOf(context);
    if (controller == null) return;
    try {
      await controller.withdrawApplication(application.publicId);
      if (!mounted) return;
      actorSnack(context, 'Application withdrawn');
      _reload();
    } on ApiException catch (error) {
      if (mounted) actorSnack(context, error.message);
    }
  }

  Future<void> _openApplyDialog(OpportunityRole role) async {
    final controller = OpportunitiesScope.maybeOf(context);
    if (controller == null) return;
    final noteController = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(role.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (role.requiredDocuments.isNotEmpty) ...[
              Text(
                'Required documents',
                style: AppTextStyles.cardLabel.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final document in role.requiredDocuments)
                    Chip(
                      label: Text(document),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: noteController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Why are you a good fit?',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    noteController.dispose();
    if (submitted != true || !mounted) return;
    final note = noteController.text.trim();
    try {
      await controller.createApplication(
        role.publicId,
        coverNote: note,
      );
      if (!mounted) return;
      actorSnack(context, 'Application submitted');
      _reload();
    } on ApiException catch (error) {
      if (mounted) actorSnack(context, error.message);
    }
  }
}

class _OpportunityRoleCard extends StatelessWidget {
  final OpportunityRole role;
  final VoidCallback onSave;
  final VoidCallback onApply;

  const _OpportunityRoleCard({
    required this.role,
    required this.onSave,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final alreadyApplied = role.applicationStatus != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  role.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: role.saved ? 'Unsave' : 'Save',
                icon: Icon(
                  role.saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: colors.goldDark,
                  size: 20,
                ),
                onPressed: onSave,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            role.project.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (role.project.city != null)
                StatusChip(label: role.project.city!.name, color: colors.infoBlue),
              StatusChip(label: role.budgetLabel, color: colors.success),
              if (role.isVerifiedOnly)
                StatusChip(label: 'Verified only', color: colors.infoPurple),
              StatusChip(
                label: '${role.quantity} needed',
                color: colors.goldMid,
              ),
            ],
          ),
          if (role.summary != null && role.summary!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              role.summary!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textSecondary,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 10),
          CorePrimaryButton(
            icon: alreadyApplied
                ? Icons.check_circle_outline_rounded
                : Icons.send_outlined,
            label: alreadyApplied
                ? actorCastingTitleCase(role.applicationStatus ?? 'Applied')
                : 'Apply',
            compact: true,
            onTap: alreadyApplied ? null : onApply,
          ),
        ],
      ),
    );
  }
}

class _ApplicationRow extends StatelessWidget {
  final OpportunityApplication application;
  final VoidCallback? onWithdraw;
  final VoidCallback? onTap;

  const _ApplicationRow({
    required this.application,
    this.onWithdraw,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.borderMuted)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    application.role.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardLabel.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${application.role.project.title} · ${actorCastingTitleCase(application.status)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.smallMeta.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (onWithdraw != null)
              TextButton(onPressed: onWithdraw, child: const Text('Withdraw')),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}
