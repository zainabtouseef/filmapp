import 'package:cineconnect/core/auth/auth_controller.dart';
import 'package:cineconnect/core/auth/auth_repository.dart';
import 'package:cineconnect/core/auth/token_store.dart';
import 'package:cineconnect/core/director/director_dashboard_models.dart';
import 'package:cineconnect/core/director/director_discovery_models.dart';
import 'package:cineconnect/core/network/api_client.dart';
import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/features/director_producer/screens/dp_home_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _DirectorHomeAuth extends AuthController {
  final DirectorDashboard dashboard;
  final DirectorSchedule schedule;
  int dashboardLoads = 0;
  int scheduleLoads = 0;
  int discoveryLoads = 0;

  _DirectorHomeAuth({required this.dashboard, required this.schedule})
      : super(
          repository: AuthRepository(ApiClient()),
          client: ApiClient(),
          tokenStore: const TokenStore(),
        );

  @override
  bool get isAuthenticated => true;

  @override
  Future<DirectorDashboard> directorDashboard() async {
    dashboardLoads++;
    return dashboard;
  }

  @override
  Future<DirectorSchedule> directorSchedule({String? projectId}) async {
    scheduleLoads++;
    return schedule;
  }

  @override
  Future<DirectorDiscoveryBundle> directorDiscovery({
    String? category,
    String? query,
    String? city,
    String? subcategory,
    bool? verifiedOnly,
    bool? newOnly,
  }) async {
    discoveryLoads++;
    return const DirectorDiscoveryBundle(
      items: [],
      kindCounts: {},
      cityCounts: {},
      unsupportedCategories: {},
    );
  }
}

void main() {
  testWidgets(
    'Director dashboard uses the live schedule once and shows one day pipeline',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();
      final auth = _DirectorHomeAuth(
        dashboard: DirectorDashboard.fromJson(const <String, dynamic>{}),
        schedule: DirectorSchedule(
          events: [
            DirectorScheduleEvent.fromJson({
              'public_id': 'evt-live-1',
              'project_id': 'prj-live-1',
              'project_title': 'Live Project',
              'title': 'Camera blocking rehearsal',
              'starts_at': DateTime(
                now.year,
                now.month,
                now.day,
                14,
                30,
              ).toIso8601String(),
              'ends_at': DateTime(
                now.year,
                now.month,
                now.day,
                15,
                30,
              ).toIso8601String(),
            }),
          ],
          risks: const [],
          callSheet: DirectorCallSheet.fromJson(const <String, dynamic>{}),
        ),
      );

      await tester.pumpWidget(
        AuthScope(
          controller: auth,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(
              body: SingleChildScrollView(child: DPHomeDashboardScreen()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(auth.dashboardLoads, 1);
      expect(auth.scheduleLoads, 1);
      expect(auth.discoveryLoads, 1);
      expect(find.text("Today's schedule"), findsOneWidget);
      expect(find.text('Camera blocking rehearsal'), findsWidgets);
      expect(find.text('Live Project'), findsOneWidget);
      expect(find.text('From screenplay'), findsOneWidget);
      expect(find.text('to call sheet.'), findsOneWidget);
      expect(find.text('Discover'), findsWidgets);
      expect(find.text('Production workflow'), findsNothing);
      expect(find.text("Today's Production Timeline"), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
