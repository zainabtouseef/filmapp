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

  testWidgets('command centre stays compact on desktop and phone',
      (tester) async {
    Widget subject(double width) {
      return MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            width: width,
            child: SingleChildScrollView(
              child: PortalCommandCenter(
                eyebrow: 'Portal operations',
                title: 'Workflow Command Centre',
                subtitle: 'Live records and the next actions.',
                icon: Icons.dashboard_customize_outlined,
                primaryTitle: 'Latest record',
                primary: const Column(
                  children: [
                    PortalCommandDataRow(
                      icon: Icons.person_outline,
                      label: 'Owner',
                      value: 'CineConnect member',
                    ),
                    PortalCommandDataRow(
                      icon: Icons.verified_outlined,
                      label: 'Status',
                      value: 'Active',
                    ),
                  ],
                ),
                actions: const [
                  PortalCommandAction(
                    icon: Icons.inbox_outlined,
                    title: 'Open requests',
                    subtitle: 'Review live server records',
                    value: '3',
                  ),
                  PortalCommandAction(
                    icon: Icons.fact_check_outlined,
                    title: 'Review evidence',
                    subtitle: 'Verify pending work',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    for (final size in const [Size(1100, 800), Size(390, 844)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(subject(size.width));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Workflow Command Centre'), findsOneWidget);
      expect(find.text('Latest record'.toUpperCase()), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  testWidgets('pipeline uses a readable two by two flow on a phone',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            width: 358,
            child: PortalPipelineFlow(
              stages: const [
                PortalPipelineStage(
                  value: '7',
                  label: 'Negotiating',
                  sublabel: 'PKR 1.65M total',
                  color: Colors.amber,
                ),
                PortalPipelineStage(
                  value: '0',
                  label: 'Offer accepted',
                  sublabel: 'PKR 0 total',
                  color: Colors.blue,
                ),
                PortalPipelineStage(
                  value: '1',
                  label: 'Contract sent',
                  sublabel: 'PKR 205K total',
                  color: Colors.purple,
                ),
                PortalPipelineStage(
                  value: '0',
                  label: 'Signed',
                  sublabel: 'PKR 0 total',
                  color: Colors.green,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Negotiating'), findsOneWidget);
    expect(find.text('Offer accepted'), findsOneWidget);
    expect(find.text('Contract sent'), findsOneWidget);
    expect(find.text('Signed'), findsOneWidget);
    expect(tester.getSize(find.byType(PortalPipelineFlow)).height,
        greaterThan(120));
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
      final source = File(path).readAsStringSync();
      expect(
        source,
        contains('PortalDashboardPage('),
        reason: '$path must use the shared dashboard composition',
      );
      for (final obsoletePattern in const [
        'PersonalDashboardKpiStrip(',
        'PortalQuickStatTile(',
        '_TalentKpiStrip(',
        '_BrandQuickStatRow(',
        '_CrewQuickStats(',
        '_MetricStatsRow(',
        '_AdminPulseStrip(',
      ]) {
        expect(
          source,
          isNot(contains(obsoletePattern)),
          reason: '$path must keep its three headline figures in the hero',
        );
      }
    }

    for (final path in const [
      'lib/features/actor_talent/screens/at01_talent_dashboard_screen.dart',
      'lib/features/brand_sponsors/screens/br01_brand_dashboard_screen.dart',
      'lib/features/casting_agency/screens/ca01_agency_dashboard_screen.dart',
      'lib/features/crew_services/screens/cr01_crew_dashboard_screen.dart',
      'lib/features/distribution_partner/screens/ds01_distribution_dashboard_screen.dart',
      'lib/features/influencer/screens/influencer_portal_screen.dart',
      'lib/features/insurance_partner/screens/in01_insurance_dashboard_screen.dart',
      'lib/features/legal_partner/screens/lg01_legal_dashboard_screen.dart',
      'lib/features/location_owner/screens/lo01_owner_dashboard_screen.dart',
      'lib/features/media_equipment/screens/me01_provider_dashboard_screen.dart',
      'lib/features/model_extension/screens/md01_campaign_categories_screen.dart',
      'lib/features/super_admin/screens/admin_portal/admin_dashboard_screen.dart',
    ]) {
      expect(
        File(path).readAsStringSync(),
        contains('PortalCommandCenter('),
        reason: '$path must use the shared command-centre surface',
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
