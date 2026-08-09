import 'package:flutter_test/flutter_test.dart';

import 'package:cineconnect/features/director_producer/routes/director_producer_routes.dart';
import 'package:cineconnect/features/director_producer/widgets/dp_full_walkthrough_steps.dart';

void main() {
  test('full walkthrough covers only the 69-step Director workflow', () {
    expect(dpFullWalkthroughSteps, hasLength(69));
    expect(dpFullWalkthroughSteps.first.badge, '1 / 69');
    expect(
      dpFullWalkthroughSteps.first.routeName,
      DirectorProducerRoutes.console,
    );
    expect(dpFullWalkthroughSteps.last.badge, '69 / 69');
    expect(
      dpFullWalkthroughSteps.last.routeName,
      DirectorProducerRoutes.reports,
    );

    const expectedRoutes = {
      DirectorProducerRoutes.console,
      DirectorProducerRoutes.createProject,
      DirectorProducerRoutes.projects,
      DirectorProducerRoutes.marketplace,
      DirectorProducerRoutes.shortlist,
      DirectorProducerRoutes.bookingRequest,
      DirectorProducerRoutes.bargaining,
      DirectorProducerRoutes.contracts,
      DirectorProducerRoutes.schedule,
      DirectorProducerRoutes.payments,
      DirectorProducerRoutes.accounts,
      DirectorProducerRoutes.room,
      DirectorProducerRoutes.reports,
    };
    expect(
      dpFullWalkthroughSteps.map((step) => step.routeName).toSet(),
      expectedRoutes,
    );

    final projectCreationSteps = dpFullWalkthroughSteps.where(
      (step) => step.routeName == DirectorProducerRoutes.createProject,
    );
    expect(projectCreationSteps, hasLength(10));
    expect(projectCreationSteps.first.title, 'Create the production');
    expect(projectCreationSteps.last.title, 'Save the project');

    final ids = dpFullWalkthroughSteps.map((step) => step.id).toSet();
    expect(ids, hasLength(69));
    for (var index = 0; index < dpFullWalkthroughSteps.length; index++) {
      final step = dpFullWalkthroughSteps[index];
      expect(step.badge, '${index + 1} / 69');
      expect(step.title, isNotEmpty);
      expect(step.description, isNotEmpty);
      expect(step.targetId, isNotEmpty);
    }
  });
}
