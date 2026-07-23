import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../models/dp_project.dart';
import '../../routes/director_producer_routes.dart';
import '../dp_project_card.dart';

/// The "Project Command Deck" — three active-production previews, with the
/// complete list available from the parent section action.
class DPProjectDeck extends StatelessWidget {
  final List<DpProject> projects;

  const DPProjectDeck({super.key, required this.projects});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (projects.isEmpty) {
      return Text(
        'No live projects are available yet. Create a project to start the command deck.',
        style: AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final project in projects.take(3)) ...[
            SizedBox(
              width: 330,
              child: DPProjectCard(
                project: project,
                onOpen: () => Navigator.pushNamed(
                  context,
                  DirectorProducerRoutes.projectDetail,
                  arguments: project.id,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}
