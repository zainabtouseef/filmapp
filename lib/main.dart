import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/admin/admin_controller.dart';
import 'core/auth/auth_controller.dart';
import 'core/auth/auth_repository.dart';
import 'core/auth/token_store.dart';
import 'core/analytics/analytics_controller.dart';
import 'core/bookings/bookings_controller.dart';
import 'core/casting/casting_controller.dart';
import 'core/cineplanner/cineplanner_controller.dart';
import 'core/contracts/contracts_controller.dart';
import 'core/core_ui/core_routes.dart';
import 'core/credits/credits_controller.dart';
import 'core/insurance/insurance_controller.dart';
import 'core/network/api_client.dart';
import 'core/operations/operations_controller.dart';
import 'core/opportunities/opportunities_controller.dart';
import 'core/payments/payments_controller.dart';
import 'core/projects/projects_controller.dart';
import 'core/specialist/specialist_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/tour/spotlight_overlay.dart';
import 'core/tour/tour_controller.dart';
import 'core/trust_safety/trust_safety_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiClient = ApiClient();
  final authController = AuthController(
    repository: AuthRepository(apiClient),
    client: apiClient,
    tokenStore: const TokenStore(),
  );
  // Never hold the first frame behind browser storage or a session-refresh
  // request. The splash screen waits briefly for this same idempotent future.
  unawaited(authController.initialize());
  runApp(
    CineConnectApp(
      controller: ThemeController(),
      authController: authController,
      bookingsController: BookingsController.fromClient(apiClient),
      contractsController: ContractsController.fromClient(apiClient),
      paymentsController: PaymentsController.fromClient(apiClient),
      operationsController: OperationsController.fromClient(apiClient),
      insuranceController: InsuranceController.fromClient(apiClient),
      specialistController: SpecialistController.fromClient(apiClient),
      trustSafetyController: TrustSafetyController.fromClient(apiClient),
      analyticsController: AnalyticsController.fromClient(apiClient),
      adminController: AdminController.fromClient(apiClient),
    ),
  );
}

class CineConnectApp extends StatelessWidget {
  final ThemeController controller;
  final AuthController authController;
  final BookingsController? bookingsController;
  final ContractsController? contractsController;
  final CastingController? castingController;
  final CinePlannerController? cinePlannerController;
  final OpportunitiesController? opportunitiesController;
  final CreditsController? creditsController;
  final PaymentsController? paymentsController;
  final ProjectsController? projectsController;
  final OperationsController? operationsController;
  final InsuranceController? insuranceController;
  final SpecialistController? specialistController;
  final TrustSafetyController? trustSafetyController;
  final AnalyticsController? analyticsController;
  final AdminController? adminController;
  final String initialRoute;
  final Widget? homeOverride;

  const CineConnectApp({
    super.key,
    required this.controller,
    required this.authController,
    this.bookingsController,
    this.contractsController,
    this.castingController,
    this.cinePlannerController,
    this.opportunitiesController,
    this.creditsController,
    this.paymentsController,
    this.projectsController,
    this.operationsController,
    this.insuranceController,
    this.specialistController,
    this.trustSafetyController,
    this.analyticsController,
    this.adminController,
    this.initialRoute = CoreRoutes.splash,
    this.homeOverride,
  });

  @override
  Widget build(BuildContext context) {
    final tourController =
        TourController(navigatorKey: CoreRoutes.navigatorKey);

    final app = TourScope(
      controller: tourController,
      child: ThemeControllerProvider(
        controller: controller,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final isDark = controller.isDarkMode;

            SystemChrome.setSystemUIOverlayStyle(
              SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness:
                    isDark ? Brightness.light : Brightness.dark,
                systemNavigationBarColor:
                    isDark ? const Color(0xFF171817) : const Color(0xFFF8F5EF),
                systemNavigationBarIconBrightness:
                    isDark ? Brightness.light : Brightness.dark,
              ),
            );

            return MaterialApp(
              title: 'CineConnect',
              debugShowCheckedModeBanner: false,
              navigatorKey: CoreRoutes.navigatorKey,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: controller.themeMode,
              themeAnimationDuration: Duration.zero,
              home: homeOverride,
              initialRoute: homeOverride == null ? initialRoute : null,
              // Flutter's default initial-route generator expands a deep link
              // such as `/admin/disputes/123` into `/`, `/admin`, and the
              // requested route. In CineConnect that unnecessarily creates a
              // hidden SplashScreen, which can restore a session and navigate
              // underneath the requested workspace. Generate the requested
              // route directly so browser refreshes and shared links are
              // deterministic.
              onGenerateInitialRoutes: homeOverride == null
                  ? (routeName) => <Route<dynamic>>[
                        CoreRoutes.onGenerateRoute(
                          RouteSettings(name: routeName),
                        ),
                      ]
                  : null,
              onGenerateRoute: CoreRoutes.onGenerateRoute,
              // `builder`'s content sits above the app's own Navigator, so
              // it has no Overlay/Material ancestor of its own yet — both
              // are required by SpotlightOverlay's Tooltip/InkResponse
              // controls, so it gets its own self-contained pair here
              // rather than crashing at runtime (a gap `flutter analyze`
              // can't catch; only caught by actually pumping the widget).
              builder: (context, child) => Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (context) => Material(
                      type: MaterialType.transparency,
                      child: Stack(
                        children: [
                          if (child != null) child,
                          const Positioned.fill(
                            child: SpotlightOverlay(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    final adminScope = AdminScope(
      controller: adminController ??
          AdminController.fromClient(authController.apiClient),
      child: AnalyticsScope(
        controller: analyticsController ??
            AnalyticsController.fromClient(authController.apiClient),
        child: TrustSafetyScope(
          controller: trustSafetyController ??
              TrustSafetyController.fromClient(authController.apiClient),
          child: SpecialistScope(
            controller: specialistController ??
                SpecialistController.fromClient(authController.apiClient),
            child: InsuranceScope(
              controller: insuranceController ??
                  InsuranceController.fromClient(authController.apiClient),
              child: OperationsScope(
                controller: operationsController ??
                    OperationsController.fromClient(authController.apiClient),
                child: PaymentsScope(
                  controller: paymentsController ??
                      PaymentsController.fromClient(authController.apiClient),
                  child: ContractsScope(
                    controller: contractsController ??
                        ContractsController.fromClient(
                            authController.apiClient),
                    child: ProjectsScope(
                      controller: projectsController ??
                          ProjectsController.fromClient(
                              authController.apiClient),
                      child: CinePlannerScope(
                        controller: cinePlannerController ??
                            CinePlannerController.fromClient(
                              authController.apiClient,
                            ),
                        child: BookingsScope(
                          controller: bookingsController ??
                              BookingsController.fromClient(
                                  authController.apiClient),
                          child: CastingScope(
                            controller: castingController ??
                                CastingController.fromClient(
                                  authController.apiClient,
                                ),
                            child: OpportunitiesScope(
                              controller: opportunitiesController ??
                                  OpportunitiesController.fromClient(
                                    authController.apiClient,
                                  ),
                              child: CreditsScope(
                                controller: creditsController ??
                                    CreditsController.fromClient(
                                      authController.apiClient,
                                    ),
                                child: app,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return AuthScope(
      controller: authController,
      child: adminScope,
    );
  }
}
