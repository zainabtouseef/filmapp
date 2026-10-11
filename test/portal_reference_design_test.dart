import 'package:cineconnect/shared/cards/cine_card_system.dart';
import 'package:cineconnect/shared/layout/portal_body_theme.dart';
import 'package:cineconnect/shared/layout/portal_adaptive_collection.dart';
import 'package:cineconnect/shared/layout/portal_page_header.dart';
import 'package:cineconnect/shared/layout/portal_reference_design.dart';
import 'package:cineconnect/shared/widgets/cine_animated_gold_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PortalReferenceDesign', () {
    test('excludes dashboards and marketplace routes', () {
      const excluded = [
        '/director',
        '/console',
        '/talent',
        '/influencer',
        '/model',
        '/location-owner',
        '/equipment-provider',
        '/crew',
        '/agency',
        '/brand',
        '/legal',
        '/insurance',
        '/distribution',
        '/public',
        '/admin/dashboard',
        '/marketplace',
        '/director/marketplace',
        '/brand/discover',
        '/public/browse',
        '/public/actors',
      ];
      for (final route in excluded) {
        expect(
          PortalReferenceDesign.usesReference(route),
          isFalse,
          reason: route,
        );
      }
    });

    test('includes operational screens across every portal family', () {
      const included = [
        '/director/cineplanner',
        '/director/shortlist',
        '/director/contracts',
        '/talent/profile',
        '/influencer/packages',
        '/model/usage-rights',
        '/location-owner/pricing',
        '/equipment-provider/inventory',
        '/crew/contracts-payments',
        '/agency/shortlist',
        '/brand/payments',
        '/legal/contract-review',
        '/insurance/claims',
        '/distribution/release',
        '/admin/payments',
        '/public/account',
      ];
      for (final route in included) {
        expect(
          PortalReferenceDesign.usesReference(route),
          isTrue,
          reason: route,
        );
      }
    });

    test('limits standalone hero styling to operational utilities', () {
      expect(
        PortalReferenceDesign.usesOperationalUtilityHero('/contract/123'),
        isTrue,
      );
      expect(
        PortalReferenceDesign.usesOperationalUtilityHero('/payments/ledger'),
        isTrue,
      );
      expect(
        PortalReferenceDesign.usesOperationalUtilityHero('/login'),
        isFalse,
      );
    });

    test('maps operational routes to all nine reference layouts', () {
      const expected = <String, PortalBodyLayout>{
        '/director/reports': PortalBodyLayout.analytics,
        '/director/contracts': PortalBodyLayout.timeline,
        '/talent/availability': PortalBodyLayout.calendar,
        '/talent/rates': PortalBodyLayout.editorial,
        '/agency/shortlist': PortalBodyLayout.list,
        '/brand/campaign-tracker': PortalBodyLayout.kanban,
        '/crew/portfolio': PortalBodyLayout.gallery,
        '/director/cineplanner': PortalBodyLayout.splitView,
        '/crew/opportunities': PortalBodyLayout.horizontalRail,
      };

      for (final entry in expected.entries) {
        expect(
          PortalReferenceDesign.layoutForRoute(entry.key),
          entry.value,
          reason: entry.key,
        );
      }
      expect(expected.values.toSet().length, PortalBodyLayout.values.length);
    });
  });

  testWidgets('route-aware collections switch between rows and rails',
      (tester) async {
    Widget appFor(String route) => MaterialApp(
          key: ValueKey(route),
          initialRoute: route,
          routes: {
            route: (_) => Scaffold(
                  body: PortalAdaptiveCollection(
                    minWidth: 220,
                    children: const [
                      SizedBox(key: ValueKey('a'), height: 50),
                      SizedBox(key: ValueKey('b'), height: 50),
                    ],
                  ),
                ),
          },
        );

    await tester.pumpWidget(appFor('/agency/shortlist'));
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.byType(Column), findsWidgets);

    await tester.pumpWidget(appFor('/crew/opportunities'));
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(
      tester
          .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .scrollDirection,
      Axis.horizontal,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('operational page header renders editorial hero and four stats',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/director/shortlist',
        routes: {
          '/director/shortlist': (_) => const Scaffold(
                body: PortalPageHeader(
                  eyebrow: 'Shortlists · saved talent',
                  title: 'Shortlist',
                ),
              ),
        },
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Shortlist'), findsOneWidget);
    expect(find.text('SHORTLISTS · SAVED TALENT'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
    expect(find.text('SAVED'), findsOneWidget);
    expect(find.text('RANKED'), findsOneWidget);
    expect(find.text('SYNCED'), findsOneWidget);
    expect(find.byType(CineAnimatedGoldBorder), findsOneWidget);
  });

  testWidgets('marketplace uses the same hero, typography and live controls',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/director/marketplace',
        routes: {
          '/director/marketplace': (_) => const Scaffold(
                body: PortalPageHeader(
                  eyebrow: 'CineConnect',
                  title: 'Marketplace',
                  trailing: FilledButton(
                    onPressed: null,
                    child: Text('Smart filters'),
                  ),
                ),
              ),
        },
      ),
    );
    await tester.pump();

    expect(find.text('Marketplace'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
    expect(find.text('VERIFIED'), findsOneWidget);
    expect(find.text('SMART'), findsOneWidget);
    expect(find.text('Smart filters'), findsOneWidget);
    expect(find.byType(CineAnimatedGoldBorder), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in const [Size(390, 844), Size(1440, 1000)]) {
    testWidgets('page hero lays out without overflow at ${size.width}px',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/location-owner/pricing',
          routes: {
            '/location-owner/pricing': (_) => const Scaffold(
                  body: SingleChildScrollView(
                    padding: EdgeInsets.all(12),
                    child: PortalPageHeader(
                      eyebrow: 'Rates · deposits · rental policy',
                      title: 'Pricing & Deposits',
                      subtitle:
                          'Manage live pricing, deposit rules and booking terms.',
                      trailing: Chip(label: Text('Location Owner')),
                    ),
                  ),
                ),
          },
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      expect(tester.takeException(), isNull);
      expect(find.text('Pricing & Deposits'), findsOneWidget);
      expect(find.text('PKR'), findsOneWidget);
    });
  }

  testWidgets('operational body applies premium sections, icons and touch zoom',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/crew/contracts-payments',
        routes: {
          '/crew/contracts-payments': (_) => Scaffold(
                body: PortalBodyTheme(
                  route: '/crew/contracts-payments',
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        const SectionContainer(
                          title: 'Contracts and payments',
                          description: 'Live agreements and payout actions.',
                          child: QuickActionCard(
                            item: QuickActionItem(
                              icon: Icons.draw_outlined,
                              title: 'Review agreement',
                              description: 'Signature requested',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CardShell(
                          key: const ValueKey('touch-card'),
                          accentEdge: true,
                          tone: CineTone.information,
                          child: const Text('Touch preview'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Contracts and payments'), findsOneWidget);
    expect(find.byIcon(Icons.draw_outlined), findsWidgets);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

    final scaleFinder = find.descendant(
      of: find.byKey(const ValueKey('touch-card')),
      matching: find.byType(AnimatedScale),
    );
    expect(scaleFinder, findsOneWidget);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('touch-card'))),
    );
    await tester.pump(const Duration(milliseconds: 180));
    expect(tester.widget<AnimatedScale>(scaleFinder).scale, greaterThan(1));
    await gesture.up();
  });
}
