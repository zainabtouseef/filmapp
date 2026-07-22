import 'package:flutter/material.dart';

import '../../data/director_producer_demo_data.dart';
import '../../routes/director_producer_routes.dart';
import '../dp_project_card.dart';

/// The "Project Command Deck" — three active-production previews, with the
/// complete list available from the parent section action.
class DPProjectDeck extends StatelessWidget {
  const DPProjectDeck({super.key});

  @override
  Widget build(BuildContext context) {
    final projects = DirectorProducerDemoData.projects;
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
