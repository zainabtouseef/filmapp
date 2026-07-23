part of '../super_admin_screens.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  Future<List<AdminUserRecordDto>>? _future;
  final _search = TextEditingController();
  String _filter = 'All';
  String? _busyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AdminScope.of(context).users();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() => _future = AdminScope.of(context).users(force: true));
  }

  List<AdminUserRecordDto> _visible(List<AdminUserRecordDto> users) {
    final query = _search.text.trim().toLowerCase();
    return users.where((user) {
      final haystack = [
        user.publicId,
        user.displayName,
        user.email,
        ...user.roles.expand((role) => [role.code, role.name]),
      ].join(' ').toLowerCase();
      if (query.isNotEmpty && !haystack.contains(query)) return false;
      return switch (_filter) {
        'Suspended' => user.status == 'suspended',
        'Locked' => user.status == 'locked',
        'KYC pending' => !{'approved', 'verified'}.contains(user.kycStatus),
        'High risk' => user.kycRiskLevel == 'high',
        'Disputes' => user.disputesCount > 0,
        'Admins' => user.roles.any(
            (role) => const {
              'reviewer',
              'finance_admin',
              'support_agent',
              'super_admin',
            }.contains(role.code),
          ),
        _ => true,
      };
    }).toList();
  }

  Future<void> _setStatus(AdminUserRecordDto user, String status) async {
    if (_busyId != null) return;
    setState(() => _busyId = user.publicId);
    try {
      await AdminScope.of(context).updateUser(
        user.publicId,
        status: status,
      );
      if (!mounted) return;
      Navigator.maybePop(context);
      showCoreSnack(
        context,
        status == 'active'
            ? 'User access restored.'
            : 'User access changed to $status and sessions revoked.',
      );
      _refresh();
    } on ApiException catch (error) {
      if (mounted) showCoreSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _assignRole(AdminUserRecordDto user) async {
    final role = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Assign platform role'),
        children: [
          for (final item in const [
            ('reviewer', 'Reviewer'),
            ('finance_admin', 'Finance Admin'),
            ('support_agent', 'Support Agent'),
            ('super_admin', 'Super Admin'),
          ])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, item.$1),
              child: Text(item.$2),
            ),
        ],
      ),
    );
    if (!mounted || role == null) return;
    setState(() => _busyId = user.publicId);
    try {
      await AdminScope.of(context).updateUser(
        user.publicId,
        roleCode: role,
        roleStatus: 'active',
      );
      if (!mounted) return;
      Navigator.maybePop(context);
      showCoreSnack(context, 'Role assigned and activated.');
      _refresh();
    } on ApiException catch (error) {
      if (mounted) showCoreSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminSurface(
          child: Column(
            children: [
              CoreTextField(
                controller: _search,
                label: 'Search name, email, ID or role',
                icon: Icons.search_rounded,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              AdminFilterBar(
                filters: const [
                  'All',
                  'Suspended',
                  'Locked',
                  'KYC pending',
                  'High risk',
                  'Disputes',
                  'Admins',
                ],
                selected: _filter,
                onSelected: (value) => setState(() => _filter = value),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: AdminActionButton(
                  icon: Icons.refresh_rounded,
                  label: 'Refresh',
                  secondary: true,
                  onTap: _refresh,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<AdminUserRecordDto>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const AdminSurface(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              final error = snapshot.error;
              return AdminSurface(
                child: Column(
                  children: [
                    AdminEmptyState(
                      icon: Icons.manage_accounts_outlined,
                      title: 'Could not load user access',
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
            final users = _visible(snapshot.data ?? const []);
            if (users.isEmpty) {
              return const AdminEmptyState(
                icon: Icons.search_off_rounded,
                title: 'No matching users',
                message: 'Change the search or access filter.',
              );
            }
            return AdminDataTable(
              columns: const [
                'User',
                'Roles',
                'KYC',
                'Risk',
                'Bookings',
                'Disputes',
                'Sessions',
                'Status',
                'Action',
              ],
              rowActions: users
                  .map<VoidCallback?>(
                    (user) => () => _userDrawer(context, user),
                  )
                  .toList(),
              rows: users.map((user) {
                final roleNames = user.roles.isEmpty
                    ? 'No active role'
                    : user.roles.map((item) => item.name).join(', ');
                return [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _text(context, user.displayName, strong: true),
                      _text(context, user.email),
                    ],
                  ),
                  _text(context, roleNames),
                  AdminStatusBadge(
                    label: user.kycStatus,
                    tone: {'approved', 'verified'}.contains(user.kycStatus)
                        ? AdminDecisionTone.success
                        : AdminDecisionTone.warning,
                  ),
                  AdminRiskBadge(
                    label: user.kycRiskLevel,
                    risk: user.kycRiskLevel == 'high'
                        ? AdminRiskTone.high
                        : AdminRiskTone.low,
                  ),
                  _text(context, '${user.bookingsCount}'),
                  _text(context, '${user.disputesCount}'),
                  _text(context, '${user.activeSessions}'),
                  AdminStatusBadge(
                    label: user.status,
                    tone: user.status == 'active'
                        ? AdminDecisionTone.success
                        : AdminDecisionTone.danger,
                  ),
                  _tinyAction(
                    context,
                    'Open',
                    _busyId == user.publicId
                        ? null
                        : () => _userDrawer(context, user),
                  ),
                ];
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _userDrawer(BuildContext context, AdminUserRecordDto user) {
    final roleNames = user.roles.isEmpty
        ? 'No role assigned'
        : user.roles.map((item) => item.name).join(', ');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => AdminDetailDrawer(
        title: user.displayName,
        children: [
          AdminUserMiniCard(
            name: user.displayName,
            detail: user.email,
            badge: user.status,
          ),
          const SizedBox(height: 12),
          _kv(sheetContext, 'User ID', user.publicId),
          _kv(sheetContext, 'Roles', roleNames),
          _kv(sheetContext, 'KYC', user.kycStatus),
          _kv(sheetContext, 'KYC risk', user.kycRiskLevel),
          _kv(sheetContext, 'Bookings', '${user.bookingsCount}'),
          _kv(sheetContext, 'Disputes', '${user.disputesCount}'),
          _kv(sheetContext, 'Active sessions', '${user.activeSessions}'),
          _kv(
            sheetContext,
            'Last login',
            _adminDateTime(user.lastLoginAt),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (user.status == 'active')
                _tinyAction(
                  sheetContext,
                  'Suspend access',
                  () => _setStatus(user, 'suspended'),
                )
              else
                _tinyAction(
                  sheetContext,
                  'Restore access',
                  () => _setStatus(user, 'active'),
                ),
              _tinyAction(
                sheetContext,
                'Lock account',
                user.status == 'locked'
                    ? null
                    : () => _setStatus(user, 'locked'),
              ),
              _tinyAction(
                sheetContext,
                'Assign role',
                () => _assignRole(user),
              ),
              _tinyAction(
                sheetContext,
                'KYC queue',
                () => Navigator.pushNamed(
                  context,
                  SuperAdminRoutes.verifications,
                ),
              ),
              _tinyAction(
                sheetContext,
                'Support tickets',
                () => Navigator.pushNamed(
                  context,
                  SuperAdminRoutes.support,
                ),
              ),
              _tinyAction(
                sheetContext,
                'Audit trail',
                () => Navigator.pushNamed(
                  context,
                  SuperAdminRoutes.auditLogs,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
