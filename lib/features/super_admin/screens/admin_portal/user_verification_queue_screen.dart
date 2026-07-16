part of '../super_admin_screens.dart';

class UserVerificationQueueScreen extends StatefulWidget {
  const UserVerificationQueueScreen({super.key});

  @override
  State<UserVerificationQueueScreen> createState() =>
      _UserVerificationQueueScreenState();
}

class _UserVerificationQueueScreenState
    extends State<UserVerificationQueueScreen> {
  String _role = 'All';
  String _city = 'Lahore';
  String _sla = 'New';
  String _risk = 'Duplicate Device';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<KycSubmission> get _rows {
    final query = _search.text.toLowerCase();
    return AdminMockData.kycSubmissions.where((item) {
      final roleMatch = _role == 'All' || item.role.contains(_role);
      final queryMatch = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.risk.toLowerCase().contains(query);
      final cityMatch = item.city == _city;
      final ageHours = int.tryParse(item.age.replaceAll('h', '')) ?? 0;
      final slaMatch = switch (_sla) {
        'New' => ageHours < 12,
        '12h+' => ageHours >= 12,
        '24h+' => ageHours >= 24,
        '48h+' => ageHours >= 48,
        _ => true,
      };
      final riskMatch = item.risk.toLowerCase().contains(_risk.toLowerCase());
      return roleMatch && queryMatch && cityMatch && slaMatch && riskMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CoreTextField(
                controller: _search,
                label: 'Search applicant, CNIC risk, device or role',
                icon: Icons.search_rounded,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              AdminFilterBar(
                filters: const [
                  'All',
                  'Director/Producer',
                  'Actor/Talent',
                  'Model',
                  'Location Owner',
                  'Equipment Provider',
                  'Agency',
                  'Brand/Sponsor',
                ],
                selected: _role,
                onSelected: (value) => setState(() => _role = value),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _dropdown(
                    context,
                    'City',
                    _city,
                    const ['Lahore', 'Karachi', 'Islamabad', 'Rawalpindi'],
                    (value) => setState(() => _city = value),
                  ),
                  _dropdown(
                    context,
                    'SLA',
                    _sla,
                    const ['New', '12h+', '24h+', '48h+'],
                    (value) => setState(() => _sla = value),
                  ),
                  _dropdown(
                    context,
                    'Risk',
                    _risk,
                    const [
                      'Duplicate CNIC',
                      'Duplicate Device',
                      'Mismatched Name',
                      'Bank Name Mismatch',
                    ],
                    (value) => setState(() => _risk = value),
                  ),
                  AdminActionButton(
                    icon: Icons.groups_outlined,
                    label: 'Bulk assign selected',
                    secondary: true,
                    onTap: () => _staffSheet(context),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_rows.isEmpty)
          const AdminEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No matching submissions',
            message: 'Try a different city, SLA or risk filter.',
          )
        else
          AdminDataTable(
            columns: const [
              'User',
              'Role',
              'City',
              'Docs',
              'Age',
              'Risk Flags',
              'Assigned',
              'Status',
              'Action',
            ],
            rowActions: _rows
                .map<VoidCallback?>(
                  (_) => () => Navigator.pushNamed(
                      context, SuperAdminRoutes.verificationDetail),
                )
                .toList(),
            rows: _rows
                .map(
                  (row) => [
                    _text(context, row.name, strong: true),
                    _text(context, row.role),
                    _text(context, row.city),
                    _text(context, row.docs),
                    AdminSlaBadge(age: row.age),
                    AdminRiskBadge(
                      label: row.risk,
                      risk: row.risk == 'No risk'
                          ? AdminRiskTone.low
                          : AdminRiskTone.high,
                    ),
                    _text(context, row.assignedTo),
                    AdminStatusBadge(
                      label: row.status,
                      tone: row.status.contains('Risk')
                          ? AdminDecisionTone.danger
                          : AdminDecisionTone.warning,
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _tinyAction(
                          context,
                          'Review',
                          () => Navigator.pushNamed(
                              context, SuperAdminRoutes.verificationDetail),
                        ),
                        _tinyAction(
                            context, 'Assign', () => _staffSheet(context)),
                        _tinyAction(
                          context,
                          'Reject',
                          () => _noteDialog(context, 'Reject quick note'),
                        ),
                      ],
                    ),
                  ],
                )
                .toList(),
          ),
      ],
    );
  }
}
