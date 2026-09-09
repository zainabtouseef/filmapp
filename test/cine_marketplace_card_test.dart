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

    expect(find.text('Haveli Gulberg'), findsNWidgets(2));
    expect(find.text('Lahore'), findsOneWidget);
    expect(find.text('PKR 220K'), findsOneWidget);
    expect(find.text('Trust 92/100'), findsOneWidget);

    await tester.tap(find.text('View profile'));
    await tester.tap(find.text('Request'));
    await tester.tap(find.byTooltip('Add to shortlist'));
    await tester.pump();

    expect(profileCalls, 1);
    expect(requestCalls, 1);
    expect(shortlistCalls, 1);
    expect(find.byTooltip('Remove from shortlist'), findsOneWidget);
  });

  testWidgets('uses a stable stacked layout on narrow screens', (tester) async {
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
    expect(find.text('Maya Raza'), findsNWidgets(2));
    expect(find.text('Campaign-ready model profile.'), findsOneWidget);
  });
}
