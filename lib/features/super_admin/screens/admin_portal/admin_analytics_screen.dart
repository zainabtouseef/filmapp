part of '../super_admin_screens.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  String _range = '30 days';
  Future<AdminAnalyticsDto>? _future;

  int get _rangeDays => switch (_range) {
        '7 days' => 7,
        '90 days' => 90,
        _ => 30,
      };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<AdminAnalyticsDto> _load() {
    return AnalyticsScope.of(context).adminAnalytics(
      force: true,
      days: _rangeDays,
    );
  }

  void _changeRange(String value) {
    setState(() {
      _range = value;
      _future = _load();
    });
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminAnalyticsDto>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AdminSurface(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          final error = snapshot.error;
          return AdminSurface(
            child: Column(
              children: [
                AdminEmptyState(
                  icon: Icons.analytics_outlined,
                  title: 'Platform analytics unavailable',
                  message: error is ApiException
                      ? error.message
                      : 'Check the backend connection and try again.',
                ),
                const SizedBox(height: 12),
                AdminActionButton(
                  icon: Icons.refresh_rounded,
                  label: 'Retry',
                  secondary: true,
                  onTap: _refresh,
                ),
              ],
            ),
          );
        }
        final data = snapshot.data!;
        final users = data.newUsersByDay.values.fold<int>(
          0,
          (sum, value) => sum + value,
        );
        final bookings = data.newBookingsByDay.values.fold<int>(
          0,
          (sum, value) => sum + value,
        );
        final secured = data.securedBookingsByDay.values.fold<int>(
          0,
          (sum, value) => sum + value,
        );
        final conversion = bookings == 0 ? 0 : secured / bookings;
        final userSeries =
            data.newUsersByDay.values.map((value) => value.toDouble()).toList();
        final bookingSeries = data.newBookingsByDay.values
            .map((value) => value.toDouble())
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminSurface(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final controls = Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ExportActionButton(
                        exportType: 'bookings',
                        label: 'Export bookings',
                        builder: (context, onTap, label) => AdminActionButton(
                          icon: Icons.download_outlined,
                          label: label,
                          secondary: true,
                          onTap: onTap,
                        ),
                      ),
                      ExportActionButton(
                        exportType: 'admin_disputes',
                        label: 'Export disputes',
                        builder: (context, onTap, label) => AdminActionButton(
                          icon: Icons.gavel_outlined,
                          label: label,
                          secondary: true,
                          onTap: onTap,
                        ),
                      ),
                      AdminActionButton(
                        icon: Icons.refresh_rounded,
                        label: 'Refresh',
                        secondary: true,
                        onTap: _refresh,
                      ),
                    ],
                  );
                  final range = _dropdown(
                    context,
                    'Date range',
                    _range,
                    const ['7 days', '30 days', '90 days'],
                    _changeRange,
                  );
                  if (constraints.maxWidth < 680) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        range,
                        const SizedBox(height: 10),
                        controls,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      range,
                      const Spacer(),
                      controls,
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _ResponsiveGrid(
              minTileWidth: 190,
              childAspectRatio: 2.6,
              children: [
                AdminMetricTile(
                  label: 'New users',
                  value: '$users',
                  icon: Icons.person_add_alt_1_outlined,
                  tone: AdminDecisionTone.success,
                ),
                AdminMetricTile(
                  label: 'New bookings',
                  value: '$bookings',
                  icon: Icons.work_outline_rounded,
                  tone: AdminDecisionTone.info,
                ),
                AdminMetricTile(
                  label: 'Secured bookings',
                  value: '$secured',
                  icon: Icons.lock_outline_rounded,
                  tone: AdminDecisionTone.warning,
                ),
                AdminMetricTile(
                  label: 'Booking conversion',
                  value: '${(conversion * 100).toStringAsFixed(1)}%',
                  icon: Icons.trending_up_rounded,
                  tone: conversion >= 0.3
                      ? AdminDecisionTone.success
                      : AdminDecisionTone.warning,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _TwoPane(
              left: AdminChartCard(
                title: 'New users by day',
                subtitle: '${data.rangeDays}-day verified registration trend',
                values: userSeries.isEmpty ? const [0] : userSeries,
                bars: false,
              ),
              right: AdminChartCard(
                title: 'Bookings by day',
                subtitle: 'New booking requests and secured activity',
                values: bookingSeries.isEmpty ? const [0] : bookingSeries,
              ),
            ),
          ],
        );
      },
    );
  }
}

class NotificationCardPreview extends StatelessWidget {
  final String title;
  final String body;
  final String priority;
  final String segment;
  final String status;

  const NotificationCardPreview({
    super.key,
    required this.title,
    required this.body,
    required this.priority,
    required this.segment,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: colors.inactiveChipGradient,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 5,
            child: ColoredBox(color: colors.goldMid),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 15, 15, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminStatusBadge(
                  label: '$priority · $status',
                  tone: AdminDecisionTone.warning,
                ),
                const SizedBox(height: 12),
                _headline(context, title),
                const SizedBox(height: 6),
                _text(context, body),
                const SizedBox(height: 12),
                AdminStatusBadge(
                  label: segment,
                  tone: AdminDecisionTone.info,
                ),
                const SizedBox(height: 12),
                AdminActionButton(
                  icon: Icons.notifications_none_rounded,
                  label: 'Open notification center',
                  secondary: true,
                  onTap: () =>
                      Navigator.pushNamed(context, CoreRoutes.notifications),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
