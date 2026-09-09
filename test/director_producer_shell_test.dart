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

  testWidgets('mobile DP shell always shows a labeled demo launcher',
      (tester) async {
    final controller = await pumpShell(tester, size: const Size(390, 844));

    expect(find.byKey(const ValueKey('dp-demo-launcher')), findsOneWidget);
    expect(find.text('Demo'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final launcher = tester.widget<InkWell>(
      find.byKey(const ValueKey('dp-demo-launcher')),
    );
    launcher.onTap!();

    expect(controller.isActive, isTrue);
    expect(controller.activeTourId, dpFullWalkthroughTourId);
  });

  testWidgets('desktop keeps the tour action in the top bar', (tester) async {
    await pumpShell(tester, size: const Size(1440, 1000));

    expect(find.byKey(const ValueKey('dp-demo-launcher')), findsNothing);
    expect(find.byTooltip('Take the tour'), findsOneWidget);
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
