import 'package:flutter/material.dart';

import '../../../../core/director/director_dashboard_models.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/formatters/cine_format.dart';
import '../../routes/director_producer_routes.dart';
import '../dp_glass_card.dart';

/// The dashboard's "Production Pulse" — the exact 3-tile plain glass
/// grid from the source design (Active productions / Paid-pending /
/// Bookings secured), values computed live from demo-data state.
class DPPulseStrip extends StatelessWidget {
  final DirectorDashboardSummary summary;

  const DPPulseStrip({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final paid = summary.paidMinor ~/ 100;
    final pending = summary.pendingPaymentMinor ~/ 100;

    final tiles = [
      _PulseTile(
        label: 'Active productions',
        value: '${summary.activeProjects}',
        onTap: () =>
            Navigator.pushNamed(context, DirectorProducerRoutes.projects),
      ),
      _PulseTile(
        label: 'Paid / pending',
        value:
            '${CineFormat.count(paid, compact: true)} / ${CineFormat.count(pending, compact: true)}',
        onTap: () =>
            Navigator.pushNamed(context, DirectorProducerRoutes.payments),
      ),
      _PulseTile(
        label: 'Bookings secured',
        value: '${summary.securedBookings}',
        onTap: () =>
            Navigator.pushNamed(context, DirectorProducerRoutes.bargaining),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 9.0;
        final columns = constraints.maxWidth < 360
            ? 1
            : constraints.maxWidth < 700
                ? 2
                : 3;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final tile in tiles) SizedBox(width: width, child: tile),
          ],
        );
      },
    );
  }
}

class _PulseTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _PulseTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = switch (label) {
      'Active productions' => colors.infoBlue,
      'Paid / pending' => colors.warning,
      'Bookings secured' => colors.success,
      _ => colors.goldDark,
    };
    return GestureDetector(
      onTap: onTap,
      child: DPGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
        accentColor: accent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(color: colors.textTertiary),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.cardLabel.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 15.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
