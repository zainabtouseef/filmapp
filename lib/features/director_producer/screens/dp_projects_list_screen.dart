import 'package:flutter/material.dart';

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

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.toLowerCase();
    final projects = DirectorProducerDemoData.projects.where((project) {
      final statusMatch = _filter == 'All' || project.status.contains(_filter);
      final queryMatch = query.isEmpty ||
          project.title.toLowerCase().contains(query) ||
          project.city.toLowerCase().contains(query) ||
          project.status.toLowerCase().contains(query);
      return statusMatch && queryMatch;
    }).toList();
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
