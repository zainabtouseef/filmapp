import 'dart:convert';

import 'package:cineconnect/core/cineplanner/cineplanner_controller.dart';
import 'package:cineconnect/core/network/api_client.dart';
import 'package:cineconnect/core/projects/projects_controller.dart';
import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/features/director_producer/routes/director_producer_routes.dart';
import 'package:cineconnect/features/director_producer/screens/cineplanner_console_screen.dart';
import 'package:cineconnect/features/director_producer/widgets/dp_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('CinePlanner is a Director/Producer route and prominent nav item', () {
    expect(
      DirectorProducerRoutes.allRoutes,
      contains(DirectorProducerRoutes.cinePlanner),
    );
    expect(
      DPShell.navItems.any((item) =>
          item.label == 'CinePlanner' &&
          item.route == DirectorProducerRoutes.cinePlanner),
      isTrue,
    );
  });

  testWidgets('first use renders connected production onboarding',
      (tester) async {
    final client = ApiClient(
      baseUrl: 'https://test.example/api/v1',
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/cineplanner/productions')) {
          return http.Response(
            jsonEncode({
              'data': {'productions': <Object>[]},
              'meta': {'pagination': null, 'request_id': 'req_test'},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/projects')) {
          return http.Response(
            jsonEncode({
              'data': {'projects': <Object>[]},
              'meta': {'pagination': null, 'request_id': 'req_test'},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 404);
      }),
    );
    final cinePlanner = CinePlannerController.fromClient(client);
    final projects = ProjectsController.fromClient(client);

    await tester.pumpWidget(
      ProjectsScope(
        controller: projects,
        child: CinePlannerScope(
          controller: cinePlanner,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: CinePlannerConsoleScreen()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CinePlanner'), findsOneWidget);
    expect(find.text('Create your first project plan'), findsOneWidget);
    expect(find.text('Project name'), findsOneWidget);
    expect(find.text('Select screenplay PDF'), findsOneWidget);
    expect(find.text('Create project & plan script'), findsOneWidget);
  });

  testWidgets('loaded production uses the compact premium portal language',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final production = {
      'public_id': 'CPR-CINEPLANNER-001',
      'title': 'Shehar Ke Paar',
      'currency': 'PKR',
    };
    final snapshot = {
      'production': production,
      'permissions': ['*'],
      'scripts': <Object>[],
      'jobs': <Object>[],
      'dashboard': {
        'screenplay_title': 'Shehar Ke Paar',
        'total_pages': 13,
        'total_scenes': 60,
        'characters': 11,
        'lead_characters': 3,
        'locations': 43,
        'props': 12,
        'scheduled_shoot_days': 13,
        'production_progress': 100,
        'estimated_budget_minor': 125000000,
        'upcoming_shoot': '2026-09-07',
        'schedule_conflicts': 1,
        'actor_availability_issues': 0,
        'unapproved_ai_items': 0,
        'high_complexity_scenes': 8,
      },
      'scenes': <Object>[],
      'characters': <Object>[],
      'locations': <Object>[],
      'elements': <Object>[],
      'actors': <Object>[],
      'cast_assignments': <Object>[],
      'crew': <Object>[],
      'call_sheets': <Object>[],
      'team': <Object>[],
      'schedule': {
        'locked': true,
        'days': <Object>[],
        'conflicts': [
          {
            'severity': 'warning',
            'message': 'Night-filming permit required',
            'type': 'location_permit',
          },
        ],
      },
      'budget': {
        'currency': 'PKR',
        'totals': <String, Object>{},
        'lines': <Object>[],
      },
    };
    final client = ApiClient(
      baseUrl: 'https://test.example/api/v1',
      httpClient: MockClient((request) async {
        final data = request.url.path.endsWith('/cineplanner/productions')
            ? {
                'productions': [production],
              }
            : snapshot;
        return http.Response(
          jsonEncode({
            'data': data,
            'meta': {'pagination': null, 'request_id': 'req_premium'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final cinePlanner = CinePlannerController.fromClient(client);
    final projects = ProjectsController.fromClient(client);

    await tester.pumpWidget(
      ProjectsScope(
        controller: projects,
        child: CinePlannerScope(
          controller: cinePlanner,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: CinePlannerConsoleScreen()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('cineplanner-premium-shell')),
      findsOneWidget,
    );
    expect(find.text('Shehar Ke Paar'), findsWidgets);
    expect(find.text('60'), findsOneWidget);
    expect(find.text('11'), findsOneWidget);
    expect(find.text('1 open schedule conflicts'), findsOneWidget);

    final activeModule = tester.widget<Container>(
      find.byKey(const ValueKey('cineplanner-module-Dashboard')),
    );
    final decoration = activeModule.decoration! as BoxDecoration;
    expect((decoration.border! as Border).left.width, 3);
    expect(tester.takeException(), isNull);

    const modules = [
      'Screenplay',
      'Scenes',
      'Characters',
      'Casting',
      'Locations',
      'Props',
      'Wardrobe',
      'Makeup',
      'Vehicles',
      'Extras',
      'Stunts',
      'VFX / SFX',
      'Equipment',
      'Crew',
      'Scheduling',
      'Timetable',
      'Budget',
      'Call Sheets',
      'Reports',
      'AI Assistant',
      'Settings',
    ];
    for (final module in modules) {
      final moduleFinder = find.byKey(ValueKey('cineplanner-module-$module'));
      for (var attempt = 0;
          moduleFinder.evaluate().isEmpty && attempt < 5;
          attempt++) {
        await tester.drag(
          find.byType(ListView).first,
          const Offset(0, -220),
        );
        await tester.pump();
      }
      expect(moduleFinder, findsOneWidget,
          reason: '$module should be reachable');
      await tester.ensureVisible(moduleFinder);
      await tester.pump();
      await tester.tap(moduleFinder);
      await tester.pump();
      expect(tester.takeException(), isNull, reason: '$module should render');
    }
  });
}
