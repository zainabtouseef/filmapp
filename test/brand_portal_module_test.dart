import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/core/theme/theme_controller.dart';
import 'package:cineconnect/core/tour/tour_controller.dart';
import 'package:cineconnect/features/brand_sponsors/routes/brand_sponsor_routes.dart';
import 'package:cineconnect/features/brand_sponsors/widgets/brand_sponsor_shell.dart';
import 'package:cineconnect/features/brand_sponsors/widgets/brand_tour_steps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Brand Portal exposes connected production routes and guide steps', () {
    expect(
      BrandSponsorRoutes.allRoutes,
      containsAll([
        BrandSponsorRoutes.projects,
        BrandSponsorRoutes.marketplace,
        BrandSponsorRoutes.shortlists,
        BrandSponsorRoutes.bookings,
      ]),
    );
    expect(
      brandSponsorMenuEntries.map((item) => item.route),
      containsAll(BrandSponsorRoutes.allRoutes),
    );
    expect(brandTourSteps, hasLength(10));
    expect(
      brandTourSteps.map((step) => step.title),
      containsAll([
        'Meet the project',
        '1. Register the production',
        '2. Register every requirement',
        '3. Keep discovery project-scoped',
        '4. Evaluate the complete profile',
        '5. Compare one production team',
        '6. Follow every response',
        '7. Negotiate and communicate',
        '8. Return to the production truth',
        'The connected flow is complete',
      ]),
    );
  });

  testWidgets('mobile Brand shell renders and launches the guided tour',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final navigatorKey = GlobalKey<NavigatorState>();
    final tour = TourController(navigatorKey: navigatorKey);
    await tester.pumpWidget(
      ThemeControllerProvider(
        controller: ThemeController(initialThemeMode: ThemeMode.light),
        child: TourScope(
          controller: tour,
          child: MaterialApp(
            navigatorKey: navigatorKey,
            theme:
                AppTheme.light.copyWith(splashFactory: NoSplash.splashFactory),
            onGenerateRoute: (settings) => MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const Scaffold(),
            ),
            home: const BrandSponsorShell(
              routeName: BrandSponsorRoutes.home,
              title: 'Brand Workspace',
              screenId: 'BR-01',
              child: SizedBox(height: 200),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('brand-demo-launcher')), findsOneWidget);
    expect(find.text('Project demo'), findsOneWidget);
    expect(find.byTooltip('Notifications'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('brand-demo-launcher')));
    await tester.pump();
    expect(tour.isActive, isTrue);
    expect(tour.activeTourId, brandTourId);
  });
}
