import 'package:cineconnect/shared/dashboard/portal_floating_bubbles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _scene({bool reducedMotion = false, VoidCallback? onTap}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reducedMotion),
        child: SizedBox(
          width: 320,
          height: 180,
          child: Stack(children: [
            Center(
                child: TextButton(onPressed: onTap, child: const Text('Open'))),
            const Positioned.fill(child: PortalFloatingBubbles()),
          ]),
        ),
      ),
    );

List<Matrix4> _positions(WidgetTester tester) => tester
    .widgetList<Transform>(find.descendant(
        of: find.byType(PortalFloatingBubbles),
        matching: find.byType(Transform)))
    .map((widget) => widget.transform.clone())
    .toList();

void main() {
  testWidgets('bubble loop returns to its starting position without a jump',
      (tester) async {
    await tester.pumpWidget(_scene());
    await tester.pump();
    final initial = _positions(tester);
    await tester.pump(const Duration(seconds: 20));
    final repeated = _positions(tester);
    expect(initial.length, 6);
    for (var index = 0; index < initial.length; index++) {
      expect(repeated[index].storage, orderedEquals(initial[index].storage));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion is stationary and bubbles do not block controls',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(_scene(reducedMotion: true, onTap: () => taps++));
    final initial = _positions(tester);
    await tester.pump(const Duration(seconds: 7));
    final stopped = _positions(tester);
    for (var index = 0; index < initial.length; index++) {
      expect(stopped[index].storage, orderedEquals(initial[index].storage));
    }
    await tester.tap(find.text('Open'));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
}
