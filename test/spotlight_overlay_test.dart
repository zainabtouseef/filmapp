import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/core/theme/theme_controller.dart';
import 'package:cineconnect/core/tour/spotlight_overlay.dart';
import 'package:cineconnect/core/tour/tour_controller.dart';
import 'package:cineconnect/core/tour/tour_models.dart';
import 'package:cineconnect/core/tour/tour_target.dart';

const _steps = [
  TourStep(
    id: 'one',
    targetId: 'demo.button',
    badge: 'STEP ONE',
    title: 'First step',
    description: 'Tap the highlighted button, or use Next below.',
  ),
  TourStep(
    id: 'two',
    targetId: 'demo.card',
    badge: 'STEP TWO',
    title: 'Second step',
    description: 'Almost done.',
  ),
];

Future<TourController> _pumpDemo(
  WidgetTester tester, {
  required Size size,
  VoidCallback? onButtonTap,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final navigatorKey = GlobalKey<NavigatorState>();
  final controller = TourController(navigatorKey: navigatorKey);

  await tester.pumpWidget(
    ThemeControllerProvider(
      controller: ThemeController(),
      child: TourScope(
        controller: controller,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          builder: (context, child) => Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => Material(
                  type: MaterialType.transparency,
                  child: Stack(
                    children: [
                      if (child != null) child,
                      const Positioned.fill(child: SpotlightOverlay()),
                    ],
                  ),
                ),
              ),
            ],
          ),
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TourTarget(
                    id: 'demo.button',
                    child: ElevatedButton(
                      onPressed: onButtonTap ?? () {},
                      child: const Text('Do the thing'),
                    ),
                  ),
                  TourTarget(
                    id: 'demo.card',
                    child: Container(
                      width: 120,
                      height: 60,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return controller;
}

void main() {
  for (final size in [const Size(320, 640), const Size(1600, 900)]) {
    testWidgets('renders the current step with no exceptions at $size', (
      tester,
    ) async {
      final controller = await _pumpDemo(tester, size: size);
      controller.start(_steps, tourId: 'demo');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('First step'), findsOneWidget);
      expect(find.text('STEP ONE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('nothing is rendered before a tour starts', (tester) async {
    await _pumpDemo(tester, size: const Size(400, 800));
    expect(find.text('First step'), findsNothing);
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Next advances to the next step and Done ends it', (
    tester,
  ) async {
    final controller = await _pumpDemo(tester, size: const Size(400, 800));
    controller.start(_steps, tourId: 'demo');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Second step'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pump();
    expect(controller.isActive, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Skip ends the tour immediately', (tester) async {
    final controller = await _pumpDemo(tester, size: const Size(400, 800));
    controller.start(_steps, tourId: 'demo');
    await tester.pump();

    await tester.tap(find.byTooltip('Skip tour'));
    await tester.pump();
    expect(controller.isActive, isFalse);
  });

  testWidgets(
    'tapping the real highlighted widget through the cutout both fires '
    'its own action and advances the tour',
    (tester) async {
      var tapped = false;
      final controller = await _pumpDemo(
        tester,
        size: const Size(400, 800),
        onButtonTap: () => tapped = true,
      );
      controller.start(_steps, tourId: 'demo');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('Do the thing'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tapped, isTrue);
      expect(find.text('Second step'), findsOneWidget);
    },
  );

  testWidgets('the rest of the app is blocked from taps mid-tour', (
    tester,
  ) async {
    var tapped = false;
    final controller = await _pumpDemo(
      tester,
      size: const Size(400, 800),
      onButtonTap: () => tapped = true,
    );
    controller.start(_steps, tourId: 'demo');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Step one highlights the button, not the card — tapping the card
    // should be absorbed by the scrim rather than reaching it.
    await tester.tap(find.byType(Container).first, warnIfMissed: false);
    await tester.pump();

    expect(tapped, isFalse);
    expect(find.text('First step'), findsOneWidget);
  });
}
