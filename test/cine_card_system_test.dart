import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineconnect/core/theme/app_theme.dart';
import 'package:cineconnect/shared/cards/cine_card_system.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const widths = <double>[320, 390, 768, 1280, 1600];
  const modes = <String>['light', 'dark'];

  for (final mode in modes) {
    for (final width in widths) {
      testWidgets(
        'shared cards fit at ${width.toInt()}px in $mode mode',
        (tester) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            MaterialApp(
              theme: mode == 'light' ? AppTheme.light : AppTheme.dark,
              home: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MetricStrip(
                        title: 'Operational pulse',
                        items: const [
                          MetricStripItem(
                            icon: Icons.movie_outlined,
                            label: 'Open briefs',
                            value: '24',
                            trend: '+8%',
                            tone: CineTone.premium,
                          ),
                          MetricStripItem(
                            icon: Icons.event_available_outlined,
                            label: 'Bookings',
                            value: '12',
                            contextLabel: 'This month',
                            tone: CineTone.positive,
                          ),
                          MetricStripItem(
                            icon: Icons.payments_outlined,
                            label: 'Pending value',
                            value: 'PKR 434K / 2.2M',
                            tone: CineTone.warning,
                          ),
                          MetricStripItem(
                            icon: Icons.verified_outlined,
                            label: 'Verified',
                            value: '96%',
                            tone: CineTone.information,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      QuickActionRail(
                        items: const [
                          QuickActionItem(
                            icon: Icons.add_circle_outline,
                            title: 'Create opportunity',
                          ),
                          QuickActionItem(
                            icon: Icons.person_search_outlined,
                            title: 'Find talent',
                          ),
                          QuickActionItem(
                            icon: Icons.calendar_month_outlined,
                            title: 'Check schedule',
                          ),
                          QuickActionItem(
                            icon: Icons.receipt_long_outlined,
                            title: 'Review payments',
                          ),
                          QuickActionItem(
                            icon: Icons.description_outlined,
                            title: 'Open contracts',
                          ),
                          QuickActionItem(
                            icon: Icons.insights_outlined,
                            title: 'View analytics',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const PriorityActionCard(
                        title: 'Confirm the final production schedule',
                        metadata: 'Project Aurora - Stage 3',
                        priority: 'Due in 2h',
                        icon: Icons.priority_high_rounded,
                      ),
                      const SizedBox(height: 16),
                      const FinancialSummaryCard(
                        label: 'Available balance',
                        amount: 'PKR 1.2M',
                        period: 'Updated today',
                        status: 'Verified',
                        tone: CineTone.positive,
                        progress: 0.72,
                      ),
                      const SizedBox(height: 16),
                      const ProjectCard(
                        title: 'Project Aurora',
                        type: 'Feature film',
                        stage: 'In production',
                        nextMilestone: 'Principal photography',
                        progress: 0.64,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final exception = tester.takeException();
          expect(exception, isNull, reason: 'Unexpected exception: $exception');

          final firstMetricTop = tester.getTopLeft(find.text('Open briefs')).dy;
          final secondMetricTop = tester.getTopLeft(find.text('Bookings')).dy;
          if (width == 320) {
            expect(secondMetricTop, greaterThan(firstMetricTop));
          } else {
            expect(secondMetricTop, firstMetricTop);
          }
        },
      );
    }
  }
}
