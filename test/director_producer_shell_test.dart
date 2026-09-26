import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/core/theme/theme_controller.dart';
import 'package:cineconnect/core/tour/tour_controller.dart';
import 'package:cineconnect/features/director_producer/routes/director_producer_routes.dart';
import 'package:cineconnect/features/director_producer/widgets/dp_full_walkthrough_steps.dart';
import 'package:cineconnect/features/director_producer/widgets/dp_shell.dart';

void main() {
  Future<TourController> pumpShell(
    WidgetTester tester, {
    required Size size,
    String currentRoute = DirectorProducerRoutes.console,
    Widget child = const SizedBox(height: 200),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final navigatorKey = GlobalKey<NavigatorState>();
    final controller = TourController(navigatorKey: navigatorKey);
    await tester.pumpWidget(
      ThemeControllerProvider(
        controller: ThemeController(initialThemeMode: ThemeMode.light),
        child: TourScope(
          controller: controller,
          child: MaterialApp(
            navigatorKey: navigatorKey,
            theme: AppTheme.light,
            onGenerateRoute: (settings) => MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const Scaffold(),
            ),
            home: DPShell(
              title: 'Dashboard',
              currentRoute: currentRoute,
              showHeading: false,
              child: child,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return controller;
  }

  testWidgets('mobile DP shell exposes the guided tour through About',
      (tester) async {
    final controller = await pumpShell(tester, size: const Size(390, 844));

    expect(find.byTooltip('About CineConnect'), findsOneWidget);
    expect(find.text('Demo'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('About CineConnect'));
    await tester.pumpAndSettle();
    expect(find.text('Guided tour'), findsOneWidget);
    await tester.tap(find.text('Guided tour'));
    await tester.pumpAndSettle();

    expect(controller.isActive, isTrue);
    expect(controller.activeTourId, dpFullWalkthroughTourId);
  });

  testWidgets('desktop keeps About in the top bar', (tester) async {
    await pumpShell(tester, size: const Size(1440, 1000));

    expect(find.byTooltip('About CineConnect'), findsOneWidget);
    expect(find.byTooltip('Take the tour'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CinePlanner receives bounded height inside the portal',
      (tester) async {
    await pumpShell(
      tester,
      size: const Size(1440, 1000),
      currentRoute: DirectorProducerRoutes.cinePlanner,
      child: const Column(
        children: [
          Text('CinePlanner toolbar'),
          Expanded(child: Center(child: Text('CinePlanner dashboard'))),
        ],
      ),
    );

    expect(find.text('CinePlanner toolbar'), findsOneWidget);
    expect(find.text('CinePlanner dashboard'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
