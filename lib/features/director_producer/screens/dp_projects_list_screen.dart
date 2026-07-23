import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/projects/project_models.dart';
import '../../../core/projects/projects_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/dp_project.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_empty_state.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_project_card.dart';
import '../widgets/dp_status_chip.dart';

const _filterKeys = [
  'All',
  'Pre-production',
  'Casting',
  'Negotiating',
  'Shooting',
  'Draft',
];

class DPProjectsListScreen extends StatefulWidget {
  const DPProjectsListScreen({super.key});

  @override
  State<DPProjectsListScreen> createState() => _DPProjectsListScreenState();
}

class _DPProjectsListScreenState extends State<DPProjectsListScreen> {
  String _filter = 'All';
  final _search = TextEditingController();
  Future<List<Project>>? _projectsFuture;
  bool _started = false;
  ProjectsController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _reload();
      // Re-fetch reactively whenever the controller's project list
      // changes elsewhere (e.g. a project created from the wizard) —
      // no manual pull-to-refresh needed to see it here.
      _controller = ProjectsScope.maybeOf(context);
      _controller?.addListener(_reload);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_reload);
    _search.dispose();
    super.dispose();
  }

  void _reload() {
    final controller = ProjectsScope.maybeOf(context);
    setState(() {
      _projectsFuture = controller == null
          ? Future<List<Project>>.error(
              const ApiException(
                code: 'auth.required',
                message: 'Sign in to load projects.',
              ),
            )
          : controller.projects();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Project>>(
      future: _projectsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _ProjectsLoadingState();
        }
        if (snapshot.hasError) {
          return _ProjectsErrorState(
            message: _friendlyError(snapshot.error),
            onRetry: _reload,
          );
        }
        final allProjects = (snapshot.data ?? const <Project>[])
            .map((p) => p.toDpProject())
            .toList();
        final filtered = _filterProjects(allProjects);
        final needingAction =
            allProjects.where((p) => p.pendingActions > 0).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderRow(
              total: allProjects.length,
              needingAction: needingAction,
            ),
            const SizedBox(height: 14),
            _ProjectSearchRow(
              controller: _search,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 10),
            _FilterChips(
              value: _filter,
              onChanged: (value) => setState(() => _filter = value),
            ),
            const SizedBox(height: 14),
            if (allProjects.isEmpty)
              const DPEmptyState(
                icon: Icons.movie_creation_outlined,
                title: 'No live projects yet',
                message:
                    'Create your first production to start seeing real project cards here.',
              )
            else if (filtered.isEmpty)
              const DPEmptyState(
                icon: Icons.movie_filter_outlined,
                title: 'No matching live projects',
                message: 'Try a different search term or status filter.',
              )
            else
              DPResponsiveGrid(
                children: filtered
                    .map(
                      (project) => DPProjectCard(
                        project: project,
                        onOpen: () => Navigator.pushNamed(
                          context,
                          DirectorProducerRoutes.projectDetail,
                          arguments: project.id,
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        );
      },
    );
  }

  List<DpProject> _filterProjects(List<DpProject> projects) {
    final query = _search.text.toLowerCase();
    return projects.where((project) {
      final status = project.status.toLowerCase();
      final statusMatch = _filter == 'All' ||
          status.contains(_filter.toLowerCase().replaceAll('-', ' ')) ||
          status.contains(_filter.toLowerCase());
      final queryMatch = query.isEmpty ||
          project.title.toLowerCase().contains(query) ||
          project.city.toLowerCase().contains(query) ||
          status.contains(query);
      return statusMatch && queryMatch;
    }).toList();
  }

  String _friendlyError(Object? error) {
    if (error is ApiException) {
      return switch (error.code) {
        'auth.required' ||
        'auth.invalid_token' =>
          'Sign in to load live projects.',
        'network.offline' =>
          'Live projects are unavailable. Check your connection and retry.',
        _ => error.message,
      };
    }
    return 'Live projects are unavailable right now.';
  }
}

class _HeaderRow extends StatelessWidget {
  final int total;
  final int needingAction;

  const _HeaderRow({required this.total, required this.needingAction});

  @override
  Widget build(BuildContext context) {
    return DPPageHeader(
      eyebrow: needingAction == 0
          ? '$total productions'
          : '$total productions · $needingAction need action',
      title: 'Projects',
      actionLabel: 'New Project',
      actionIcon: Icons.add_rounded,
      onActionTap: () =>
          Navigator.pushNamed(context, DirectorProducerRoutes.createProject),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _FilterChips({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final key in _filterKeys) ...[
            DpDotChip(
              label: key,
              active: value == key,
              onTap: () => onChanged(key),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _ProjectsLoadingState extends StatelessWidget {
  const _ProjectsLoadingState();

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
              'Loading live projects...',
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

class _ProjectsErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ProjectsErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DPGlassCard(
      accentColor: colors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DPPageHeader(
            eyebrow: 'Live projects',
            title: 'Projects',
            actionLabel: 'New Project',
            actionIcon: Icons.add_rounded,
            onActionTap: () => Navigator.pushNamed(
              context,
              DirectorProducerRoutes.createProject,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.cloud_off_outlined, color: colors.warning, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Could not load live projects',
                      style: AppTextStyles.cardTitle.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      message,
                      style: AppTextStyles.smallMeta.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectSearchRow extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _ProjectSearchRow({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DPGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: colors.goldDark, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search project, city, status...',
                hintStyle: AppTextStyles.smallMeta.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
