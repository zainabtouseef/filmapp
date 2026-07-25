import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/casting/casting_controller.dart';
import '../../../core/casting/casting_models.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../models/actor_talent_models.dart';
import '../routes/actor_talent_routes.dart';
import '../widgets/actor_casting_widgets.dart';
import '../widgets/actor_talent_components.dart';

/// AT-06 Role discovery and direct offers.
class AT06OpportunityInboxScreen extends StatefulWidget {
  const AT06OpportunityInboxScreen({super.key});

  @override
  State<AT06OpportunityInboxScreen> createState() =>
      _AT06OpportunityInboxScreenState();
}

class _AT06OpportunityInboxScreenState
    extends State<AT06OpportunityInboxScreen> {
  String _query = '';
  String _filter = 'All';
  Future<CastingRolePage>? _rolesFuture;
  Future<List<Booking>>? _offersFuture;
  Timer? _searchDebounce;
  bool _loadingMore = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rolesFuture ??= _loadRoles();
    final bookings = BookingsScope.maybeOf(context);
    if (_offersFuture == null && bookings != null) {
      _offersFuture = bookings.opportunities(force: true);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<CastingRolePage> _loadRoles({int page = 1}) {
    final controller = CastingScope.maybeOf(context);
    if (controller == null) {
      return Future<CastingRolePage>.error(
        const ApiException(
          code: 'casting.scope_missing',
          message: 'Sign in to discover live casting roles.',
        ),
      );
    }
    return controller.roles(
      query: _query,
      saved: _filter == 'Saved',
      auditionMode: switch (_filter) {
        'Self-tape' => 'self_tape',
        'Online' => 'online',
        'In person' => 'in_person',
        _ => null,
      },
      page: page,
      force: true,
    );
  }

  void _reload() {
    setState(() => _rolesFuture = _loadRoles());
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
            _searchDebounce = Timer(
              const Duration(milliseconds: 350),
              _reload,
            );
          },
          filters: const [
            'All',
            'Self-tape',
            'Online',
            'In person',
            'Saved',
          ],
          selectedFilter: _filter,
          onFilterChanged: (value) {
            _filter = value;
            _reload();
          },
        ),
        const SizedBox(height: 12),
        ActorSectionCard(
          title: _filter == 'Saved' ? 'Saved Roles' : 'Casting Calls',
          icon: _filter == 'Saved'
              ? Icons.bookmarks_outlined
              : Icons.manage_search_outlined,
          actionText: 'Refresh',
          onActionTap: _reload,
          child: FutureBuilder<CastingRolePage>(
            future: _rolesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _RoleSkeletons();
              }
              if (snapshot.hasError) {
                return CoreEmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Casting roles unavailable',
                  message: snapshot.error is ApiException
                      ? (snapshot.error! as ApiException).message
                      : 'Could not load casting calls. Check your connection.',
                  actionLabel: 'Try again',
                  onAction: _reload,
                );
              }
              final roles = snapshot.data?.roles ?? const <CastingRole>[];
              if (roles.isEmpty) {
                return CoreEmptyState(
                  icon: _filter == 'Saved'
                      ? Icons.bookmark_add_outlined
                      : Icons.search_off_rounded,
                  title: _filter == 'Saved'
                      ? 'No saved roles'
                      : 'No matching roles',
                  message: _filter == 'Saved'
                      ? 'Save a casting call to compare it here later.'
                      : 'Try a different search or check again when productions publish new roles.',
                  actionLabel: _filter == 'Saved' ? 'Browse roles' : null,
                  onAction: _filter == 'Saved'
                      ? () {
                          _filter = 'All';
                          _reload();
                        }
                      : null,
                );
              }
              final page = snapshot.data!;
              return Column(
                children: [
                  ActorResponsiveGrid(
                    minWidth: 285,
                    children: [
                      for (final role in roles)
                        ActorCastingRoleCard(
                          role: role,
                          onOpen: () => Navigator.pushNamed(
                            context,
                            role.applicationId == null
                                ? ActorTalentRoutes.roleDetail
                                : ActorTalentRoutes.applicationDetail,
                            arguments: role.applicationId ?? role.publicId,
                          ),
                          onSave: () => _toggleSaved(role),
                        ),
                    ],
                  ),
                  if (roles.length < page.total) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 190,
                      child: CoreSecondaryButton(
                        icon: Icons.expand_more_rounded,
                        label:
                            _loadingMore ? 'Loading roles' : 'Load more roles',
                        compact: true,
                        onTap: _loadingMore ? null : () => _loadMore(page),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        ActorSectionCard(
          title: 'Direct Offers',
          icon: Icons.local_activity_outlined,
          actionText: 'Bookings',
          onActionTap: () =>
              Navigator.pushNamed(context, ActorTalentRoutes.bookings),
          tone: ActorTone.green,
          child: _DirectOffers(future: _offersFuture),
        ),
      ],
    );
  }

  Future<void> _toggleSaved(CastingRole role) async {
    final controller = CastingScope.maybeOf(context);
    if (controller == null) return;
    try {
      await controller.setSaved(role, !role.saved);
      if (!mounted) return;
      actorSnack(
        context,
        role.saved ? 'Role removed from saved' : 'Role saved',
      );
      _reload();
    } on ApiException catch (error) {
      if (mounted) actorSnack(context, error.message);
    }
  }

  Future<void> _loadMore(CastingRolePage current) async {
    if (_loadingMore || current.roles.length >= current.total) return;
    setState(() => _loadingMore = true);
    try {
      final next = await _loadRoles(page: current.page + 1);
      if (!mounted) return;
      setState(() {
        _rolesFuture = Future.value(
          CastingRolePage(
            roles: [...current.roles, ...next.roles],
            page: next.page,
            perPage: next.perPage,
            total: next.total,
          ),
        );
      });
    } on ApiException catch (error) {
      if (mounted) actorSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }
}

class _RoleSkeletons extends StatelessWidget {
  const _RoleSkeletons();

  @override
  Widget build(BuildContext context) {
    return const ActorResponsiveGrid(
      minWidth: 285,
      children: [
        SkeletonCard(height: 340),
        SkeletonCard(height: 340),
        SkeletonCard(height: 340),
      ],
    );
  }
}

class _DirectOffers extends StatelessWidget {
  final Future<List<Booking>>? future;

  const _DirectOffers({required this.future});

  @override
  Widget build(BuildContext context) {
    if (future == null) {
      return const CoreEmptyState(
        icon: Icons.lock_outline_rounded,
        title: 'Sign in to view offers',
        message: 'Producer booking offers will appear here.',
      );
    }
    return FutureBuilder<List<Booking>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SkeletonCard(height: 120);
        }
        if (snapshot.hasError) {
          return const CoreEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Offers unavailable',
            message: 'Could not load direct booking offers.',
          );
        }
        final rows = snapshot.data ?? const <Booking>[];
        if (rows.isEmpty) {
          return const CoreEmptyState(
            icon: Icons.mark_email_read_outlined,
            title: 'No direct offers',
            message: 'New producer offers will appear here.',
          );
        }
        return Column(
          children: [
            for (final booking in rows.take(3))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.handshake_outlined),
                title: Text(booking.requester.displayName),
                subtitle: Text(
                  '${booking.activeOffer?.feeLabel ?? 'Rate TBD'} · ${actorCastingTitleCase(booking.status)}',
                ),
                trailing: IconButton(
                  tooltip: 'Review offer',
                  icon: const Icon(Icons.arrow_forward_rounded),
                  onPressed: () => Navigator.pushNamed(
                    context,
                    ActorTalentRoutes.offerDetail,
                    arguments: booking.publicId,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
