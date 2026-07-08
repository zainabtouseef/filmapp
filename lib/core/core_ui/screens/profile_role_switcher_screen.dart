import 'package:flutter/material.dart';

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
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
      decoration: BoxDecoration(
        gradient: colors.cardGradient,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: const SafeArea(
        top: false,
        child: _RoleSwitcherContent(fullScreen: false),
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
        'Used today'
      ),
      (
        'Actor / Talent',
        Icons.theater_comedy_outlined,
        'Verified',
        'Last used 2d ago'
      ),
      (
        'Location Owner',
        Icons.location_city_outlined,
        'KYC required',
        'New role'
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
          const SizedBox(height: 20),
          ...roles.map(
            (role) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RoleRow(
                title: role.$1,
                icon: role.$2,
                badge: role.$3,
                lastUsed: role.$4,
              ),
            ),
          ),
          const SizedBox(height: 8),
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

  const _RoleRow({
    required this.title,
    required this.icon,
    required this.badge,
    required this.lastUsed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final verified = badge == 'Verified';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: colors.inactiveChipGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.goldDark),
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
              }
            },
            child: const Text('Switch'),
          ),
        ],
      ),
    );
  }
}
