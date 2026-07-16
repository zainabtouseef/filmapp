part of '../super_admin_screens.dart';

class SupportCrmScreen extends StatefulWidget {
  const SupportCrmScreen({super.key});

  @override
  State<SupportCrmScreen> createState() => _SupportCrmScreenState();
}

class _SupportCrmScreenState extends State<SupportCrmScreen> {
  String _tab = 'Inbox';
  AdminTicket _selected = AdminMockData.tickets.first;
  final _reply = TextEditingController();
  final Map<String, List<String>> _threads = {
    for (final ticket in AdminMockData.tickets)
      ticket.id: [
        'Support thread opened.',
        'Admin note: verify related booking.',
      ],
  };

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  bool _matches(AdminTicket ticket) {
    if (_tab == 'Inbox') return true;
    return ticket.status == _tab;
  }

  @override
  Widget build(BuildContext context) {
    final tickets = AdminMockData.tickets.where(_matches).toList();
    final messages = _threads[_selected.id]!;
    return Column(
      children: [
        AdminFilterBar(
          filters: const [
            'Inbox',
            'Open',
            'Waiting on User',
            'Escalated',
            'Resolved'
          ],
          selected: _tab,
          onSelected: (value) => setState(() => _tab = value),
        ),
        const SizedBox(height: 18),
        _TwoPane(
          leftFlex: 3,
          rightFlex: 4,
          left: AdminSurface(
            child: tickets.isEmpty
                ? const AdminEmptyState(
                    icon: Icons.forum_outlined,
                    title: 'No tickets here',
                    message: 'Nothing in this queue right now.',
                  )
                : Column(
                    children: tickets.map((ticket) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () => setState(() => _selected = ticket),
                          child: AdminUserMiniCard(
                            name: '${ticket.id} - ${ticket.user}',
                            detail:
                                '${ticket.category} - ${ticket.age} - ${ticket.lastMessage}',
                            badge: ticket.priority,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          right: AdminSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headline(context, _selected.id),
                const SizedBox(height: 8),
                _text(context,
                    '${_selected.source} - ${_selected.category} - Assigned ${_selected.assignedTo}'),
                const SizedBox(height: 12),
                ...messages.map((message) => _bullet(context, message)),
                const SizedBox(height: 12),
                CoreTextField(
                  controller: _reply,
                  label: 'Write a reply',
                  icon: Icons.reply_rounded,
                  maxLines: 3,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _tinyAction(
                        context,
                        'Send response',
                        _reply.text.trim().isEmpty
                            ? null
                            : () => setState(() {
                                  messages.add(_reply.text.trim());
                                  _reply.clear();
                                })),
                    _tinyAction(context, 'Change status',
                        () => setState(() => _tab = 'Open')),
                    _tinyAction(
                        context, 'Assign admin', () => _staffSheet(context)),
                    _tinyAction(
                        context,
                        'Escalate',
                        () => Navigator.pushNamed(
                            context, SuperAdminRoutes.disputeCase)),
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
