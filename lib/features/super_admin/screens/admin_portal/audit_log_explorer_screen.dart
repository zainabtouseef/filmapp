part of '../super_admin_screens.dart';

class AuditLogExplorerScreen extends StatefulWidget {
  const AuditLogExplorerScreen({super.key});

  @override
  State<AuditLogExplorerScreen> createState() => _AuditLogExplorerScreenState();
}

class _AuditLogExplorerScreenState extends State<AuditLogExplorerScreen> {
  String _filter = 'Event type';
  AdminAuditEvent _selected = AdminMockData.auditEvents.first;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminFilterBar(
          filters: const [
            'Event type',
            'Admin user',
            'Affected user',
            'Booking ID',
            'Contract ID',
            'Payment ID',
            'Date range',
            'Risk level'
          ],
          selected: _filter,
          onSelected: (value) => setState(() => _filter = value),
        ),
        const SizedBox(height: 18),
        _TwoPane(
          leftFlex: 5,
          rightFlex: 3,
          left: AdminDataTable(
            columns: const [
              'Timestamp',
              'Event Type',
              'Actor/Admin',
              'Affected User',
              'Entity',
              'IP/Device',
              'Risk',
              'Action'
            ],
            rowActions: AdminMockData.auditEvents
                .map<VoidCallback?>(
                    (event) => () => setState(() => _selected = event))
                .toList(),
            rows: AdminMockData.auditEvents
                .map((event) => [
                      _text(context, event.timestamp),
                      _text(context, event.type, strong: true),
                      _text(context, event.actor),
                      _text(context, event.affectedUser),
                      _text(context, event.entity),
                      _text(context, event.device),
                      AdminRiskBadge(
                          label: event.risk,
                          risk: event.risk == 'High'
                              ? AdminRiskTone.high
                              : AdminRiskTone.low),
                      _tinyAction(context, 'Open',
                          () => Navigator.pushNamed(context, event.route)),
                    ])
                .toList(),
          ),
          right: AdminSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headline(context, _selected.type),
                const SizedBox(height: 8),
                _text(context, _selected.description),
                const SizedBox(height: 12),
                _kv(context, 'Before/after', 'Status pending -> verified'),
                _kv(context, 'Admin note', 'Reviewed inside control room'),
                _kv(context, 'Linked entity', _selected.entity),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ExportActionButton(
                      exportType: 'admin_disputes',
                      label: 'Export CSV',
                      builder: (context, onTap, label) =>
                          _tinyAction(context, label, onTap),
                    ),
                    _tinyAction(context, 'Export PDF',
                        () => showCoreSnack(context, 'PDF export prepared')),
                    _tinyAction(context, 'Copy Event ID',
                        () => showCoreSnack(context, 'Event ID copied')),
                    _tinyAction(context, 'Open Entity',
                        () => Navigator.pushNamed(context, _selected.route)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
