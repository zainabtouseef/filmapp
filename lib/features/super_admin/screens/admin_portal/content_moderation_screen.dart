part of '../super_admin_screens.dart';

class ContentModerationScreen extends StatefulWidget {
  const ContentModerationScreen({super.key});

  @override
  State<ContentModerationScreen> createState() =>
      _ContentModerationScreenState();
}

class _ContentModerationScreenState extends State<ContentModerationScreen> {
  String _tab = 'Portfolio Photos';
  late final List<AdminContentItem> _items =
      List.of(AdminMockData.contentItems);

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((item) => _tab == item.type).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFilterBar(
          filters: const [
            'Portfolio Photos',
            'Videos',
            'Location Images',
            'Rate Claims',
            'Reported Content',
            'Watermark Issues',
          ],
          selected: _tab,
          onSelected: (value) => setState(() => _tab = value),
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          const AdminEmptyState(
            icon: Icons.inbox_outlined,
            title: 'Nothing queued here',
            message: 'No items in this category right now.',
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: filtered
                .map((item) => SizedBox(
                      width: 236,
                      child: _moderationCard(context, item),
                    ))
                .toList(),
          ),
      ],
    );
  }

  Widget _moderationCard(BuildContext context, AdminContentItem item) {
    final colors = context.appColors;
    return AdminSurface(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: RadialGradient(
                    colors: [
                      colors.goldGlow.withValues(alpha: .55),
                      colors.softSurface.withValues(alpha: .55),
                    ],
                  ),
                ),
                child: Icon(Icons.photo_library_outlined,
                    color: colors.goldDark, size: 20),
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
                      style: AppTextStyles.label
                          .copyWith(color: colors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.user} - ${item.time}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.micro.copyWith(
                        color: colors.textSecondary,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              AdminStatusBadge(
                  label: item.watermark, tone: AdminDecisionTone.warning),
              AdminRiskBadge(
                label: '${item.reports} reports',
                risk: item.risk == 'High'
                    ? AdminRiskTone.high
                    : AdminRiskTone.low,
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _tinyAction(context, 'Approve', () {
                  setState(() => _items.remove(item));
                  showCoreSnack(context, 'Content approved');
                }),
              ),
              Expanded(
                child: _tinyAction(context, 'Remove',
                    () => _noteDialog(context, 'Removal reason')),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_vert_rounded,
                    color: colors.iconMuted, size: 19),
                onSelected: (value) {
                  switch (value) {
                    case 'warn':
                      _noteDialog(context, 'Warning template');
                      return;
                    case 'profile':
                      Navigator.pushNamed(context, SuperAdminRoutes.users);
                      return;
                    case 'escalate':
                      showCoreSnack(context, 'Support ticket created');
                      Navigator.pushNamed(context, SuperAdminRoutes.support);
                      return;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'warn', child: Text('Warn')),
                  PopupMenuItem(value: 'profile', child: Text('Profile')),
                  PopupMenuItem(value: 'escalate', child: Text('Escalate')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
