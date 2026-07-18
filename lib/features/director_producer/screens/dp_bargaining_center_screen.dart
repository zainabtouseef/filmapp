import 'package:flutter/material.dart';

import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/director_producer_demo_data.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_empty_state.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_status_chip.dart';

class DPBargainingCenterScreen extends StatefulWidget {
  const DPBargainingCenterScreen({super.key});

  @override
  State<DPBargainingCenterScreen> createState() =>
      _DPBargainingCenterScreenState();
}

class _DPBargainingCenterScreenState extends State<DPBargainingCenterScreen> {
  late Future<List<NegotiationThread>> _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future = BookingsScope.of(context).negotiations();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NegotiationThread>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const DPEmptyState(
            icon: Icons.hourglass_top_rounded,
            title: 'Loading negotiations',
            message: 'Fetching live booking threads.',
          );
        }
        if (snapshot.hasError) {
          return _DemoNegotiations();
        }
        final negotiations = snapshot.data ?? const [];
        if (negotiations.isEmpty) {
          return const DPEmptyState(
            icon: Icons.forum_outlined,
            title: 'No negotiations yet',
            message: 'Send a booking request to start a bargaining thread.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            dpHeaderAction(
              context,
              icon: Icons.forum_outlined,
              label: 'Thread',
              onTap: () => Navigator.pushNamed(
                context,
                DirectorProducerRoutes.negotiationThread,
                arguments: negotiations.first.publicId,
              ),
            ),
            const SizedBox(height: 8),
            DPResponsiveGrid(
              minWidth: 300,
              children: negotiations
                  .map(
                    (negotiation) => _NegotiationCard(
                      title: negotiation.booking.provider.displayName,
                      project: 'Project ${negotiation.booking.projectId}',
                      subtitle: negotiation.booking.category,
                      rate: negotiation.currentOffer?.feeLabel ?? 'Rate TBD',
                      status: _statusLabel(negotiation.status),
                      expiry: negotiation.currentOffer?.expiresAt == null
                          ? 'Open'
                          : 'Expiring',
                      onTap: () => Navigator.pushNamed(
                        context,
                        DirectorProducerRoutes.negotiationThread,
                        arguments: negotiation.publicId,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  String _statusLabel(String status) {
    return switch (status) {
      'accepted' => 'Accepted',
      'rejected' => 'Rejected',
      _ => 'Open',
    };
  }
}

class _DemoNegotiations extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final negotiations = DirectorProducerDemoData.negotiations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DPSectionCard(
          title: 'Preview mode',
          icon: Icons.info_outline_rounded,
          child: dpText(
            context,
            'Live negotiations unavailable — showing preview threads.',
          ),
        ),
        const SizedBox(height: 12),
        DPResponsiveGrid(
          minWidth: 300,
          children: negotiations
              .map(
                (negotiation) => _NegotiationCard(
                  title: negotiation.candidate,
                  project: negotiation.project,
                  subtitle: negotiation.requirement,
                  rate: negotiation.currentRate,
                  status: negotiation.status,
                  expiry: negotiation.expiry,
                  onTap: () => Navigator.pushNamed(
                    context,
                    DirectorProducerRoutes.negotiationThread,
                    arguments: negotiation.id,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _NegotiationCard extends StatelessWidget {
  final String title;
  final String project;
  final String subtitle;
  final String rate;
  final String status;
  final String expiry;
  final VoidCallback onTap;

  const _NegotiationCard({
    required this.title,
    required this.project,
    required this.subtitle,
    required this.rate,
    required this.status,
    required this.expiry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tone = status == 'Your move'
        ? DpTone.warning
        : status == 'Accepted'
            ? DpTone.success
            : status == 'Expiring'
                ? DpTone.danger
                : DpTone.info;
    return GestureDetector(
      onTap: onTap,
      child: DPGlassCard(
        selected: status == 'Your move' || status == 'Expiring',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: dpText(context, title, strong: true)),
                DPStatusChip(label: status, tone: tone),
              ],
            ),
            const SizedBox(height: 6),
            dpText(context, '$project - $subtitle'),
            const SizedBox(height: 9),
            Row(
              children: [
                Text(
                  rate,
                  style: AppTextStyles.metricNumberCompact
                      .copyWith(color: colors.textPrimary),
                ),
                const Spacer(),
                DPStatusChip(label: expiry, tone: DpTone.warning),
              ],
            ),
            const SizedBox(height: 9),
            DPHolographicButton(
              label: 'Open Negotiation',
              icon: Icons.chat_bubble_outline_rounded,
              onTap: onTap,
              secondary: true,
            ),
          ],
        ),
      ),
    );
  }
}
