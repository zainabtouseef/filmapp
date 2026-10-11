import 'package:cineconnect/core/theme/app_text_styles.dart';
import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/core/theme/theme_controller.dart';
import 'package:cineconnect/features/director_producer/widgets/dp_layout_helpers.dart';
import 'package:cineconnect/shared/layout/portal_page_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final entry in const {
    'mobile': (size: Size(390, 844), titleSize: 32.0),
    'desktop': (size: Size(1440, 1000), titleSize: 46.0),
  }.entries) {
    testWidgets(
      'Marketplace and Shortlist share the portal title system on ${entry.key}',
      (tester) async {
        tester.view.physicalSize = entry.value.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ThemeControllerProvider(
            controller: ThemeController(initialThemeMode: ThemeMode.light),
            child: MaterialApp(
              theme: AppTheme.light,
              home: const Scaffold(
                body: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PortalPageHeader(
                        eyebrow: 'CINECONNECT',
                        title: 'Marketplace',
                      ),
                      SizedBox(height: 24),
                      DPPageHeader(
                        eyebrow: 'Shortlists · saved talent',
                        title: 'Shortlist',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        final marketplace = tester.widget<Text>(find.text('Marketplace'));
        final shortlist = tester.widget<Text>(find.text('Shortlist'));
        for (final title in [marketplace, shortlist]) {
          expect(title.style?.fontFamily, AppTextStyles.heading.fontFamily);
          expect(title.style?.fontSize, entry.value.titleSize);
          expect(title.style?.fontWeight, FontWeight.w700);
          expect(title.style?.fontStyle, isNot(FontStyle.italic));
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
