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
  String _status = 'pending';
  final _search = TextEditingController();
  Future<List<verification.KycSubmission>>? _submissionsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _submissionsFuture ??= _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<verification.KycSubmission>> _load() {
    return AuthScope.of(context).adminKycSubmissions(status: _status);
  }

  void _refresh() {
    setState(() => _submissionsFuture = _load());
  }

  List<verification.KycSubmission> _rows(
      List<verification.KycSubmission> submissions) {
    final query = _search.text.toLowerCase();
    return submissions.where((item) {
      final roleMatch = _role == 'All' || item.roleName.contains(_role);
      final queryMatch = query.isEmpty ||
          item.applicantName.toLowerCase().contains(query) ||
          item.applicantEmail.toLowerCase().contains(query) ||
          item.publicId.toLowerCase().contains(query) ||
          item.riskLevel.toLowerCase().contains(query);
      return roleMatch && queryMatch;
    }).toList();
  }

  void _open(verification.KycSubmission submission) {
    Navigator.pushNamed(
      context,
      SuperAdminRoutes.verificationPath(submission.publicId),
    );
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
                  'Director / Producer',
                  'Actor / Talent',
                  'Model',
                  'Location Owner',
                  'Media / Equipment Provider',
                  'Casting Agency',
                  'Brand / Sponsor',
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
                    'Status',
                    _status,
                    const [
                      'pending',
                      'approved',
                      'needs_resubmission',
                      'rejected',
                    ],
                    (value) {
                      setState(() {
                        _status = value;
                        _submissionsFuture = _load();
                      });
                    },
                  ),
                  AdminActionButton(
                    icon: Icons.refresh_rounded,
                    label: 'Refresh queue',
                    secondary: true,
                    onTap: _refresh,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FutureBuilder<List<verification.KycSubmission>>(
          future: _submissionsFuture,
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
                      icon: Icons.admin_panel_settings_outlined,
                      title: error is ApiException && error.statusCode == 403
                          ? 'KYC review permission required'
                          : 'Could not load verification queue',
                      message: error is ApiException
                          ? error.message
                          : 'Check your connection and try again.',
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
            final rows = _rows(snapshot.data ?? const []);
            if (rows.isEmpty) {
              return const AdminEmptyState(
                icon: Icons.search_off_rounded,
                title: 'No matching submissions',
                message: 'Try a different role, status or search term.',
              );
            }
            return AdminDataTable(
              columns: const [
                'User',
                'Role',
                'Docs',
                'Risk',
                'Status',
                'Scan',
                'Action',
              ],
              rowActions:
                  rows.map<VoidCallback?>((row) => () => _open(row)).toList(),
              rows: rows
                  .map(
                    (row) => [
                      _text(context, row.applicantName, strong: true),
                      _text(context, row.roleName),
                      _text(context, '${row.files.length} file(s)'),
                      AdminRiskBadge(
                        label: row.riskLevel,
                        risk: row.riskLevel == 'high'
                            ? AdminRiskTone.high
                            : AdminRiskTone.low,
                      ),
                      AdminStatusBadge(
                        label: row.status,
                        tone: row.status == 'approved'
                            ? AdminDecisionTone.success
                            : AdminDecisionTone.warning,
                      ),
                      _text(
                        context,
                        row.files.isEmpty
                            ? 'No files'
                            : row.files
                                .map((file) => file.scanStatus)
                                .join(', '),
                      ),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _tinyAction(context, 'Review', () => _open(row)),
                          _tinyAction(
                            context,
                            'Request info',
                            () => Navigator.pushNamed(
                              context,
                              SuperAdminRoutes.verificationPath(row.publicId),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
