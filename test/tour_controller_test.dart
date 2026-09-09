import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineconnect/core/tour/tour_controller.dart';
import 'package:cineconnect/core/tour/tour_models.dart';
import 'package:cineconnect/core/tour/tour_target.dart';

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
      controller.start(steps,
          tourId: 'demo', onFinished: () => finished = true);
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

    testWidgets('consecutive steps on one route do not push duplicate pages', (
      tester,
    ) async {
      var otherBuilds = 0;
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          initialRoute: '/home',
          routes: {
            '/home': (_) => const Scaffold(body: Text('home')),
            '/other': (_) {
              otherBuilds++;
              return const Scaffold(body: Text('other'));
            },
          },
        ),
      );

      controller.start(
        const [
          TourStep(
            id: 'other-one',
            targetId: 'target.other',
            badge: '1 / 2',
            title: 'Other one',
            description: 'First lesson on this page.',
            routeName: '/other',
          ),
          TourStep(
            id: 'other-two',
            targetId: 'target.other',
            badge: '2 / 2',
            title: 'Other two',
            description: 'Second lesson on this page.',
            routeName: '/other',
          ),
        ],
        tourId: 'same-route-demo',
      );
      await tester.pumpAndSettle();
      expect(otherBuilds, 1);

      controller.next();
      await tester.pumpAndSettle();

      expect(otherBuilds, 1);
      expect(find.text('other'), findsOneWidget);
    });

    testWidgets('replaceRoutes keeps a full walkthrough off the page stack', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          routes: {
            '/': (_) => const Scaffold(body: Text('home')),
            '/other': (_) => const Scaffold(body: Text('other')),
          },
        ),
      );

      controller.start(
        const [
          TourStep(
            id: 'replace-route',
            targetId: 'target.other',
            badge: '1 / 1',
            title: 'Other',
            description: 'Replace the current walkthrough page.',
            routeName: '/other',
          ),
        ],
        tourId: 'replacement-demo',
        replaceRoutes: true,
      );
      await tester.pumpAndSettle();

      expect(find.text('other'), findsOneWidget);
      expect(navigatorKey.currentState!.canPop(), isFalse);
    });
  });

  testWidgets('registering an active target during build notifies after frame',
      (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final controller = TourController(navigatorKey: navigatorKey);
    const buildStep = TourStep(
      id: 'build-target',
      targetId: 'target-during-build',
      badge: '1 / 1',
      title: 'Build target',
      description: 'The target mounts after the tour starts.',
    );
    var notifications = 0;
    controller.addListener(() => notifications++);
    controller.start(const [buildStep], tourId: 'build-target-test');
    final afterStart = notifications;

    await tester.pumpWidget(
      TourScope(
        controller: controller,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(
            body: TourTarget(
              id: 'target-during-build',
              child: SizedBox(width: 40, height: 40),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(notifications, greaterThan(afterStart));
  });

  group('TourScope', () {
    testWidgets('of(context) resolves the nearest controller', (tester) async {
      final controller =
          TourController(navigatorKey: GlobalKey<NavigatorState>());
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
