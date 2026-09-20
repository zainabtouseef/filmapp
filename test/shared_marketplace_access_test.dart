import 'package:cineconnect/core/marketplace/marketplace_models.dart';
import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/core/theme/theme_controller.dart';
import 'package:cineconnect/shared/layout/floating_portal_menu.dart';
import 'package:cineconnect/shared/marketplace/marketplace_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('every portal menu exposes the shared marketplace route',
      (tester) async {
    String? selectedRoute;
    await tester.pumpWidget(
      ThemeControllerProvider(
        controller: ThemeController(initialThemeMode: ThemeMode.dark),
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          home: Scaffold(
            body: FloatingPortalMenuOverlay(
              open: true,
              currentRoute: '/talent',
              items: const [
                FloatingPortalMenuItem(
                  route: '/talent',
                  label: 'Home',
                  icon: Icons.home_outlined,
                ),
              ],
              statusTitle: 'Talent',
              statusSubtitle: 'Ready',
              statusIcon: Icons.person_outline,
              onClose: () {},
              onRouteTap: (route) => selectedRoute = route,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Marketplace'), findsOneWidget);
    await tester.tap(find.text('Marketplace'));
    expect(selectedRoute, MarketplaceRoutes.browse);
  });

  test('published talent and crew listings use director category filters', () {
    MarketplaceListing listing(String type) => MarketplaceListing(
          publicId: 'LIST-1',
          listingType: type,
          title: 'Provider',
          summary: 'Production provider',
          cityName: 'Lahore',
          priceFromMinor: null,
          currency: 'PKR',
          verificationStatus: 'approved',
          ownerName: 'Provider',
          media: const [],
        );

    expect(listing('talent').toCandidate().category, 'Actors');
    expect(listing('crew').toCandidate().category, 'Crew');
  });
}
