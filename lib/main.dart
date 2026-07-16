import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/core_ui/core_routes.dart';
import 'core/core_ui/screens/onboarding_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(CineConnectApp(controller: ThemeController()));
}

class CineConnectApp extends StatelessWidget {
  final ThemeController controller;

  const CineConnectApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ThemeControllerProvider(
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
                  isDark ? const Color(0xFF0A0A0B) : const Color(0xFFFBFAF7),
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
            home: const OnboardingScreen(),
            onGenerateRoute: CoreRoutes.onGenerateRoute,
            builder: (context, child) {
              return AnimatedTheme(
                data: Theme.of(context),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
