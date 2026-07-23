import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/admin/admin_controller.dart';
import 'core/auth/auth_controller.dart';
import 'core/auth/auth_repository.dart';
import 'core/auth/token_store.dart';
import 'core/analytics/analytics_controller.dart';
import 'core/bookings/bookings_controller.dart';
import 'core/contracts/contracts_controller.dart';
import 'core/core_ui/core_routes.dart';
import 'core/insurance/insurance_controller.dart';
import 'core/network/api_client.dart';
import 'core/operations/operations_controller.dart';
import 'core/payments/payments_controller.dart';
import 'core/specialist/specialist_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/trust_safety/trust_safety_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiClient = ApiClient();
  final authController = AuthController(
    repository: AuthRepository(apiClient),
    client: apiClient,
    tokenStore: const TokenStore(),
  );
  await authController.initialize();
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
  final PaymentsController? paymentsController;
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
    this.paymentsController,
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
    final app = ThemeControllerProvider(
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
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: controller.themeMode,
            themeAnimationDuration: Duration.zero,
            home: homeOverride,
            initialRoute: homeOverride == null ? initialRoute : null,
            onGenerateRoute: CoreRoutes.onGenerateRoute,
          );
        },
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
                    child: BookingsScope(
                      controller: bookingsController ??
                          BookingsController.fromClient(
                              authController.apiClient),
                      child: app,
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
