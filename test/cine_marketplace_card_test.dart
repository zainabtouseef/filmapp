import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/shared/widgets/cine_marketplace_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders live marketplace fields and connected actions',
      (tester) async {
    var shortlistCalls = 0;
    var requestCalls = 0;
    var profileCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light.copyWith(splashFactory: NoSplash.splashFactory),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 1100,
              child: CineMarketplaceCard(
                title: 'Haveli Gulberg',
                kind: 'location',
                category: 'Locations',
                subtitle: 'Heritage interior',
                summary: 'A camera-ready production location.',
                city: 'Lahore',
                rateLabel: 'PKR 220k',
                verificationStatus: 'approved',
                imageUrl: null,
                tags: const ['Power backup', 'Holding space'],
                available: true,
                rating: 4.8,
                trustScore: 92,
                busy: false,
                featured: true,
                onProfile: () => profileCalls++,
                onRequest: () => requestCalls++,
                onShortlist: () async {
                  shortlistCalls++;
                  return true;
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    // The cinematic list row shows the title once, beside the thumbnail —
    // unlike the old banner-card layout, it is never repeated as an
    // image-overlay caption.
    expect(find.text('Haveli Gulberg'), findsOneWidget);
    expect(find.text('Lahore'), findsOneWidget);
    expect(find.text('PKR 220K'), findsOneWidget);
    expect(find.text('Trust 92/100'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

    await tester.tap(find.text('View profile'));
    // Bargaining is allowed by default, so the primary action reads
    // "Make offer" rather than the fixed-price "Request at price" label.
    await tester.tap(find.text('Make offer'));
    await tester.tap(find.byTooltip('Add to shortlist'));
    await tester.pump();

    expect(profileCalls, 1);
    expect(requestCalls, 1);
    expect(shortlistCalls, 1);
    expect(find.byTooltip('Remove from shortlist'), findsOneWidget);
  });

  testWidgets('shows the fixed-price action label when bargaining is off',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light.copyWith(splashFactory: NoSplash.splashFactory),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 1100,
              child: CineMarketplaceCard(
                title: 'ARRI Alexa Mini LF',
                kind: 'equipment',
                category: 'Media & Equipment',
                subtitle: 'Cinema camera package',
                summary: 'Full production-ready kit.',
                city: 'Karachi',
                rateLabel: 'PKR 90k/day',
                pricingMode: 'fixed',
                allowsBargaining: false,
                verificationStatus: 'approved',
                imageUrl: null,
                tags: [],
                available: true,
                rating: 0,
                trustScore: null,
                busy: false,
                featured: false,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Request at price'), findsOneWidget);
    expect(find.text('Fixed price'), findsOneWidget);
  });

  testWidgets('stays overflow-safe as a compact list row on narrow screens',
      (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light.copyWith(splashFactory: NoSplash.splashFactory),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CineMarketplaceCard(
                title: 'Maya Raza',
                kind: 'model',
                category: 'Models',
                subtitle: 'Commercial model',
                summary: 'Campaign-ready model profile.',
                city: 'Lahore',
                rateLabel: 'PKR 145k',
                verificationStatus: 'approved',
                imageUrl: null,
                tags: ['Beauty', 'Lifestyle'],
                available: true,
                rating: 4.9,
                trustScore: 94,
                busy: false,
                featured: false,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Maya Raza'), findsOneWidget);
    expect(find.text('Campaign-ready model profile.'), findsOneWidget);
  });

  testWidgets('morphs its thumbnail into the destination hero via a Hero tag',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light.copyWith(splashFactory: NoSplash.splashFactory),
        home: Scaffold(
          body: SizedBox(
            width: 1100,
            child: CineMarketplaceCard(
              heroTag: 'marketplace-profile-test-id',
              title: 'Bilal Raza',
              kind: 'crew',
              category: 'Crew',
              subtitle: 'DOP / Cinematographer',
              summary: 'Karachi-based cinematographer.',
              city: 'Karachi',
              rateLabel: 'PKR 60k/day',
              verificationStatus: 'approved',
              imageUrl: null,
              tags: const [],
              available: true,
              rating: 0,
              trustScore: null,
              busy: false,
              featured: false,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Hero), findsOneWidget);
    expect(
      tester.widget<Hero>(find.byType(Hero)).tag,
      'marketplace-profile-test-id',
    );
  });

  testWidgets(
      'CineMarketplaceResults tolerates rapid rebuilds with fresh list '
      'instances, like a search box firing setState on every keystroke',
      (tester) async {
    Widget buildCard(String title) => CineMarketplaceCard(
          key: ValueKey(title),
          title: title,
          kind: 'actor',
          category: 'Actors',
          subtitle: 'Actor',
          summary: 'Summary',
          city: 'Lahore',
          rateLabel: 'PKR 10k',
          verificationStatus: 'approved',
          imageUrl: null,
          tags: const [],
          available: true,
          rating: 0,
          trustScore: null,
          busy: false,
          featured: false,
        );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: CineMarketplaceResults(
            // A brand-new List instance each build, exactly like the
            // discovery screen's `.map(...).toList()` on every keystroke.
            cards: [buildCard('Ayesha Khan'), buildCard('Sara Ahmed')],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);

    // Simulate several keystrokes arriving faster than the entrance
    // animation would complete, each rebuilding with a fresh list.
    for (var i = 0; i < 5; i++) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: CineMarketplaceResults(
              cards: [buildCard('Ayesha Khan'), buildCard('Sara Ahmed')],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 20));
      expect(tester.takeException(), isNull);
    }

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Ayesha Khan'), findsOneWidget);
    expect(find.text('Sara Ahmed'), findsOneWidget);
  });
}
