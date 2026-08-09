import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineconnect/core/tour/tour_controller.dart';
import 'package:cineconnect/core/tour/tour_models.dart';

void main() {
  group('TourController', () {
    late GlobalKey<NavigatorState> navigatorKey;
    late TourController controller;

    setUp(() {
      navigatorKey = GlobalKey<NavigatorState>();
      controller = TourController(navigatorKey: navigatorKey);
    });

    const steps = [
      TourStep(
        id: 'a',
        targetId: 'target.a',
        badge: '1 / 2',
        title: 'A',
        description: 'First step',
      ),
      TourStep(
        id: 'b',
        targetId: 'target.b',
        badge: '2 / 2',
        title: 'B',
        description: 'Second step',
      ),
    ];

    test('is inactive before start() is called', () {
      expect(controller.isActive, isFalse);
      expect(controller.currentStep, isNull);
    });

    test('start() activates the tour at the first step', () {
      controller.start(steps, tourId: 'demo');
      expect(controller.isActive, isTrue);
      expect(controller.activeTourId, 'demo');
      expect(controller.currentStep, steps[0]);
      expect(controller.isFirstStep, isTrue);
      expect(controller.isLastStep, isFalse);
    });

    test('next() advances and finish()es past the last step', () {
      controller.start(steps, tourId: 'demo');
      controller.next();
      expect(controller.currentStep, steps[1]);
      expect(controller.isLastStep, isTrue);

      controller.next();
      expect(controller.isActive, isFalse);
      expect(controller.currentStep, isNull);
    });

    test('back() does not move before the first step', () {
      controller.start(steps, tourId: 'demo');
      controller.back();
      expect(controller.currentIndex, 0);
    });

    test('skip() ends the tour immediately and runs onFinished', () {
      var finished = false;
      controller.start(steps, tourId: 'demo', onFinished: () => finished = true);
      controller.skip();
      expect(controller.isActive, isFalse);
      expect(finished, isTrue);
    });

    test('start() with an empty step list is a no-op', () {
      controller.start(const [], tourId: 'empty');
      expect(controller.isActive, isFalse);
    });

    test('registerTarget/rectFor resolves a laid-out target\'s bounds', () {
      final key = GlobalKey();
      controller.registerTarget('target.a', key);
      // No render object attached yet (never built) — resolves to null
      // rather than throwing.
      expect(controller.rectFor('target.a'), isNull);
    });

    test('unregisterTarget only removes a still-current registration', () {
      final oldKey = GlobalKey();
      final newKey = GlobalKey();
      controller.registerTarget('target.a', oldKey);
      controller.registerTarget('target.a', newKey);
      // Disposal of the OLD widget must not clobber the newer registration.
      controller.unregisterTarget('target.a', oldKey);
      expect(controller.rectFor('target.a'), isNull); // newKey unattached too
      controller.unregisterTarget('target.a', newKey);
    });

    test('notifies listeners on start/next/back/finish', () {
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.start(steps, tourId: 'demo');
      controller.next();
      controller.back();
      controller.skip();
      expect(notifications, 4);
    });

    testWidgets(
      'a step with a routeName pushes that route via the shared navigatorKey',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            initialRoute: '/home',
            routes: {
              '/home': (_) => const Scaffold(body: Text('home')),
              '/other': (_) => const Scaffold(body: Text('other')),
            },
          ),
        );
        expect(find.text('home'), findsOneWidget);

        controller.start(
          const [
            TourStep(
              id: 'cross-route',
              targetId: 'target.other',
              badge: '1 / 1',
              title: 'Elsewhere',
              description: 'Lives on another screen.',
              routeName: '/other',
            ),
          ],
          tourId: 'cross-route-demo',
        );
        await tester.pumpAndSettle();

        expect(find.text('other'), findsOneWidget);
      },
    );
  });

  group('TourScope', () {
    testWidgets('of(context) resolves the nearest controller', (tester) async {
      final controller = TourController(navigatorKey: GlobalKey<NavigatorState>());
      late TourController resolved;
      await tester.pumpWidget(
        TourScope(
          controller: controller,
          child: Builder(
            builder: (context) {
              resolved = TourScope.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(identical(resolved, controller), isTrue);
    });

    testWidgets('maybeOf(context) returns null with no ancestor scope', (
      tester,
    ) async {
      TourController? resolved;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            resolved = TourScope.maybeOf(context);
            return const SizedBox.shrink();
          },
        ),
      );
      expect(resolved, isNull);
    });
  });
}
