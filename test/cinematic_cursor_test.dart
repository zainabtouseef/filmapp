import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineconnect/core/theme/app_durations.dart';
import 'package:cineconnect/shared/widgets/cinematic_cursor.dart';

void main() {
  testWidgets('mouse movement shows the cinematic trailing ring',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CinematicCursor(child: SizedBox.expand()),
      ),
    );

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(120, 90));
    await mouse.moveTo(const Offset(180, 130));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const ValueKey('cinematic-cursor-ring')), findsOneWidget);

    await mouse.removePointer();
    await tester.pump();
    expect(find.byKey(const ValueKey('cinematic-cursor-ring')), findsNothing);
  });

  testWidgets('touch shows lightning and a fading bubble trail',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CinematicCursor(child: SizedBox.expand()),
      ),
    );

    final touch = await tester.createGesture(kind: PointerDeviceKind.touch);
    await touch.down(const Offset(80, 110));
    await touch.moveTo(const Offset(128, 146));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byKey(const ValueKey('cinematic-cursor-lightning')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('cinematic-cursor-trail-1')),
      findsOneWidget,
    );

    await touch.up();
    await tester.pump();
    await tester
        .pump(AppDurations.pointerFade + const Duration(milliseconds: 1));
    await tester.pump();

    final pointer = find.byKey(const ValueKey('cinematic-cursor-lightning'));
    if (pointer.evaluate().isNotEmpty) {
      final fade = tester.widget<Opacity>(
        find.ancestor(of: pointer, matching: find.byType(Opacity)).first,
      );
      expect(fade.opacity, 0);
    }
  });

  testWidgets('reduced motion keeps the native cursor without a trail',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: CinematicCursor(child: SizedBox.expand()),
        ),
      ),
    );

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(120, 90));
    await mouse.moveTo(const Offset(180, 130));
    await tester.pump();

    expect(find.byKey(const ValueKey('cinematic-cursor-ring')), findsNothing);
    await mouse.removePointer();
  });
}
