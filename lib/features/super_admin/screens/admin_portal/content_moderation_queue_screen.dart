part of '../super_admin_screens.dart';

class ContentModerationQueueScreen extends StatefulWidget {
  const ContentModerationQueueScreen({super.key});

  @override
  State<ContentModerationQueueScreen> createState() =>
      _ContentModerationQueueScreenState();
}

class _ContentModerationQueueScreenState
    extends State<ContentModerationQueueScreen> {
  String _filter = 'All';
  final _search = TextEditingController();

  static const _filters = [
    'All',
    'Portfolio',
    'Location Media',
    'Videos',
    'Rate Claims',
    'Reported',
    'Watermark Issues',
    'High Risk',
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(AdminContentItem item) {
    final query = _search.text.toLowerCase();
    final queryMatch = query.isEmpty ||
        item.title.toLowerCase().contains(query) ||
        item.user.toLowerCase().contains(query);
    if (!queryMatch) return false;
    return switch (_filter) {
      'All' => true,
      'Portfolio' => item.type == 'Portfolio Photos',
      'Location Media' => item.type == 'Location Images',
      'Videos' => item.type == 'Videos',
      'Rate Claims' => item.type == 'Rate Claims',
      'Reported' => item.type == 'Reported Content' || item.reports > 0,
      'Watermark Issues' => item.watermark == 'Missing',
      'High Risk' => item.risk == 'High',
      _ => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final rows = AdminMockData.contentItems.where(_matches).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _LiveModerationCases(),
        const SizedBox(height: 14),
        CoreTextField(
          controller: _search,
          label: 'Search content or uploader',
          icon: Icons.search_rounded,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        AdminFilterBar(
          filters: _filters,
          selected: _filter,
          onSelected: (value) => setState(() => _filter = value),
        ),
        const SizedBox(height: 16),
        if (rows.isEmpty)
          const AdminEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No matching content',
            message: 'Try a different filter or search term.',
          )
        else
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ContentQueueCard(item: row),
            ),
          ),
      ],
    );
  }
}

class _LiveModerationCases extends StatefulWidget {
  const _LiveModerationCases();

  @override
  State<_LiveModerationCases> createState() => _LiveModerationCasesState();
}

class _LiveModerationCasesState extends State<_LiveModerationCases> {
  late Future<List<ModerationCaseDto>> _future;
  bool _deciding = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final trustSafety = TrustSafetyScope.maybeOf(context);
    _future = trustSafety == null
        ? Future.value(const <ModerationCaseDto>[])
        : trustSafety.adminModerationCases(force: true);
  }

  Future<void> _decide(ModerationCaseDto item, String decision) async {
    final trustSafety = TrustSafetyScope.maybeOf(context);
    if (trustSafety == null || _deciding) return;
    setState(() => _deciding = true);
    try {
      await trustSafety.decideModerationCase(
        caseId: item.publicId,
        decision: decision,
        reason: 'Reviewed from Flutter Super Admin moderation queue.',
      );
      if (!mounted) return;
      setState(() => _future = trustSafety.adminModerationCases(force: true));
      showCoreSnack(context, 'Live moderation case updated');
    } catch (_) {
      if (mounted) showCoreSnack(context, 'Could not update live case');
    } finally {
      if (mounted) setState(() => _deciding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ModerationCaseDto>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator(minHeight: 2);
        }
        if (snapshot.hasError) {
          return const InlineNotice(
            message:
                'Live moderation queue unavailable — showing preview moderation items.',
            tone: CoreStatusTone.warning,
          );
        }
        final rows = snapshot.data ?? const <ModerationCaseDto>[];
        if (rows.isEmpty) {
          return const InlineNotice(
            message:
                'No live moderation cases are open — preview moderation items remain below.',
          );
        }
        final item = rows.first;
        return AdminSurface(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AdminStatusBadge(
                label: '${rows.length} live cases',
                tone: AdminDecisionTone.info,
              ),
              AdminStatusBadge(
                label: item.riskLevel,
                tone: item.riskLevel == 'high'
                    ? AdminDecisionTone.danger
                    : AdminDecisionTone.warning,
              ),
              Text(
                '${item.publicId} · ${item.entityType} · ${item.status}',
                style: AppTextStyles.caption
                    .copyWith(color: context.appColors.textSecondary),
              ),
              _tinyAction(
                context,
                _deciding ? 'Updating...' : 'Approve live',
                _deciding ? null : () => _decide(item, 'approved'),
              ),
              _tinyAction(
                context,
                _deciding ? 'Updating...' : 'Remove live',
                _deciding ? null : () => _decide(item, 'rejected'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ContentQueueCard extends StatefulWidget {
  final AdminContentItem item;

  const _ContentQueueCard({required this.item});

  @override
  State<_ContentQueueCard> createState() => _ContentQueueCardState();
}

class _ContentQueueCardState extends State<_ContentQueueCard> {
  bool _removed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final item = widget.item;
    final riskTone = item.risk == 'High'
        ? AdminDecisionTone.danger
        : item.risk == 'Medium'
            ? AdminDecisionTone.warning
            : AdminDecisionTone.success;
    if (_removed) {
      return AdminSurface(
        padding: const EdgeInsets.all(12),
        child: Text(
          '${item.title} - removed from queue',
          style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
        ),
      );
    }
    return AdminSurface(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _dashboardToneColor(context, riskTone)
                      .withValues(alpha: 0.12),
                ),
                child: Icon(Icons.photo_library_outlined,
                    color: _dashboardToneColor(context, riskTone), size: 26),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.user} - ${item.role} - ${item.time}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.micro.copyWith(
                        color: colors.textSecondary,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        AdminStatusBadge(
                            label: item.visibility,
                            tone: AdminDecisionTone.info),
                        AdminStatusBadge(
                            label: item.watermark,
                            tone: AdminDecisionTone.warning),
                        AdminRiskBadge(
                          label: '${item.reports} reports',
                          risk: item.risk == 'High'
                              ? AdminRiskTone.high
                              : AdminRiskTone.low,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _tinyAction(context, 'Approve', () {
                setState(() => _removed = true);
                showCoreSnack(context, 'Content approved');
              }),
              _tinyAction(context, 'Remove',
                  () => _noteDialog(context, 'Removal reason')),
              _tinyAction(context, 'Warn',
                  () => _noteDialog(context, 'Warning template')),
              _tinyAction(context, 'Profile',
                  () => Navigator.pushNamed(context, SuperAdminRoutes.users)),
              _tinyAction(context, 'Escalate', () {
                showCoreSnack(context, 'Support ticket created');
                Navigator.pushNamed(context, SuperAdminRoutes.support);
              }),
            ],
          ),
        ],
      ),
    );
  }
}
