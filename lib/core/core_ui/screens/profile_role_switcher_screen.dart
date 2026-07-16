import 'package:flutter/material.dart';

import '../../../features/actor_talent/routes/actor_talent_routes.dart';
import '../../../features/brand_sponsors/routes/brand_sponsor_routes.dart';
import '../../../features/casting_agency/routes/casting_agency_routes.dart';
import '../../../features/crew_services/routes/crew_services_routes.dart';
import '../../../features/director_producer/routes/director_producer_routes.dart';
import '../../../features/distribution_partner/routes/distribution_partner_routes.dart';
import '../../../features/insurance_partner/routes/insurance_partner_routes.dart';
import '../../../features/legal_partner/routes/legal_partner_routes.dart';
import '../../../features/location_owner/routes/location_owner_routes.dart';
import '../../../features/media_equipment/routes/media_equipment_routes.dart';
import '../../../features/model_extension/routes/model_extension_routes.dart';
import '../../theme/app_color_scheme.dart';
import '../../theme/app_text_styles.dart';
import '../core_routes.dart';
import '../widgets/core_widgets.dart';

class ProfileRoleSwitcherScreen extends StatelessWidget {
  const ProfileRoleSwitcherScreen({super.key});

  static void showRoleSwitcherSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _RoleSwitcherSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CoreScreenScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CoreAppHeader(
            title: 'Profile / Role Switcher',
            subtitle: 'Manage active roles and move between portal shells.',
            icon: Icons.switch_account_outlined,
          ),
          const SizedBox(height: 20),
          const _RoleSwitcherContent(fullScreen: true),
        ],
      ),
    );
  }
}

class _RoleSwitcherSheet extends StatelessWidget {
  const _RoleSwitcherSheet();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // 11 roles comfortably exceed most phone viewport heights, so this
    // sheet needs its own scrollable + bounded-height wrapper — a bottom
    // sheet with isScrollControlled:true does NOT make its content
    // scroll on its own.
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
      decoration: BoxDecoration(
        gradient: colors.cardGradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: const _RoleSwitcherContent(fullScreen: false),
        ),
      ),
    );
  }
}

class _RoleSwitcherContent extends StatelessWidget {
  final bool fullScreen;

  const _RoleSwitcherContent({required this.fullScreen});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final roles = const [
      (
        'Director / Producer',
        Icons.movie_creation_outlined,
        'Verified',
        'Used today',
        DirectorProducerRoutes.home,
      ),
      (
        'Actor / Talent',
        Icons.theater_comedy_outlined,
        'Verified',
        'Last used 2d ago',
        ActorTalentRoutes.dashboard,
      ),
      (
        'Model',
        Icons.style_outlined,
        'Verified',
        'Campaign setup',
        ModelExtensionRoutes.categories,
      ),
      (
        'Location Owner',
        Icons.location_city_outlined,
        'Verified',
        'Property live',
        LocationOwnerRoutes.home,
      ),
      (
        'Media / Equipment Provider',
        Icons.videocam_outlined,
        'Verified',
        'Inventory active',
        MediaEquipmentRoutes.home,
      ),
      (
        'Crew / Services',
        Icons.groups_2_outlined,
        'Verified',
        'Available this week',
        CrewServicesRoutes.home,
      ),
      (
        'Casting Agency',
        Icons.badge_outlined,
        'Verified',
        'Roster synced',
        CastingAgencyRoutes.home,
      ),
      (
        'Brand / Sponsor',
        Icons.campaign_outlined,
        'Verified',
        'Campaign live',
        BrandSponsorRoutes.home,
      ),
      (
        'Legal Partner',
        Icons.gavel_outlined,
        'Verified',
        'Review queue',
        LegalPartnerRoutes.home,
      ),
      (
        'Insurance / Safety Partner',
        Icons.health_and_safety_outlined,
        'Verified',
        'Safety queue',
        InsurancePartnerRoutes.home,
      ),
      (
        'Distribution / Release Partner',
        Icons.public_outlined,
        'Verified',
        'Release desk',
        DistributionPartnerRoutes.home,
      ),
    ];

    return CoreGlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: fullScreen ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: colors.goldGradient,
                ),
                child: Icon(Icons.person_outline_rounded, color: colors.onGold),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sara Ahmed',
                      style: AppTextStyles.sectionTitle.copyWith(
                        color: colors.textPrimary,
                        fontSize: 21,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const StatusBadge(
                      label: 'Current: Director / Producer',
                      icon: Icons.verified_outlined,
                      tone: CoreStatusTone.success,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < roles.length; i++)
            _RoleRow(
              title: roles[i].$1,
              icon: roles[i].$2,
              badge: roles[i].$3,
              lastUsed: roles[i].$4,
              route: roles[i].$5,
              showDivider: i != roles.length - 1,
            ),
          const SizedBox(height: 12),
          CorePrimaryButton(
            icon: Icons.add_circle_outline_rounded,
            label: 'Add a New Role',
            onTap: () => Navigator.pushNamed(context, CoreRoutes.roleSelection),
          ),
        ],
      ),
    );
  }
}

class _RoleRow extends StatelessWidget {
  final String title;
  final IconData icon;
  final String badge;
  final String lastUsed;
  final String route;
  final bool showDivider;

  const _RoleRow({
    required this.title,
    required this.icon,
    required this.badge,
    required this.lastUsed,
    required this.route,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final verified = badge == 'Verified';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.borderMuted))
            : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.goldDark, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    StatusBadge(
                      label: badge,
                      tone: verified
                          ? CoreStatusTone.success
                          : CoreStatusTone.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lastUsed,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption
                            .copyWith(color: colors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              showCoreSnack(context, 'Switched to $title');
              if (!verified) {
                Navigator.pushNamed(context, CoreRoutes.kyc, arguments: title);
              } else {
                Navigator.pushNamed(context, route);
              }
            },
            child: const Text('Switch'),
          ),
        ],
      ),
    );
  }
}
