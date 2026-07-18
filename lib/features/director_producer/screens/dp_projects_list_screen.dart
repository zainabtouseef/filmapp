import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/projects/project_models.dart';
import '../../../core/projects/projects_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/director_producer_demo_data.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_empty_state.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_project_card.dart';
import '../widgets/dp_status_chip.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _reload();
    }
  }

  @override
  void dispose() {
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
          : controller.projects(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dpHeaderAction(
          context,
          icon: Icons.add_circle_outline_rounded,
          label: 'New Project',
          onTap: () => Navigator.pushNamed(
              context, DirectorProducerRoutes.createProject),
        ),
        const SizedBox(height: 6),
        _ProjectSearchRow(
            controller: _search, onChanged: () => setState(() {})),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final filter in const [
              'All',
              'Pre-production',
              'Casting',
              'Negotiating',
              'Shooting',
              'Draft',
            ])
              GestureDetector(
                onTap: () => setState(() => _filter = filter),
                child: DPStatusChip(
                  label: filter,
                  tone: _filter == filter ? DpTone.warning : DpTone.neutral,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Project>>(
          future: _projectsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _ProjectsLoadingState();
            }
            if (snapshot.hasError) {
              return _ProjectFallbackGrid(
                filter: _filter,
                query: _search.text,
                warning: _friendlyError(snapshot.error),
              );
            }
            final projects = _filterProjects(snapshot.data ?? const []);
            if (projects.isEmpty) {
              return const DPEmptyState(
                icon: Icons.movie_filter_outlined,
                title: 'No matching projects',
                message: 'Try a different search term or status filter.',
              );
            }
            return DPResponsiveGrid(
              children: projects
                  .map(
                    (project) => DPProjectCard(
                      project: project.toDpProject(),
                      onOpen: () => Navigator.pushNamed(
                        context,
                        DirectorProducerRoutes.projectDetail,
                        arguments: project.publicId,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  List<Project> _filterProjects(List<Project> projects) {
    final query = _search.text.toLowerCase();
    return projects.where((project) {
      final status = project.status.toLowerCase();
      final statusMatch = _filter == 'All' ||
          status.contains(_filter.toLowerCase().replaceAll('-', ' ')) ||
          status.contains(_filter.toLowerCase());
      final queryMatch = query.isEmpty ||
          project.title.toLowerCase().contains(query) ||
          (project.city?.name.toLowerCase().contains(query) ?? false) ||
          status.contains(query);
      return statusMatch && queryMatch;
    }).toList();
  }

  String _friendlyError(Object? error) {
    if (error is ApiException) {
      return switch (error.code) {
        'auth.required' ||
        'auth.invalid_token' =>
          'Sign in to load live projects — showing preview projects.',
        'network.offline' =>
          'Live projects unavailable — showing preview projects. Check your connection and retry.',
        _ => 'Live projects unavailable — showing preview projects.',
      };
    }
    return 'Live projects unavailable — showing preview projects.';
  }
}

class _ProjectFallbackGrid extends StatelessWidget {
  final String filter;
  final String query;
  final String warning;

  const _ProjectFallbackGrid({
    required this.filter,
    required this.query,
    required this.warning,
  });

  @override
  Widget build(BuildContext context) {
    final search = query.toLowerCase();
    final projects = DirectorProducerDemoData.projects.where((project) {
      final statusMatch = filter == 'All' || project.status.contains(filter);
      final queryMatch = search.isEmpty ||
          project.title.toLowerCase().contains(search) ||
          project.city.toLowerCase().contains(search) ||
          project.status.toLowerCase().contains(search);
      return statusMatch && queryMatch;
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InlineWarning(message: warning),
        const SizedBox(height: 12),
        if (projects.isEmpty)
          const DPEmptyState(
            icon: Icons.movie_filter_outlined,
            title: 'No matching projects',
            message: 'Try a different search term or status filter.',
          )
        else
          DPResponsiveGrid(
            children: projects
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

class _InlineWarning extends StatelessWidget {
  final String message;

  const _InlineWarning({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.goldMid.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.goldMid.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: colors.goldMid, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textSecondary,
              ),
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
