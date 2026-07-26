import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_contract/screens/contract_viewer_screen.dart';
import '../../../core/core_payment/screens/receipts_ledger_screen.dart';
import '../../../core/core_ui/core_back_navigation.dart';
import '../../../core/core_ui/core_logout.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/layout/admin_bottom_nav.dart';
import '../../../shared/layout/admin_screen_scaffold.dart';
import '../../../shared/layout/admin_top_bar.dart';
import '../../../shared/layout/floating_portal_menu.dart';
import '../../../shared/widgets/app_header.dart' show ThemeToggleButton;
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../director_producer/screens/dp_booking_request_form_screen.dart';
import '../../director_producer/screens/dp_marketplace_discovery_screen.dart';
import '../../director_producer/screens/dp_stakeholder_profile_screen.dart';
import '../../director_producer/widgets/dp_glass_card.dart';
import '../../director_producer/widgets/dp_holographic_button.dart';
import '../../director_producer/widgets/dp_layout_helpers.dart';
import '../../director_producer/widgets/dp_status_chip.dart';
import '../routes/general_public_routes.dart';

class GeneralPublicPortalScreen extends StatelessWidget {
  final String routeName;
  final Object? arguments;

  const GeneralPublicPortalScreen({
    super.key,
    required this.routeName,
    this.arguments,
  });

  static const _ownHeaderRoutes = {
    GeneralPublicRoutes.home,
    GeneralPublicRoutes.browse,
    GeneralPublicRoutes.actors,
    GeneralPublicRoutes.models,
    GeneralPublicRoutes.influencers,
  };

  @override
  Widget build(BuildContext context) {
    return GeneralPublicShell(
      title: GeneralPublicRoutes.titleFor(routeName),
      currentRoute: routeName,
      showHeading: !_ownHeaderRoutes.contains(routeName),
      child: _content(routeName),
    );
  }

  Widget _content(String route) {
    final id = _stringArg('id') ??
        _stringArg('candidateId') ??
        (arguments is String ? arguments as String : null);
    final category = _stringArg('category') ?? _stringArg('type');
    return switch (route) {
      GeneralPublicRoutes.home => const GeneralPublicHomeScreen(),
      GeneralPublicRoutes.actors => const DPMarketplaceDiscoveryScreen(
          publicBuyerMode: true,
          initialCategory: 'Actors',
        ),
      GeneralPublicRoutes.models => const DPMarketplaceDiscoveryScreen(
          publicBuyerMode: true,
          initialCategory: 'Models',
        ),
      GeneralPublicRoutes.influencers => const DPMarketplaceDiscoveryScreen(
          publicBuyerMode: true,
          initialCategory: 'Influencers',
        ),
      GeneralPublicRoutes.browse => DPMarketplaceDiscoveryScreen(
          publicBuyerMode: true,
          initialCategory: category,
        ),
      GeneralPublicRoutes.profile => DPStakeholderProfileScreen(
          candidateId: id,
          profileType: category,
        ),
      GeneralPublicRoutes.bookingRequest => DPBookingRequestFormScreen(
          candidateId: id,
          category: category,
        ),
      GeneralPublicRoutes.requests => const GeneralPublicRequestsScreen(),
      GeneralPublicRoutes.contracts => const ContractViewerScreen(),
      GeneralPublicRoutes.payments => const ReceiptsLedgerScreen(),
      GeneralPublicRoutes.account => const GeneralPublicAccountScreen(),
      _ => const GeneralPublicHomeScreen(),
    };
  }

  String? _stringArg(String key) {
    final args = arguments;
    if (args is Map && args[key] is String) return args[key] as String;
    return null;
  }
}

class GeneralPublicShell extends StatelessWidget {
  final String title;
  final String currentRoute;
  final Widget child;
  final bool showHeading;

  const GeneralPublicShell({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.child,
    this.showHeading = true,
  });

  static const navItems = [
    GeneralPublicNavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      route: GeneralPublicRoutes.home,
    ),
    GeneralPublicNavItem(
      label: 'Browse',
      icon: Icons.manage_search_rounded,
      route: GeneralPublicRoutes.browse,
    ),
    GeneralPublicNavItem(
      label: 'Actors',
      icon: Icons.theater_comedy_outlined,
      route: GeneralPublicRoutes.actors,
    ),
    GeneralPublicNavItem(
      label: 'Influencers',
      icon: Icons.campaign_outlined,
      route: GeneralPublicRoutes.influencers,
    ),
    GeneralPublicNavItem(
      label: 'Requests',
      icon: Icons.handshake_outlined,
      route: GeneralPublicRoutes.requests,
    ),
    GeneralPublicNavItem(
      label: 'Payments',
      icon: Icons.payments_outlined,
      route: GeneralPublicRoutes.payments,
    ),
    GeneralPublicNavItem(
      label: 'Account',
      icon: Icons.person_outline_rounded,
      route: GeneralPublicRoutes.account,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final routedChild = showHeading
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DPPageHeader(
                eyebrow: 'Customer portal · live database',
                title: title,
              ),
              const SizedBox(height: 14),
              child,
            ],
          )
        : child;
    return AdminScreenScaffold(
      title: title,
      currentRoute: currentRoute,
      showHeading: false,
      showKycStatusBanner: false,
      topBarBuilder: (context, wide, onMenuTap) => _PublicTopBar(
        wide: wide,
        onMenuTap: onMenuTap,
      ),
      sideNavBuilder: (context, currentRoute, onRouteTap) => _PublicSidebar(
        currentRoute: currentRoute,
        onRouteTap: onRouteTap,
      ),
      bottomNavBuilder:
          (context, currentRoute, menuOpen, onRouteTap, onMoreTap) =>
              AdminBottomNavSlot(
        child: _PublicBottomNav(
          currentRoute: currentRoute,
          menuOpen: menuOpen,
          onRouteTap: onRouteTap,
          onMoreTap: onMoreTap,
        ),
      ),
      floatingMenuBuilder: (context, open, currentRoute, onClose, onRouteTap) =>
          _PublicMenuOverlay(
        open: open,
        currentRoute: currentRoute,
        onClose: onClose,
        onRouteTap: onRouteTap,
      ),
      onRouteSelected: (context, route) => Navigator.pushNamed(context, route),
      child: routedChild,
    );
  }
}

class GeneralPublicHomeScreen extends StatelessWidget {
  const GeneralPublicHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.maybeOf(context)?.user;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DPPageHeader(
          eyebrow: 'Marketing campaigns · verified talent',
          title: 'Book talent for your brand',
          trailing: DPHolographicButton(
            label: 'Browse talent',
            icon: Icons.search_rounded,
            onTap: () =>
                Navigator.pushNamed(context, GeneralPublicRoutes.browse),
          ),
        ),
        const SizedBox(height: 14),
        DPGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome${user?.displayName == null ? '' : ', ${user!.displayName}'}',
                style: AppTextStyles.cardTitle.copyWith(
                  color: context.appColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              dpText(
                context,
                'Create direct booking requests for actors, models and influencers. Track offers, messages and campaign terms from your customer workspace.',
                strong: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        DPResponsiveGrid(
          minWidth: 240,
          children: [
            _PublicActionCard(
              icon: Icons.campaign_outlined,
              title: 'Influencer campaigns',
              body:
                  'Find creators for reels, product launches and brand shoots.',
              route: GeneralPublicRoutes.influencers,
            ),
            _PublicActionCard(
              icon: Icons.theater_comedy_outlined,
              title: 'Actors for ads',
              body:
                  'Book screen-ready actors for commercials and social videos.',
              route: GeneralPublicRoutes.actors,
            ),
            _PublicActionCard(
              icon: Icons.style_outlined,
              title: 'Models',
              body: 'Find models for fashion, ecommerce and product visuals.',
              route: GeneralPublicRoutes.models,
            ),
            _PublicActionCard(
              icon: Icons.receipt_long_outlined,
              title: 'My requests',
              body:
                  'Track offers, status and next steps after you send a booking.',
              route: GeneralPublicRoutes.requests,
            ),
          ],
        ),
      ],
    );
  }
}

class GeneralPublicRequestsScreen extends StatefulWidget {
  const GeneralPublicRequestsScreen({super.key});

  @override
  State<GeneralPublicRequestsScreen> createState() =>
      _GeneralPublicRequestsScreenState();
}

class _GeneralPublicRequestsScreenState
    extends State<GeneralPublicRequestsScreen> {
  Future<List<Booking>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<List<Booking>> _load() async {
    final bookings = BookingsScope.maybeOf(context);
    if (bookings == null) {
      throw const ApiException(
        code: 'booking.scope_missing',
        message: 'Booking service is not available in this session.',
      );
    }
    return bookings.bookings(role: 'requester', force: true);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Booking>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const DPGlassCard(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return DPGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _friendlyError(snapshot.error),
                  style: AppTextStyles.cardTitle.copyWith(
                    color: context.appColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                DPHolographicButton(
                  label: 'Retry',
                  icon: Icons.refresh_rounded,
                  onTap: () => setState(() => _future = _load()),
                ),
              ],
            ),
          );
        }
        final rows = snapshot.data ?? const <Booking>[];
        if (rows.isEmpty) {
          return DPGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No booking requests yet',
                  style: AppTextStyles.cardTitle.copyWith(
                    color: context.appColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                dpText(
                  context,
                  'Browse actors, models or influencers and send a campaign request. New requests will appear here from the live database.',
                ),
                const SizedBox(height: 14),
                DPHolographicButton(
                  label: 'Browse talent',
                  icon: Icons.search_rounded,
                  onTap: () =>
                      Navigator.pushNamed(context, GeneralPublicRoutes.browse),
                ),
              ],
            ),
          );
        }
        return Column(
          children: [
            for (final booking in rows) ...[
              _PublicBookingCard(booking: booking),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }

  String _friendlyError(Object? error) {
    if (error is ApiException) return error.message;
    return 'Could not load your live booking requests.';
  }
}

class GeneralPublicAccountScreen extends StatelessWidget {
  const GeneralPublicAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.maybeOf(context)?.user;
    return Column(
      children: [
        DPGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.displayName ?? 'General Public customer',
                style: AppTextStyles.cardTitle.copyWith(
                  color: context.appColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              dpText(
                context,
                user?.email ?? 'Signed in customer account',
                strong: true,
              ),
              const SizedBox(height: 12),
              const DPStatusChip(
                label: 'Customer account',
                tone: DpTone.info,
                icon: Icons.shopping_bag_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DPResponsiveGrid(
          minWidth: 260,
          children: [
            _PublicActionCard(
              icon: Icons.swap_horiz_rounded,
              title: 'Manage roles',
              body:
                  'Add actor, model or influencer provider roles if you also want to be booked.',
              route: CoreRoutes.profileRoles,
            ),
            _PublicActionCard(
              icon: Icons.settings_outlined,
              title: 'Settings',
              body: 'Update account, security and notification preferences.',
              route: CoreRoutes.settings,
            ),
            _PublicActionCard(
              icon: Icons.logout_rounded,
              title: 'Logout',
              body: 'Leave this browser session safely.',
              onTap: () => logoutToLogin(context),
            ),
          ],
        ),
      ],
    );
  }
}

class _PublicTopBar extends StatelessWidget {
  final bool wide;
  final VoidCallback onMenuTap;

  const _PublicTopBar({
    required this.wide,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final compact = !wide;
    final canGoBack = wide || Navigator.canPop(context);
    return AdminTopBarFrame(
      compact: compact,
      child: Row(
        children: [
          _PublicIconButton(
            icon: canGoBack ? Icons.arrow_back_rounded : Icons.menu_rounded,
            tooltip: canGoBack ? 'Back' : 'Menu',
            onTap: canGoBack ? () => navigateCoreBack(context) : onMenuTap,
          ),
          const SizedBox(width: 10),
          _PublicBrandLockup(compact: compact),
          SizedBox(width: compact ? 8 : 16),
          Expanded(child: _PublicSearchPill(compact: compact)),
          const SizedBox(width: 10),
          if (wide) ...[
            _PublicIconButton(
              icon: Icons.notifications_none_rounded,
              tooltip: 'Notifications',
              onTap: () =>
                  Navigator.pushNamed(context, CoreRoutes.notifications),
            ),
            const SizedBox(width: 10),
          ],
          ThemeToggleButton(size: compact ? 34 : 38),
          if (wide) ...[
            const SizedBox(width: 10),
            _PublicIconButton(
              icon: Icons.person_outline_rounded,
              tooltip: 'Account',
              onTap: () => Navigator.pushNamed(
                context,
                GeneralPublicRoutes.account,
              ),
            ),
            const SizedBox(width: 10),
            const DPStatusChip(
              label: 'Customer',
              tone: DpTone.warning,
              icon: Icons.shopping_bag_outlined,
            ),
          ],
        ],
      ),
    );
  }
}

class _PublicBrandLockup extends StatelessWidget {
  final bool compact;

  const _PublicBrandLockup({required this.compact});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: compact ? 98 : 166,
        maxWidth: compact ? 120 : 210,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: AppTextStyles.sectionHeaderStyle.copyWith(
                color: colors.textPrimary,
                fontSize: compact ? 17 : 22,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
              children: [
                const TextSpan(text: 'Cine'),
                TextSpan(
                  text: 'Connect',
                  style: TextStyle(color: colors.goldDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Public Booking',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: colors.textSecondary,
              fontSize: compact ? 10.5 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicSearchPill extends StatelessWidget {
  final bool compact;

  const _PublicSearchPill({required this.compact});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, GeneralPublicRoutes.browse),
      child: Container(
        height: compact ? 38 : 44,
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 13),
        decoration: BoxDecoration(
          gradient: colors.searchGradient,
          borderRadius: BorderRadius.circular(compact ? 15 : 18),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded,
                color: colors.icon, size: compact ? 18 : 21),
            SizedBox(width: compact ? 7 : 9),
            Expanded(
              child: Text(
                compact ? 'Search...' : 'Search actors, models, influencers...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.smallMeta.copyWith(
                  color: colors.textSecondary,
                  fontSize: compact ? 12 : 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _PublicIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: GlassContainer(
          width: 38,
          height: 38,
          radius: 19,
          child: Icon(icon, color: colors.icon, size: 20),
        ),
      ),
    );
  }
}

class _PublicSidebar extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String> onRouteTap;

  const _PublicSidebar({
    required this.currentRoute,
    required this.onRouteTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 276,
      margin: const EdgeInsets.fromLTRB(14, 14, 0, 14),
      child: GlassContainer(
        radius: 24,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CUSTOMER',
              style: AppTextStyles.sectionHeaderStyle.copyWith(
                color: colors.textPrimary,
                fontSize: 18,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Campaign booking portal',
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: GeneralPublicShell.navItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = GeneralPublicShell.navItems[index];
                  final active = _publicActive(currentRoute, item.route);
                  return GestureDetector(
                    onTap: () => onRouteTap(item.route),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        gradient: active
                            ? colors.activeChipGradient
                            : colors.inactiveChipGradient,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: active ? colors.goldMid : colors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            color: active ? colors.goldDark : colors.iconMuted,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.cardLabel.copyWith(
                                color: active
                                    ? colors.textPrimary
                                    : colors.textSecondary,
                                fontWeight:
                                    active ? FontWeight.w800 : FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublicBottomNav extends StatelessWidget {
  final String currentRoute;
  final bool menuOpen;
  final ValueChanged<String> onRouteTap;
  final VoidCallback onMoreTap;

  const _PublicBottomNav({
    required this.currentRoute,
    required this.menuOpen,
    required this.onRouteTap,
    required this.onMoreTap,
  });

  static const _destinations = [
    CineBottomNavDestination(label: 'Home', icon: Icons.home_outlined),
    CineBottomNavDestination(label: 'Browse', icon: Icons.search_rounded),
    CineBottomNavDestination(label: 'Book', icon: Icons.campaign_outlined),
    CineBottomNavDestination(label: 'Requests', icon: Icons.handshake_outlined),
    CineBottomNavDestination(label: 'More', icon: Icons.menu_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return CineBottomNav(
      currentIndex: _currentIndex,
      destinations: _destinations,
      compactCenter: true,
      onTap: (index) {
        switch (index) {
          case 0:
            onRouteTap(GeneralPublicRoutes.home);
            return;
          case 1:
            onRouteTap(GeneralPublicRoutes.browse);
            return;
          case 2:
            onRouteTap(GeneralPublicRoutes.influencers);
            return;
          case 3:
            onRouteTap(GeneralPublicRoutes.requests);
            return;
          default:
            onMoreTap();
        }
      },
    );
  }

  int get _currentIndex {
    if (menuOpen) return 4;
    if (_publicActive(currentRoute, GeneralPublicRoutes.home)) return 0;
    if (_publicActive(currentRoute, GeneralPublicRoutes.browse) ||
        _publicActive(currentRoute, GeneralPublicRoutes.actors) ||
        _publicActive(currentRoute, GeneralPublicRoutes.models)) {
      return 1;
    }
    if (_publicActive(currentRoute, GeneralPublicRoutes.influencers)) return 2;
    if (_publicActive(currentRoute, GeneralPublicRoutes.requests)) return 3;
    return 4;
  }
}

class _PublicMenuOverlay extends StatelessWidget {
  final bool open;
  final String currentRoute;
  final VoidCallback onClose;
  final ValueChanged<String> onRouteTap;

  const _PublicMenuOverlay({
    required this.open,
    required this.currentRoute,
    required this.onClose,
    required this.onRouteTap,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingPortalMenuOverlay(
      open: open,
      currentRoute: currentRoute,
      items: [
        for (final item in GeneralPublicShell.navItems)
          FloatingPortalMenuItem(
            route: item.route,
            label: item.label,
            icon: item.icon,
          ),
      ],
      statusTitle: 'Public Booking Portal',
      statusSubtitle: 'Customer campaign bookings',
      statusIcon: Icons.shopping_bag_outlined,
      onClose: onClose,
      onRouteTap: onRouteTap,
      isRouteActive: _publicActive,
    );
  }
}

class _PublicActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? route;
  final VoidCallback? onTap;

  const _PublicActionCard({
    required this.icon,
    required this.title,
    required this.body,
    this.route,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap ??
          (route == null ? null : () => Navigator.pushNamed(context, route!)),
      child: DPGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: colors.goldGradient,
              ),
              child: Icon(icon, color: colors.onGold, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.cardTitle.copyWith(
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            dpText(context, body),
          ],
        ),
      ),
    );
  }
}

class _PublicBookingCard extends StatelessWidget {
  final Booking booking;

  const _PublicBookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DPGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.listingTitle,
                  style: AppTextStyles.cardTitle.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              DPStatusChip(
                label: _titleCase(booking.status),
                tone: _toneForStatus(booking.status),
              ),
            ],
          ),
          const SizedBox(height: 6),
          dpText(
            context,
            '${booking.projectTitle} · ${_shortDate(booking.startAt)} → ${_shortDate(booking.endAt)}',
            strong: true,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DPStatusChip(
                label: booking.activeOffer?.feeLabel ??
                    (booking.agreedAmountMinor == null
                        ? 'Fee pending'
                        : '${booking.currency} ${booking.agreedAmountMinor! ~/ 100}'),
                tone: DpTone.info,
                icon: Icons.payments_outlined,
              ),
              DPStatusChip(
                label: booking.provider.displayName,
                tone: DpTone.neutral,
                icon: Icons.person_outline_rounded,
              ),
              if (booking.conversationId != null)
                DPStatusChip(
                  label: 'Chat ready',
                  tone: DpTone.success,
                  icon: Icons.chat_bubble_outline_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }

  DpTone _toneForStatus(String status) {
    return switch (status) {
      'accepted' || 'secured' => DpTone.success,
      'under_negotiation' || 'sent' => DpTone.warning,
      'rejected' || 'cancelled' => DpTone.danger,
      _ => DpTone.neutral,
    };
  }
}

bool _publicActive(String currentRoute, String route) {
  if (route == GeneralPublicRoutes.home) return currentRoute == route;
  return currentRoute == route || currentRoute.startsWith(route);
}

String _shortDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _titleCase(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.trim().isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
