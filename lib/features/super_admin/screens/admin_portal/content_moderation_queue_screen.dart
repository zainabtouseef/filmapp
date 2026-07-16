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
