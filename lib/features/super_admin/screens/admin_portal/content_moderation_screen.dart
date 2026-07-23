part of '../super_admin_screens.dart';

class ContentModerationScreen extends StatelessWidget {
  const ContentModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminModerationControlView();
  }
}

class AdminModerationControlView extends StatefulWidget {
  const AdminModerationControlView({super.key});

  @override
  State<AdminModerationControlView> createState() =>
      _AdminModerationControlViewState();
}

class _AdminModerationControlViewState
    extends State<AdminModerationControlView> {
  Future<List<ModerationCaseDto>>? _future;
  String _filter = 'All';
  final _search = TextEditingController();
  String? _busyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= TrustSafetyScope.of(context).adminModerationCases(force: true);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(
      () => _future =
          TrustSafetyScope.of(context).adminModerationCases(force: true),
    );
  }

  List<ModerationCaseDto> _visible(List<ModerationCaseDto> cases) {
    final query = _search.text.trim().toLowerCase();
    return cases.where((item) {
      final haystack = [
        item.publicId,
        item.entityId,
        item.entityType,
        item.source,
        item.status,
      ].join(' ').toLowerCase();
      if (query.isNotEmpty && !haystack.contains(query)) return false;
      return switch (_filter) {
        'Queued' => item.status == 'queued',
        'Escalated' => item.status == 'escalated',
        'Resolved' => item.status == 'resolved',
        'High risk' => item.riskLevel == 'high',
        'Profiles' => item.entityType.contains('profile'),
        'Listings' => item.entityType.contains('listing'),
        'Media' => item.entityType.contains('media'),
        _ => true,
      };
    }).toList();
  }

  Future<void> _decide(
    ModerationCaseDto item,
    String decision,
  ) async {
    final reason = await _adminNotePrompt(
      context,
      title: '${decision[0].toUpperCase()}${decision.substring(1)} content',
      hint: 'Record the policy basis and required follow-up.',
    );
    if (!mounted || reason == null || _busyId != null) return;
    setState(() => _busyId = item.publicId);
    try {
      await TrustSafetyScope.of(context).decideModerationCase(
        caseId: item.publicId,
        decision: decision,
        reason: reason,
      );
      if (!mounted) return;
      showCoreSnack(context, 'Moderation case changed to $decision.');
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSurface(
          child: Column(
            children: [
              CoreTextField(
                controller: _search,
                label: 'Search case, entity, source or status',
                icon: Icons.search_rounded,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              AdminFilterBar(
                filters: const [
                  'All',
                  'Queued',
                  'Escalated',
                  'Resolved',
                  'High risk',
                  'Profiles',
                  'Listings',
                  'Media',
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
        FutureBuilder<List<ModerationCaseDto>>(
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
                      icon: Icons.policy_outlined,
                      title: 'Could not load moderation cases',
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
            final rows = _visible(snapshot.data ?? const []);
            if (rows.isEmpty) {
              return const AdminEmptyState(
                icon: Icons.verified_outlined,
                title: 'No matching moderation cases',
                message: 'This trust and safety view is currently clear.',
              );
            }
            return Column(
              children: [
                for (final item in rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ModerationCaseCard(
                      item: item,
                      busy: _busyId == item.publicId,
                      onApprove: () => _decide(item, 'approved'),
                      onReject: () => _decide(item, 'rejected'),
                      onEscalate: () => _decide(item, 'escalated'),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ModerationCaseCard extends StatelessWidget {
  final ModerationCaseDto item;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onEscalate;

  const _ModerationCaseCard({
    required this.item,
    required this.busy,
    required this.onApprove,
    required this.onReject,
    required this.onEscalate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final high = item.riskLevel == 'high';
    final closed = item.status == 'resolved';
    return AdminSurface(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: high ? colors.danger : colors.goldMid,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final details = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.entityType.replaceAll('_', ' '),
                          style: AppTextStyles.cardTitle.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        _text(
                          context,
                          '${item.publicId} · ${item.entityId} · ${item.source}',
                        ),
                        const SizedBox(height: 7),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            AdminStatusBadge(
                              label: item.status,
                              tone: item.status == 'escalated'
                                  ? AdminDecisionTone.danger
                                  : closed
                                      ? AdminDecisionTone.success
                                      : AdminDecisionTone.warning,
                            ),
                            AdminRiskBadge(
                              label: item.riskLevel,
                              risk: high
                                  ? AdminRiskTone.high
                                  : AdminRiskTone.medium,
                            ),
                            if (item.decision != null)
                              AdminStatusBadge(
                                label: item.decision!,
                                tone: AdminDecisionTone.info,
                              ),
                            AdminStatusBadge(
                              label: '${item.eventCount} events',
                              tone: AdminDecisionTone.neutral,
                            ),
                          ],
                        ),
                      ],
                    );
                    final actions = Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _tinyAction(
                          context,
                          'Approve',
                          busy || closed ? null : onApprove,
                        ),
                        _tinyAction(
                          context,
                          'Reject',
                          busy || closed ? null : onReject,
                        ),
                        _tinyAction(
                          context,
                          'Escalate',
                          busy || item.status == 'escalated'
                              ? null
                              : onEscalate,
                        ),
                      ],
                    );
                    if (constraints.maxWidth < 720) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          details,
                          const SizedBox(height: 10),
                          actions,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: details),
                        const SizedBox(width: 12),
                        actions,
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
