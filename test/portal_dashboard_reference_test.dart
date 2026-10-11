import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/shared/dashboard/dashboard_kit.dart';

void main() {
  Widget referenceDashboard(double width) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            child: SingleChildScrollView(
              child: PortalDashboardPage(
                children: [
                  PortalHeroCard(
                    initials: 'CC',
                    name: 'CineConnect Workspace',
                    badgeLabel: 'Verified portal',
                    stats: const [
                      PortalHeroStat(value: '12', label: 'Active projects'),
                      PortalHeroStat(value: 'PKR 205K', label: 'Committed'),
                      PortalHeroStat(value: '7', label: 'Actions ready'),
                    ],
                    ctaLabel: 'Open workspace',
                    onCta: () {},
                  ),
                  const PortalGlassRingWidget(
                    progress: .65,
                    value: '65%',
                    label: 'Workspace ready',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('reference dashboard hierarchy is compact and overflow free',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(referenceDashboard(1120));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const ValueKey('portal-dashboard-page')), findsOneWidget);
    expect(find.byType(PortalDashboardLiveStrip), findsOneWidget);
    expect(find.text('CineConnect Workspace'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reference dashboard stays overflow free on a phone',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(referenceDashboard(358));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(PortalHeroCard), findsOneWidget);
    expect(find.byType(PortalDashboardLiveStrip), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard hero zooms in while touched', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(referenceDashboard(358));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(PortalHeroCard)),
    );
    await tester.pump();

    final scales = tester
        .widgetList<AnimatedScale>(find.byType(AnimatedScale))
        .map((widget) => widget.scale);
    expect(scales.any((scale) => scale > 1), isTrue);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 300));
  });

  test('every role dashboard uses the canonical composition and hero', () {
    const dashboardFiles = [
      'lib/features/actor_talent/screens/at01_talent_dashboard_screen.dart',
      'lib/features/brand_sponsors/screens/br01_brand_dashboard_screen.dart',
      'lib/features/casting_agency/screens/ca01_agency_dashboard_screen.dart',
      'lib/features/crew_services/screens/cr01_crew_dashboard_screen.dart',
      'lib/features/director_producer/screens/dp_home_dashboard_screen.dart',
      'lib/features/distribution_partner/screens/ds01_distribution_dashboard_screen.dart',
      'lib/features/general_public/screens/general_public_portal_screen.dart',
      'lib/features/influencer/screens/influencer_portal_screen.dart',
      'lib/features/insurance_partner/screens/in01_insurance_dashboard_screen.dart',
      'lib/features/legal_partner/screens/lg01_legal_dashboard_screen.dart',
      'lib/features/location_owner/screens/lo01_owner_dashboard_screen.dart',
      'lib/features/media_equipment/screens/me01_provider_dashboard_screen.dart',
      'lib/features/model_extension/screens/md01_campaign_categories_screen.dart',
      'lib/features/super_admin/screens/admin_portal/admin_dashboard_screen.dart',
    ];

    for (final path in dashboardFiles) {
      expect(
        File(path).readAsStringSync(),
        contains('PortalDashboardPage('),
        reason: '$path must use the shared dashboard composition',
      );
    }

    for (final path in const [
      'lib/features/location_owner/screens/lo01_owner_dashboard_screen.dart',
      'lib/features/media_equipment/screens/me01_provider_dashboard_screen.dart',
      'lib/features/model_extension/screens/md01_campaign_categories_screen.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, contains('PortalHeroCard('));
      expect(source, isNot(contains('ProviderWorkspaceHero(')));
    }
  });
}
