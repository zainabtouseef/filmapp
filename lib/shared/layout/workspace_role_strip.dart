import 'package:flutter/material.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/auth_models.dart';
import '../../core/auth/role_mapper.dart';
import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';

/// Keeps every granted workspace within reach when one person works in more
/// than one part of a production. The backend still authorizes each portal.
class WorkspaceRoleStrip extends StatefulWidget {
  const WorkspaceRoleStrip({super.key});

  @override
  State<WorkspaceRoleStrip> createState() => _WorkspaceRoleStripState();
}

class _WorkspaceRoleStripState extends State<WorkspaceRoleStrip> {
  String? _switchingTo;

  Future<void> _openWorkspace(AuthRole role) async {
    final auth = AuthScope.of(context);
    final route = RoleMapper.portalRouteForCode(role.code);
    if (route == null || _switchingTo != null) return;
    if (auth.user?.primaryRole?.code == role.code) return;

    setState(() => _switchingTo = role.code);
    try {
      await auth.setPrimaryRole(role.code);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not switch workspaces. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _switchingTo = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.maybeOf(context)?.user;
    final roles = (user?.roles ?? const <AuthRole>[])
        .where((role) =>
            role.status == 'active' &&
            RoleMapper.portalRouteForCode(role.code) != null)
        .toList();
    if (roles.length < 2) return const SizedBox.shrink();

    final colors = context.appColors;
    final current = user?.primaryRole?.code;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: colors.elevatedSurface,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.switch_account_outlined,
                size: 20, color: colors.goldDark),
            const SizedBox(width: 9),
            Text(
              'Workspaces',
              style: AppTextStyles.cardLabel.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: roles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final role = roles[index];
                  final selected = role.code == current;
                  final switching = role.code == _switchingTo;
                  final label = _workspaceLabel(role);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Tooltip(
                      message: selected
                          ? '$label workspace is open'
                          : 'Open $label workspace',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(13),
                          onTap: selected || _switchingTo != null
                              ? null
                              : () => _openWorkspace(role),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(horizontal: 11),
                            decoration: BoxDecoration(
                              color: selected
                                  ? colors.softSurface
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                color:
                                    selected ? colors.goldMid : colors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                switching
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: colors.goldDark,
                                        ),
                                      )
                                    : Icon(
                                        RoleMapper.iconForCode(role.code),
                                        size: 17,
                                        color: colors.goldDark,
                                      ),
                                const SizedBox(width: 7),
                                Text(
                                  label,
                                  style: AppTextStyles.smallMeta.copyWith(
                                    color: selected
                                        ? colors.textPrimary
                                        : colors.textSecondary,
                                    fontWeight: selected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                                ),
                                if (selected) ...[
                                  const SizedBox(width: 6),
                                  Icon(Icons.check_rounded,
                                      size: 15, color: colors.goldDark),
                                ],
                              ],
                            ),
                          ),
                        ),
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

String _workspaceLabel(AuthRole role) => switch (role.code) {
      'director_producer' => 'Production tools',
      'actor_talent' => 'Actor tools',
      'crew_service' => 'Production service tools',
      'general_public' => 'Customer tools',
      _ => RoleMapper.displayLabelForName(role.name),
    };
