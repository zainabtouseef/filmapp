import 'package:cineconnect/core/projects/project_models.dart';
import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/shared/projects/project_readiness_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'saved planning data reports missing fields without fake completion',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final project = Project.fromJson(
        {'public_id': 'PRJ-1', 'title': 'Test film', 'progress_percent': 90});
    final requirement = ProjectRequirement.fromJson({
      'public_id': 'REQ-1',
      'title': 'Director of Photography',
      'status': 'open'
    });
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
            body: SingleChildScrollView(
                child: ProjectReadinessSummary(
                    project: project, requirements: [requirement])))));
    expect(find.text('Completed (2)'), findsOneWidget);
    expect(find.text('Missing (4)'), findsOneWidget);
    expect(find.text('Pending (1)'), findsOneWidget);
    expect(
        find.textContaining('Director of Photography · open'), findsOneWidget);
    expect(find.text('90%'), findsNothing);
    await tester.ensureVisible(find.text('Pending (1)'));
    expect(tester.takeException(), isNull);
  });
}
