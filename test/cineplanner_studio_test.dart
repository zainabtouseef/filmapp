import 'dart:convert';
import 'package:cineconnect/core/cineplanner/cineplanner_controller.dart';
import 'package:cineconnect/core/network/api_client.dart';
import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/features/director_producer/screens/cineplanner_chat_panel.dart';
import 'package:cineconnect/features/director_producer/screens/cineplanner_plan_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('chat reviews changes, applies once, and offers undo',
      (tester) async {
    var status = 'proposed';
    var applied = 0;
    final snapshot = {
      'access': {'full_access': true, 'alterations_remaining': 10},
      'scenes': <Object>[],
      'jobs': <Object>[]
    };
    final api = ApiClient(
        baseUrl: 'https://test.example/api/v1',
        httpClient: MockClient((request) async {
          Map<String, dynamic> data;
          if (request.url.path.endsWith('/apply')) {
            applied++;
            status = 'applied';
            data = {};
          } else if (request.url.path.endsWith('/undo')) {
            status = 'undone';
            data = {};
          } else if (request.url.path.endsWith('/assistant/messages')) {
            data = {
              'messages': [
                {
                  'public_id': 'CAM-1',
                  'role': 'assistant',
                  'status': status,
                  'content': 'A focused change for scene 1.',
                  'changes': [
                    {
                      'resource': 'scenes',
                      'action': 'update',
                      'before': {'summary': 'Original summary'},
                      'after': {'summary': 'Improved summary'}
                    }
                  ]
                }
              ]
            };
          } else {
            data = snapshot;
          }
          return http.Response(jsonEncode({'data': data}), 200);
        }));
    final controller = CinePlannerController.fromClient(api)
      ..selectedProductionId = 'CPR-1'
      ..snapshot = snapshot;
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
            body: CinePlannerChatPanel(
                productionId: 'CPR-1', controller: controller))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review 1 proposed item'));
    await tester.pumpAndSettle();
    expect(find.text('Original summary'), findsOneWidget);
    expect(find.text('Improved summary'), findsOneWidget);
    await tester.ensureVisible(find.text('Apply · 1 alteration'));
    await tester.tap(find.text('Apply · 1 alteration'));
    await tester.pumpAndSettle();
    expect(applied, 1);
    expect(find.text('Undo these changes'), findsOneWidget);
    await tester.tap(find.text('Undo these changes'));
    await tester.pumpAndSettle();
    expect(status, 'undone');
    expect(applied, 1);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets(
      'Complete plan shows pending bank review without another payment form',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final api = ApiClient(
        baseUrl: 'https://test.example/api/v1',
        httpClient: MockClient((_) async => http.Response(
            jsonEncode({
              'data': {
                'access': {'full_access': false},
                'payments': [
                  {'reference': 'BANK-001', 'status': 'pending'}
                ]
              }
            }),
            200)));
    final controller = CinePlannerController.fromClient(api);
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
            body: Padding(
                padding: const EdgeInsets.all(16),
                child: CinePlannerPlanPanel(controller: controller)))));
    await tester.pumpAndSettle();
    expect(find.text(r'$20 / month'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Payment awaiting approval'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Payment awaiting approval'), findsOneWidget);
    expect(find.text('Submit for finance approval'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
