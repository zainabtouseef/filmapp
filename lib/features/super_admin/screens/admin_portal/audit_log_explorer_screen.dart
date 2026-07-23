part of '../super_admin_screens.dart';

class AuditLogExplorerScreen extends StatefulWidget {
  const AuditLogExplorerScreen({super.key});

  @override
  State<AuditLogExplorerScreen> createState() => _AuditLogExplorerScreenState();
}

class _AuditLogExplorerScreenState extends State<AuditLogExplorerScreen> {
  Future<List<AdminAuditEventDto>>? _future;
  AdminAuditEventDto? _selected;
  String _filter = 'All';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AdminScope.of(context).auditEvents();
  }

  void _refresh() {
    setState(() => _future = AdminScope.of(context).auditEvents(force: true));
  }

  String _entityRoute(AdminAuditEventDto event) {
    return event.route.replaceFirst(':id', event.entityId);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminSurface(
          child: Column(
            children: [
              AdminFilterBar(
                filters: const [
                  'All',
                  'High risk',
                  'KYC',
                  'Bookings',
                  'Payments',
                  'Moderation',
                ],
                selected: _filter,
                onSelected: (value) => setState(() => _filter = value),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ExportActionButton(
                      exportType: 'admin_audit_events',
                      label: 'Export CSV',
                      builder: (context, onTap, label) => AdminActionButton(
                        icon: Icons.download_outlined,
                        label: label,
                        secondary: true,
                        onTap: onTap,
                      ),
                    ),
                    AdminActionButton(
                      icon: Icons.refresh_rounded,
                      label: 'Refresh',
                      secondary: true,
                      onTap: _refresh,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<AdminAuditEventDto>>(
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
                      icon: Icons.assignment_late_outlined,
                      title: 'Could not load audit events',
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
            final events = (snapshot.data ?? const []).where((event) {
              return switch (_filter) {
                'High risk' => event.risk == 'high',
                'KYC' => event.entityType == 'kyc_submission',
                'Bookings' => event.entityType == 'booking',
                'Payments' => event.entityType == 'payment_proof',
                'Moderation' => event.eventType == 'moderation_action',
                _ => true,
              };
            }).toList();
            if (events.isEmpty) {
              return const AdminEmptyState(
                icon: Icons.assignment_turned_in_outlined,
                title: 'No matching audit events',
                message: 'The selected forensic view is clear.',
              );
            }
            final selected = _selected != null &&
                    events.any((event) => event.eventId == _selected!.eventId)
                ? _selected!
                : events.first;
            return _TwoPane(
              leftFlex: 5,
              rightFlex: 3,
              left: AdminDataTable(
                columns: const [
                  'Timestamp',
                  'Event',
                  'Actor',
                  'Affected',
                  'Entity',
                  'Risk',
                  'Action',
                ],
                rowActions: events
                    .map<VoidCallback?>(
                      (event) => () => setState(() => _selected = event),
                    )
                    .toList(),
                rows: events
                    .map(
                      (event) => [
                        _text(context, _adminDateTime(event.occurredAt)),
                        _text(context, event.eventType, strong: true),
                        _text(context, event.actor),
                        _text(context, event.affectedUser),
                        _text(
                          context,
                          '${event.entityType} · ${event.entityId}',
                        ),
                        AdminRiskBadge(
                          label: event.risk,
                          risk: event.risk == 'high'
                              ? AdminRiskTone.high
                              : event.risk == 'medium'
                                  ? AdminRiskTone.medium
                                  : AdminRiskTone.low,
                        ),
                        _tinyAction(
                          context,
                          'Inspect',
                          () => setState(() => _selected = event),
                        ),
                      ],
                    )
                    .toList(),
              ),
              right: AdminSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _headline(context, selected.eventType),
                    const SizedBox(height: 7),
                    _text(context, selected.description),
                    const SizedBox(height: 12),
                    _kv(context, 'Event ID', selected.eventId),
                    _kv(context, 'Actor', selected.actor),
                    _kv(context, 'Affected', selected.affectedUser),
                    _kv(context, 'Entity', selected.entityType),
                    _kv(context, 'Entity ID', selected.entityId),
                    _kv(context, 'Risk', selected.risk),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _tinyAction(
                          context,
                          'Copy event ID',
                          () async {
                            await Clipboard.setData(
                              ClipboardData(text: selected.eventId),
                            );
                            if (context.mounted) {
                              showCoreSnack(context, 'Event ID copied.');
                            }
                          },
                        ),
                        _tinyAction(
                          context,
                          'Open entity',
                          selected.route.isEmpty
                              ? null
                              : () => Navigator.pushNamed(
                                    context,
                                    _entityRoute(selected),
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
