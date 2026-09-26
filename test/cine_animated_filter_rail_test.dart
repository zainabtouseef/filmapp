import 'package:cineconnect/shared/widgets/cine_animated_filter_rail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shared filter rail switches selection and exposes semantics',
      (tester) async {
    var selected = 'All';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: 320,
              child: CineAnimatedFilterRail<String>(
                values: const ['All', 'Active', 'Completed'],
                selected: selected,
                onSelected: (value) => setState(() => selected = value),
                labelFor: (value) => value,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(selected, 'All');
    final semanticsHandle = tester.ensureSemantics();
    await tester.tap(find.text('Active'));
    await tester.pumpAndSettle();

    expect(selected, 'Active');
    expect(
      tester.getSemantics(find.text('Active')),
      matchesSemantics(
        label: 'Active',
        hasSelectedState: true,
        isSelected: true,
        isButton: true,
      ),
    );
    semanticsHandle.dispose();
  });

  testWidgets('shared filter rail works when reduced motion is enabled',
      (tester) async {
    var selected = 'List';
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => CineAnimatedFilterRail<String>(
                values: const ['List', 'Grid'],
                selected: selected,
                onSelected: (value) => setState(() => selected = value),
                labelFor: (value) => value,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grid'));
    await tester.pump();
    expect(selected, 'Grid');
  });
}
