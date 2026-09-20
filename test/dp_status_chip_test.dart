import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/features/director_producer/widgets/dp_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DpDotChip animates between active and inactive without error',
      (tester) async {
    var active = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => DpDotChip(
              label: 'Verified only',
              active: active,
              onTap: () => setState(() => active = !active),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Verified only'));
    // Pump mid-animation (not settled) to catch any assertion errors from
    // AnimatedContainer/AnimatedScale/AnimatedDefaultTextStyle mid-flight.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Verified only'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
