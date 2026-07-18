import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/projects/project_models.dart';
import '../../../core/projects/projects_controller.dart';
import '../data/director_producer_demo_data.dart';
import '../models/dp_project.dart';
import '../models/dp_requirement.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_booking_status_spine.dart';
import '../widgets/dp_budget_health_bar.dart';
import '../widgets/dp_empty_state.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_requirement_card.dart';
import '../widgets/dp_status_chip.dart';

class DPProjectDetailScreen extends StatefulWidget {
  final String? projectId;

  const DPProjectDetailScreen({super.key, this.projectId});

  @override
  State<DPProjectDetailScreen> createState() => _DPProjectDetailScreenState();
}

class _DPProjectDetailScreenState extends State<DPProjectDetailScreen> {
  Future<Project>? _projectFuture;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _reload();
    }
  }

  void _reload() {
    final controller = ProjectsScope.maybeOf(context);
    final projectId = widget.projectId;
    setState(() {
      _projectFuture = controller == null || projectId == null
          ? Future<Project>.error(
              const ApiException(
                code: 'project.missing',
                message: 'Project id is required.',
              ),
            )
          : controller.project(projectId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Project>(
      future: _projectFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const DPEmptyState(
            icon: Icons.hourglass_top_rounded,
            title: 'Loading project',
            message: 'Fetching the latest project hub from the server.',
          );
        }
        if (snapshot.hasError) {
          final projects = DirectorProducerDemoData.projects;
          final project = projects.firstWhere(
            (item) => item.id == widget.projectId,
            orElse: () => projects.first,
          );
          return _ProjectDetailBody(
            project: project,
            requirements:
                DirectorProducerDemoData.requirements.take(3).toList(),
            warning: _friendlyError(snapshot.error),
          );
        }
        final project = snapshot.data!;
        return _ProjectDetailBody(
          project: project.toDpProject(),
          requirements: project.requirements
              .map((item) => item.toDpRequirement())
              .toList(),
          projectId: project.publicId,
        );
      },
    );
  }

  String _friendlyError(Object? error) {
    if (error is ApiException && error.code == 'project.missing') {
      return 'No live project selected — showing preview hub.';
    }
    return 'Live project unavailable — showing preview hub.';
  }
}

class _ProjectDetailBody extends StatelessWidget {
  final DpProject project;
  final List<DpRequirement> requirements;
  final String? projectId;
  final String? warning;

  const _ProjectDetailBody({
    required this.project,
    required this.requirements,
    this.projectId,
    this.warning,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (warning != null) ...[
          _InlineWarning(message: warning!),
          const SizedBox(height: 12),
        ],
        DPGlassCard(
          selected: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: dpText(context, project.title, strong: true)),
                  DPStatusChip(label: project.status, tone: DpTone.warning),
                ],
              ),
              const SizedBox(height: 8),
              dpText(
                context,
                '${project.type} - ${project.city} - ${project.dateRange} - PKR ${project.estimatedBudget}',
              ),
              const SizedBox(height: 12),
              DPBudgetHealthBar(value: project.budgetHealth, label: 'Budget'),
              const SizedBox(height: 12),
              const DPBookingStatusSpine(activeIndex: 9),
            ],
          ),
        ),
        const SizedBox(height: 14),
        DPTwoColumn(
          left: DPSectionCard(
            title: 'Open Requirements',
            icon: Icons.rule_folder_outlined,
            actionText: 'Builder',
            onActionTap: () => Navigator.pushNamed(
              context,
              DirectorProducerRoutes.requirements,
              arguments: projectId ?? project.id,
            ),
            child: requirements.isEmpty
                ? const DPEmptyState(
                    icon: Icons.rule_folder_outlined,
                    title: 'No requirements yet',
                    message: 'Open the builder and add your first role.',
                  )
                : Column(
                    children: requirements
                        .take(3)
                        .map(
                          (req) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: DPRequirementCard(
                              requirement: req,
                              onFindMatches: () => Navigator.pushNamed(
                                context,
                                DirectorProducerRoutes.marketplace,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          right: DPSectionCard(
            title: 'Command Actions',
            icon: Icons.bolt_rounded,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                DPHolographicButton(
                  label: 'Send Booking',
                  icon: Icons.send_rounded,
                  onTap: () => Navigator.pushNamed(
                    context,
                    DirectorProducerRoutes.bookingRequest,
                  ),
                ),
                DPHolographicButton(
                  label: 'Contracts',
                  icon: Icons.article_outlined,
                  onTap: () => Navigator.pushNamed(
                    context,
                    DirectorProducerRoutes.contracts,
                  ),
                  secondary: true,
                ),
                DPHolographicButton(
                  label: 'Room',
                  icon: Icons.forum_outlined,
                  onTap: () => Navigator.pushNamed(
                    context,
                    DirectorProducerRoutes.room,
                    arguments: projectId ?? project.id,
                  ),
                  secondary: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineWarning extends StatelessWidget {
  final String message;

  const _InlineWarning({required this.message});

  @override
  Widget build(BuildContext context) {
    return DPGlassCard(
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 18),
          const SizedBox(width: 8),
          Expanded(child: dpText(context, message)),
        ],
      ),
    );
  }
}
