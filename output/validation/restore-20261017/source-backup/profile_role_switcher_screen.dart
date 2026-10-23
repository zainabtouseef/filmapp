import 'package:flutter/material.dart';

import '../../../features/actor_talent/routes/actor_talent_routes.dart';
import '../../../features/director_producer/routes/director_producer_routes.dart';
import '../../../features/director_producer/widgets/dp_full_walkthrough_steps.dart';
import '../../../features/director_producer/widgets/dp_tour_steps.dart';
import '../../../shared/layout/portal_identity.dart';
import '../../auth/auth_controller.dart';
import '../../auth/auth_models.dart';
import '../../auth/role_mapper.dart';
import '../../theme/app_color_scheme.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_text_styles.dart';
import '../../tour/tour_controller.dart';
import '../../tour/tour_preferences_store.dart';
import '../core_routes.dart';
import '../widgets/core_widgets.dart';

// dpTourSteps assumes its targets are already mounted on the DP console
// (see dp_tour_steps.dart) — this screen isn't wrapped in DPShell, so route
// there first and let SpotlightOverlay pick up the targets once it mounts.
void _startDirectorProducerTour(BuildContext context) {
  Navigator.pushNamed(context, DirectorProducerRoutes.home);
  TourScope.of(context).start(
    dpTourSteps,
    tourId: dpTourId,
    onFinished: () => const TourPreferencesStore().markSeen(dpTourId),
  );
}

void _startFullWalkthrough(BuildContext context) {
  TourScope.of(context).start(
    dpFullWalkthroughSteps,
    tourId: dpFullWalkthroughTourId,
    replaceRoutes: true,
    onFinished: () {
      const TourPreferencesStore().markSeen(dpFullWalkthroughTourId);
      CoreRoutes.navigatorKey.currentState?.pushNamed(CoreRoutes.profileRoles);
    },
  );
}

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
            title: 'Your Roles & Portfolios',
            subtitle:
                'One account can show different work in several marketplace categories.',
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
    final hasDirectorProducerRole = user?.hasRole('director_producer') ?? false;

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
                    if (user != null && user.username.isNotEmpty)
                      Text(
                        '@${user.username}',
                        style: AppTextStyles.bodyMuted.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 5),
                    if (user?.primaryRole case final primaryRole?)
                      if (primaryRole.code == 'director_producer' ||
                          primaryRole.code == 'crew_service')
                        FutureBuilder<String>(
                          future:
                              PortalCategoryScope.load(auth, primaryRole.code),
                          builder: (context, snapshot) => StatusBadge(
                            label:
                                'Current: ${snapshot.data ?? RoleMapper.displayNameForCode(primaryRole.code)}',
                            icon: Icons.verified_outlined,
                            tone: CoreStatusTone.success,
                          ),
                        )
                      else
                        StatusBadge(
                          label:
                              'Current: ${RoleMapper.displayNameForCode(primaryRole.code)}',
                          icon: Icons.verified_outlined,
                          tone: CoreStatusTone.success,
                        )
                    else
                      const StatusBadge(
                        label: 'Current: No role',
                        icon: Icons.verified_outlined,
                        tone: CoreStatusTone.success,
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (hasDirectorProducerRole) ...[
            const SizedBox(height: 14),
            _DirectorProducerTutorials(
              onQuickTour: () => _startDirectorProducerTour(context),
              onFullWalkthrough: () => _startFullWalkthrough(context),
            ),
          ],
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
          if (user?.hasRole('actor_talent') ?? false) ...[
            const SizedBox(height: 16),
            CoreGlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Singer / Musician portfolio',
                      style: AppTextStyles.sectionTitle
                          .copyWith(color: colors.textPrimary)),
                  const SizedBox(height: 6),
                  Text(
                    'Add up to 3 audio performances and 1 video. Your actor headshots and showreels stay in the actor portfolio.',
                    style: AppTextStyles.bodyMuted
                        .copyWith(color: colors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        CoreRoutes.professionalProfile,
                        arguments: 'singer',
                      ),
                      icon: const Icon(Icons.library_music_outlined),
                      label: const Text('Edit music portfolio'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                          context, ActorTalentRoutes.profile),
                      icon: const Icon(Icons.storefront_outlined),
                      label: const Text('Marketplace categories'),
                    ),
                  ]),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          CorePrimaryButton(
            icon: Icons.add_circle_outline_rounded,
            label: 'Add roles & specialties',
            onTap: () => Navigator.pushNamed(context, CoreRoutes.roleSelection),
          ),
        ],
      ),
    );
  }
}

class _DirectorProducerTutorials extends StatelessWidget {
  final VoidCallback onQuickTour;
  final VoidCallback onFullWalkthrough;

  const _DirectorProducerTutorials({
    required this.onQuickTour,
    required this.onFullWalkthrough,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.softSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.borderMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: colors.goldGradient,
                  boxShadow: [
                    BoxShadow(color: colors.goldGlow, blurRadius: 14),
                  ],
                ),
                child: Icon(
                  Icons.school_outlined,
                  color: colors.onGold,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Director / Producer Tutorials',
                      style: AppTextStyles.label.copyWith(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose a quick orientation or learn the complete Director / Producer workflow.',
                      style: AppTextStyles.caption.copyWith(
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final quick = _TutorialChoice(
                icon: Icons.bolt_outlined,
                title: 'Quick Walkthrough',
                subtitle: '8 key actions · about 2 min',
                onTap: onQuickTour,
              );
              final detailed = _TutorialChoice(
                icon: Icons.menu_book_outlined,
                title: 'Full Director Walkthrough',
                subtitle: 'Create project to final report · 69 steps',
                featured: true,
                onTap: onFullWalkthrough,
              );

              if (constraints.maxWidth < 680) {
                return Column(
                  children: [
                    quick,
                    const SizedBox(height: 10),
                    detailed,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: quick),
                  const SizedBox(width: 12),
                  Expanded(child: detailed),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TutorialChoice extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool featured;
  final VoidCallback onTap;

  const _TutorialChoice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.featured = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final foreground = featured ? colors.onGold : colors.textPrimary;
    final secondary =
        featured ? colors.onGold.withValues(alpha: 0.72) : colors.textSecondary;

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: featured ? null : colors.elevatedSurface,
            gradient: featured ? colors.goldGradient : null,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: featured ? colors.goldDark : colors.border,
            ),
            boxShadow: featured
                ? [BoxShadow(color: colors.goldGlow, blurRadius: 18)]
                : null,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(icon, color: foreground, size: 23),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.label.copyWith(
                              color: foreground,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: secondary,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: foreground,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
    final roleLabel = RoleMapper.displayNameForCode(role.code);
    final route =
        RoleMapper.portalRouteForCode(role.code) ?? CoreRoutes.dashboard;
    const hireableRoles = {
      'director_producer',
      'actor_talent',
      'model',
      'location_owner',
      'equipment_provider',
      'crew_service',
      'casting_agency',
      'brand_sponsor',
      'legal_partner',
      'insurance_partner',
      'distribution_partner',
      'influencer',
    };
    final identity = Row(children: [
      Icon(RoleMapper.iconForCode(role.code), color: colors.goldDark, size: 20),
      const SizedBox(width: 12),
      Expanded(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (role.code == 'director_producer' || role.code == 'crew_service')
            PortalCategoryText(
              roleCode: role.code,
              style: AppTextStyles.label.copyWith(
                  color: colors.textPrimary, fontWeight: FontWeight.w900),
            )
          else
            Text(roleLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(
                    color: colors.textPrimary, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Row(children: [
            StatusBadge(
              label: verified ? 'Verified' : 'Pending',
              tone: verified ? CoreStatusTone.success : CoreStatusTone.warning,
            ),
            const SizedBox(width: 8),
            Expanded(
                child: Text(
              role.isPrimary ? 'Primary role' : 'Granted role',
              overflow: TextOverflow.ellipsis,
              style:
                  AppTextStyles.caption.copyWith(color: colors.textSecondary),
            )),
          ]),
        ],
      )),
    ]);
    final controls = <Widget>[
      if (hireableRoles.contains(role.code))
        Builder(builder: (context) {
          void edit() =>
              Navigator.pushNamed(context, CoreRoutes.professionalProfile,
                  arguments: role.code);
          final specialist = switch (role.code) {
            'actor_talent' => ('singer', 'Singer / Musician profile'),
            'crew_service' => ('writer', 'Writer profile'),
            _ => null,
          };
          if (specialist != null) {
            return PopupMenuButton<String>(
              tooltip: 'Choose a $roleLabel hiring profile to edit',
              onSelected: (code) => Navigator.pushNamed(
                  context, CoreRoutes.professionalProfile,
                  arguments: code),
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: role.code, child: Text('$roleLabel profile')),
                PopupMenuItem(value: specialist.$1, child: Text(specialist.$2)),
              ],
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.edit_outlined, size: 18),
                  if (MediaQuery.sizeOf(context).width >= 600) ...[
                    const SizedBox(width: 5),
                    const Text('Edit profiles'),
                  ],
                  const Icon(Icons.arrow_drop_down_rounded, size: 18),
                ]),
              ),
            );
          }
          if (MediaQuery.sizeOf(context).width < 600) {
            return IconButton(
              tooltip: 'Edit $roleLabel profile',
              onPressed: edit,
              icon: const Icon(Icons.edit_outlined),
            );
          }
          return TextButton.icon(
            onPressed: edit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit profile'),
          );
        }),
      TextButton(
        onPressed: () async {
          await AuthScope.of(context).setPrimaryRole(role.code);
          if (!context.mounted) return;
          showCoreSnack(context, 'Switched to $roleLabel');
          if (!verified) {
            Navigator.pushNamed(context, CoreRoutes.kyc, arguments: role.name);
          } else {
            Navigator.pushNamed(context, route);
          }
        },
        child: const Text('Switch'),
      ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.borderMuted))
            : null,
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < 430) {
          return Column(children: [
            identity,
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Row(mainAxisSize: MainAxisSize.min, children: controls),
            ),
          ]);
        }
        return Row(children: [Expanded(child: identity), ...controls]);
      }),
    );
  }
}
