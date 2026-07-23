part of '../super_admin_screens.dart';

class AdminRolesPermissionsScreen extends StatefulWidget {
  const AdminRolesPermissionsScreen({super.key});

  @override
  State<AdminRolesPermissionsScreen> createState() =>
      _AdminRolesPermissionsScreenState();
}

class _AdminRolesPermissionsScreenState
    extends State<AdminRolesPermissionsScreen> {
  Future<AdminRolesBundleDto>? _future;
  String? _selectedCode;
  Set<String> _draftPermissions = {};
  bool _saving = false;

  static const _adminCodes = {
    'reviewer',
    'finance_admin',
    'support_agent',
    'super_admin',
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AdminScope.of(context).roles();
  }

  void _refresh() {
    setState(() {
      _future = AdminScope.of(context).roles(force: true);
      _selectedCode = null;
      _draftPermissions = {};
    });
  }

  void _select(AdminRoleRecordDto role) {
    setState(() {
      _selectedCode = role.code;
      _draftPermissions = {...role.permissions};
    });
  }

  Future<void> _save(AdminRoleRecordDto role) async {
    if (_saving || role.code == 'super_admin') return;
    setState(() => _saving = true);
    try {
      await AdminScope.of(context).updateRolePermissions(
        role.code,
        _draftPermissions,
      );
      if (!mounted) return;
      showCoreSnack(context, 'Permissions saved for ${role.name}.');
      _refresh();
    } on ApiException catch (error) {
      if (mounted) showCoreSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminRolesBundleDto>(
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
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Could not load admin permissions',
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
        final roles = data.roles
            .where((role) => _adminCodes.contains(role.code))
            .toList();
        if (roles.isEmpty) {
          return const AdminEmptyState(
            icon: Icons.admin_panel_settings_outlined,
            title: 'No admin roles configured',
            message: 'Seed admin roles before assigning staff access.',
          );
        }
        final selected = roles.firstWhere(
          (role) => role.code == _selectedCode,
          orElse: () => roles.first,
        );
        if (_selectedCode == null) {
          _selectedCode = selected.code;
          _draftPermissions = {...selected.permissions};
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ResponsiveGrid(
              minTileWidth: 180,
              childAspectRatio: 2.7,
              children: [
                AdminMetricTile(
                  label: 'Admin roles',
                  value: '${roles.length}',
                  icon: Icons.admin_panel_settings_outlined,
                  tone: AdminDecisionTone.info,
                ),
                AdminMetricTile(
                  label: 'Assigned admins',
                  value: '${roles.fold<int>(
                    0,
                    (sum, role) => sum + role.adminUsers,
                  )}',
                  icon: Icons.groups_2_outlined,
                  tone: AdminDecisionTone.success,
                ),
                AdminMetricTile(
                  label: 'Permissions',
                  value: '${data.permissions.length}',
                  icon: Icons.key_outlined,
                  tone: AdminDecisionTone.warning,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _TwoPane(
              leftFlex: 2,
              rightFlex: 5,
              left: AdminSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminSectionHeader(
                      title: 'Admin roles',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 10),
                    for (final role in roles)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: _AdminRoleCard(
                          role: role,
                          selected: role.code == selected.code,
                          onTap: () => _select(role),
                        ),
                      ),
                    const SizedBox(height: 8),
                    AdminActionButton(
                      icon: Icons.person_add_alt_1_outlined,
                      label: 'Assign staff roles',
                      secondary: true,
                      onTap: () => Navigator.pushNamed(
                        context,
                        SuperAdminRoutes.users,
                      ),
                    ),
                  ],
                ),
              ),
              right: AdminSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _headline(context, selected.name),
                              const SizedBox(height: 3),
                              _text(
                                context,
                                '${selected.adminUsers} active admin(s) · '
                                '${selected.code}',
                              ),
                            ],
                          ),
                        ),
                        if (selected.code == 'super_admin')
                          const AdminStatusBadge(
                            label: 'Protected',
                            icon: Icons.lock_outline_rounded,
                            tone: AdminDecisionTone.warning,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final permission in data.permissions)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        value: _draftPermissions.contains(permission.code),
                        onChanged: selected.code == 'super_admin'
                            ? null
                            : (value) {
                                setState(() {
                                  if (value ?? false) {
                                    _draftPermissions.add(permission.code);
                                  } else {
                                    _draftPermissions.remove(permission.code);
                                  }
                                });
                              },
                        title: Text(
                          permission.code,
                          style: AppTextStyles.label.copyWith(
                            color: context.appColors.textPrimary,
                          ),
                        ),
                        subtitle: permission.description.isEmpty
                            ? null
                            : Text(permission.description),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    const SizedBox(height: 12),
                    AdminActionButton(
                      icon: Icons.save_outlined,
                      label: selected.code == 'super_admin'
                          ? 'Protected role'
                          : 'Save permissions',
                      onTap: _saving || selected.code == 'super_admin'
                          ? null
                          : () => _save(selected),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AdminRoleCard extends StatelessWidget {
  final AdminRoleRecordDto role;
  final bool selected;
  final VoidCallback onTap;

  const _AdminRoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 9, 10, 9),
        decoration: BoxDecoration(
          color: selected
              ? colors.goldGlow.withValues(alpha: 0.12)
              : colors.softSurface.withValues(alpha: 0.44),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? colors.goldMid : colors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 30,
              color: selected ? colors.goldMid : Colors.transparent,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _text(context, role.name, strong: true),
                  _text(
                    context,
                    '${role.permissions.length} permissions · '
                    '${role.adminUsers} staff',
                  ),
                ],
              ),
            ),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: role.isActive ? colors.success : colors.iconMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
