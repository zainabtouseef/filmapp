part of '../super_admin_screens.dart';

class SupportCrmScreen extends StatefulWidget {
  const SupportCrmScreen({super.key});

  @override
  State<SupportCrmScreen> createState() => _SupportCrmScreenState();
}

class _SupportCrmScreenState extends State<SupportCrmScreen> {
  Future<List<SupportTicketDto>>? _future;
  final _reply = TextEditingController();
  String _filter = 'All';
  String? _selectedId;
  bool _updating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= TrustSafetyScope.of(context).adminSupportTickets(force: true);
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(
      () => _future =
          TrustSafetyScope.of(context).adminSupportTickets(force: true),
    );
  }

  List<SupportTicketDto> _visible(List<SupportTicketDto> tickets) {
    if (_filter == 'All') return tickets;
    return tickets.where((ticket) => ticket.status == _filter).toList();
  }

  Future<void> _update(
    SupportTicketDto ticket, {
    String? status,
    bool assignToMe = false,
  }) async {
    if (_updating) return;
    setState(() => _updating = true);
    try {
      await TrustSafetyScope.of(context).updateSupportTicket(
        ticket.publicId,
        {
          if (status != null) 'status': status,
          if (assignToMe) 'assign_to_me': true,
        },
      );
      if (!mounted) return;
      showCoreSnack(context, 'Support ticket updated.');
      _refresh();
    } on ApiException catch (error) {
      if (mounted) showCoreSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _sendReply(SupportTicketDto ticket) async {
    final body = _reply.text.trim();
    if (body.isEmpty || _updating) return;
    setState(() => _updating = true);
    try {
      await TrustSafetyScope.of(context).createSupportMessage(
        ticketId: ticket.publicId,
        body: body,
      );
      if (!mounted) return;
      _reply.clear();
      showCoreSnack(context, 'Response sent to the member.');
      _refresh();
    } on ApiException catch (error) {
      if (mounted) showCoreSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SupportTicketDto>>(
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
                  icon: Icons.support_agent_outlined,
                  title: 'Could not load support tickets',
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
        final all = snapshot.data ?? const <SupportTicketDto>[];
        final tickets = _visible(all);
        final selected = tickets.isEmpty
            ? null
            : tickets.firstWhere(
                (ticket) => ticket.publicId == _selectedId,
                orElse: () => tickets.first,
              );
        return Column(
          children: [
            AdminSurface(
              child: Column(
                children: [
                  AdminFilterBar(
                    filters: const [
                      'All',
                      'open',
                      'in_progress',
                      'waiting_on_user',
                      'escalated',
                      'resolved',
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
            _TwoPane(
              leftFlex: 3,
              rightFlex: 4,
              left: AdminSurface(
                child: tickets.isEmpty
                    ? const AdminEmptyState(
                        icon: Icons.forum_outlined,
                        title: 'No tickets here',
                        message: 'This service queue is currently clear.',
                      )
                    : Column(
                        children: [
                          for (final ticket in tickets)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _SupportTicketCard(
                                ticket: ticket,
                                selected: ticket.publicId == selected?.publicId,
                                onTap: () => setState(
                                  () => _selectedId = ticket.publicId,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              right: AdminSurface(
                child: selected == null
                    ? const AdminEmptyState(
                        icon: Icons.mark_email_read_outlined,
                        title: 'No ticket selected',
                        message: 'Choose a ticket to view its controls.',
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _headline(context, selected.subject),
                          const SizedBox(height: 7),
                          Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: [
                              AdminStatusBadge(
                                label: selected.publicId,
                                tone: AdminDecisionTone.info,
                              ),
                              AdminStatusBadge(
                                label: selected.status,
                                tone: selected.status == 'resolved'
                                    ? AdminDecisionTone.success
                                    : AdminDecisionTone.warning,
                              ),
                              AdminStatusBadge(
                                label: selected.priority,
                                tone: selected.priority == 'urgent'
                                    ? AdminDecisionTone.danger
                                    : AdminDecisionTone.neutral,
                              ),
                              AdminStatusBadge(
                                label: '${selected.messageCount} messages',
                                tone: AdminDecisionTone.neutral,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          CoreTextField(
                            controller: _reply,
                            label: 'Write a member response',
                            icon: Icons.reply_rounded,
                            maxLines: 4,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              AdminActionButton(
                                icon: Icons.send_outlined,
                                label: 'Send response',
                                onTap: _reply.text.trim().isEmpty || _updating
                                    ? null
                                    : () => _sendReply(selected),
                              ),
                              AdminActionButton(
                                icon: Icons.person_add_alt_1_outlined,
                                label: 'Assign to me',
                                secondary: true,
                                onTap: _updating
                                    ? null
                                    : () => _update(
                                          selected,
                                          assignToMe: true,
                                        ),
                              ),
                              AdminActionButton(
                                icon: Icons.hourglass_top_rounded,
                                label: 'Waiting on user',
                                secondary: true,
                                onTap: _updating
                                    ? null
                                    : () => _update(
                                          selected,
                                          status: 'waiting_on_user',
                                        ),
                              ),
                              AdminActionButton(
                                icon: Icons.priority_high_rounded,
                                label: 'Escalate',
                                secondary: true,
                                onTap: _updating
                                    ? null
                                    : () => _update(
                                          selected,
                                          status: 'escalated',
                                        ),
                              ),
                              AdminActionButton(
                                icon: Icons.task_alt_outlined,
                                label: 'Resolve',
                                secondary: true,
                                onTap:
                                    _updating || selected.status == 'resolved'
                                        ? null
                                        : () => _update(
                                              selected,
                                              status: 'resolved',
                                            ),
                              ),
                            ],
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

class _SupportTicketCard extends StatelessWidget {
  final SupportTicketDto ticket;
  final bool selected;
  final VoidCallback onTap;

  const _SupportTicketCard({
    required this.ticket,
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
        padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
        decoration: BoxDecoration(
          color: selected
              ? colors.goldGlow.withValues(alpha: 0.12)
              : colors.softSurface.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? colors.goldMid : colors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 34,
              color: selected ? colors.goldMid : Colors.transparent,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _text(context, ticket.subject, strong: true),
                  _text(
                    context,
                    '${ticket.publicId} · ${ticket.category} · '
                    '${ticket.messageCount} messages',
                  ),
                ],
              ),
            ),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ticket.priority == 'urgent'
                    ? colors.danger
                    : colors.goldMid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
