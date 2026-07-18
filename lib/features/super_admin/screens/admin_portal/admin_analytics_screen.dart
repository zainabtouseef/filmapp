part of '../super_admin_screens.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  String _tab = 'Marketplace Growth';
  String _range = 'This month';
  Future<AdminAnalyticsDto>? _future;

  int get _rangeDays => switch (_range) {
        'Year' => 90,
        'Quarter' => 90,
        'Last month' => 30,
        _ => 30,
      };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  void _load() {
    final analytics = AnalyticsScope.maybeOf(context);
    if (analytics != null) {
      _future = analytics.adminAnalytics(force: true, days: _rangeDays);
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = switch (_tab) {
      'Demand' => const [
          ('Active producers', '312', Icons.movie_creation_outlined),
          ('Projects created', '91', Icons.add_box_outlined),
          ('Requests sent', '1.8k', Icons.send_outlined),
          ('Top category', 'Actors', Icons.theater_comedy_outlined),
        ],
      'Conversion Funnel' => const [
          ('Requests', '100%', Icons.flag_outlined),
          ('Negotiations', '68%', Icons.swap_horiz_rounded),
          ('Terms approved', '44%', Icons.check_circle_outline),
          ('Contracts signed', '37%', Icons.draw_outlined),
          ('Payments verified', '31%', Icons.payments_outlined),
          ('Closed bookings', '26%', Icons.lock_outline),
        ],
      'Trust Metrics' => const [
          ('Avg verification time', '11h', Icons.verified_user_outlined),
          ('Dispute rate', '2.4%', Icons.gpp_maybe_outlined),
          ('Cancellation rate', '4.8%', Icons.cancel_outlined),
          ('Fake-profile rejection', '8.1%', Icons.person_off_outlined),
          ('Payment verification time', '5h', Icons.timer_outlined),
        ],
      'Revenue' => const [
          ('Commission revenue', 'PKR 2.8M', Icons.percent_rounded),
          ('Subscription revenue', 'PKR 680k', Icons.card_membership_outlined),
          ('Verification fees', 'PKR 310k', Icons.verified_outlined),
          ('Featured listings', 'PKR 490k', Icons.workspace_premium_outlined),
          ('Premium tools', 'PKR 180k', Icons.auto_awesome_outlined),
        ],
      'Retention' => const [
          ('Repeat producers', '41%', Icons.repeat_rounded),
          ('Repeat bookings', '33%', Icons.loop_rounded),
          ('Active listings', '418', Icons.storefront_outlined),
          ('Monthly active users', '9.4k', Icons.groups_outlined),
        ],
      _ => const [
          ('Verified actors', '1,280', Icons.theater_comedy_outlined),
          ('Verified models', '740', Icons.style_outlined),
          ('Locations live', '312', Icons.location_city_outlined),
          ('Media providers', '224', Icons.videocam_outlined),
          ('Crew accounts', '950', Icons.groups_2_outlined),
          ('Partner accounts', '68', Icons.handshake_outlined),
        ],
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_future != null) ...[
          FutureBuilder<AdminAnalyticsDto>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(minHeight: 2),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: InlineNotice(
                    message:
                        'Live analytics unavailable — showing preview analytics below.',
                    tone: CoreStatusTone.warning,
                  ),
                );
              }
              final live = snapshot.data!;
              final users = live.newUsersByDay.values.fold<int>(
                0,
                (sum, value) => sum + value,
              );
              final bookings = live.newBookingsByDay.values.fold<int>(
                0,
                (sum, value) => sum + value,
              );
              final secured = live.securedBookingsByDay.values.fold<int>(
                0,
                (sum, value) => sum + value,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AdminSurface(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      AdminStatusBadge(
                        label: '${live.rangeDays} day live range',
                        tone: AdminDecisionTone.info,
                      ),
                      AdminStatusBadge(
                        label: '$users new users',
                        tone: AdminDecisionTone.success,
                      ),
                      AdminStatusBadge(
                        label: '$bookings new bookings',
                        tone: AdminDecisionTone.warning,
                      ),
                      AdminStatusBadge(
                        label: '$secured secured bookings',
                        tone: AdminDecisionTone.success,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
        AdminFilterBar(
          filters: const [
            'Marketplace Growth',
            'Demand',
            'Conversion Funnel',
            'Trust Metrics',
            'Revenue',
            'Retention'
          ],
          selected: _tab,
          onSelected: (value) => setState(() => _tab = value),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _dropdown(
                context,
                'Date range',
                _range,
                const ['This month', 'Last month', 'Quarter', 'Year'],
                (v) => setState(() {
                      _range = v;
                      _load();
                    })),
            ExportActionButton(
              exportType: 'admin_disputes',
              label: 'Export report',
              builder: (context, onTap, label) => AdminActionButton(
                icon: Icons.download_outlined,
                label: label,
                secondary: true,
                onTap: onTap,
              ),
            ),
            AdminActionButton(
                icon: Icons.compare_arrows_rounded,
                label: 'Compare month',
                secondary: true,
                onTap: () => showCoreSnack(context, 'Comparison enabled')),
            AdminActionButton(
                icon: Icons.picture_as_pdf_outlined,
                label: 'Investor summary',
                onTap: () =>
                    showCoreSnack(context, 'Investor summary downloaded')),
          ],
        ),
        const SizedBox(height: 18),
        _ResponsiveGrid(
          minTileWidth: 190,
          childAspectRatio: 2.6,
          children: metrics
              .map((m) => AdminMetricTile(
                  label: m.$1,
                  value: m.$2,
                  icon: m.$3,
                  tone: AdminDecisionTone.info))
              .toList(),
        ),
        const SizedBox(height: 18),
        _TwoPane(
          leftFlex: 3,
          rightFlex: 2,
          left: AdminChartCard(
            title: 'Category growth',
            subtitle: 'Verified supply indexed by week - $_range',
            values: const [20, 28, 35, 42, 58, 62, 74, 88],
            bars: false,
          ),
          right: const AdminChartCard(
            title: 'City distribution',
            subtitle: 'Lahore, Karachi, Islamabad, Rawalpindi, Multan',
            values: [72, 64, 45, 28, 22],
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: colors.inactiveChipGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminStatusBadge(
              label: '$priority - $status', tone: AdminDecisionTone.warning),
          const SizedBox(height: 12),
          _headline(context, title),
          const SizedBox(height: 6),
          _text(context, body),
          const SizedBox(height: 12),
          AdminStatusBadge(label: segment, tone: AdminDecisionTone.info),
          const SizedBox(height: 12),
          AdminActionButton(
            icon: Icons.notifications_none_rounded,
            label: 'Open SC-10 Notification Center',
            secondary: true,
            onTap: () => Navigator.pushNamed(context, CoreRoutes.notifications),
          ),
        ],
      ),
    );
  }
}
