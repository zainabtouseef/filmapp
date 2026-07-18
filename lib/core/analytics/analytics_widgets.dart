import 'package:flutter/material.dart';

import '../../shared/cards/metric_action_card.dart';
import '../core_ui/core_routes.dart';
import '../core_ui/widgets/core_widgets.dart';
import '../theme/app_color_scheme.dart';
import 'analytics_controller.dart';
import 'analytics_models.dart';

class PersonalDashboardKpiStrip extends StatefulWidget {
  final String fallbackMessage;

  const PersonalDashboardKpiStrip({
    super.key,
    this.fallbackMessage =
        'Live dashboard unavailable — showing preview dashboard metrics below.',
  });

  @override
  State<PersonalDashboardKpiStrip> createState() =>
      _PersonalDashboardKpiStripState();
}

class _PersonalDashboardKpiStripState extends State<PersonalDashboardKpiStrip> {
  late Future<PersonalDashboardDto> _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final analytics = AnalyticsScope.maybeOf(context);
    _future = analytics == null
        ? Future.error(StateError('AnalyticsScope missing'))
        : analytics.personalDashboard(force: true);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PersonalDashboardDto>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator(minHeight: 2);
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return InlineNotice(
            message: widget.fallbackMessage,
            tone: CoreStatusTone.warning,
          );
        }
        final data = snapshot.data!;
        final colors = context.appColors;
        return MetricActionRail(
          items: [
            MetricActionItem(
              icon: Icons.handshake_outlined,
              value: '${data.pendingOffers}',
              title: 'Pending offers',
              subtitle: 'Live server count',
              accentColor: colors.infoPurple,
            ),
            MetricActionItem(
              icon: Icons.lock_outline,
              value: _money(data.securedValueMinor),
              title: 'Secured value',
              subtitle: 'Across your bookings',
              accentColor: colors.success,
            ),
            MetricActionItem(
              icon: Icons.star_outline_rounded,
              value: data.ratingAverage.toStringAsFixed(1),
              title: '${data.reviewCount} reviews',
              subtitle: 'Public reputation',
              accentColor: colors.goldMid,
              onTap: () => Navigator.pushNamed(context, CoreRoutes.review),
            ),
            MetricActionItem(
              icon: Icons.notifications_none_rounded,
              value: '${data.unreadNotifications}',
              title: 'Unread alerts',
              subtitle:
                  '${data.openDisputes} disputes · ${data.openSupportTickets} support',
              accentColor: colors.infoBlue,
              onTap: () =>
                  Navigator.pushNamed(context, CoreRoutes.notifications),
            ),
          ],
        );
      },
    );
  }

  String _money(int minor) {
    final whole = minor ~/ 100;
    if (whole >= 1000000) {
      return 'PKR ${(whole / 1000000).toStringAsFixed(1)}M';
    }
    if (whole >= 1000) {
      return 'PKR ${(whole / 1000).toStringAsFixed(0)}k';
    }
    return 'PKR $whole';
  }
}

class ExportActionButton extends StatefulWidget {
  final String exportType;
  final String label;
  final Widget Function(BuildContext context, VoidCallback? onTap, String label)
      builder;

  const ExportActionButton({
    super.key,
    required this.exportType,
    required this.label,
    required this.builder,
  });

  @override
  State<ExportActionButton> createState() => _ExportActionButtonState();
}

class _ExportActionButtonState extends State<ExportActionButton> {
  bool _loading = false;

  Future<void> _create() async {
    final analytics = AnalyticsScope.maybeOf(context);
    if (analytics == null || _loading) return;
    setState(() => _loading = true);
    try {
      final job = await analytics.createExport(widget.exportType);
      if (!mounted) return;
      showCoreSnack(
        context,
        'Export ${job.publicId} ready with ${job.rowCount} rows.',
      );
    } catch (_) {
      if (mounted) {
        showCoreSnack(context, 'Could not create live export right now.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      _loading ? null : _create,
      _loading ? 'Exporting...' : widget.label,
    );
  }
}
