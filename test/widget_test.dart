import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:cineconnect/main.dart';
import 'package:cineconnect/screens/dashboard_screen.dart';
import 'package:cineconnect/theme/theme_controller.dart';

void main() {
  testWidgets('renders CineConnect dashboard without overflow errors', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(CineConnectApp(controller: ThemeController()));
    await tester.pumpAndSettle();

    final exception = tester.takeException();

    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.text('Featured Talent'), findsOneWidget);
    expect(exception, isNull, reason: 'Unexpected exception: $exception');
  });
}
