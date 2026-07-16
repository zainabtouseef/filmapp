part of '../super_admin_screens.dart';

class PeopleVerificationQueueScreen extends StatefulWidget {
  const PeopleVerificationQueueScreen({super.key});

  @override
  State<PeopleVerificationQueueScreen> createState() =>
      _PeopleVerificationQueueScreenState();
}

class _PeopleVerificationQueueScreenState
    extends State<PeopleVerificationQueueScreen> {
  String _filter = 'All';
  final _search = TextEditingController();

  static const _filters = [
    'All',
    'Actors',
    'Models',
    'Producers',
    'Agencies',
    'Media Providers',
    'Location Owners',
    'High Risk',
    '24h+',
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(KycSubmission item) {
    final query = _search.text.toLowerCase();
    final queryMatch = query.isEmpty ||
        item.name.toLowerCase().contains(query) ||
        item.risk.toLowerCase().contains(query);
    if (!queryMatch) return false;
    return switch (_filter) {
      'All' => true,
      'High Risk' => item.risk != 'No risk',
      '24h+' => item.age.contains('h') &&
          (int.tryParse(item.age.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0) >= 24,
      'Actors' => item.role.contains('Actor'),
      'Models' => item.role.contains('Model'),
      'Producers' =>
        item.role.contains('Producer') || item.role.contains('Director'),
      'Agencies' => item.role.contains('Agency'),
      'Media Providers' => item.role.contains('Media Provider'),
      'Location Owners' => item.role.contains('Location Owner'),
      _ => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final rows = AdminMockData.kycSubmissions.where(_matches).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CoreTextField(
          controller: _search,
          label: 'Search name or risk flag',
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
            title: 'No matching submissions',
            message: 'Try a different filter or search term.',
          )
        else
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PeopleQueueCard(submission: row),
            ),
          ),
      ],
    );
  }
}

class _PeopleQueueCard extends StatelessWidget {
  final KycSubmission submission;

  const _PeopleQueueCard({required this.submission});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final riskTone = submission.risk == 'No risk'
        ? AdminDecisionTone.success
        : AdminDecisionTone.danger;
    return AdminSurface(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: colors.softSurface,
                child: Text(
                  submission.name.isEmpty ? '?' : submission.name[0],
                  style: AppTextStyles.label.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      submission.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${submission.role} - ${submission.city}',
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
              const SizedBox(width: 8),
              AdminSlaBadge(age: submission.age),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: colors.iconMuted),
                onSelected: (value) {
                  switch (value) {
                    case 'assign':
                      _staffSheet(context);
                      return;
                    case 'reject':
                      _noteDialog(context, 'Reject quick note');
                      return;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'assign', child: Text('Assign')),
                  PopupMenuItem(value: 'reject', child: Text('Reject')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              AdminStatusBadge(
                  label: submission.docs, tone: AdminDecisionTone.info),
              AdminRiskBadge(
                  label: submission.risk,
                  risk: riskTone == AdminDecisionTone.success
                      ? AdminRiskTone.low
                      : AdminRiskTone.high),
              AdminStatusBadge(
                label: 'Assigned: ${submission.assignedTo}',
                tone: AdminDecisionTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: _ReviewOutlineButton(
              label: 'Review',
              onTap: () => Navigator.pushNamed(
                  context, SuperAdminRoutes.verificationDetail),
            ),
          ),
        ],
      ),
    );
  }
}
