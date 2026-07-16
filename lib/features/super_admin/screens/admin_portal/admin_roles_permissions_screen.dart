part of '../super_admin_screens.dart';

class AdminRolesPermissionsScreen extends StatefulWidget {
  const AdminRolesPermissionsScreen({super.key});

  @override
  State<AdminRolesPermissionsScreen> createState() =>
      _AdminRolesPermissionsScreenState();
}

class _AdminRolesPermissionsScreenState
    extends State<AdminRolesPermissionsScreen> {
  final roles = const [
    'Verification Agent',
    'Payments Officer',
    'Dispute Officer',
    'Content Moderator',
    'Support Agent',
    'Super Admin'
  ];
  final permissions = const [
    'View users',
    'Approve KYC',
    'Reject KYC',
    'Verify payments',
    'Resolve disputes',
    'Moderate content',
    'Manage templates',
    'Manage fees',
    'Broadcast',
    'Audit logs',
    'Manage admins'
  ];
  late Set<String> enabled = {
    for (final role in roles)
      for (final permission in permissions)
        if (role == 'Super Admin' || permission == 'View users')
          '$role|$permission',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ResponsiveGrid(
          minTileWidth: 180,
          childAspectRatio: 2.6,
          children: const [
            AdminMetricTile(
                label: 'Active admins',
                value: '12',
                icon: Icons.admin_panel_settings_outlined,
                tone: AdminDecisionTone.info),
            AdminMetricTile(
                label: '2FA enabled',
                value: '10',
                icon: Icons.password_rounded,
                tone: AdminDecisionTone.success),
            AdminMetricTile(
                label: 'Suspicious sessions',
                value: '1',
                icon: Icons.warning_amber_rounded,
                tone: AdminDecisionTone.danger),
            AdminMetricTile(
                label: 'Pending invites',
                value: '3',
                icon: Icons.mail_outline_rounded,
                tone: AdminDecisionTone.warning),
          ],
        ),
        const SizedBox(height: 18),
        AdminPermissionMatrix(
          roles: roles,
          permissions: permissions,
          enabled: enabled,
          onToggle: (key) => setState(() {
            if (enabled.contains(key)) {
              enabled.remove(key);
            } else {
              enabled.add(key);
            }
          }),
        ),
        const SizedBox(height: 18),
        AdminDataTable(
          columns: const [
            'Name',
            'Email',
            'Role',
            '2FA',
            'Last Active',
            'Session',
            'Action'
          ],
          rows: const [
            [
              'Ayesha',
              'ayesha@cineconnect.pk',
              'Verification Agent',
              'Enabled',
              '8m ago',
              'Healthy'
            ],
            [
              'Raamiz',
              'raamiz@cineconnect.pk',
              'Payments Officer',
              'Enabled',
              '15m ago',
              'Healthy'
            ],
            [
              'Mahnoor',
              'mahnoor@cineconnect.pk',
              'Content Moderator',
              'Pending',
              '1h ago',
              'Review'
            ],
            [
              'Basit',
              'basit@cineconnect.pk',
              'Super Admin',
              'Enabled',
              'Now',
              'Protected'
            ],
          ]
              .map((row) => [
                    _text(context, row[0], strong: true),
                    _text(context, row[1]),
                    _text(context, row[2]),
                    AdminStatusBadge(
                        label: row[3],
                        tone: row[3] == 'Enabled'
                            ? AdminDecisionTone.success
                            : AdminDecisionTone.warning),
                    _text(context, row[4]),
                    AdminRiskBadge(
                        label: row[5],
                        risk: row[5] == 'Review'
                            ? AdminRiskTone.high
                            : AdminRiskTone.low),
                    Wrap(spacing: 6, children: [
                      _tinyAction(
                          context,
                          'Invite/Edit',
                          () => _noteDialog(
                              context, 'Invite or edit permissions')),
                      _tinyAction(context, 'Force 2FA',
                          () => showCoreSnack(context, '2FA enforced')),
                      _tinyAction(context, 'Revoke',
                          () => showCoreSnack(context, 'Session revoked')),
                    ]),
                  ])
              .toList(),
        ),
      ],
    );
  }
}
