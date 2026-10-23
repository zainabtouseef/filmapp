import 'dart:io';

import 'package:cineconnect/shared/layout/portal_adaptive_collection.dart';
import 'package:cineconnect/shared/layout/portal_body_canvas.dart';
import 'package:cineconnect/shared/layout/portal_body_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release inventory includes all 164 screen files', () {
    final files = <File>[
      ...Directory('lib/features').listSync(recursive: true).whereType<File>(),
      ...Directory('lib/core').listSync(recursive: true).whereType<File>(),
    ].where((file) => file.path.endsWith('screen.dart')).toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    expect(files, hasLength(164));
    expect(
      files.every((file) => file.readAsStringSync().contains('Widget build')),
      isTrue,
      reason: 'Every screen must expose a render path for the shared shell.',
    );

    final themeSource = File(
      'lib/shared/layout/portal_body_theme.dart',
    ).readAsStringSync();
    final adminShellSource = File(
      'lib/shared/layout/admin_screen_scaffold.dart',
    ).readAsStringSync();
    final coreShellSource = File(
      'lib/core/core_ui/widgets/core_widgets.dart',
    ).readAsStringSync();

    expect(themeSource, contains('PortalBodyCanvas'));
    expect(adminShellSource, contains('PortalBodyTheme'));
    expect(coreShellSource, contains('PortalBodyTheme'));
  });

  testWidgets('operational body mounts the cinematic canvas', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: PortalBodyTheme(
            route: '/director/payments',
            child: Text('ledger'),
          ),
        ),
      ),
    );

    expect(find.byType(PortalBodyCanvas), findsOneWidget);
    expect(find.text('ledger'), findsOneWidget);
  });

  testWidgets('shared split view stacks on phones and divides on desktop',
      (tester) async {
    Future<void> pump(double width) {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      return tester.pumpWidget(
        const MaterialApp(
          home: SizedBox.expand(
            child: PortalSplitView(
              primary: Text('primary'),
              secondary: Text('secondary'),
            ),
          ),
        ),
      );
    }

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pump(600);
    expect(find.byType(Column), findsWidgets);

    await pump(1200);
    expect(find.byType(Row), findsWidgets);
  });
}
