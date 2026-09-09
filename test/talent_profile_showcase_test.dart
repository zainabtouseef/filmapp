import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/shared/widgets/talent_profile_showcase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('talent showcase is image-led and communicates buyer proof',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(20),
            child: TalentProfileShowcase(
              name: 'Ayaan Malik',
              role: 'Commercial actor',
              city: 'Lahore',
              summary: 'Natural screen presence for premium brand stories.',
              verified: true,
              available: true,
              rateLabel: 'PKR 145k',
              rating: 4.8,
              reviewCount: 24,
              highlights: ['Urdu', 'English', '8 years'],
              badge: 'Screen-ready talent',
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('talent-profile-showcase')), findsOne);
    expect(find.text('Ayaan Malik'), findsOne);
    expect(find.text('Identity verified'), findsOne);
    expect(find.text('Available for bookings'), findsOne);
    expect(find.text('4.8 · 24 reviews'), findsOne);
    expect(
      tester.getSize(find.byKey(const ValueKey('talent-profile-showcase'))),
      const Size(1160, 430),
    );
  });
}
