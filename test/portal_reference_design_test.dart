import 'package:cineconnect/shared/layout/portal_page_header.dart';
import 'package:cineconnect/shared/layout/portal_reference_design.dart';
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
    await tester.pumpAndSettle();

    expect(find.text('Shortlist'), findsOneWidget);
    expect(find.text('SHORTLISTS · SAVED TALENT'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
    expect(find.text('SAVED'), findsOneWidget);
    expect(find.text('RANKED'), findsOneWidget);
    expect(find.text('SYNCED'), findsOneWidget);
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
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Pricing & Deposits'), findsOneWidget);
      expect(find.text('PKR'), findsOneWidget);
    });
  }
}
