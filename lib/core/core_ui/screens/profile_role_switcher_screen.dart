import 'package:flutter/material.dart';

import '../../auth/auth_controller.dart';
import '../../auth/auth_models.dart';
import '../../auth/role_mapper.dart';
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
    final auth = AuthScope.of(context);
    final user = auth.user;
    final roles = user?.roles ?? const <AuthRole>[];

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
                      user?.displayName ?? 'CineConnect User',
                      style: AppTextStyles.sectionTitle.copyWith(
                        color: colors.textPrimary,
                        fontSize: 21,
                      ),
                    ),
                    const SizedBox(height: 5),
                    StatusBadge(
                      label: 'Current: ${user?.primaryRole?.name ?? 'No role'}',
                      icon: Icons.verified_outlined,
                      tone: CoreStatusTone.success,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (roles.isEmpty)
            const CoreEmptyState(
              icon: Icons.switch_account_outlined,
              title: 'No active roles yet',
              message: 'Add a role to start building your CineConnect profile.',
            )
          else
            for (var i = 0; i < roles.length; i++)
              _RoleRow(role: roles[i], showDivider: i != roles.length - 1),
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
  final AuthRole role;
  final bool showDivider;

  const _RoleRow({required this.role, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final verified = role.status == 'active';
    final route =
        RoleMapper.portalRouteForCode(role.code) ?? CoreRoutes.dashboard;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.borderMuted))
            : null,
      ),
      child: Row(
        children: [
          Icon(
            RoleMapper.iconForCode(role.code),
            color: colors.goldDark,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role.name,
                  style: AppTextStyles.label.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    StatusBadge(
                      label: verified ? 'Verified' : 'Pending',
                      tone: verified
                          ? CoreStatusTone.success
                          : CoreStatusTone.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        role.isPrimary ? 'Primary role' : 'Granted role',
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
          TextButton(
            onPressed: () async {
              await AuthScope.of(context).setPrimaryRole(role.code);
              if (!context.mounted) return;
              showCoreSnack(context, 'Switched to ${role.name}');
              if (!verified) {
                Navigator.pushNamed(
                  context,
                  CoreRoutes.kyc,
                  arguments: role.name,
                );
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
