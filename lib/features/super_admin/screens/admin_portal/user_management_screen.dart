part of '../super_admin_screens.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _filter = 'Role';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(AdminUserRecord user) {
    final query = _search.text.toLowerCase();
    final queryMatch = query.isEmpty ||
        user.name.toLowerCase().contains(query) ||
        user.city.toLowerCase().contains(query) ||
        user.roles.toLowerCase().contains(query);
    if (!queryMatch) return false;
    return switch (_filter) {
      'Suspended users' => user.status == 'Suspended',
      'High-value users' => user.bookings >= 15,
      'Dispute count' => user.disputes > 0,
      _ => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final users = AdminMockData.users.where(_matches).toList();
    return Column(
      children: [
        AdminSurface(
          child: CoreTextField(
            controller: _search,
            label: 'Search by name, role or city',
            icon: Icons.search_rounded,
            onChanged: (_) => setState(() {}),
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
          selected: _filter,
          onSelected: (value) => setState(() => _filter = value),
        ),
        const SizedBox(height: 18),
        if (users.isEmpty)
          const AdminEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No matching users',
            message: 'Try a different search term or filter.',
          )
        else
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
            rowActions: users
                .map<VoidCallback?>((user) => () => _userDrawer(context, user))
                .toList(),
            rows: users.map((user) {
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
