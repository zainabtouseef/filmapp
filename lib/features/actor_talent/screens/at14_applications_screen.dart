import 'package:flutter/material.dart';

import '../../../core/casting/casting_controller.dart';
import '../../../core/casting/casting_models.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../routes/actor_talent_routes.dart';
import '../widgets/actor_casting_widgets.dart';
import '../widgets/actor_talent_components.dart';

class AT14ApplicationsScreen extends StatefulWidget {
  final bool auditionsOnly;

  const AT14ApplicationsScreen({
    super.key,
    this.auditionsOnly = false,
  });

  @override
  State<AT14ApplicationsScreen> createState() => _AT14ApplicationsScreenState();
}

class _AT14ApplicationsScreenState extends State<AT14ApplicationsScreen> {
  late String _filter = widget.auditionsOnly ? 'Auditions' : 'All';
  String _query = '';
  Future<List<CastingApplication>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<List<CastingApplication>> _load() {
    final controller = CastingScope.maybeOf(context);
    if (controller == null) {
      return Future<List<CastingApplication>>.error(
        const ApiException(
          code: 'casting.scope_missing',
          message: 'Sign in to view your applications.',
        ),
      );
    }
    return controller.actorApplications(force: true);
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ActorSearchFilterBar(
          query: _query,
          onQueryChanged: (value) => setState(() => _query = value),
          filters: const ['All', 'Active', 'Auditions', 'Offers', 'Closed'],
          selectedFilter: _filter,
          onFilterChanged: (value) => setState(() => _filter = value),
        ),
        const SizedBox(height: 12),
        ActorSectionCard(
          title:
              widget.auditionsOnly ? 'Auditions & Callbacks' : 'Applications',
          icon: widget.auditionsOnly
              ? Icons.video_camera_front_outlined
              : Icons.assignment_outlined,
          actionText: 'Refresh',
          onActionTap: _reload,
          child: FutureBuilder<List<CastingApplication>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Column(
                  children: [
                    SkeletonCard(height: 120),
                    SizedBox(height: 10),
                    SkeletonCard(height: 120),
                  ],
                );
              }
              if (snapshot.hasError) {
                return CoreEmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Applications unavailable',
                  message: snapshot.error is ApiException
                      ? (snapshot.error! as ApiException).message
                      : 'Could not load your application tracker.',
                  actionLabel: 'Try again',
                  onAction: _reload,
                );
              }
              final rows = (snapshot.data ?? const <CastingApplication>[])
                  .where(_matchesFilter)
                  .toList();
              if (rows.isEmpty) {
                return CoreEmptyState(
                  icon: widget.auditionsOnly
                      ? Icons.video_camera_front_outlined
                      : Icons.assignment_add,
                  title: widget.auditionsOnly
                      ? 'No upcoming auditions'
                      : 'No $_filter applications',
                  message: widget.auditionsOnly
                      ? 'Audition requests, self-tapes and callbacks appear here.'
                      : 'Browse live roles and submit an application to start tracking it.',
                  actionLabel: widget.auditionsOnly ? null : 'Discover roles',
                  onAction: widget.auditionsOnly
                      ? null
                      : () => Navigator.pushNamed(
                            context,
                            ActorTalentRoutes.opportunities,
                          ),
                );
              }
              return Column(
                children: [
                  for (var index = 0; index < rows.length; index++) ...[
                    ActorCastingApplicationCard(
                      application: rows[index],
                      onOpen: () => Navigator.pushNamed(
                        context,
                        ActorTalentRoutes.applicationDetail,
                        arguments: rows[index].publicId,
                      ),
                    ),
                    if (index != rows.length - 1) const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  bool _matchesFilter(CastingApplication item) {
    final query = _query.trim().toLowerCase();
    final matchesQuery = query.isEmpty ||
        [
          item.role.title,
          item.role.project.title,
          item.role.project.city?.name ?? '',
          item.status,
        ].join(' ').toLowerCase().contains(query);
    if (!matchesQuery) return false;
    if (widget.auditionsOnly) return item.isAudition;
    return switch (_filter) {
      'Active' => !const {
          'draft',
          'selected',
          'rejected',
          'withdrawn',
        }.contains(item.status),
      'Auditions' => item.isAudition,
      'Offers' => const {'offer_received', 'selected'}.contains(item.status),
      'Closed' => const {'rejected', 'withdrawn'}.contains(item.status),
      _ => true,
    };
  }
}
