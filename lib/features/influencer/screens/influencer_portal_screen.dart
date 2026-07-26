import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/payments/payment_models.dart';
import '../../../core/payments/payments_controller.dart';
import '../../../core/profile/profile_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../actor_talent/screens/at03_portfolio_showreel_screen.dart';
import '../../actor_talent/screens/at04_availability_calendar_screen.dart';
import '../../actor_talent/screens/at09_contract_signing_screen.dart';
import '../../actor_talent/screens/at10_earnings_security_screen.dart';
import '../../actor_talent/screens/at11_reputation_reviews_screen.dart';
import '../../actor_talent/screens/at12_safety_controls_screen.dart';
import '../../actor_talent/widgets/actor_talent_components.dart';
import '../../actor_talent/widgets/actor_talent_shell.dart';
import '../../../shared/widgets/bottom_nav_bar.dart';
import '../../director_producer/widgets/dp_glass_card.dart';
import '../../director_producer/widgets/dp_holographic_button.dart';
import '../../director_producer/widgets/dp_layout_helpers.dart';
import '../../director_producer/widgets/dp_metric_card.dart';
import '../../director_producer/widgets/dp_status_chip.dart';
import '../routes/influencer_routes.dart';

typedef _InfluencerBundle = ({
  UserProfile profile,
  TalentProfile talent,
  List<Booking> campaigns,
  List<Booking> bookings,
  PaymentDashboardDto? payments,
});

const _influencerBottomDestinations = [
  CineBottomNavDestination(label: 'Home', icon: Icons.home_outlined),
  CineBottomNavDestination(label: 'Media Kit', icon: Icons.badge_outlined),
  CineBottomNavDestination(label: 'Packages', icon: Icons.sell_outlined),
  CineBottomNavDestination(label: 'Campaigns', icon: Icons.campaign_outlined),
  CineBottomNavDestination(label: 'Analytics', icon: Icons.insights_outlined),
];

const _influencerMenuEntries = <ActorShellMenuEntry>[
  (
    route: InfluencerRoutes.home,
    screenId: 'IF-01',
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
  ),
  (
    route: InfluencerRoutes.mediaKit,
    screenId: 'IF-02',
    label: 'Media Kit',
    icon: Icons.badge_outlined,
  ),
  (
    route: InfluencerRoutes.packages,
    screenId: 'IF-03',
    label: 'Rate Packages',
    icon: Icons.sell_outlined,
  ),
  (
    route: InfluencerRoutes.campaigns,
    screenId: 'IF-04',
    label: 'Campaigns',
    icon: Icons.campaign_outlined,
  ),
  (
    route: InfluencerRoutes.analytics,
    screenId: 'IF-05',
    label: 'Analytics',
    icon: Icons.insights_outlined,
  ),
  (
    route: InfluencerRoutes.portfolio,
    screenId: 'IF-06',
    label: 'Portfolio',
    icon: Icons.video_library_outlined,
  ),
  (
    route: InfluencerRoutes.calendar,
    screenId: 'IF-07',
    label: 'Calendar',
    icon: Icons.calendar_month_outlined,
  ),
  (
    route: InfluencerRoutes.contracts,
    screenId: 'IF-08',
    label: 'Contracts',
    icon: Icons.draw_outlined,
  ),
  (
    route: InfluencerRoutes.earnings,
    screenId: 'IF-09',
    label: 'Earnings',
    icon: Icons.payments_outlined,
  ),
  (
    route: InfluencerRoutes.reviews,
    screenId: 'IF-10',
    label: 'Reviews',
    icon: Icons.stars_outlined,
  ),
  (
    route: InfluencerRoutes.safety,
    screenId: 'IF-11',
    label: 'Safety & Support',
    icon: Icons.health_and_safety_outlined,
  ),
];

const _influencerBottomOverrides = {
  InfluencerRoutes.portfolio: 1,
  InfluencerRoutes.calendar: 3,
  InfluencerRoutes.contracts: 3,
  InfluencerRoutes.earnings: 4,
  InfluencerRoutes.reviews: 4,
  InfluencerRoutes.safety: 4,
};

class InfluencerPortalScreen extends StatelessWidget {
  final String routeName;
  final Object? arguments;

  const InfluencerPortalScreen({
    super.key,
    required this.routeName,
    this.arguments,
  });

  @override
  Widget build(BuildContext context) {
    return ActorTalentShell(
      routeName: routeName,
      title: InfluencerRoutes.titleFor(routeName),
      screenId: InfluencerRoutes.screenIdFor(routeName),
      workspaceLayout: true,
      portalLabel: 'Influencer Portal',
      menuTitle: 'Influencer portal screens',
      navRoutes: InfluencerRoutes.primaryNav,
      navDestinations: _influencerBottomDestinations,
      menuEntries: _influencerMenuEntries,
      bottomIndexOverrides: _influencerBottomOverrides,
      workspaceTitle: 'Influencer Workspace',
      workspaceSectionLabel: 'INFLUENCER',
      workspaceBadgeLabel: 'Influencer',
      workspaceStatusSubtitle: 'Media kit, packages, campaigns and analytics',
      workspaceSearchHint: 'Search campaigns, brands, packages...',
      workspaceSearchRoute: InfluencerRoutes.campaigns,
      workspaceProfileRoute: InfluencerRoutes.mediaKit,
      workspaceIcon: Icons.campaign_outlined,
      workspaceEyebrow: (route) => switch (route) {
        InfluencerRoutes.home => 'Creator command center · live profile',
        InfluencerRoutes.mediaKit => 'Public media kit · audience identity',
        InfluencerRoutes.packages => 'Commercial packages · brand terms',
        InfluencerRoutes.campaigns => 'Campaign inbox · bookings',
        InfluencerRoutes.analytics => 'Performance view · campaign health',
        InfluencerRoutes.portfolio => 'Content library · public proof',
        InfluencerRoutes.calendar => 'Availability · campaign conflicts',
        InfluencerRoutes.contracts => 'Agreements · signatures',
        InfluencerRoutes.earnings => 'Payouts · receipts',
        InfluencerRoutes.reviews => 'Reputation · trust signals',
        InfluencerRoutes.safety => 'Boundaries · support',
        _ => 'Influencer portal',
      },
      child: _screenFor(routeName),
    );
  }

  Widget _screenFor(String route) {
    return switch (route) {
      InfluencerRoutes.home => const InfluencerDashboardScreen(),
      InfluencerRoutes.mediaKit => const InfluencerMediaKitScreen(),
      InfluencerRoutes.packages => const InfluencerPackagesScreen(),
      InfluencerRoutes.campaigns => const InfluencerCampaignsScreen(),
      InfluencerRoutes.analytics => const InfluencerAnalyticsScreen(),
      InfluencerRoutes.portfolio => const AT03PortfolioShowreelScreen(),
      InfluencerRoutes.calendar => const AT04AvailabilityCalendarScreen(),
      InfluencerRoutes.contracts => const AT09ContractSigningScreen(),
      InfluencerRoutes.earnings => const AT10EarningsSecurityScreen(),
      InfluencerRoutes.reviews => const AT11ReputationReviewsScreen(),
      InfluencerRoutes.safety => const AT12SafetyControlsScreen(),
      _ => const InfluencerDashboardScreen(),
    };
  }
}

class InfluencerDashboardScreen extends StatefulWidget {
  const InfluencerDashboardScreen({super.key});

  @override
  State<InfluencerDashboardScreen> createState() =>
      _InfluencerDashboardScreenState();
}

class _InfluencerDashboardScreenState extends State<InfluencerDashboardScreen> {
  Future<_InfluencerBundle>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AuthScope.maybeOf(context) != null) {
      _future ??= _load(context);
    }
  }

  Future<_InfluencerBundle> _load(BuildContext context) async {
    final auth = AuthScope.of(context);
    final bookings = BookingsScope.maybeOf(context);
    final payments = PaymentsScope.maybeOf(context);
    final values = await Future.wait<Object?>([
      auth.myProfile(),
      auth.talentProfile(),
      if (bookings != null)
        bookings.opportunities(force: true)
      else
        Future.value(<Booking>[]),
      if (bookings != null)
        bookings.bookings(role: 'provider', force: true)
      else
        Future.value(<Booking>[]),
      if (payments != null)
        payments.dashboard(force: true)
      else
        Future.value(null),
    ]);
    return (
      profile: values[0] as UserProfile,
      talent: values[1] as TalentProfile,
      campaigns: values[2] as List<Booking>,
      bookings: values[3] as List<Booking>,
      payments: values[4] as PaymentDashboardDto?,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (AuthScope.maybeOf(context) == null) {
      return const CoreEmptyState(
        icon: Icons.campaign_outlined,
        title: 'Sign in to load influencer workspace',
        message:
            'This portal shows live media-kit, campaign, booking and payment data from your CineConnect account.',
      );
    }
    return FutureBuilder<_InfluencerBundle>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return CoreEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Influencer workspace unavailable',
            message: _friendlyError(snapshot.error),
            actionLabel: 'Try again',
            onAction: () => setState(() => _future = _load(context)),
          );
        }
        final data = snapshot.data!;
        final activeCampaigns = data.campaigns
            .where((item) =>
                item.category == 'influencer' ||
                item.listingTitle.toLowerCase().contains('influencer'))
            .toList();
        final secured =
            data.bookings.where((item) => item.status == 'secured').length;
        final packages = influencerPackages(data.talent);
        final followers = audienceFollowers(data.talent);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DPResponsiveGrid(
              minWidth: 210,
              children: [
                DPMetricCard(
                  icon: Icons.groups_2_outlined,
                  value: followers == 0 ? 'Add' : _shortNumber(followers),
                  title: 'Audience',
                  subtitle: 'From media-kit metrics',
                  accentColor: context.appColors.goldDark,
                  onTap: () =>
                      Navigator.pushNamed(context, InfluencerRoutes.mediaKit),
                ),
                DPMetricCard(
                  icon: Icons.sell_outlined,
                  value: '${packages.length}',
                  title: 'Packages',
                  subtitle: 'Saved in live profile',
                  accentColor: context.appColors.infoBlue,
                  onTap: () =>
                      Navigator.pushNamed(context, InfluencerRoutes.packages),
                ),
                DPMetricCard(
                  icon: Icons.campaign_outlined,
                  value: '${activeCampaigns.length}',
                  title: 'Campaign offers',
                  subtitle: 'Live booking inbox',
                  accentColor: context.appColors.warning,
                  onTap: () =>
                      Navigator.pushNamed(context, InfluencerRoutes.campaigns),
                ),
                DPMetricCard(
                  icon: Icons.verified_outlined,
                  value: '$secured',
                  title: 'Secured work',
                  subtitle: _money(data.payments?.creditMinor ?? 0),
                  accentColor: context.appColors.success,
                  onTap: () =>
                      Navigator.pushNamed(context, InfluencerRoutes.analytics),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DPTwoColumn(
              left:
                  _HeroMediaKitCard(profile: data.profile, talent: data.talent),
              right: _NextBestActions(
                hasInfluencerCategory:
                    data.talent.availabilityCategories.contains('influencer'),
                hasPackages: packages.isNotEmpty,
                hasAudience: followers > 0,
              ),
            ),
            const SizedBox(height: 14),
            _CampaignPreviewCard(campaigns: activeCampaigns.take(3).toList()),
          ],
        );
      },
    );
  }
}

class InfluencerMediaKitScreen extends StatefulWidget {
  const InfluencerMediaKitScreen({super.key});

  @override
  State<InfluencerMediaKitScreen> createState() =>
      _InfluencerMediaKitScreenState();
}

class _InfluencerMediaKitScreenState extends State<InfluencerMediaKitScreen> {
  final instagram = TextEditingController();
  final tiktok = TextEditingController();
  final youtube = TextEditingController();
  final followers = TextEditingController();
  final engagement = TextEditingController();
  final niche = TextEditingController();
  final bio = TextEditingController();

  Future<(UserProfile, TalentProfile)>? _future;
  bool _saving = false;
  bool _publishing = false;
  String? _status;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AuthScope.maybeOf(context) != null) {
      _future ??= _load();
    }
  }

  @override
  void dispose() {
    instagram.dispose();
    tiktok.dispose();
    youtube.dispose();
    followers.dispose();
    engagement.dispose();
    niche.dispose();
    bio.dispose();
    super.dispose();
  }

  Future<(UserProfile, TalentProfile)> _load() async {
    final auth = AuthScope.of(context);
    final values = await Future.wait<Object?>([
      auth.myProfile(),
      auth.talentProfile(),
    ]);
    final profile = values[0] as UserProfile;
    final talent = values[1] as TalentProfile;
    final social = {...profile.socialLinks, ...talent.socialLinks};
    instagram.text = social['instagram']?.toString() ?? '';
    tiktok.text = social['tiktok']?.toString() ?? '';
    youtube.text = social['youtube']?.toString() ?? '';
    followers.text = social['followers']?.toString() ?? '';
    engagement.text = social['engagement_rate']?.toString() ?? '';
    niche.text = social['niche']?.toString() ?? '';
    bio.text = profile.bio ?? '';
    return (profile, talent);
  }

  Future<void> _save() async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null) return;
    setState(() {
      _saving = true;
      _error = null;
      _status = null;
    });
    try {
      final current = await auth.talentProfile();
      final profile = await auth.myProfile();
      final social = _socialPayload();
      final categories = {
        ...current.availabilityCategories,
        'influencer',
      }.where((item) => item.isNotEmpty).toList();
      await auth.updateMyProfile(
        bio: bio.text.trim().isEmpty
            ? 'Influencer media kit for brand campaigns.'
            : bio.text.trim(),
        cityId: profile.city?.publicId,
        visibility: 'public',
        websiteUrl: profile.websiteUrl,
        socialLinks: social,
      );
      await auth.updateTalentProfile(
        screenName: current.screenName ??
            auth.user?.displayName ??
            'CineConnect Influencer',
        socialLinks: social,
        availabilityCategories: categories,
        availabilityStatus: current.availabilityStatus,
        currency: current.currency,
        dayRateMinor: current.dayRateMinor,
        skills: current.skills,
        representation: current.representation,
      );
      setState(() {
        _status = 'Media kit saved and influencer availability enabled.';
        _future = _load();
      });
    } catch (error) {
      setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _publish() async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null) return;
    setState(() {
      _publishing = true;
      _error = null;
      _status = null;
    });
    try {
      final talent = await auth.talentProfile();
      final profile = await auth.myProfile();
      await auth.publishMarketplaceListing(
        title: talent.screenName ?? auth.user?.displayName ?? 'Influencer',
        summary: bio.text.trim().isEmpty
            ? 'Creator available for Pakistan-relevant brand campaigns.'
            : bio.text.trim(),
        listingType: 'influencer',
        cityId: profile.city?.publicId,
      );
      setState(() => _status = 'Influencer marketplace listing published.');
    } catch (error) {
      setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Map<String, dynamic> _socialPayload() {
    return {
      if (instagram.text.trim().isNotEmpty) 'instagram': instagram.text.trim(),
      if (tiktok.text.trim().isNotEmpty) 'tiktok': tiktok.text.trim(),
      if (youtube.text.trim().isNotEmpty) 'youtube': youtube.text.trim(),
      if (followers.text.trim().isNotEmpty) 'followers': followers.text.trim(),
      if (engagement.text.trim().isNotEmpty)
        'engagement_rate': engagement.text.trim(),
      if (niche.text.trim().isNotEmpty) 'niche': niche.text.trim(),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (AuthScope.maybeOf(context) == null) {
      return const CoreEmptyState(
        icon: Icons.badge_outlined,
        title: 'Sign in to edit media kit',
        message: 'Influencer media kits are saved to live profile records.',
      );
    }
    return FutureBuilder<(UserProfile, TalentProfile)>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return CoreEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load media kit',
            message: _friendlyError(snapshot.error),
            actionLabel: 'Try again',
            onAction: () => setState(() => _future = _load()),
          );
        }
        return ActorTwoColumn(
          left: Column(
            children: [
              ActorCollapsibleSection(
                title: 'Audience channels',
                subtitle: 'Social handles and reach',
                icon: Icons.public_outlined,
                initiallyExpanded: true,
                child: Column(
                  children: [
                    _field(instagram, 'Instagram handle'),
                    _field(tiktok, 'TikTok handle'),
                    _field(youtube, 'YouTube / Shorts channel'),
                    _field(followers, 'Total followers',
                        keyboardType: TextInputType.number),
                    _field(engagement, 'Engagement rate',
                        hint: 'Example: 4.8%'),
                    _field(niche, 'Niche / audience fit',
                        hint: 'Fashion, food, tech, lifestyle...'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ActorCollapsibleSection(
                title: 'Media-kit story',
                subtitle: 'Public pitch shown to brands',
                icon: Icons.article_outlined,
                initiallyExpanded: true,
                child: _field(bio, 'Brand-facing bio', maxLines: 5),
              ),
            ],
          ),
          right: DPGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Publish checklist',
                    style: AppTextStyles.cardTitle
                        .copyWith(color: context.appColors.textPrimary)),
                const SizedBox(height: 10),
                const DPStatusChip(
                    label: 'Influencer availability',
                    tone: DpTone.success,
                    icon: Icons.check_circle_outline),
                const SizedBox(height: 8),
                const DPStatusChip(
                    label: 'Public media kit',
                    tone: DpTone.info,
                    icon: Icons.badge_outlined),
                const SizedBox(height: 8),
                const DPStatusChip(
                    label: 'KYC required for paid work',
                    tone: DpTone.warning,
                    icon: Icons.verified_user_outlined),
                if (_status != null) ...[
                  const SizedBox(height: 12),
                  Text(_status!,
                      style: AppTextStyles.smallMeta
                          .copyWith(color: context.appColors.success)),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: AppTextStyles.smallMeta
                          .copyWith(color: context.appColors.danger)),
                ],
                const SizedBox(height: 14),
                DPHolographicButton(
                  label: _saving ? 'Saving...' : 'Save media kit',
                  icon: Icons.save_outlined,
                  onTap: _saving ? null : _save,
                ),
                const SizedBox(height: 10),
                DPHolographicButton(
                  label: _publishing ? 'Publishing...' : 'Publish listing',
                  icon: Icons.campaign_outlined,
                  secondary: true,
                  onTap: _publishing ? null : _publish,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class InfluencerPackagesScreen extends StatefulWidget {
  const InfluencerPackagesScreen({super.key});

  @override
  State<InfluencerPackagesScreen> createState() =>
      _InfluencerPackagesScreenState();
}

class _InfluencerPackagesScreenState extends State<InfluencerPackagesScreen> {
  final List<TextEditingController> names =
      List.generate(3, (_) => TextEditingController());
  final List<TextEditingController> deliverables =
      List.generate(3, (_) => TextEditingController());
  final List<TextEditingController> prices =
      List.generate(3, (_) => TextEditingController());
  Future<TalentProfile>? _future;
  bool _saving = false;
  String? _status;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AuthScope.maybeOf(context) != null) {
      _future ??= _load();
    }
  }

  @override
  void dispose() {
    for (final controller in [...names, ...deliverables, ...prices]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<TalentProfile> _load() async {
    final talent = await AuthScope.of(context).talentProfile();
    final packages = influencerPackages(talent);
    final defaults = [
      ('Reel Starter', '1 reel, 3 story frames, 7-day usage', '75000'),
      ('Launch Push', '2 reels, 6 story frames, BTS approval', '150000'),
      ('Brand Ambassador', 'Monthly content, exclusivity reviewed', '300000'),
    ];
    for (var i = 0; i < 3; i++) {
      final row = i < packages.length ? packages[i] : null;
      names[i].text = row?['name']?.toString() ?? defaults[i].$1;
      deliverables[i].text = row?['deliverables']?.toString() ?? defaults[i].$2;
      prices[i].text = row?['price']?.toString() ?? defaults[i].$3;
    }
    return talent;
  }

  Future<void> _save() async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null) return;
    setState(() {
      _saving = true;
      _error = null;
      _status = null;
    });
    try {
      final current = await auth.talentProfile();
      final representation = Map<String, dynamic>.from(current.representation);
      representation['influencer_packages'] = [
        for (var i = 0; i < 3; i++)
          if (names[i].text.trim().isNotEmpty)
            {
              'name': names[i].text.trim(),
              'deliverables': deliverables[i].text.trim(),
              'price': prices[i].text.trim(),
              'currency': current.currency,
            },
      ];
      await auth.updateTalentProfile(
        screenName:
            current.screenName ?? auth.user?.displayName ?? 'Influencer',
        representation: representation,
        availabilityCategories: {
          ...current.availabilityCategories,
          'influencer',
        }.toList(),
        socialLinks: current.socialLinks,
        availabilityStatus: current.availabilityStatus,
        currency: current.currency,
        dayRateMinor: current.dayRateMinor,
        skills: current.skills,
      );
      setState(() {
        _status = 'Rate packages saved to your live influencer profile.';
        _future = _load();
      });
    } catch (error) {
      setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (AuthScope.maybeOf(context) == null) {
      return const CoreEmptyState(
        icon: Icons.sell_outlined,
        title: 'Sign in to edit packages',
        message: 'Packages are stored in your live talent profile settings.',
      );
    }
    return FutureBuilder<TalentProfile>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return CoreEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load packages',
            message: _friendlyError(snapshot.error),
            actionLabel: 'Try again',
            onAction: () => setState(() => _future = _load()),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DPResponsiveGrid(
              minWidth: 260,
              children: [
                for (var i = 0; i < 3; i++)
                  DPGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Package ${i + 1}',
                            style: AppTextStyles.cardTitle.copyWith(
                                color: context.appColors.textPrimary)),
                        const SizedBox(height: 10),
                        _field(names[i], 'Package name'),
                        _field(deliverables[i], 'Deliverables', maxLines: 3),
                        _field(prices[i], 'Price PKR',
                            keyboardType: TextInputType.number),
                      ],
                    ),
                  ),
              ],
            ),
            if (_status != null) ...[
              const SizedBox(height: 12),
              Text(_status!,
                  style: AppTextStyles.smallMeta
                      .copyWith(color: context.appColors.success)),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: AppTextStyles.smallMeta
                      .copyWith(color: context.appColors.danger)),
            ],
            const SizedBox(height: 14),
            DPHolographicButton(
              label: _saving ? 'Saving packages...' : 'Save packages',
              icon: Icons.save_outlined,
              onTap: _saving ? null : _save,
            ),
          ],
        );
      },
    );
  }
}

class InfluencerCampaignsScreen extends StatefulWidget {
  const InfluencerCampaignsScreen({super.key});

  @override
  State<InfluencerCampaignsScreen> createState() =>
      _InfluencerCampaignsScreenState();
}

class _InfluencerCampaignsScreenState extends State<InfluencerCampaignsScreen> {
  Future<List<Booking>>? _future;
  String? _actionStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (BookingsScope.maybeOf(context) != null) {
      _future ??= _load();
    }
  }

  Future<List<Booking>> _load() async {
    final bookings = BookingsScope.of(context);
    final rows = await bookings.opportunities(force: true);
    return rows
        .where((item) =>
            item.category == 'influencer' ||
            item.listingTitle.toLowerCase().contains('influencer'))
        .toList();
  }

  Future<void> _accept(Booking booking) async {
    final offer = booking.activeOffer;
    if (offer == null) return;
    try {
      await BookingsScope.of(context).acceptOffer(offer.publicId);
      setState(() {
        _actionStatus =
            'Campaign accepted. Calendar lock/payment steps will update from backend.';
        _future = _load();
      });
    } catch (error) {
      setState(() => _actionStatus = _friendlyError(error));
    }
  }

  Future<void> _reject(Booking booking) async {
    try {
      await BookingsScope.of(context).rejectBooking(
        booking.publicId,
        reason: 'Influencer declined from campaign portal.',
      );
      setState(() {
        _actionStatus = 'Campaign declined.';
        _future = _load();
      });
    } catch (error) {
      setState(() => _actionStatus = _friendlyError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (BookingsScope.maybeOf(context) == null) {
      return const CoreEmptyState(
        icon: Icons.campaign_outlined,
        title: 'Sign in to load campaigns',
        message: 'Campaign requests appear here from the live booking API.',
      );
    }
    return FutureBuilder<List<Booking>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return CoreEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load campaigns',
            message: _friendlyError(snapshot.error),
            actionLabel: 'Try again',
            onAction: () => setState(() => _future = _load()),
          );
        }
        final rows = snapshot.data ?? const [];
        if (rows.isEmpty) {
          return CoreEmptyState(
            icon: Icons.campaign_outlined,
            title: 'No influencer campaign requests yet',
            message:
                'Publish your influencer listing and packages. Brand and public booking requests will appear here from the backend.',
            actionLabel: 'Edit media kit',
            onAction: () =>
                Navigator.pushNamed(context, InfluencerRoutes.mediaKit),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_actionStatus != null) ...[
              DPGlassCard(
                  child: Text(_actionStatus!,
                      style: AppTextStyles.smallMeta
                          .copyWith(color: context.appColors.textPrimary))),
              const SizedBox(height: 12),
            ],
            DPResponsiveGrid(
              minWidth: 320,
              children: [
                for (final booking in rows)
                  DPGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: Text(booking.projectTitle,
                                    style: AppTextStyles.cardTitle.copyWith(
                                        color: context.appColors.textPrimary))),
                            DPStatusChip(
                                label: booking.status, tone: DpTone.info),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ActorInfoRow(
                            icon: Icons.business_center_outlined,
                            label: 'Brand / buyer',
                            value: booking.requester.displayName),
                        ActorInfoRow(
                            icon: Icons.calendar_month_outlined,
                            label: 'Dates',
                            value:
                                '${_shortDate(booking.startAt)} - ${_shortDate(booking.endAt)}'),
                        ActorInfoRow(
                            icon: Icons.payments_outlined,
                            label: 'Offer',
                            value: booking.activeOffer?.feeLabel ?? 'Rate TBD'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: DPHolographicButton(
                                label: 'Accept',
                                icon: Icons.check_rounded,
                                onTap: () => _accept(booking),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DPHolographicButton(
                                label: 'Decline',
                                icon: Icons.close_rounded,
                                secondary: true,
                                onTap: () => _reject(booking),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class InfluencerAnalyticsScreen extends StatelessWidget {
  const InfluencerAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.maybeOf(context);
    final bookings = BookingsScope.maybeOf(context);
    final payments = PaymentsScope.maybeOf(context);
    if (auth == null) {
      return const CoreEmptyState(
        icon: Icons.insights_outlined,
        title: 'Sign in to load analytics',
        message:
            'Campaign analytics are calculated from your live profile, booking and payment records.',
      );
    }
    return FutureBuilder<List<Object?>>(
      future: Future.wait<Object?>([
        auth.talentProfile(),
        if (bookings != null)
          bookings.bookings(role: 'provider', force: true)
        else
          Future.value(<Booking>[]),
        if (payments != null)
          payments.dashboard(force: true)
        else
          Future.value(null),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return CoreEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load analytics',
            message: _friendlyError(snapshot.error),
          );
        }
        final talent = snapshot.data![0] as TalentProfile;
        final rows = snapshot.data![1] as List<Booking>;
        final payment = snapshot.data![2] as PaymentDashboardDto?;
        final campaigns =
            rows.where((item) => item.category == 'influencer').toList();
        final secured =
            campaigns.where((item) => item.status == 'secured').length;
        final followers = audienceFollowers(talent);
        final engagement =
            talent.socialLinks['engagement_rate']?.toString() ?? 'Not set';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DPResponsiveGrid(
              minWidth: 220,
              children: [
                DPMetricCard(
                    icon: Icons.groups_outlined,
                    value: _shortNumber(followers),
                    title: 'Audience',
                    subtitle: 'Saved reach',
                    accentColor: context.appColors.goldDark),
                DPMetricCard(
                    icon: Icons.touch_app_outlined,
                    value: engagement,
                    title: 'Engagement',
                    subtitle: 'Media-kit rate',
                    accentColor: context.appColors.infoBlue),
                DPMetricCard(
                    icon: Icons.verified_outlined,
                    value: '$secured',
                    title: 'Secured campaigns',
                    subtitle: '${campaigns.length} total',
                    accentColor: context.appColors.success),
                DPMetricCard(
                    icon: Icons.payments_outlined,
                    value: _money(payment?.creditMinor ?? 0),
                    title: 'Credits',
                    subtitle: 'Payment dashboard',
                    accentColor: context.appColors.warning),
              ],
            ),
            const SizedBox(height: 14),
            DPGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Campaign health',
                      style: AppTextStyles.cardTitle
                          .copyWith(color: context.appColors.textPrimary)),
                  const SizedBox(height: 12),
                  _bar(context, 'Profile completeness',
                      _profileCompleteness(talent)),
                  _bar(context, 'Package readiness',
                      influencerPackages(talent).isEmpty ? .25 : 1),
                  _bar(context, 'Campaign conversion',
                      campaigns.isEmpty ? 0 : secured / campaigns.length),
                  const SizedBox(height: 10),
                  Text(
                    'Analytics use live profile, package and booking data. Connect social platform APIs later for automatic impressions/reach sync.',
                    style: AppTextStyles.smallMeta
                        .copyWith(color: context.appColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeroMediaKitCard extends StatelessWidget {
  final UserProfile profile;
  final TalentProfile talent;

  const _HeroMediaKitCard({required this.profile, required this.talent});

  @override
  Widget build(BuildContext context) {
    return DPGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            talent.screenName ?? 'Influencer media kit',
            style: AppTextStyles.heroSerifHeadline
                .copyWith(color: context.appColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            profile.bio ??
                'Create a short brand-facing pitch so public buyers and brands understand your creator niche.',
            style: AppTextStyles.body
                .copyWith(color: context.appColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DPStatusChip(
                  label: profile.city?.name ?? 'Pakistan',
                  tone: DpTone.neutral,
                  icon: Icons.location_on_outlined),
              DPStatusChip(
                  label: talent.availabilityStatus,
                  tone: DpTone.success,
                  icon: Icons.event_available_outlined),
              DPStatusChip(
                  label: '${audienceFollowers(talent)} followers',
                  tone: DpTone.info,
                  icon: Icons.groups_outlined),
            ],
          ),
          const SizedBox(height: 14),
          DPHolographicButton(
            label: 'Improve media kit',
            icon: Icons.edit_outlined,
            onTap: () =>
                Navigator.pushNamed(context, InfluencerRoutes.mediaKit),
          ),
        ],
      ),
    );
  }
}

class _NextBestActions extends StatelessWidget {
  final bool hasInfluencerCategory;
  final bool hasPackages;
  final bool hasAudience;

  const _NextBestActions({
    required this.hasInfluencerCategory,
    required this.hasPackages,
    required this.hasAudience,
  });

  @override
  Widget build(BuildContext context) {
    return DPGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Next best actions',
              style: AppTextStyles.cardTitle
                  .copyWith(color: context.appColors.textPrimary)),
          const SizedBox(height: 10),
          _check(
              context, hasInfluencerCategory, 'Enable influencer availability'),
          _check(context, hasAudience, 'Add audience metrics'),
          _check(context, hasPackages, 'Save at least one rate package'),
          const SizedBox(height: 14),
          DPHolographicButton(
            label: hasPackages && hasAudience
                ? 'View campaigns'
                : 'Complete setup',
            icon: hasPackages && hasAudience
                ? Icons.campaign_outlined
                : Icons.tune_outlined,
            secondary: hasPackages && hasAudience,
            onTap: () => Navigator.pushNamed(
              context,
              hasPackages && hasAudience
                  ? InfluencerRoutes.campaigns
                  : InfluencerRoutes.mediaKit,
            ),
          ),
        ],
      ),
    );
  }
}

class _CampaignPreviewCard extends StatelessWidget {
  final List<Booking> campaigns;

  const _CampaignPreviewCard({required this.campaigns});

  @override
  Widget build(BuildContext context) {
    return DPGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text('Latest campaign requests',
                      style: AppTextStyles.cardTitle
                          .copyWith(color: context.appColors.textPrimary))),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, InfluencerRoutes.campaigns),
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (campaigns.isEmpty)
            Text(
                'No live influencer campaigns yet. Publish your media kit and packages to start receiving requests.',
                style: AppTextStyles.smallMeta
                    .copyWith(color: context.appColors.textSecondary))
          else
            for (final campaign in campaigns)
              ActorInfoRow(
                icon: Icons.campaign_outlined,
                label: campaign.projectTitle,
                value: campaign.activeOffer?.feeLabel ?? campaign.status,
              ),
        ],
      ),
    );
  }
}

Widget _field(
  TextEditingController controller,
  String label, {
  String? hint,
  int maxLines = 1,
  TextInputType? keyboardType,
}) {
  return Builder(
    builder: (context) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: context.appColors.surface.withValues(alpha: 0.62),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    ),
  );
}

Widget _check(BuildContext context, bool done, String label) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(
          done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          color: done ? context.appColors.success : context.appColors.iconMuted,
          size: 19,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.smallMeta.copyWith(
              color: context.appColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _bar(BuildContext context, String label, double value) {
  final clamped = value.clamp(0, 1).toDouble();
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: Text(label,
                    style: AppTextStyles.smallMeta
                        .copyWith(color: context.appColors.textPrimary))),
            Text('${(clamped * 100).round()}%',
                style: AppTextStyles.cardLabel
                    .copyWith(color: context.appColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: clamped,
            backgroundColor: context.appColors.border,
            color: context.appColors.goldDark,
          ),
        ),
      ],
    ),
  );
}

List<Map<String, dynamic>> influencerPackages(TalentProfile talent) {
  final raw = talent.representation['influencer_packages'];
  if (raw is List) {
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
  return const [];
}

int audienceFollowers(TalentProfile talent) {
  final raw = talent.socialLinks['followers'] ??
      talent.socialLinks['total_followers'] ??
      talent.socialLinks['audience'];
  if (raw is num) return raw.toInt();
  return int.tryParse(
          raw?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '') ??
      0;
}

double _profileCompleteness(TalentProfile talent) {
  var score = 0;
  if ((talent.screenName ?? '').isNotEmpty) score++;
  if (talent.socialLinks.isNotEmpty) score++;
  if (audienceFollowers(talent) > 0) score++;
  if (influencerPackages(talent).isNotEmpty) score++;
  if (talent.availabilityCategories.contains('influencer')) score++;
  return score / 5;
}

String _money(int minor) {
  final whole = minor ~/ 100;
  if (whole >= 1000000) return 'PKR ${(whole / 1000000).toStringAsFixed(1)}M';
  if (whole >= 1000) return 'PKR ${(whole / 1000).round()}k';
  return 'PKR $whole';
}

String _shortNumber(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).round()}k';
  return '$value';
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
  return '${months[date.month - 1]} ${date.day}';
}

String _friendlyError(Object? error) {
  final text = error?.toString() ?? 'Unknown error';
  return text
      .replaceFirst('ApiException: ', '')
      .replaceFirst('Exception: ', '');
}
