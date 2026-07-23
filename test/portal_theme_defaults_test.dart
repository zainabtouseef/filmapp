import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/core/theme/theme_controller.dart';
import 'package:cineconnect/features/media_equipment/routes/media_equipment_routes.dart';
import 'package:cineconnect/features/media_equipment/screens/media_equipment_portal_screen.dart';

void main() {
  test('portal theme defaults to light', () {
    expect(ThemeController().themeMode, ThemeMode.light);
  });

  testWidgets('portal header switches between light and dark modes',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = ThemeController();
    await tester.pumpWidget(
      ThemeControllerProvider(
        controller: controller,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: controller.themeMode,
            home: const MediaEquipmentPortalScreen(
              routeName: MediaEquipmentRoutes.home,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(controller.themeMode, ThemeMode.light);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(MediaEquipmentPortalScreen)))
          .brightness,
      Brightness.light,
    );

    await tester.tap(find.byIcon(Icons.dark_mode_outlined));
    await tester.pumpAndSettle();

    expect(controller.themeMode, ThemeMode.dark);
    expect(find.byIcon(Icons.wb_sunny_outlined), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(MediaEquipmentPortalScreen)))
          .brightness,
      Brightness.dark,
    );
    expect(tester.takeException(), isNull);
  });
}
