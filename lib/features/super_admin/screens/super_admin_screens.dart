import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/core_booking/screens/booking_chat_screen.dart';
import '../../../core/core_payment/screens/receipts_ledger_screen.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/models/shared_models.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../mock_data/admin_mock_data.dart';
import '../models/admin_models.dart';
import '../routes/super_admin_routes.dart';
import '../widgets/admin_widgets.dart';

class SuperAdminPortalScreen extends StatelessWidget {
  final String routeName;

  const SuperAdminPortalScreen({
    super.key,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    final meta = _meta(routeName);
    return AdminShell(
      currentRoute: routeName,
      title: meta.$1,
      subtitle: meta.$2,
      child: _content(routeName),
    );
  }

  (String, String) _meta(String route) {
    return switch (route) {
      SuperAdminRoutes.reviewHub => (
          'Review Hub',
          'Review people, listings and reported content before they go live.',
        ),
      SuperAdminRoutes.reviewHubPeople => (
          'People Verification',
          'Full queue for people, documents and role verification decisions.',
        ),
      SuperAdminRoutes.reviewHubListings => (
          'Listings Review',
          'Full queue for marketplace listings before they go live.',
        ),
      SuperAdminRoutes.reviewHubContent => (
          'Content Moderation',
          'Full queue for reported content, media checks and profile safety.',
        ),
      SuperAdminRoutes.verifications => (
          'User Verification Queue',
          'Review identity, role documents and bank details before unlocking marketplace access.',
        ),
      SuperAdminRoutes.verificationDetail => (
          'KYC / KYB Review Detail',
          'Inspect documents, risk signals and decision checklist.',
        ),
      SuperAdminRoutes.contentModeration => (
          'Profile & Content Moderation',
          'Review portfolio, location media, reported content and watermark issues.',
        ),
      SuperAdminRoutes.listingsModeration => (
          'Listings Moderation',
          'Approve locations, equipment, packages and service listings.',
        ),
      SuperAdminRoutes.bookingsMonitor => (
          'Booking & Negotiation Monitor',
          'Monitor booking status, contract state, payments and risk flags.',
        ),
      SuperAdminRoutes.paymentQueue => (
          'Payment Verification Queue',
          'Verify uploaded proofs against contracts, milestones and agreed schedules.',
        ),
      SuperAdminRoutes.paymentReview => (
          'Payment Review Detail',
          'Compare uploaded proof with contract schedule and bank records.',
        ),
      SuperAdminRoutes.contractTemplates => (
          'Contract Template Manager',
          'Control agreement templates, mandatory clauses and version publishing.',
        ),
      SuperAdminRoutes.fees => (
          'Commission & Fee Management',
          'Manage platform revenue settings, plans, boosts and verification fees.',
        ),
      SuperAdminRoutes.disputes => (
          'Dispute Center',
          'Manage payment, completion, cancellation, damage and safety cases.',
        ),
      SuperAdminRoutes.disputeCase => (
          'Dispute Case File',
          'Evidence room, timeline and final decision workspace.',
        ),
      SuperAdminRoutes.users => (
          'User Management',
          'Search, inspect and control user access, roles, trust and risk.',
        ),
      SuperAdminRoutes.adminRoles => (
          'Admin Roles & Permissions',
          'Manage staff roles, protected permissions, sessions and 2FA.',
        ),
      SuperAdminRoutes.support => (
          'Support CRM / Tickets',
          'Handle reports, help requests, moderation follow-ups and disputes.',
        ),
      SuperAdminRoutes.broadcasts => (
          'Broadcast & Announcements',
          'Compose segmented in-app, push, email, SMS and WhatsApp announcements.',
        ),
      SuperAdminRoutes.auditLogs => (
          'Audit Log Explorer',
          'Read-only forensic event log for trust, money, safety and admin actions.',
        ),
      SuperAdminRoutes.analytics => (
          'Analytics Dashboard',
          'Investor-ready marketplace, trust, revenue and retention intelligence.',
        ),
      _ => (
          'Admin Dashboard',
          'Unified control. Real-time insights. Smarter decisions.',
        ),
    };
  }

  Widget _content(String route) {
    return switch (route) {
      SuperAdminRoutes.reviewHub => const ReviewHubScreen(),
      SuperAdminRoutes.reviewHubPeople => const UserVerificationQueueScreen(),
      SuperAdminRoutes.reviewHubListings => const ListingsModerationScreen(),
      SuperAdminRoutes.reviewHubContent => const ContentModerationScreen(),
      SuperAdminRoutes.verifications => const UserVerificationQueueScreen(),
      SuperAdminRoutes.verificationDetail => const KycReviewDetailScreen(),
      SuperAdminRoutes.contentModeration => const ContentModerationScreen(),
      SuperAdminRoutes.listingsModeration => const ListingsModerationScreen(),
      SuperAdminRoutes.bookingsMonitor => const BookingMonitorScreen(),
      SuperAdminRoutes.paymentQueue => const PaymentVerificationQueueScreen(),
      SuperAdminRoutes.paymentReview => const PaymentReviewDetailScreen(),
      SuperAdminRoutes.contractTemplates =>
        const ContractTemplateManagerScreen(),
      SuperAdminRoutes.fees => const CommissionFeeScreen(),
      SuperAdminRoutes.disputes => const DisputeCenterScreen(),
      SuperAdminRoutes.disputeCase => const DisputeCaseFileScreen(),
      SuperAdminRoutes.users => const UserManagementScreen(),
      SuperAdminRoutes.adminRoles => const AdminRolesPermissionsScreen(),
      SuperAdminRoutes.support => const SupportCrmScreen(),
      SuperAdminRoutes.broadcasts => const BroadcastAnnouncementsScreen(),
      SuperAdminRoutes.auditLogs => const AuditLogExplorerScreen(),
      SuperAdminRoutes.analytics => const AdminAnalyticsScreen(),
      _ => const AdminDashboardScreen(),
    };
  }
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ScrollController _kpiController = ScrollController();
  int _kpiPage = 0;

  static const _kpis = [
    _DashboardKpiData(
      label: 'Verifications',
      value: '42',
      subtext: '+9 today',
      icon: Icons.verified_user_outlined,
      tone: AdminDecisionTone.warning,
      route: SuperAdminRoutes.verifications,
    ),
    _DashboardKpiData(
      label: 'Payments',
      value: '18',
      subtext: 'PKR 4.2M',
      icon: Icons.payments_outlined,
      tone: AdminDecisionTone.danger,
      route: SuperAdminRoutes.paymentQueue,
    ),
    _DashboardKpiData(
      label: 'Disputes',
      value: '7',
      subtext: '2 high value',
      icon: Icons.gpp_maybe_outlined,
      tone: AdminDecisionTone.danger,
      route: SuperAdminRoutes.disputes,
    ),
    _DashboardKpiData(
      label: 'Negotiations',
      value: '126',
      subtext: '+18%',
      icon: Icons.swap_horiz_rounded,
      tone: AdminDecisionTone.info,
      route: SuperAdminRoutes.bookingsMonitor,
    ),
    _DashboardKpiData(
      label: 'Bookings',
      value: '14',
      subtext: 'Secured today',
      icon: Icons.lock_outline_rounded,
      tone: AdminDecisionTone.success,
      route: SuperAdminRoutes.bookingsMonitor,
    ),
    _DashboardKpiData(
      label: 'Revenue',
      value: 'PKR 2.8M',
      subtext: '+22%',
      icon: Icons.show_chart_rounded,
      tone: AdminDecisionTone.success,
      route: SuperAdminRoutes.analytics,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _kpiController.addListener(_updateKpiPage);
  }

  @override
  void dispose() {
    _kpiController
      ..removeListener(_updateKpiPage)
      ..dispose();
    super.dispose();
  }

  void _updateKpiPage() {
    final next = (_kpiController.offset / 300).round().clamp(0, 2).toInt();
    if (next != _kpiPage) setState(() => _kpiPage = next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DashboardKpiCarousel(
          items: _kpis,
          controller: _kpiController,
          activePage: _kpiPage,
          onTap: (item) => Navigator.pushNamed(context, item.route),
        ),
        const SizedBox(height: 16),
        _DashboardTwoColumn(
          left: _ActionFeedCard(
            onTap: (route) => Navigator.pushNamed(context, route),
          ),
          right: const _QueueSnapshotCard(),
        ),
        const SizedBox(height: 12),
        _QuickActionsCard(
          onRouteTap: (route) => Navigator.pushNamed(context, route),
        ),
        const SizedBox(height: 12),
        const _RecentActivityCard(),
      ],
    );
  }
}

class _DashboardKpiData {
  final String label;
  final String value;
  final String subtext;
  final IconData icon;
  final AdminDecisionTone tone;
  final String route;

  const _DashboardKpiData({
    required this.label,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.tone,
    required this.route,
  });
}

class _DashboardKpiCarousel extends StatelessWidget {
  final List<_DashboardKpiData> items;
  final ScrollController controller;
  final int activePage;
  final ValueChanged<_DashboardKpiData> onTap;

  const _DashboardKpiCarousel({
    required this.items,
    required this.controller,
    required this.activePage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            constraints.maxWidth < 520 ? 142.0 : constraints.maxWidth / 4.35;
        return Column(
          children: [
            SizedBox(
              height: 126,
              child: ListView.separated(
                controller: controller,
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return SizedBox(
                    width: cardWidth.clamp(136.0, 168.0).toDouble(),
                    child: _DashboardKpiCard(
                      item: item,
                      onTap: () => onTap(item),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            _CarouselDots(activePage: activePage),
          ],
        );
      },
    );
  }
}

class _DashboardKpiCard extends StatelessWidget {
  final _DashboardKpiData item;
  final VoidCallback onTap;

  const _DashboardKpiCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final toneColor = _dashboardToneColor(context, item.tone);
    return GestureDetector(
      onTap: onTap,
      child: AdminSurface(
        padding: const EdgeInsets.all(14),
        selected: item.tone == AdminDecisionTone.info,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: toneColor.withValues(alpha: 0.14),
              ),
              child: Icon(item.icon, color: toneColor, size: 19),
            ),
            const Spacer(),
            Text(
              item.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.sectionTitle.copyWith(
                color: colors.textPrimary,
                fontSize: item.value.length > 5 ? 21 : 27,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
                height: 1.04,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.subtext,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarouselDots extends StatelessWidget {
  final int activePage;

  const _CarouselDots({required this.activePage});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final active = index == activePage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 8 : 7,
          height: active ? 8 : 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? colors.goldDark : colors.textTertiary,
          ),
        );
      }),
    );
  }
}

class _DashboardTwoColumn extends StatelessWidget {
  final Widget left;
  final Widget right;

  const _DashboardTwoColumn({
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(
            children: [
              left,
              const SizedBox(height: 12),
              right,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 12),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _ActionFeedCard extends StatelessWidget {
  final ValueChanged<String> onTap;

  const _ActionFeedCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      padding: const EdgeInsets.all(13),
      child: Column(
        children: [
          _DashboardSectionHeader(
            title: 'Action Feed',
            icon: Icons.bolt_rounded,
            action: 'View all',
            onAction: () => onTap(SuperAdminRoutes.auditLogs),
          ),
          const SizedBox(height: 10),
          _FeedRow(
            badge: 'High',
            title: 'Payment proof waiting',
            meta: '5h 20m · Assigned to Raamiz',
            tone: AdminDecisionTone.danger,
            route: SuperAdminRoutes.paymentReview,
            onTap: onTap,
          ),
          const SizedBox(height: 8),
          _FeedRow(
            badge: 'SLA',
            title: 'KYC request older than 24h',
            meta: '28m · Assigned to Ayesha',
            tone: AdminDecisionTone.warning,
            route: SuperAdminRoutes.verificationDetail,
            onTap: onTap,
          ),
          const SizedBox(height: 8),
          _FeedRow(
            badge: 'Critical',
            title: 'High-value dispute needs decision',
            meta: '2d · Assigned to Basit',
            tone: AdminDecisionTone.danger,
            route: SuperAdminRoutes.disputeCase,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

class _FeedRow extends StatelessWidget {
  final String badge;
  final String title;
  final String meta;
  final AdminDecisionTone tone;
  final String route;
  final ValueChanged<String> onTap;

  const _FeedRow({
    required this.badge,
    required this.title,
    required this.meta,
    required this.tone,
    required this.route,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: () => onTap(route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          gradient: colors.inactiveChipGradient,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: colors.borderMuted),
        ),
        child: Row(
          children: [
            AdminStatusBadge(label: badge, tone: tone),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.iconMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueSnapshotCard extends StatelessWidget {
  const _QueueSnapshotCard();

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      padding: const EdgeInsets.all(13),
      child: const Column(
        children: [
          _DashboardSectionHeader(
            title: 'Queue Snapshot',
            icon: Icons.layers_rounded,
          ),
          SizedBox(height: 10),
          _QueueRow(
            title: 'KYC Queue',
            value: '12 pending',
            badge: 'On track',
            icon: Icons.person_search_outlined,
            tone: AdminDecisionTone.success,
          ),
          SizedBox(height: 8),
          _QueueRow(
            title: 'Payments Queue',
            value: '18 pending',
            badge: 'Attention',
            icon: Icons.wallet_outlined,
            tone: AdminDecisionTone.danger,
          ),
          SizedBox(height: 8),
          _QueueRow(
            title: 'Disputes Queue',
            value: '7 open',
            badge: '1 high value',
            icon: Icons.gpp_maybe_outlined,
            tone: AdminDecisionTone.warning,
          ),
        ],
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  final String title;
  final String value;
  final String badge;
  final IconData icon;
  final AdminDecisionTone tone;

  const _QueueRow({
    required this.title,
    required this.value,
    required this.badge,
    required this.icon,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final toneColor = _dashboardToneColor(context, tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        gradient: colors.inactiveChipGradient,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.borderMuted),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: toneColor.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: toneColor, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          AdminStatusBadge(label: badge, tone: tone),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  final ValueChanged<String> onRouteTap;

  const _QuickActionsCard({required this.onRouteTap});

  @override
  Widget build(BuildContext context) {
    const actions = [
      _QuickActionData(
        label: 'Open Review Hub',
        icon: Icons.verified_user_outlined,
        route: SuperAdminRoutes.reviewHub,
      ),
      _QuickActionData(
        label: 'Verify Payments',
        icon: Icons.payments_outlined,
        route: SuperAdminRoutes.paymentQueue,
      ),
      _QuickActionData(
        label: 'Open Disputes',
        icon: Icons.gpp_maybe_outlined,
        route: SuperAdminRoutes.disputes,
      ),
      _QuickActionData(
        label: 'View Bookings',
        icon: Icons.calendar_month_outlined,
        route: SuperAdminRoutes.bookingsMonitor,
      ),
      _QuickActionData(
        label: 'Open Audit Logs',
        icon: Icons.manage_search_outlined,
        route: SuperAdminRoutes.auditLogs,
      ),
      _QuickActionData(
        label: 'Run Analytics',
        icon: Icons.analytics_outlined,
        route: SuperAdminRoutes.analytics,
      ),
    ];

    return AdminSurface(
      padding: const EdgeInsets.all(13),
      child: Column(
        children: [
          const _DashboardSectionHeader(
            title: 'Quick Actions',
            icon: Icons.bolt_rounded,
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 620 ? 3 : 2;
              final itemWidth =
                  (constraints.maxWidth - (columns - 1) * 9) / columns;
              return Wrap(
                spacing: 9,
                runSpacing: 9,
                children: actions
                    .map(
                      (action) => SizedBox(
                        width: itemWidth,
                        child: _QuickActionButton(
                          action: action,
                          onTap: () => onRouteTap(action.route),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActionData {
  final String label;
  final IconData icon;
  final String route;

  const _QuickActionData({
    required this.label,
    required this.icon,
    required this.route,
  });
}

class _QuickActionButton extends StatelessWidget {
  final _QuickActionData action;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          gradient: colors.inactiveChipGradient,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.borderMuted),
        ),
        child: Row(
          children: [
            Container(
              width: 27,
              height: 27,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.goldMid.withValues(alpha: 0.12),
              ),
              child: Icon(action.icon, color: colors.goldDark, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard();

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      padding: const EdgeInsets.all(13),
      child: Column(
        children: const [
          _DashboardSectionHeader(
            title: 'Recent Activity',
            icon: Icons.history_rounded,
            action: 'View all',
          ),
          SizedBox(height: 8),
          _ActivityRow(
            title: 'Payment approved',
            detail: 'PKR 1,250,000 · CineFlex Studios',
            time: '11:32 AM',
            icon: Icons.check_circle_outline,
            tone: AdminDecisionTone.success,
          ),
          _ActivityRow(
            title: 'KYC rejected',
            detail: 'Applicant ID: CNK-87421',
            time: '10:45 AM',
            icon: Icons.cancel_outlined,
            tone: AdminDecisionTone.danger,
          ),
          _ActivityRow(
            title: 'Contract template published',
            detail: 'Template: Talent Agreement v2.1',
            time: '09:18 AM',
            icon: Icons.description_outlined,
            tone: AdminDecisionTone.info,
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final String title;
  final String detail;
  final String time;
  final IconData icon;
  final AdminDecisionTone tone;

  const _ActivityRow({
    required this.title,
    required this.detail,
    required this.time,
    required this.icon,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final toneColor = _dashboardToneColor(context, tone);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.borderMuted),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: toneColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            time,
            style: AppTextStyles.caption.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? action;
  final VoidCallback? onAction;

  const _DashboardSectionHeader({
    required this.title,
    required this.icon,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Icon(icon, color: colors.goldDark, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.sectionTitle.copyWith(
              color: colors.textPrimary,
              fontSize: 17,
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              action!,
              style: AppTextStyles.caption.copyWith(
                color: colors.goldDark,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }
}

Color _dashboardToneColor(BuildContext context, AdminDecisionTone tone) {
  final colors = context.appColors;
  return switch (tone) {
    AdminDecisionTone.success => colors.success,
    AdminDecisionTone.warning => colors.goldMid,
    AdminDecisionTone.info => colors.infoBlue,
    AdminDecisionTone.danger => colors.infoPurple,
    AdminDecisionTone.neutral => colors.textSecondary,
  };
}

class ReviewHubScreen extends StatelessWidget {
  const ReviewHubScreen({super.key});

  static const _summary = [
    _ReviewSummaryData(
      label: 'People Pending',
      value: '12',
      subtext: '3 today',
      icon: Icons.groups_rounded,
      tone: AdminDecisionTone.danger,
    ),
    _ReviewSummaryData(
      label: 'Listings Pending',
      value: '18',
      subtext: '5 today',
      icon: Icons.storefront_outlined,
      tone: AdminDecisionTone.warning,
    ),
    _ReviewSummaryData(
      label: 'Content Reports',
      value: '9',
      subtext: '2 today',
      icon: Icons.flag_outlined,
      tone: AdminDecisionTone.info,
    ),
    _ReviewSummaryData(
      label: 'High Risk',
      value: '4',
      subtext: 'Requires attention',
      icon: Icons.warning_amber_rounded,
      tone: AdminDecisionTone.danger,
    ),
  ];

  static const _people = [
    _ReviewPersonData(
      name: 'Ali Khan',
      role: 'Actor / Talent',
      city: 'Lahore',
      docsDone: 4,
      docsTotal: 5,
      risk: 'Low Risk',
      time: '2h ago',
      asset: AppAssets.bilalAbbas,
      tone: AdminDecisionTone.success,
    ),
    _ReviewPersonData(
      name: 'Sara Malik',
      role: 'Model',
      city: 'Karachi',
      docsDone: 5,
      docsTotal: 5,
      risk: 'Medium Risk',
      time: '18h ago',
      asset: AppAssets.sanaKhalid,
      tone: AdminDecisionTone.warning,
    ),
    _ReviewPersonData(
      name: 'FrameHouse Pvt Ltd',
      role: 'Media Provider',
      city: 'Lahore',
      docsDone: 6,
      docsTotal: 6,
      risk: 'High Risk',
      time: '1d ago',
      tone: AdminDecisionTone.danger,
    ),
  ];

  static const _listings = [
    _ReviewListingData(
      title: 'Gulberg Heritage Home',
      owner: 'Sara Malik',
      city: 'Lahore',
      category: 'Location',
      price: 'PKR 95k/day',
      deposit: 'Deposit PKR 50k',
      status: 'Pending',
      icon: Icons.apartment_rounded,
      tone: AdminDecisionTone.warning,
    ),
    _ReviewListingData(
      title: 'ARRI Alexa Mini Package',
      owner: 'FrameHouse Pvt Ltd',
      city: 'Karachi',
      category: 'Equipment',
      price: 'PKR 80k/day',
      deposit: 'Deposit PKR 120k',
      status: 'Pending',
      icon: Icons.videocam_outlined,
      tone: AdminDecisionTone.info,
    ),
    _ReviewListingData(
      title: 'Makeup + Hair Team',
      owner: 'Glam Pro Studio',
      city: 'Lahore',
      category: 'Service',
      price: 'PKR 45k',
      deposit: 'Deposit PKR 15k',
      status: 'SLA 24h+',
      icon: Icons.brush_outlined,
      tone: AdminDecisionTone.info,
    ),
    _ReviewListingData(
      title: 'Lighting Kit Pro Bundle',
      owner: 'Northstar Crew',
      city: 'Islamabad',
      category: 'Equipment',
      price: 'PKR 60k/day',
      deposit: 'Deposit PKR 80k',
      status: 'Pending',
      icon: Icons.lightbulb_outline_rounded,
      tone: AdminDecisionTone.warning,
    ),
    _ReviewListingData(
      title: 'DOP + Gaffer Crew Bundle',
      owner: 'Northstar Crew',
      city: 'Islamabad',
      category: 'Services',
      price: 'PKR 180k',
      deposit: 'Deposit PKR 35k',
      status: 'High Risk',
      icon: Icons.groups_2_outlined,
      tone: AdminDecisionTone.danger,
    ),
  ];

  static const _content = [
    _ReviewContentData(
      title: 'Rooftop location gallery',
      owner: 'Gulberg House',
      role: 'Location Owner',
      time: '3h ago',
      visibility: 'Public pending',
      watermark: 'Passed',
      reports: '1 report',
      icon: Icons.landscape_outlined,
      tone: AdminDecisionTone.info,
    ),
    _ReviewContentData(
      title: 'Drone reel rate claim',
      owner: 'FrameHouse Pvt Ltd',
      role: 'Media Provider',
      time: 'Today',
      visibility: 'Review required',
      watermark: 'N/A',
      reports: '0 reports',
      icon: Icons.flight_takeoff_rounded,
      tone: AdminDecisionTone.warning,
    ),
    _ReviewContentData(
      title: 'Fashion campaign portfolio set',
      owner: 'Sara Malik',
      role: 'Model',
      time: '32m ago',
      visibility: 'Public pending',
      watermark: 'Passed',
      reports: '0 reports',
      icon: Icons.photo_camera_outlined,
      tone: AdminDecisionTone.info,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ReviewSummaryStrip(items: _summary),
        const SizedBox(height: 16),
        _ReviewPeopleSection(
          people: _people,
          onReview: () =>
              Navigator.pushNamed(context, SuperAdminRoutes.verificationDetail),
          onViewAll: () =>
              Navigator.pushNamed(context, SuperAdminRoutes.reviewHubPeople),
        ),
        const SizedBox(height: 16),
        _ReviewListingsSection(
          listings: _listings,
          onOpen: (listing) => _previewListing(
            context,
            AdminListing(
              title: listing.title,
              owner: listing.owner,
              city: listing.city,
              category: listing.category,
              price: listing.price,
              deposit: listing.deposit.replaceFirst('Deposit ', ''),
              date: 'Today',
              visibility: 'Public preview',
              status: listing.status,
            ),
          ),
          onViewAll: () =>
              Navigator.pushNamed(context, SuperAdminRoutes.reviewHubListings),
        ),
        const SizedBox(height: 16),
        _ReviewContentSection(
          items: _content,
          onViewAll: () =>
              Navigator.pushNamed(context, SuperAdminRoutes.reviewHubContent),
        ),
      ],
    );
  }
}

class _ReviewSummaryData {
  final String label;
  final String value;
  final String subtext;
  final IconData icon;
  final AdminDecisionTone tone;

  const _ReviewSummaryData({
    required this.label,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.tone,
  });
}

class _ReviewPersonData {
  final String name;
  final String role;
  final String city;
  final int docsDone;
  final int docsTotal;
  final String risk;
  final String time;
  final String? asset;
  final AdminDecisionTone tone;

  const _ReviewPersonData({
    required this.name,
    required this.role,
    required this.city,
    required this.docsDone,
    required this.docsTotal,
    required this.risk,
    required this.time,
    this.asset,
    required this.tone,
  });
}

class _ReviewListingData {
  final String title;
  final String owner;
  final String city;
  final String category;
  final String price;
  final String deposit;
  final String status;
  final IconData icon;
  final AdminDecisionTone tone;

  const _ReviewListingData({
    required this.title,
    required this.owner,
    required this.city,
    required this.category,
    required this.price,
    required this.deposit,
    required this.status,
    required this.icon,
    required this.tone,
  });
}

class _ReviewContentData {
  final String title;
  final String owner;
  final String role;
  final String time;
  final String visibility;
  final String watermark;
  final String reports;
  final IconData icon;
  final AdminDecisionTone tone;

  const _ReviewContentData({
    required this.title,
    required this.owner,
    required this.role,
    required this.time,
    required this.visibility,
    required this.watermark,
    required this.reports,
    required this.icon,
    required this.tone,
  });
}

class _ReviewSummaryStrip extends StatelessWidget {
  final List<_ReviewSummaryData> items;

  const _ReviewSummaryStrip({required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final cardWidth = wide ? (constraints.maxWidth - 36) / 4 : 184.0;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: items.asMap().entries.map((entry) {
              final item = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  right: entry.key == items.length - 1 ? 0 : 12,
                ),
                child: SizedBox(
                  width: cardWidth,
                  child: _ReviewSummaryCard(item: item),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _ReviewSummaryCard extends StatelessWidget {
  final _ReviewSummaryData item;

  const _ReviewSummaryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final toneColor = _dashboardToneColor(context, item.tone);
    return AdminSurface(
      padding: const EdgeInsets.all(15),
      selected: item.tone == AdminDecisionTone.warning,
      child: SizedBox(
        height: 106,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(item.icon, color: toneColor, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              item.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.sectionTitle.copyWith(
                color: colors.textPrimary,
                fontSize: 34,
                height: 1,
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                if (item.label != 'High Risk') ...[
                  Icon(Icons.arrow_upward_rounded,
                      color: colors.success, size: 16),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    item.subtext,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewPeopleSection extends StatelessWidget {
  final List<_ReviewPersonData> people;
  final VoidCallback onReview;
  final VoidCallback onViewAll;

  const _ReviewPeopleSection({
    required this.people,
    required this.onReview,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          _ReviewSectionHeader(
            title: 'People Verification',
            icon: Icons.manage_accounts_outlined,
            action: 'View All People',
            onAction: onViewAll,
          ),
          const SizedBox(height: 12),
          ...people.asMap().entries.map((entry) {
            return _ReviewPersonRow(
              person: entry.value,
              onReview: onReview,
              showDivider: entry.key != people.length - 1,
            );
          }),
        ],
      ),
    );
  }
}

class _ReviewPersonRow extends StatelessWidget {
  final _ReviewPersonData person;
  final VoidCallback onReview;
  final bool showDivider;

  const _ReviewPersonRow({
    required this.person,
    required this.onReview,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final toneColor = _dashboardToneColor(context, person.tone);
    return Container(
      padding: EdgeInsets.only(bottom: showDivider ? 12 : 4),
      margin: EdgeInsets.only(bottom: showDivider ? 12 : 0),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.borderMuted))
            : null,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final main = Row(
            children: [
              _ReviewAvatar(person: person),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${person.role} - ${person.city}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Documents ${person.docsDone}/${person.docsTotal}',
                          style: AppTextStyles.caption.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: person.docsDone / person.docsTotal,
                              minHeight: 4,
                              color: toneColor,
                              backgroundColor:
                                  colors.borderMuted.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
          final action = Column(
            crossAxisAlignment:
                compact ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              AdminStatusBadge(label: person.risk, tone: person.tone),
              const SizedBox(height: 8),
              Text(
                person.time,
                style: AppTextStyles.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              _ReviewOutlineButton(label: 'Review', onTap: onReview),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                main,
                const SizedBox(height: 12),
                action,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: main),
              const SizedBox(width: 14),
              SizedBox(width: 140, child: action),
            ],
          );
        },
      ),
    );
  }
}

class _ReviewAvatar extends StatelessWidget {
  final _ReviewPersonData person;

  const _ReviewAvatar({required this.person});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      width: 62,
      height: 62,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipOval(
              child: person.asset == null
                  ? Container(
                      color: colors.softSurface,
                      alignment: Alignment.center,
                      child: Text(
                        'FH',
                        style: AppTextStyles.label.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  : Image.asset(person.asset!, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.surface,
                border: Border.all(
                    color: _dashboardToneColor(context, person.tone)),
              ),
              child: Icon(
                Icons.verified_user_outlined,
                color: _dashboardToneColor(context, person.tone),
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewListingsSection extends StatelessWidget {
  final List<_ReviewListingData> listings;
  final ValueChanged<_ReviewListingData> onOpen;
  final VoidCallback onViewAll;

  const _ReviewListingsSection({
    required this.listings,
    required this.onOpen,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _ReviewSectionHeader(
              title: 'Listings Review',
              icon: Icons.storefront_outlined,
              action: 'View All Listings',
              onAction: onViewAll,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 360,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(right: 16),
              itemCount: listings.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final listing = listings[index];
                return SizedBox(
                  width: 168,
                  child: _ReviewListingCard(
                    listing: listing,
                    onOpen: () => onOpen(listing),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewListingCard extends StatelessWidget {
  final _ReviewListingData listing;
  final VoidCallback onOpen;

  const _ReviewListingCard({
    required this.listing,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final toneColor = _dashboardToneColor(context, listing.tone);
    return Container(
      decoration: BoxDecoration(
        gradient: colors.inactiveChipGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderMuted),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 112,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  toneColor.withValues(alpha: 0.34),
                  colors.softSurface.withValues(alpha: 0.84),
                  colors.surface.withValues(alpha: 0.92),
                ],
              ),
            ),
            child: Icon(listing.icon, color: toneColor, size: 42),
          ),
          Padding(
            padding: const EdgeInsets.all(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminStatusBadge(label: listing.category, tone: listing.tone),
                const SizedBox(height: 10),
                Text(
                  listing.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${listing.owner}\n${listing.city}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: colors.textSecondary,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                AdminStatusBadge(
                    label: listing.price, tone: AdminDecisionTone.info),
                const SizedBox(height: 7),
                Text(
                  listing.deposit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: colors.goldDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  listing.status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: toneColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                _ReviewOutlineButton(label: 'Open', onTap: onOpen),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewContentSection extends StatelessWidget {
  final List<_ReviewContentData> items;
  final VoidCallback onViewAll;

  const _ReviewContentSection({
    required this.items,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          _ReviewSectionHeader(
            title: 'Content Moderation',
            icon: Icons.shield_outlined,
            action: 'View All Content',
            onAction: onViewAll,
          ),
          const SizedBox(height: 12),
          ...items.asMap().entries.map((entry) {
            return _ReviewContentRow(
              item: entry.value,
              showDivider: entry.key != items.length - 1,
            );
          }),
        ],
      ),
    );
  }
}

class _ReviewContentRow extends StatelessWidget {
  final _ReviewContentData item;
  final bool showDivider;

  const _ReviewContentRow({
    required this.item,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final toneColor = _dashboardToneColor(context, item.tone);
    return Container(
      padding: EdgeInsets.only(bottom: showDivider ? 12 : 4),
      margin: EdgeInsets.only(bottom: showDivider ? 12 : 0),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.borderMuted))
            : null,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final identity = Row(
            children: [
              Container(
                width: 72,
                height: 62,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: toneColor.withValues(alpha: 0.12),
                ),
                child: Icon(item.icon, color: toneColor, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.owner} - ${item.role} - ${item.time}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        AdminStatusBadge(
                          label: item.visibility,
                          tone: AdminDecisionTone.info,
                        ),
                        AdminStatusBadge(
                          label: item.watermark,
                          tone: AdminDecisionTone.warning,
                        ),
                        AdminStatusBadge(
                          label: item.reports,
                          tone: AdminDecisionTone.success,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            children: const [
              _ReviewContentAction(
                icon: Icons.check_circle_outline,
                label: 'Approve',
                tone: AdminDecisionTone.warning,
              ),
              _ReviewContentAction(
                icon: Icons.delete_outline_rounded,
                label: 'Remove',
                tone: AdminDecisionTone.danger,
              ),
              _ReviewContentAction(
                icon: Icons.warning_amber_rounded,
                label: 'Warn',
                tone: AdminDecisionTone.warning,
              ),
              _ReviewContentAction(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                tone: AdminDecisionTone.neutral,
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                identity,
                const SizedBox(height: 12),
                actions,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: identity),
              const SizedBox(width: 14),
              SizedBox(width: 280, child: actions),
            ],
          );
        },
      ),
    );
  }
}

class _ReviewContentAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final AdminDecisionTone tone;

  const _ReviewContentAction({
    required this.icon,
    required this.label,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final toneColor = _dashboardToneColor(context, tone);
    return SizedBox(
      width: 56,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: toneColor, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.micro.copyWith(
              color: tone == AdminDecisionTone.neutral
                  ? colors.textSecondary
                  : toneColor,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final String action;
  final VoidCallback onAction;

  const _ReviewSectionHeader({
    required this.title,
    required this.icon,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Icon(icon, color: colors.goldDark, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.sectionTitle.copyWith(
              color: colors.textPrimary,
              fontSize: 22,
            ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                action,
                style: AppTextStyles.label.copyWith(
                  color: colors.goldDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 5),
              Icon(Icons.chevron_right_rounded,
                  color: colors.goldDark, size: 19),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ReviewOutlineButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.goldDark, width: 1.1),
          color: colors.goldGlow.withValues(alpha: 0.04),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.label.copyWith(
            color: colors.goldDark,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class UserVerificationQueueScreen extends StatefulWidget {
  const UserVerificationQueueScreen({super.key});

  @override
  State<UserVerificationQueueScreen> createState() =>
      _UserVerificationQueueScreenState();
}

class _UserVerificationQueueScreenState
    extends State<UserVerificationQueueScreen> {
  String _role = 'All';
  String _city = 'Lahore';
  String _sla = 'New';
  String _risk = 'Duplicate CNIC';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<KycSubmission> get _rows {
    final query = _search.text.toLowerCase();
    return AdminMockData.kycSubmissions.where((item) {
      final roleMatch = _role == 'All' || item.role.contains(_role);
      final queryMatch = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.risk.toLowerCase().contains(query);
      return roleMatch && queryMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CoreTextField(
                controller: _search,
                label: 'Search applicant, CNIC risk, device or role',
                icon: Icons.search_rounded,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              AdminFilterBar(
                filters: const [
                  'All',
                  'Director/Producer',
                  'Actor/Talent',
                  'Model',
                  'Location Owner',
                  'Equipment Provider',
                  'Agency',
                  'Brand/Sponsor',
                ],
                selected: _role,
                onSelected: (value) => setState(() => _role = value),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _dropdown(
                    context,
                    'City',
                    _city,
                    const ['Lahore', 'Karachi', 'Islamabad', 'Rawalpindi'],
                    (value) => setState(() => _city = value),
                  ),
                  _dropdown(
                    context,
                    'SLA',
                    _sla,
                    const ['New', '12h+', '24h+', '48h+'],
                    (value) => setState(() => _sla = value),
                  ),
                  _dropdown(
                    context,
                    'Risk',
                    _risk,
                    const [
                      'Duplicate CNIC',
                      'Duplicate Device',
                      'Mismatched Name',
                      'Bank Name Mismatch',
                    ],
                    (value) => setState(() => _risk = value),
                  ),
                  AdminActionButton(
                    icon: Icons.groups_outlined,
                    label: 'Bulk assign selected',
                    secondary: true,
                    onTap: () => _staffSheet(context),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        AdminDataTable(
          columns: const [
            'User',
            'Role',
            'City',
            'Docs',
            'Age',
            'Risk Flags',
            'Assigned',
            'Status',
            'Action',
          ],
          rowActions: _rows
              .map<VoidCallback?>(
                (_) => () => Navigator.pushNamed(
                    context, SuperAdminRoutes.verificationDetail),
              )
              .toList(),
          rows: _rows
              .map(
                (row) => [
                  _text(context, row.name, strong: true),
                  _text(context, row.role),
                  _text(context, row.city),
                  _text(context, row.docs),
                  AdminSlaBadge(age: row.age),
                  AdminRiskBadge(
                    label: row.risk,
                    risk: row.risk == 'No risk'
                        ? AdminRiskTone.low
                        : AdminRiskTone.high,
                  ),
                  _text(context, row.assignedTo),
                  AdminStatusBadge(
                    label: row.status,
                    tone: row.status.contains('Risk')
                        ? AdminDecisionTone.danger
                        : AdminDecisionTone.warning,
                  ),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _tinyAction(
                        context,
                        'Review',
                        () => Navigator.pushNamed(
                            context, SuperAdminRoutes.verificationDetail),
                      ),
                      _tinyAction(
                          context, 'Assign', () => _staffSheet(context)),
                      _tinyAction(
                        context,
                        'Reject',
                        () => _noteDialog(context, 'Reject quick note'),
                      ),
                    ],
                  ),
                ],
              )
              .toList(),
        ),
      ],
    );
  }
}

class KycReviewDetailScreen extends StatefulWidget {
  const KycReviewDetailScreen({super.key});

  @override
  State<KycReviewDetailScreen> createState() => _KycReviewDetailScreenState();
}

class _KycReviewDetailScreenState extends State<KycReviewDetailScreen> {
  String _document = 'CNIC Front';
  double _zoom = 1;
  final Set<String> _checked = {'Identity document readable'};
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final children = [
          _applicantPanel(context),
          _documentPanel(context),
          _decisionPanel(context),
        ];
        if (!wide) {
          return Column(
            children: children
                .map((child) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: child,
                    ))
                .toList(),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 270, child: children[0]),
            const SizedBox(width: 16),
            Expanded(child: children[1]),
            const SizedBox(width: 16),
            SizedBox(width: 330, child: children[2]),
          ],
        );
      },
    );
  }

  Widget _applicantPanel(BuildContext context) {
    return AdminSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminUserMiniCard(
            name: 'FrameHouse Pvt Ltd',
            detail: 'Media Provider - Lahore',
            badge: 'Risk flagged',
          ),
          const SizedBox(height: 14),
          const AdminRiskBadge(
              label: 'Risk score 72', risk: AdminRiskTone.high),
          const SizedBox(height: 14),
          _kv(context, 'Phone/email', '0300-XXX / ops@framehouse.pk'),
          _kv(context, 'Submitted', 'Jul 8, 2026 - 11:10'),
          _kv(context, 'Status', 'Pending review'),
          _kv(context, 'Device/IP', 'Android 16 / 10.0.2.15'),
          _kv(context, 'Previous submissions', '1 rejected, 1 resubmitted'),
          const SizedBox(height: 14),
          AdminActionButton(
            icon: Icons.manage_search_outlined,
            label: 'Open Audit Logs',
            secondary: true,
            onTap: () =>
                Navigator.pushNamed(context, SuperAdminRoutes.auditLogs),
          ),
          const SizedBox(height: 10),
          AdminActionButton(
            icon: Icons.upload_file_outlined,
            label: 'View user KYC flow',
            secondary: true,
            onTap: () => Navigator.pushNamed(context, CoreRoutes.kyc),
          ),
        ],
      ),
    );
  }

  Widget _documentPanel(BuildContext context) {
    return AdminSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminFilterBar(
            filters: const [
              'CNIC Front',
              'CNIC Back',
              'Selfie',
              'Company Registration',
              'Bank Details',
              'Address Proof',
            ],
            selected: _document,
            onSelected: (value) => setState(() => _document = value),
          ),
          const SizedBox(height: 16),
          Transform.scale(
            scale: _zoom,
            child: AdminEvidenceViewer(
              title: _document,
              icon: Icons.article_outlined,
              details: const [
                'Clear edges',
                'OCR confidence 94%',
                'Admin preview'
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AdminActionButton(
                icon: Icons.zoom_in_rounded,
                label: 'Zoom in',
                secondary: true,
                onTap: () =>
                    setState(() => _zoom = (_zoom + .08).clamp(1, 1.3)),
              ),
              AdminActionButton(
                icon: Icons.zoom_out_rounded,
                label: 'Zoom out',
                secondary: true,
                onTap: () =>
                    setState(() => _zoom = (_zoom - .08).clamp(1, 1.3)),
              ),
              AdminActionButton(
                icon: Icons.rotate_right_rounded,
                label: 'Rotate',
                secondary: true,
                onTap: () => showCoreSnack(context, 'Document rotated'),
              ),
              AdminActionButton(
                icon: Icons.check_circle_outline,
                label: 'Mark clear',
                onTap: () => showCoreSnack(context, 'Document marked clear'),
              ),
              AdminActionButton(
                icon: Icons.error_outline,
                label: 'Mark unclear',
                secondary: true,
                onTap: () => showCoreSnack(context, 'Document marked unclear'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _decisionPanel(BuildContext context) {
    final checks = const [
      'Identity document readable',
      'Selfie matches document',
      'Name matches account',
      'Role-specific docs valid',
      'Bank account title matches user',
      'Address proof verified',
      'No duplicate CNIC',
      'No duplicate device risk',
    ];
    return AdminSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeader(title: 'Review Checklist'),
          const SizedBox(height: 8),
          ...checks.map(
            (check) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _checked.contains(check),
              onChanged: (value) {
                setState(() {
                  if (value ?? false) {
                    _checked.add(check);
                  } else {
                    _checked.remove(check);
                  }
                });
              },
              title: Text(check),
            ),
          ),
          const SizedBox(height: 12),
          CoreTextField(
            controller: _note,
            label: 'Add internal risk note...',
            icon: Icons.note_alt_outlined,
            maxLines: 4,
          ),
          const SizedBox(height: 14),
          AdminActionButton(
            icon: Icons.verified_outlined,
            label: 'Approve',
            onTap: () => _decision(
                context, 'User approved. Marketplace access unlocked.'),
          ),
          const SizedBox(height: 10),
          AdminActionButton(
            icon: Icons.cancel_outlined,
            label: 'Reject with Reason',
            secondary: true,
            onTap: () => _noteDialog(
              context,
              'Reject reason: CNIC image unclear / Bank name mismatch / Missing property proof',
            ),
          ),
          const SizedBox(height: 10),
          AdminActionButton(
            icon: Icons.contact_support_outlined,
            label: 'Request More Info',
            secondary: true,
            onTap: () => _noteDialog(context, 'Request more information'),
          ),
        ],
      ),
    );
  }

  void _decision(BuildContext context, String message) {
    showCoreSuccessDialog(
      context,
      title: 'Decision Saved',
      message: message,
      onDone: () => showCoreSnack(context, 'Decision written to audit log.'),
    );
  }
}

class ContentModerationScreen extends StatefulWidget {
  const ContentModerationScreen({super.key});

  @override
  State<ContentModerationScreen> createState() =>
      _ContentModerationScreenState();
}

class _ContentModerationScreenState extends State<ContentModerationScreen> {
  String _tab = 'Portfolio Photos';
  late final List<AdminContentItem> _items =
      List.of(AdminMockData.contentItems);

  @override
  Widget build(BuildContext context) {
    final filtered = _items
        .where((item) => _tab == item.type || _tab == 'Portfolio Photos')
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFilterBar(
          filters: const [
            'Portfolio Photos',
            'Videos',
            'Location Images',
            'Rate Claims',
            'Reported Content',
            'Watermark Issues',
          ],
          selected: _tab,
          onSelected: (value) => setState(() => _tab = value),
        ),
        const SizedBox(height: 18),
        _ResponsiveGrid(
          minTileWidth: 280,
          children:
              filtered.map((item) => _moderationCard(context, item)).toList(),
        ),
      ],
    );
  }

  Widget _moderationCard(BuildContext context, AdminContentItem item) {
    final colors = context.appColors;
    return AdminSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: RadialGradient(
                colors: [
                  colors.goldGlow.withValues(alpha: .55),
                  colors.softSurface.withValues(alpha: .55),
                ],
              ),
            ),
            child: Center(
              child: Icon(Icons.photo_library_outlined,
                  color: colors.goldDark, size: 44),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: AppTextStyles.label.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${item.user} - ${item.role} - ${item.time}',
            style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AdminStatusBadge(
                  label: item.visibility, tone: AdminDecisionTone.info),
              AdminStatusBadge(
                  label: item.watermark, tone: AdminDecisionTone.warning),
              AdminRiskBadge(
                label: '${item.reports} reports',
                risk: item.risk == 'High'
                    ? AdminRiskTone.high
                    : AdminRiskTone.low,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _tinyAction(context, 'Approve', () {
                setState(() => _items.remove(item));
                showCoreSnack(context, 'Content approved');
              }),
              _tinyAction(context, 'Remove',
                  () => _noteDialog(context, 'Removal reason')),
              _tinyAction(context, 'Warn',
                  () => _noteDialog(context, 'Warning template')),
              _tinyAction(context, 'Profile',
                  () => Navigator.pushNamed(context, SuperAdminRoutes.users)),
              _tinyAction(context, 'Escalate', () {
                showCoreSnack(context, 'Support ticket created');
                Navigator.pushNamed(context, SuperAdminRoutes.support);
              }),
            ],
          ),
        ],
      ),
    );
  }
}

class ListingsModerationScreen extends StatefulWidget {
  const ListingsModerationScreen({super.key});

  @override
  State<ListingsModerationScreen> createState() =>
      _ListingsModerationScreenState();
}

class _ListingsModerationScreenState extends State<ListingsModerationScreen> {
  String _tab = 'Locations';
  final Map<String, String> _statuses = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFilterBar(
          filters: const [
            'Locations',
            'Equipment',
            'Packages',
            'Services',
            'Rejected',
            'Approved'
          ],
          selected: _tab,
          onSelected: (value) => setState(() => _tab = value),
        ),
        const SizedBox(height: 18),
        _ResponsiveGrid(
          minTileWidth: 360,
          children: AdminMockData.listings
              .map((listing) => _listingCard(context, listing))
              .toList(),
        ),
      ],
    );
  }

  Widget _listingCard(BuildContext context, AdminListing listing) {
    final status = _statuses[listing.title] ?? listing.status;
    final checks = listing.category == 'Equipment'
        ? const [
            'Inventory photos clear',
            'Serial number optional',
            'Deposit defined',
            'Handover terms clear',
            'Operator requirement stated',
            'Overtime terms added',
          ]
        : const [
            'Photos look genuine',
            'Exact address hidden',
            'Approximate area visible',
            'Pricing reasonable',
            'Deposit terms clear',
            'Rules and availability added',
          ];
    return AdminSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _headline(context, listing.title)),
              AdminStatusBadge(
                label: status == 'Live' ? 'Live' : status,
                tone: status == 'Live'
                    ? AdminDecisionTone.success
                    : AdminDecisionTone.warning,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _text(context,
              '${listing.owner} - ${listing.city} - ${listing.category}'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AdminStatusBadge(
                  label: listing.price, tone: AdminDecisionTone.info),
              AdminStatusBadge(
                  label: 'Deposit ${listing.deposit}',
                  tone: AdminDecisionTone.warning),
              AdminStatusBadge(
                  label: listing.visibility, tone: AdminDecisionTone.neutral),
            ],
          ),
          const SizedBox(height: 12),
          ...checks.map(
            (check) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 17, color: context.appColors.success),
                  const SizedBox(width: 8),
                  Expanded(child: _text(context, check)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _tinyAction(context, 'Approve Listing', () {
                setState(() => _statuses[listing.title] = 'Live');
                showCoreSnack(context, 'Listing approved and made live');
              }),
              _tinyAction(context, 'Reject',
                  () => _noteDialog(context, 'Reject with note')),
              _tinyAction(context, 'Request Changes',
                  () => showCoreSnack(context, 'Static notification sent')),
              _tinyAction(
                  context, 'Preview', () => _previewListing(context, listing)),
            ],
          ),
        ],
      ),
    );
  }
}

class BookingMonitorScreen extends StatefulWidget {
  const BookingMonitorScreen({super.key});

  @override
  State<BookingMonitorScreen> createState() => _BookingMonitorScreenState();
}

class _BookingMonitorScreenState extends State<BookingMonitorScreen> {
  final Set<String> _flagged = {};

  @override
  Widget build(BuildContext context) {
    const statuses = [
      'Draft',
      'Sent',
      'Under Negotiation',
      'Terms Approved',
      'Contract Pending Signature',
      'Payment Pending',
      'Payment Under Verification',
      'Secured Booking',
      'In Progress',
      'Completion Review',
      'Closed',
      'Disputed',
      'Cancelled',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSurface(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: statuses
                .asMap()
                .entries
                .map(
                  (entry) => AdminStatusBadge(
                    label: '${entry.value} ${entry.key + 3}',
                    tone: entry.value == 'Disputed'
                        ? AdminDecisionTone.danger
                        : AdminDecisionTone.info,
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 18),
        AdminFilterBar(
          filters: const [
            'Category',
            'City',
            'Booking value',
            'Status',
            'Risk flagged',
            'Date range'
          ],
          selected: 'Status',
          onSelected: (_) => showCoreSnack(context, 'Filter state changed'),
        ),
        const SizedBox(height: 18),
        AdminDataTable(
          columns: const [
            'Booking ID',
            'Project',
            'Category',
            'Parties',
            'City',
            'Value',
            'Status',
            'Activity',
            'Risk',
            'Action',
          ],
          rowActions: AdminMockData.bookings
              .map<VoidCallback?>(
                  (booking) => () => _bookingDrawer(context, booking))
              .toList(),
          rows: AdminMockData.bookings.map((booking) {
            final flagged = _flagged.contains(booking.id);
            return [
              _text(context, booking.id, strong: true),
              _text(context, booking.project),
              _text(context, booking.category),
              _text(context, booking.parties),
              _text(context, booking.city),
              _text(context, booking.value),
              AdminStatusBadge(
                  label: booking.status, tone: AdminDecisionTone.warning),
              _text(context, booking.activity),
              AdminRiskBadge(
                label: flagged ? 'Flagged' : booking.risk,
                risk: flagged || booking.risk != 'No risk'
                    ? AdminRiskTone.high
                    : AdminRiskTone.low,
              ),
              _tinyAction(
                  context, 'Open', () => _bookingDrawer(context, booking)),
            ];
          }).toList(),
        ),
      ],
    );
  }

  void _bookingDrawer(BuildContext context, AdminBooking booking) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdminDetailDrawer(
        title: '${booking.id} - ${booking.project}',
        children: [
          AdminUserMiniCard(
              name: booking.parties,
              detail: booking.city,
              badge: booking.status),
          const SizedBox(height: 12),
          const AdminTimeline(
            items: [
              'Offer sent - 10:12 AM - producer',
              'Counteroffer submitted - 11:04 AM - stakeholder',
              'Terms approved - pending signature',
              'Payment proof not yet verified',
            ],
          ),
          AdminActionButton(
            icon: Icons.flag_outlined,
            label: 'Flag booking',
            secondary: true,
            onTap: () {
              setState(() => _flagged.add(booking.id));
              Navigator.pop(context);
              showCoreSnack(context, 'Booking flagged');
            },
          ),
          const SizedBox(height: 10),
          AdminActionButton(
            icon: Icons.gpp_maybe_outlined,
            label: 'Open dispute',
            onTap: () =>
                Navigator.pushNamed(context, SuperAdminRoutes.disputeCase),
          ),
          const SizedBox(height: 10),
          AdminActionButton(
            icon: Icons.payments_outlined,
            label: 'Open payment queue',
            secondary: true,
            onTap: () =>
                Navigator.pushNamed(context, SuperAdminRoutes.paymentReview),
          ),
          const SizedBox(height: 10),
          AdminActionButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'View chat evidence',
            secondary: true,
            onTap: () => Navigator.pushNamed(context, CoreRoutes.chat),
          ),
        ],
      ),
    );
  }
}

class PaymentVerificationQueueScreen extends StatefulWidget {
  const PaymentVerificationQueueScreen({super.key});

  @override
  State<PaymentVerificationQueueScreen> createState() =>
      _PaymentVerificationQueueScreenState();
}

class _PaymentVerificationQueueScreenState
    extends State<PaymentVerificationQueueScreen> {
  String _filter = 'All';
  bool _sortValue = true;

  @override
  Widget build(BuildContext context) {
    final proofs = List<AdminPaymentProof>.of(AdminMockData.paymentProofs)
      ..sort((a, b) => _sortValue
          ? b.claimedAmount.compareTo(a.claimedAmount)
          : b.age.compareTo(a.age));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResponsiveGrid(
          minTileWidth: 190,
          children: const [
            AdminMetricTile(
                label: 'Total pending value',
                value: 'PKR 4.2M',
                icon: Icons.account_balance_wallet_outlined,
                tone: AdminDecisionTone.warning),
            AdminMetricTile(
                label: 'High-value proofs',
                value: '6',
                icon: Icons.priority_high_rounded,
                tone: AdminDecisionTone.danger),
            AdminMetricTile(
                label: 'Mismatch alerts',
                value: '3',
                icon: Icons.compare_arrows_rounded,
                tone: AdminDecisionTone.danger),
            AdminMetricTile(
                label: 'Duplicate warnings',
                value: '2',
                icon: Icons.copy_all_outlined,
                tone: AdminDecisionTone.warning),
            AdminMetricTile(
                label: 'Oldest pending proof',
                value: '27h',
                icon: Icons.timer_outlined,
                tone: AdminDecisionTone.warning),
          ],
        ),
        const SizedBox(height: 18),
        AdminFilterBar(
          filters: const [
            'All',
            'High Value',
            'Amount Mismatch',
            'Duplicate Proof',
            'Bank Transfer',
            'Wallet',
            'Gateway Ref',
            '24h+'
          ],
          selected: _filter,
          onSelected: (value) => setState(() => _filter = value),
        ),
        const SizedBox(height: 12),
        AdminActionButton(
          icon: _sortValue ? Icons.sort_by_alpha_rounded : Icons.timer_outlined,
          label: _sortValue ? 'Sorting by value' : 'Sorting by age',
          secondary: true,
          onTap: () => setState(() => _sortValue = !_sortValue),
        ),
        const SizedBox(height: 18),
        AdminDataTable(
          columns: const [
            'Booking',
            'Contract',
            'Payer',
            'Payee',
            'Milestone',
            'Expected',
            'Claimed',
            'Method',
            'Risk',
            'Age',
            'Action',
          ],
          rowActions: proofs
              .map<VoidCallback?>((_) => () =>
                  Navigator.pushNamed(context, SuperAdminRoutes.paymentReview))
              .toList(),
          rows: proofs.map((proof) {
            final risk = proof.risk == 'No Risk'
                ? AdminRiskTone.low
                : proof.risk == 'Duplicate Proof'
                    ? AdminRiskTone.high
                    : AdminRiskTone.critical;
            return [
              _text(context, proof.bookingId, strong: true),
              _text(context, proof.contractId),
              _text(context, proof.payer),
              _text(context, proof.payee),
              _text(context, proof.milestone),
              _text(context, 'PKR ${proof.expectedAmount}'),
              _text(context, 'PKR ${proof.claimedAmount}'),
              _text(context, proof.method),
              AdminRiskBadge(label: proof.risk, risk: risk),
              AdminSlaBadge(age: proof.age),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _tinyAction(
                      context,
                      'Review',
                      () => Navigator.pushNamed(
                          context, SuperAdminRoutes.paymentReview)),
                  _tinyAction(context, 'Clarify',
                      () => _noteDialog(context, 'Ask clarification')),
                  _tinyAction(context, 'Reject',
                      () => _noteDialog(context, 'Quick reject reason')),
                ],
              ),
            ];
          }).toList(),
        ),
      ],
    );
  }
}

class PaymentReviewDetailScreen extends StatefulWidget {
  const PaymentReviewDetailScreen({super.key});

  @override
  State<PaymentReviewDetailScreen> createState() =>
      _PaymentReviewDetailScreenState();
}

class _PaymentReviewDetailScreenState extends State<PaymentReviewDetailScreen> {
  String _status = 'Pending Review';

  @override
  Widget build(BuildContext context) {
    return _TwoPane(
      leftFlex: 5,
      rightFlex: 4,
      left: AdminSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionHeader(title: 'Proof Viewer'),
            const SizedBox(height: 12),
            const AdminProofViewer(
              title: 'Bank transfer proof preview',
              ocrLines: [
                'Transaction ID: HBL-884120',
                'Amount: PKR 90,000',
                'Date: Jul 8, 2026',
                'Sender: Hamza Productions',
                'Receiver: Ali Khan',
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _tinyAction(context, 'Zoom',
                    () => showCoreSnack(context, 'Zoom simulated')),
                _tinyAction(context, 'Rotate',
                    () => showCoreSnack(context, 'Proof rotated')),
                _tinyAction(context, 'Download',
                    () => showCoreSnack(context, 'Proof download simulated')),
              ],
            ),
          ],
        ),
      ),
      right: AdminSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _reviewCard(context, 'Booking Summary', [
              'BK-2048',
              'TVC Shoot - Lahore',
              'Actor',
              'Payment Under Verification',
              'Hamza / Ali Khan'
            ]),
            _reviewCard(context, 'Contract Payment Schedule', [
              'Deposit',
              'Expected PKR 90,000',
              'Due Jul 8',
              'Payee Ali Khan',
              'Bank transfer allowed'
            ]),
            _reviewCard(context, 'Uploaded Claim', [
              'Claimed PKR 90,000',
              'HBL-884120',
              'Uploaded by Hamza',
              '5h ago',
              'No notes'
            ]),
            _reviewCard(context, 'Bank Details on File', [
              'Payer HBL ****4821',
              'Payee Meezan ****9921',
              'Account title match passed'
            ]),
            const SizedBox(height: 12),
            AdminStatusBadge(
                label: _status,
                tone: _status == 'Verified'
                    ? AdminDecisionTone.success
                    : AdminDecisionTone.warning),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                AdminActionButton(
                    icon: Icons.verified_outlined,
                    label: 'Verify Payment',
                    onTap: () {
                      setState(() => _status = 'Verified');
                      showCoreSuccessDialog(
                        context,
                        title: 'Payment verified',
                        message:
                            'Receipts generated for producer, payee and company.',
                        onDone: () {
                          showCoreSnack(context,
                              'Receipt, ledger and audit log written.');
                        },
                      );
                    }),
                AdminActionButton(
                    icon: Icons.cancel_outlined,
                    label: 'Reject with Reason',
                    secondary: true,
                    onTap: () =>
                        _noteDialog(context, 'Payment rejection reason')),
                AdminActionButton(
                    icon: Icons.contact_support_outlined,
                    label: 'Ask Clarification',
                    secondary: true,
                    onTap: () {
                      setState(() => _status = 'Clarification Requested');
                      _noteDialog(context, 'Clarification message');
                    }),
                AdminActionButton(
                    icon: Icons.warning_amber_rounded,
                    label: 'Mark Suspicious',
                    secondary: true,
                    onTap: () => setState(() => _status = 'Suspicious')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ContractTemplateManagerScreen extends StatefulWidget {
  const ContractTemplateManagerScreen({super.key});

  @override
  State<ContractTemplateManagerScreen> createState() =>
      _ContractTemplateManagerScreenState();
}

class _ContractTemplateManagerScreenState
    extends State<ContractTemplateManagerScreen> {
  int _selected = 0;
  bool _hasUsageRights = true;
  String _version = 'v1.0';

  final _templates = const [
    'Actor Booking Agreement',
    'Model Release / Campaign Agreement',
    'Location / Home Booking Agreement',
    'Media / Equipment Rental Agreement',
    'Production Crew Agreement',
    'Sponsorship / Brand Integration Agreement',
    'Addendum / Change Order',
    'Cancellation / Rescheduling Agreement',
    'Damage Claim / Deposit Adjustment Record',
  ];

  @override
  Widget build(BuildContext context) {
    return _ThreePane(
      left: AdminSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _templates.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CoreChip(
                label: entry.value,
                selected: entry.key == _selected,
                onTap: () => setState(() => _selected = entry.key),
              ),
            );
          }).toList(),
        ),
      ),
      center: AdminSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headline(context, _templates[_selected]),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                AdminStatusBadge(label: _version, tone: AdminDecisionTone.info),
                const AdminStatusBadge(
                    label: 'Draft', tone: AdminDecisionTone.warning),
              ],
            ),
            const SizedBox(height: 16),
            ...[
              'Parties',
              'Project',
              'Dates',
              'Fee',
              'Payment Schedule',
              'Deliverables',
              if (_hasUsageRights) 'Usage Rights',
              'Cancellation',
              'Overtime',
              'Dispute Process',
              'Special Conditions',
            ].map((clause) => _clauseEditor(context, clause)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                AdminStatusBadge(
                    label: '{{fee}}', tone: AdminDecisionTone.neutral),
                AdminStatusBadge(
                    label: '{{dates}}', tone: AdminDecisionTone.neutral),
                AdminStatusBadge(
                    label: '{{usage_rights}}', tone: AdminDecisionTone.neutral),
                AdminStatusBadge(
                    label: '{{payment_schedule}}',
                    tone: AdminDecisionTone.neutral),
                AdminStatusBadge(
                    label: '{{deliverables}}', tone: AdminDecisionTone.neutral),
              ],
            ),
          ],
        ),
      ),
      right: AdminSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionHeader(title: 'Mandatory Rules'),
            const SizedBox(height: 8),
            ...const [
              'Model contracts must include usage rights',
              'Location contracts must include damage deposit',
              'Equipment contracts must include handover/return checklist',
              'Sponsorship contracts must include brand usage and deliverables',
            ].map((rule) => _bullet(context, rule)),
            if (!_hasUsageRights) ...[
              const SizedBox(height: 12),
              const AdminStatusBadge(
                label:
                    'Generation blocked until usage rights block is included.',
                icon: Icons.block_rounded,
                tone: AdminDecisionTone.danger,
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _tinyAction(context, 'Save Draft',
                    () => showCoreSnack(context, 'Draft saved to audit log')),
                _tinyAction(context, 'Publish Version', () {
                  if (!_hasUsageRights) {
                    showCoreSnack(context,
                        'Generation blocked until usage rights block is included.');
                    return;
                  }
                  setState(() => _version = 'v1.1');
                  showCoreSnack(
                      context, 'v1.1 published and audit log written');
                }),
                _tinyAction(context, 'Preview Contract',
                    () => Navigator.pushNamed(context, CoreRoutes.contract)),
                _tinyAction(context, 'Duplicate',
                    () => showCoreSnack(context, 'Template duplicated')),
                _tinyAction(context, 'Archive',
                    () => showCoreSnack(context, 'Template archived')),
                _tinyAction(context, 'Version History',
                    () => showCoreSnack(context, 'Version history opened')),
                _tinyAction(
                    context,
                    _hasUsageRights
                        ? 'Remove Usage Rights'
                        : 'Restore Usage Rights',
                    () => setState(() => _hasUsageRights = !_hasUsageRights)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CommissionFeeScreen extends StatefulWidget {
  const CommissionFeeScreen({super.key});

  @override
  State<CommissionFeeScreen> createState() => _CommissionFeeScreenState();
}

class _CommissionFeeScreenState extends State<CommissionFeeScreen> {
  int _preview = 2800000;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _feeSection(context, 'Platform Commission by Category', const [
          ('Actor bookings', '8%', 'PKR 2,000 min'),
          ('Model campaigns', '10%', 'PKR 3,500 min'),
          ('Location bookings', '7%', 'PKR 4,000 min'),
          ('Equipment rental', '6%', 'PKR 3,000 min'),
          ('Crew services', '8%', 'PKR 2,500 min'),
          ('Brand sponsorship', '12%', 'PKR 8,000 min'),
        ]),
        const SizedBox(height: 18),
        _feeSection(context, 'Subscription Plans', const [
          ('Free', 'PKR 0', 'Basic listing'),
          ('Verified Pro', 'PKR 4,500/mo', 'Boosted profile'),
          ('Production House', 'PKR 18,000/mo', 'Team controls'),
          ('Agency Pro', 'PKR 14,000/mo', 'Roster management'),
          ('Featured Partner', 'PKR 30,000/mo', 'Premium tools'),
        ]),
        const SizedBox(height: 18),
        _feeSection(context, 'Featured Listing Pricing', const [
          ('Homepage featured', 'PKR 25,000', '7 days'),
          ('City top listing', 'PKR 12,000', '5 days'),
          ('Search boost', 'PKR 7,500', '72 hours'),
          ('Category spotlight', 'PKR 18,000', '7 days'),
        ]),
        const SizedBox(height: 18),
        AdminSurface(
          child: Row(
            children: [
              Expanded(
                  child: _headline(context, 'Revenue preview: PKR $_preview')),
              AdminActionButton(
                  icon: Icons.receipt_long_outlined,
                  label: 'Generate monthly invoice',
                  onTap: () => showCoreSnack(context, 'Invoice generated')),
              const SizedBox(width: 10),
              AdminActionButton(
                  icon: Icons.download_outlined,
                  label: 'Export CSV/PDF',
                  secondary: true,
                  onTap: () => showCoreSnack(context, 'Export placeholder')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _feeSection(
      BuildContext context, String title, List<(String, String, String)> rows) {
    return AdminSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionHeader(title: title),
          const SizedBox(height: 12),
          _ResponsiveGrid(
            minTileWidth: 250,
            children: rows.map((row) {
              return AdminSurface(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _headline(context, row.$1),
                    const SizedBox(height: 8),
                    AdminStatusBadge(
                        label: row.$2, tone: AdminDecisionTone.warning),
                    const SizedBox(height: 8),
                    _text(context, row.$3),
                    const SizedBox(height: 10),
                    _tinyAction(context, 'Edit', () {
                      setState(() => _preview += 25000);
                      _noteDialog(context, 'Edit ${row.$1}');
                    }),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class DisputeCenterScreen extends StatefulWidget {
  const DisputeCenterScreen({super.key});

  @override
  State<DisputeCenterScreen> createState() => _DisputeCenterScreenState();
}

class _DisputeCenterScreenState extends State<DisputeCenterScreen> {
  String _tab = 'All';
  final Set<String> _urgent = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ResponsiveGrid(
          minTileWidth: 190,
          children: const [
            AdminMetricTile(
                label: 'New cases',
                value: '11',
                icon: Icons.fiber_new_outlined,
                tone: AdminDecisionTone.warning),
            AdminMetricTile(
                label: 'Evidence gathering',
                value: '9',
                icon: Icons.folder_copy_outlined,
                tone: AdminDecisionTone.info),
            AdminMetricTile(
                label: 'Decision pending',
                value: '7',
                icon: Icons.gavel_outlined,
                tone: AdminDecisionTone.danger),
            AdminMetricTile(
                label: 'Resolved this month',
                value: '48',
                icon: Icons.check_circle_outline,
                tone: AdminDecisionTone.success),
            AdminMetricTile(
                label: 'Safety cases',
                value: '2',
                icon: Icons.health_and_safety_outlined,
                tone: AdminDecisionTone.danger),
          ],
        ),
        const SizedBox(height: 18),
        AdminFilterBar(
          filters: const [
            'All',
            'Payment',
            'Completion',
            'Cancellation',
            'Location Damage',
            'Equipment Damage',
            'Harassment / Safety'
          ],
          selected: _tab,
          onSelected: (value) => setState(() => _tab = value),
        ),
        const SizedBox(height: 18),
        AdminDataTable(
          columns: const [
            'Case ID',
            'Type',
            'Parties',
            'Booking',
            'Value',
            'Age',
            'Assigned',
            'Status',
            'Severity',
            'Action'
          ],
          rowActions: AdminMockData.disputes
              .map<VoidCallback?>((_) => () =>
                  Navigator.pushNamed(context, SuperAdminRoutes.disputeCase))
              .toList(),
          rows: AdminMockData.disputes.map((d) {
            final severity = _urgent.contains(d.caseId) ? 'Urgent' : d.severity;
            return [
              _text(context, d.caseId, strong: true),
              _text(context, d.type),
              _text(context, d.parties),
              _text(context, d.bookingId),
              _text(context, d.value),
              AdminSlaBadge(age: d.age),
              _text(context, d.assignedTo),
              AdminStatusBadge(
                  label: d.status, tone: AdminDecisionTone.warning),
              AdminRiskBadge(
                  label: severity,
                  risk: severity.contains('Safety') || severity == 'Urgent'
                      ? AdminRiskTone.high
                      : AdminRiskTone.medium),
              Wrap(
                spacing: 6,
                children: [
                  _tinyAction(
                      context,
                      'Open',
                      () => Navigator.pushNamed(
                          context, SuperAdminRoutes.disputeCase)),
                  _tinyAction(context, 'Assign', () => _staffSheet(context)),
                  _tinyAction(context, 'Urgent',
                      () => setState(() => _urgent.add(d.caseId))),
                ],
              ),
            ];
          }).toList(),
        ),
      ],
    );
  }
}

class DisputeCaseFileScreen extends StatefulWidget {
  const DisputeCaseFileScreen({super.key});

  @override
  State<DisputeCaseFileScreen> createState() => _DisputeCaseFileScreenState();
}

class _DisputeCaseFileScreenState extends State<DisputeCaseFileScreen> {
  String _tab = 'Contract Versions';
  bool _notify = true;
  final _ruling = TextEditingController();

  @override
  void dispose() {
    _ruling.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminSurface(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              AdminStatusBadge(label: 'DSP-441', tone: AdminDecisionTone.info),
              AdminStatusBadge(
                  label: 'Payment dispute', tone: AdminDecisionTone.warning),
              AdminStatusBadge(
                  label: 'Decision Pending', tone: AdminDecisionTone.danger),
              AdminStatusBadge(
                  label: 'PKR 350,000', tone: AdminDecisionTone.warning),
              AdminStatusBadge(
                  label: 'Assigned: Basit', tone: AdminDecisionTone.neutral),
              AdminStatusBadge(
                  label: 'SLA 9h left', tone: AdminDecisionTone.danger),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _ThreePane(
          left: const AdminSurface(
            child: AdminTimeline(
              items: [
                'Booking created - Jul 2, 10:12 - system',
                'Offer sent - producer',
                'Counteroffer submitted - model',
                'Terms approved - both parties',
                'Contract signed - OTP signature',
                'Payment proof uploaded - payer',
                'Shoot completed - stakeholder',
                'Complaint filed - payee',
                'Evidence requested - admin',
              ],
            ),
          ),
          center: AdminSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminFilterBar(
                  filters: const [
                    'Contract Versions',
                    'Negotiation Timeline',
                    'Booking Chat',
                    'Payment Proofs & Ledger',
                    'Completion Proofs',
                    'Inspection / Handover Photos',
                    'Report Forms',
                    'Prior History',
                  ],
                  selected: _tab,
                  onSelected: (value) => setState(() => _tab = value),
                ),
                const SizedBox(height: 14),
                if (_tab == 'Booking Chat')
                  const ChatBubble(
                    message: ChatMessage(
                      sender: 'Sara',
                      message:
                          'Payment was not released after approved deliverables.',
                      time: 'Jul 7',
                      mine: false,
                    ),
                  )
                else if (_tab == 'Payment Proofs & Ledger')
                  LedgerRowCard(
                    row: AdminMockDataProxy.ledgerRow,
                    onTap: () =>
                        Navigator.pushNamed(context, CoreRoutes.ledger),
                  )
                else
                  AdminEvidenceViewer(
                    title: _tab,
                    icon: Icons.folder_copy_outlined,
                    details: const [
                      'Verified source',
                      'Linked booking',
                      'Audit available'
                    ],
                  ),
                const SizedBox(height: 12),
                AdminActionButton(
                  icon: Icons.open_in_new_rounded,
                  label: 'Open linked shared screen',
                  secondary: true,
                  onTap: () => Navigator.pushNamed(
                    context,
                    _tab == 'Booking Chat'
                        ? CoreRoutes.chat
                        : _tab == 'Payment Proofs & Ledger'
                            ? CoreRoutes.ledger
                            : CoreRoutes.contract,
                  ),
                ),
              ],
            ),
          ),
          right: AdminSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AdminSectionHeader(title: 'Decision Panel'),
                const SizedBox(height: 12),
                CoreTextField(
                  controller: _ruling,
                  label: 'Admin ruling text',
                  icon: Icons.gavel_outlined,
                  maxLines: 4,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _notify,
                  onChanged: (value) => setState(() => _notify = value),
                  title: const Text('Notify both parties'),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _decisionButton(context, 'Release payment'),
                    _decisionButton(context, 'Refund payer'),
                    _decisionButton(context, 'Partial refund'),
                    _decisionButton(context, 'Penalize party'),
                    _decisionButton(context, 'Request more evidence'),
                    _decisionButton(context, 'Close as resolved'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _decisionButton(BuildContext context, String label) {
    return AdminActionButton(
      icon: Icons.gavel_outlined,
      label: label,
      secondary: label != 'Close as resolved',
      onTap: () => showCoreSuccessDialog(
        context,
        title: 'Decision confirmed',
        message:
            '$label written to audit log. Refund/release ledger updates queued. Parties notified: $_notify.',
      ),
    );
  }
}

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminSurface(
          child: CoreTextField(
            controller: TextEditingController(),
            label: 'Search by name, phone, email, CNIC, role, city...',
            icon: Icons.search_rounded,
          ),
        ),
        const SizedBox(height: 14),
        AdminFilterBar(
          filters: const [
            'Role',
            'Verification state',
            'City',
            'Trust badge',
            'Dispute count',
            'Suspended users',
            'High-value users'
          ],
          selected: 'Role',
          onSelected: (_) => showCoreSnack(context, 'Directory filter updated'),
        ),
        const SizedBox(height: 18),
        AdminDataTable(
          columns: const [
            'User',
            'Roles',
            'City',
            'Verification',
            'Trust',
            'Bookings',
            'Disputes',
            'Device Risk',
            'Status',
            'Action'
          ],
          rowActions: AdminMockData.users
              .map<VoidCallback?>((user) => () => _userDrawer(context, user))
              .toList(),
          rows: AdminMockData.users.map((user) {
            return [
              _text(context, user.name, strong: true),
              _text(context, user.roles),
              _text(context, user.city),
              AdminStatusBadge(
                  label: user.verification,
                  tone: user.verification == 'Verified'
                      ? AdminDecisionTone.success
                      : AdminDecisionTone.warning),
              _text(context, user.trust),
              _text(context, '${user.bookings}'),
              _text(context, '${user.disputes}'),
              AdminRiskBadge(
                  label: user.deviceRisk,
                  risk: user.deviceRisk == 'Clear'
                      ? AdminRiskTone.low
                      : AdminRiskTone.high),
              AdminStatusBadge(
                  label: user.status, tone: AdminDecisionTone.info),
              _tinyAction(context, 'Open', () => _userDrawer(context, user)),
            ];
          }).toList(),
        ),
      ],
    );
  }

  void _userDrawer(BuildContext context, AdminUserRecord user) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdminDetailDrawer(
        title: user.name,
        children: [
          AdminUserMiniCard(
              name: user.name,
              detail: '${user.roles} - ${user.city}',
              badge: user.status),
          const SizedBox(height: 12),
          ...[
            'Verification history: ${user.verification}',
            'Bookings: ${user.bookings}',
            'Payments: ledger linked',
            'Disputes: ${user.disputes}',
            'Device info: ${user.deviceRisk}',
            'Bank/payment account: reviewed',
          ].map((line) => _bullet(context, line)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _tinyAction(
                  context, 'Suspend', () => _confirm(context, 'Suspend user')),
              _tinyAction(context, 'Unverify',
                  () => _confirm(context, 'Unverify user')),
              _tinyAction(context, 'Force re-KYC',
                  () => Navigator.pushNamed(context, CoreRoutes.kyc)),
              _tinyAction(context, 'Merge duplicate',
                  () => _confirm(context, 'Merge duplicate')),
              _tinyAction(context, 'Reset access',
                  () => _confirm(context, 'Reset access')),
              _tinyAction(context, 'Warning',
                  () => _noteDialog(context, 'Send warning')),
              _tinyAction(context, 'Support tickets',
                  () => Navigator.pushNamed(context, SuperAdminRoutes.support)),
              _tinyAction(
                  context,
                  'Audit trail',
                  () =>
                      Navigator.pushNamed(context, SuperAdminRoutes.auditLogs)),
            ],
          ),
        ],
      ),
    );
  }
}

class AdminRolesPermissionsScreen extends StatefulWidget {
  const AdminRolesPermissionsScreen({super.key});

  @override
  State<AdminRolesPermissionsScreen> createState() =>
      _AdminRolesPermissionsScreenState();
}

class _AdminRolesPermissionsScreenState
    extends State<AdminRolesPermissionsScreen> {
  final roles = const [
    'Verification Agent',
    'Payments Officer',
    'Dispute Officer',
    'Content Moderator',
    'Support Agent',
    'Super Admin'
  ];
  final permissions = const [
    'View users',
    'Approve KYC',
    'Reject KYC',
    'Verify payments',
    'Resolve disputes',
    'Moderate content',
    'Manage templates',
    'Manage fees',
    'Broadcast',
    'Audit logs',
    'Manage admins'
  ];
  late Set<String> enabled = {
    for (final role in roles)
      for (final permission in permissions)
        if (role == 'Super Admin' || permission == 'View users')
          '$role|$permission',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ResponsiveGrid(
          minTileWidth: 180,
          children: const [
            AdminMetricTile(
                label: 'Active admins',
                value: '12',
                icon: Icons.admin_panel_settings_outlined,
                tone: AdminDecisionTone.info),
            AdminMetricTile(
                label: '2FA enabled',
                value: '10',
                icon: Icons.password_rounded,
                tone: AdminDecisionTone.success),
            AdminMetricTile(
                label: 'Suspicious sessions',
                value: '1',
                icon: Icons.warning_amber_rounded,
                tone: AdminDecisionTone.danger),
            AdminMetricTile(
                label: 'Pending invites',
                value: '3',
                icon: Icons.mail_outline_rounded,
                tone: AdminDecisionTone.warning),
          ],
        ),
        const SizedBox(height: 18),
        AdminPermissionMatrix(
          roles: roles,
          permissions: permissions,
          enabled: enabled,
          onToggle: (key) => setState(() {
            if (enabled.contains(key)) {
              enabled.remove(key);
            } else {
              enabled.add(key);
            }
          }),
        ),
        const SizedBox(height: 18),
        AdminDataTable(
          columns: const [
            'Name',
            'Email',
            'Role',
            '2FA',
            'Last Active',
            'Session',
            'Action'
          ],
          rows: const [
            [
              'Ayesha',
              'ayesha@cineconnect.pk',
              'Verification Agent',
              'Enabled',
              '8m ago',
              'Healthy'
            ],
            [
              'Raamiz',
              'raamiz@cineconnect.pk',
              'Payments Officer',
              'Enabled',
              '15m ago',
              'Healthy'
            ],
            [
              'Mahnoor',
              'mahnoor@cineconnect.pk',
              'Content Moderator',
              'Pending',
              '1h ago',
              'Review'
            ],
            [
              'Basit',
              'basit@cineconnect.pk',
              'Super Admin',
              'Enabled',
              'Now',
              'Protected'
            ],
          ]
              .map((row) => [
                    _text(context, row[0], strong: true),
                    _text(context, row[1]),
                    _text(context, row[2]),
                    AdminStatusBadge(
                        label: row[3],
                        tone: row[3] == 'Enabled'
                            ? AdminDecisionTone.success
                            : AdminDecisionTone.warning),
                    _text(context, row[4]),
                    AdminRiskBadge(
                        label: row[5],
                        risk: row[5] == 'Review'
                            ? AdminRiskTone.high
                            : AdminRiskTone.low),
                    Wrap(spacing: 6, children: [
                      _tinyAction(
                          context,
                          'Invite/Edit',
                          () => _noteDialog(
                              context, 'Invite or edit permissions')),
                      _tinyAction(context, 'Force 2FA',
                          () => showCoreSnack(context, '2FA enforced')),
                      _tinyAction(context, 'Revoke',
                          () => showCoreSnack(context, 'Session revoked')),
                    ]),
                  ])
              .toList(),
        ),
      ],
    );
  }
}

class SupportCrmScreen extends StatefulWidget {
  const SupportCrmScreen({super.key});

  @override
  State<SupportCrmScreen> createState() => _SupportCrmScreenState();
}

class _SupportCrmScreenState extends State<SupportCrmScreen> {
  String _tab = 'Inbox';
  AdminTicket _selected = AdminMockData.tickets.first;
  final List<String> _messages = [
    'Support thread opened.',
    'Admin note: verify related booking.'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminFilterBar(
          filters: const [
            'Inbox',
            'Open',
            'Waiting on User',
            'Escalated',
            'Resolved'
          ],
          selected: _tab,
          onSelected: (value) => setState(() => _tab = value),
        ),
        const SizedBox(height: 18),
        _TwoPane(
          leftFlex: 3,
          rightFlex: 4,
          left: AdminSurface(
            child: Column(
              children: AdminMockData.tickets.map((ticket) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _selected = ticket),
                    child: AdminUserMiniCard(
                      name: '${ticket.id} - ${ticket.user}',
                      detail:
                          '${ticket.category} - ${ticket.age} - ${ticket.lastMessage}',
                      badge: ticket.priority,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          right: AdminSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headline(context, _selected.id),
                const SizedBox(height: 8),
                _text(context,
                    '${_selected.source} - ${_selected.category} - Assigned ${_selected.assignedTo}'),
                const SizedBox(height: 12),
                ..._messages.map((message) => _bullet(context, message)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    AdminStatusBadge(
                        label: 'KYC resubmission required',
                        tone: AdminDecisionTone.warning),
                    AdminStatusBadge(
                        label: 'Payment clarification requested',
                        tone: AdminDecisionTone.info),
                    AdminStatusBadge(
                        label: 'Content removed warning',
                        tone: AdminDecisionTone.danger),
                    AdminStatusBadge(
                        label: 'Safety report received',
                        tone: AdminDecisionTone.danger),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _tinyAction(
                        context,
                        'Send response',
                        () => setState(
                            () => _messages.add('Dummy admin response sent.'))),
                    _tinyAction(context, 'Change status',
                        () => setState(() => _tab = 'Open')),
                    _tinyAction(
                        context, 'Assign admin', () => _staffSheet(context)),
                    _tinyAction(
                        context,
                        'Escalate',
                        () => Navigator.pushNamed(
                            context, SuperAdminRoutes.disputeCase)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BroadcastAnnouncementsScreen extends StatefulWidget {
  const BroadcastAnnouncementsScreen({super.key});

  @override
  State<BroadcastAnnouncementsScreen> createState() =>
      _BroadcastAnnouncementsScreenState();
}

class _BroadcastAnnouncementsScreenState
    extends State<BroadcastAnnouncementsScreen> {
  final _title = TextEditingController(text: 'Payment verification update');
  final _body = TextEditingController(
      text: 'Your uploaded payment proof has moved to admin review.');
  String _priority = 'Normal';
  String _segment = 'All actors in Lahore';
  String _status = 'Draft';

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _TwoPane(
      leftFlex: 5,
      rightFlex: 3,
      left: AdminSurface(
        child: Column(
          children: [
            CoreTextField(
                controller: _title,
                label: 'Announcement title',
                icon: Icons.title_rounded,
                onChanged: (_) => setState(() {})),
            const SizedBox(height: 12),
            CoreTextField(
                controller: _body,
                label: 'Message body',
                icon: Icons.notes_outlined,
                maxLines: 5,
                onChanged: (_) => setState(() {})),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _dropdown(
                    context,
                    'Priority',
                    _priority,
                    const ['Normal', 'High', 'Urgent'],
                    (v) => setState(() => _priority = v)),
                _dropdown(
                    context,
                    'Audience',
                    _segment,
                    const [
                      'All actors in Lahore',
                      'All location owners in Karachi',
                      'All pending KYC users',
                      'All producers with active negotiations',
                      'All payment-pending users'
                    ],
                    (v) => setState(() => _segment = v)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                AdminStatusBadge(label: 'In-app', tone: AdminDecisionTone.info),
                AdminStatusBadge(label: 'Push', tone: AdminDecisionTone.info),
                AdminStatusBadge(
                    label: 'Email', tone: AdminDecisionTone.neutral),
                AdminStatusBadge(label: 'SMS', tone: AdminDecisionTone.neutral),
                AdminStatusBadge(
                    label: 'WhatsApp', tone: AdminDecisionTone.warning),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _tinyAction(context, 'Save Draft',
                    () => setState(() => _status = 'Draft saved')),
                _tinyAction(context, 'Schedule',
                    () => setState(() => _status = 'Scheduled')),
                _tinyAction(
                    context,
                    'Send Now',
                    () => showCoreSuccessDialog(context,
                        title: 'Broadcast sent',
                        message: 'Static audience segment notified.')),
                _tinyAction(context, 'Test Send',
                    () => showCoreSnack(context, 'Test notification sent')),
              ],
            ),
          ],
        ),
      ),
      right: AdminSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionHeader(title: 'Notification Preview'),
            const SizedBox(height: 12),
            NotificationCardPreview(
                title: _title.text,
                body: _body.text,
                priority: _priority,
                segment: _segment,
                status: _status),
          ],
        ),
      ),
    );
  }
}

class AuditLogExplorerScreen extends StatefulWidget {
  const AuditLogExplorerScreen({super.key});

  @override
  State<AuditLogExplorerScreen> createState() => _AuditLogExplorerScreenState();
}

class _AuditLogExplorerScreenState extends State<AuditLogExplorerScreen> {
  String _filter = 'Event type';
  AdminAuditEvent _selected = AdminMockData.auditEvents.first;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminFilterBar(
          filters: const [
            'Event type',
            'Admin user',
            'Affected user',
            'Booking ID',
            'Contract ID',
            'Payment ID',
            'Date range',
            'Risk level'
          ],
          selected: _filter,
          onSelected: (value) => setState(() => _filter = value),
        ),
        const SizedBox(height: 18),
        _TwoPane(
          leftFlex: 5,
          rightFlex: 3,
          left: AdminDataTable(
            columns: const [
              'Timestamp',
              'Event Type',
              'Actor/Admin',
              'Affected User',
              'Entity',
              'IP/Device',
              'Risk',
              'Action'
            ],
            rowActions: AdminMockData.auditEvents
                .map<VoidCallback?>(
                    (event) => () => setState(() => _selected = event))
                .toList(),
            rows: AdminMockData.auditEvents
                .map((event) => [
                      _text(context, event.timestamp),
                      _text(context, event.type, strong: true),
                      _text(context, event.actor),
                      _text(context, event.affectedUser),
                      _text(context, event.entity),
                      _text(context, event.device),
                      AdminRiskBadge(
                          label: event.risk,
                          risk: event.risk == 'High'
                              ? AdminRiskTone.high
                              : AdminRiskTone.low),
                      _tinyAction(context, 'Open',
                          () => Navigator.pushNamed(context, event.route)),
                    ])
                .toList(),
          ),
          right: AdminSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headline(context, _selected.type),
                const SizedBox(height: 8),
                _text(context, _selected.description),
                const SizedBox(height: 12),
                _kv(context, 'Before/after', 'Status pending -> verified'),
                _kv(context, 'Admin note', 'Reviewed inside control room'),
                _kv(context, 'Linked entity', _selected.entity),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _tinyAction(context, 'Export CSV',
                        () => showCoreSnack(context, 'CSV exported')),
                    _tinyAction(context, 'Export PDF',
                        () => showCoreSnack(context, 'PDF export placeholder')),
                    _tinyAction(context, 'Copy Event ID',
                        () => showCoreSnack(context, 'Event ID copied')),
                    _tinyAction(context, 'Open Entity',
                        () => Navigator.pushNamed(context, _selected.route)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  String _tab = 'Marketplace Growth';
  String _range = 'This month';

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
                (v) => setState(() => _range = v)),
            AdminActionButton(
                icon: Icons.download_outlined,
                label: 'Export report',
                secondary: true,
                onTap: () => showCoreSnack(context, 'Report exported')),
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

class _ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minTileWidth;

  const _ResponsiveGrid({
    required this.children,
    this.minTileWidth = 260,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            (constraints.maxWidth / minTileWidth).floor().clamp(1, 4);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.25,
          ),
          itemBuilder: (_, index) => children[index],
        );
      },
    );
  }
}

class _TwoPane extends StatelessWidget {
  final Widget left;
  final Widget right;
  final int leftFlex;
  final int rightFlex;

  const _TwoPane({
    required this.left,
    required this.right,
    this.leftFlex = 1,
    this.rightFlex = 1,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 860) {
          return Column(
            children: [
              left,
              const SizedBox(height: 16),
              right,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: leftFlex, child: left),
            const SizedBox(width: 16),
            Expanded(flex: rightFlex, child: right),
          ],
        );
      },
    );
  }
}

class _ThreePane extends StatelessWidget {
  final Widget left;
  final Widget center;
  final Widget right;

  const _ThreePane({
    required this.left,
    required this.center,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1040) {
          return Column(
            children: [
              left,
              const SizedBox(height: 16),
              center,
              const SizedBox(height: 16),
              right,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 270, child: left),
            const SizedBox(width: 16),
            Expanded(child: center),
            const SizedBox(width: 16),
            SizedBox(width: 320, child: right),
          ],
        );
      },
    );
  }
}

Widget _text(BuildContext context, String text, {bool strong = false}) {
  final colors = context.appColors;
  return Text(
    text,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: (strong ? AppTextStyles.label : AppTextStyles.caption).copyWith(
      color: strong ? colors.textPrimary : colors.textSecondary,
      fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
      height: 1.28,
    ),
  );
}

Widget _headline(BuildContext context, String text) {
  final colors = context.appColors;
  return Text(
    text,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
    style: AppTextStyles.sectionTitle.copyWith(
      color: colors.textPrimary,
      fontSize: 20,
    ),
  );
}

Widget _tinyAction(BuildContext context, String label, VoidCallback onTap) {
  return TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: Text(label),
  );
}

Widget _kv(BuildContext context, String label, String value) {
  final colors = context.appColors;
  return Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(color: colors.textTertiary),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.caption.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _bullet(BuildContext context, String text) {
  final colors = context.appColors;
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_outline, color: colors.goldDark, size: 17),
        const SizedBox(width: 8),
        Expanded(child: _text(context, text)),
      ],
    ),
  );
}

Widget _dropdown(
  BuildContext context,
  String label,
  String value,
  List<String> values,
  ValueChanged<String> onChanged,
) {
  return SizedBox(
    width: 230,
    child: CoreDropdownField<String>(
      value: value,
      values: values,
      label: label,
      icon: Icons.filter_list_rounded,
      onChanged: (next) => onChanged(next ?? value),
    ),
  );
}

Widget _clauseEditor(BuildContext context, String clause) {
  final colors = context.appColors;
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: colors.border),
      color: colors.surface.withValues(alpha: colors.isLight ? .7 : .26),
    ),
    child: Row(
      children: [
        Expanded(child: _text(context, clause, strong: true)),
        AdminStatusBadge(label: 'Required', tone: AdminDecisionTone.info),
      ],
    ),
  );
}

Widget _reviewCard(BuildContext context, String title, List<String> rows) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    child: AdminSurface(
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headline(context, title),
          const SizedBox(height: 8),
          ...rows.map((row) => _bullet(context, row)),
        ],
      ),
    ),
  );
}

void _staffSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => AdminDetailDrawer(
      title: 'Assign Admin Staff',
      children: const [
        AdminUserMiniCard(
            name: 'Ayesha',
            detail: 'Verification Agent - 12 open',
            badge: 'KYC'),
        SizedBox(height: 10),
        AdminUserMiniCard(
            name: 'Raamiz',
            detail: 'Payments Officer - 8 open',
            badge: 'Payments'),
        SizedBox(height: 10),
        AdminUserMiniCard(
            name: 'Mahnoor',
            detail: 'Content Moderator - 6 open',
            badge: 'Content'),
      ],
    ),
  );
}

void _noteDialog(BuildContext context, String title) {
  showAdminDecisionDialog(
    context,
    title: title,
    message: 'Write a static admin note for audit and notification history.',
    action: 'Save Note',
    onConfirm: () => showCoreSnack(context, 'Admin note written to audit log.'),
  );
}

void _confirm(BuildContext context, String title) {
  showAdminDecisionDialog(
    context,
    title: title,
    message: 'This static admin action will be logged for the demo.',
    action: 'Confirm',
    onConfirm: () => showCoreSnack(context, '$title confirmed'),
  );
}

void _previewListing(BuildContext context, AdminListing listing) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: context.appColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(listing.title),
      content: Text(
          '${listing.category} - ${listing.city} - ${listing.price}\nPublic listing preview placeholder.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close')),
      ],
    ),
  );
}

class AdminMockDataProxy {
  AdminMockDataProxy._();

  static const ledgerRow = LedgerRowData(
    projectName: 'Fashion Campaign - Karachi',
    bookingId: 'BK-2052',
    milestone: 'Final Payment',
    amount: 220000,
    direction: LedgerDirection.outgoing,
    status: LedgerStatus.pendingVerification,
    date: 'Jul 8, 2026',
    receiptId: 'RCPT-DSP-441',
    transactionId: 'HBL-884120',
  );
}
