import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/core/theme/theme_controller.dart';
import 'package:cineconnect/core/tour/tour_controller.dart';
import 'package:cineconnect/features/brand_sponsors/routes/brand_sponsor_routes.dart';
import 'package:cineconnect/features/brand_sponsors/widgets/brand_full_walkthrough_steps.dart';
import 'package:cineconnect/features/brand_sponsors/widgets/brand_sponsor_shell.dart';
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
    expect(brandFullWalkthroughSteps, hasLength(52));
    expect(
      brandFullWalkthroughSteps.map((step) => step.title),
      containsAll([
        'Read the workspace hero',
        'Set the organization identity',
        'Register a campaign project',
        'Set the campaign budget',
        'Review a proposal',
        'Evaluate a full profile',
        'Compare shortlisted candidates',
        'Manage a booking request',
        'Structure the payment schedule',
        'Review submitted proof',
        'Reconcile the ledger',
      ]),
    );
    expect(
      brandFullWalkthroughSteps.map((step) => step.routeName).toSet(),
      containsAll(BrandSponsorRoutes.allRoutes),
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
    expect(find.text('Demo'), findsOneWidget);
    expect(find.byTooltip('Notifications'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('brand-demo-launcher')));
    await tester.pump();
    expect(tour.isActive, isTrue);
    expect(tour.activeTourId, brandFullWalkthroughTourId);
  });
}
