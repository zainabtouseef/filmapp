import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/shared/widgets/talent_profile_showcase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final items = [
    const TalentProfileGalleryItem(
      label: 'Rooftop, golden hour',
      imageUrl: null,
    ),
    const TalentProfileGalleryItem(
      label: 'Walkthrough',
      imageUrl: null,
      isVideo: true,
    ),
    const TalentProfileGalleryItem(
      label: 'Courtyard, day',
      imageUrl: null,
    ),
  ];

  testWidgets('tapping a strip tile opens the full gallery viewer',
      (tester) async {
    String? openedOriginalLabel;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: TalentProfileGallery(
            items: items,
            onOpen: (item) => openedOriginalLabel = item.label,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Selected portfolio'), findsOneWidget);

    await tester.tap(find.text('Rooftop, golden hour'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(TalentGalleryViewer), findsOneWidget);
    // Every strip item is present in the full viewer, not just the tapped one.
    expect(find.text('Rooftop, golden hour'), findsOneWidget);
    expect(find.text('Courtyard, day'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    // Tapping a tile inside the viewer surfaces the original-open callback
    // rather than dropping it now that tapping first opens the viewer.
    // The masonry lays every tile out eagerly inside a SingleChildScrollView,
    // so it's already in the tree — just scrolled past the fold.
    await tester.ensureVisible(find.text('Courtyard, day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Courtyard, day'));
    await tester.pump();
    expect(openedOriginalLabel, 'Courtyard, day');

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(TalentGalleryViewer), findsNothing);
  });

  testWidgets('the "More" link opens the viewer without a specific tap',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: TalentProfileGallery(items: items),
        ),
      ),
    );

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(TalentGalleryViewer), findsOneWidget);
    expect(find.textContaining('3'), findsWidgets);
  });
}
