import 'package:cineconnect/core/network/api_client.dart';
import 'package:cineconnect/core/projects/project_models.dart';
import 'package:cineconnect/core/projects/projects_controller.dart';
import 'package:cineconnect/core/projects/projects_repository.dart';
import 'package:cineconnect/features/director_producer/widgets/dp_project_console_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Projects extends ProjectsController {
  int loads = 0;
  bool fail = false;
  _Projects() : super(repository: ProjectsRepository(ApiClient()));
  @override
  Future<List<Project>> projects({bool force = false}) async {
    loads++;
    if (fail) throw StateError('QA outage');
    await Future<void>.delayed(Duration.zero);
    notifyListeners();
    return [
      Project.fromJson({'public_id': 'PRJ-QA', 'title': 'Real QA project'})
    ];
  }
}

void main() {
  testWidgets('project options survive controller notifications and selection',
      (tester) async {
    final controller = _Projects();
    String? selected;
    await tester.pumpWidget(ProjectsScope(
      controller: controller,
      child: MaterialApp(
          home: Scaffold(
              body: DPProjectScopePicker(
        selectedProjectId: null,
        onChanged: (value) => selected = value,
      ))),
    ));
    await tester.pumpAndSettle();
    expect(controller.loads, 1);
    await tester.tap(find.text('All projects'));
    await tester.pumpAndSettle();
    expect(find.text('Real QA project'), findsOneWidget);
    await tester.tap(find.text('Real QA project'));
    await tester.pumpAndSettle();
    expect(selected, 'PRJ-QA');
    expect(controller.loads, 1);
  });

  testWidgets('failed project loading offers an actual retry', (tester) async {
    final controller = _Projects()..fail = true;
    await tester.pumpWidget(ProjectsScope(
      controller: controller,
      child: MaterialApp(
          home: Scaffold(
              body: DPProjectScopePicker(
        selectedProjectId: null,
        onChanged: (_) {},
      ))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Retry loading projects'), findsOneWidget);
    controller.fail = false;
    await tester.tap(find.text('Retry loading projects'));
    await tester.pumpAndSettle();
    expect(controller.loads, 2);
    expect(find.text('All projects'), findsOneWidget);
  });
}
