part of '../super_admin_screens.dart';

class KycReviewDetailScreen extends StatefulWidget {
  const KycReviewDetailScreen({super.key});

  @override
  State<KycReviewDetailScreen> createState() => _KycReviewDetailScreenState();
}

class _KycReviewDetailScreenState extends State<KycReviewDetailScreen> {
  String _document = 'CNIC Front';
  double _zoom = 1;
  final Set<String> _checked = {'Identity document readable'};
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Matches _ThreePane's threshold so this screen's three-column
        // layout switches together with the side nav rather than showing
        // desktop chrome next to still-stacked content.
        final wide =
            MediaQuery.sizeOf(context).width >= AppBreakpoints.wideDesktop;
        final children = [
          _applicantPanel(context),
          _documentPanel(context),
          _decisionPanel(context),
        ];
        if (!wide) {
          return Column(
            children: children
                .map((child) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: child,
                    ))
                .toList(),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 270, child: children[0]),
            const SizedBox(width: 16),
            Expanded(child: children[1]),
            const SizedBox(width: 16),
            SizedBox(width: 330, child: children[2]),
          ],
        );
      },
    );
  }

  Widget _applicantPanel(BuildContext context) {
    return AdminSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminUserMiniCard(
            name: 'FrameHouse Pvt Ltd',
            detail: 'Media Provider - Lahore',
            badge: 'Risk flagged',
          ),
          const SizedBox(height: 14),
          const AdminRiskBadge(
              label: 'Risk score 72', risk: AdminRiskTone.high),
          const SizedBox(height: 14),
          _kv(context, 'Phone/email', '0300-XXX / ops@framehouse.pk'),
          _kv(context, 'Submitted', 'Jul 8, 2026 - 11:10'),
          _kv(context, 'Status', 'Pending review'),
          _kv(context, 'Device/IP', 'Android 16 / 10.0.2.15'),
          _kv(context, 'Previous submissions', '1 rejected, 1 resubmitted'),
          const SizedBox(height: 14),
          AdminActionButton(
            icon: Icons.manage_search_outlined,
            label: 'Open Audit Logs',
            secondary: true,
            onTap: () =>
                Navigator.pushNamed(context, SuperAdminRoutes.auditLogs),
          ),
          const SizedBox(height: 10),
          AdminActionButton(
            icon: Icons.upload_file_outlined,
            label: 'View user KYC flow',
            secondary: true,
            onTap: () => Navigator.pushNamed(context, CoreRoutes.kyc),
          ),
        ],
      ),
    );
  }

  Widget _documentPanel(BuildContext context) {
    return AdminSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminFilterBar(
            filters: const [
              'CNIC Front',
              'CNIC Back',
              'Selfie',
              'Company Registration',
              'Bank Details',
              'Address Proof',
            ],
            selected: _document,
            onSelected: (value) => setState(() => _document = value),
          ),
          const SizedBox(height: 12),
          Transform.scale(
            scale: _zoom,
            child: AdminEvidenceViewer(
              title: _document,
              icon: Icons.article_outlined,
              details: const [
                'Clear edges',
                'OCR confidence 94%',
                'Admin preview'
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AdminActionButton(
                icon: Icons.zoom_in_rounded,
                label: 'Zoom in',
                secondary: true,
                onTap: () =>
                    setState(() => _zoom = (_zoom + .08).clamp(1, 1.3)),
              ),
              AdminActionButton(
                icon: Icons.zoom_out_rounded,
                label: 'Zoom out',
                secondary: true,
                onTap: () =>
                    setState(() => _zoom = (_zoom - .08).clamp(1, 1.3)),
              ),
              AdminActionButton(
                icon: Icons.rotate_right_rounded,
                label: 'Rotate',
                secondary: true,
                onTap: () => showCoreSnack(context, 'Document rotated'),
              ),
              AdminActionButton(
                icon: Icons.check_circle_outline,
                label: 'Mark clear',
                onTap: () => showCoreSnack(context, 'Document marked clear'),
              ),
              AdminActionButton(
                icon: Icons.error_outline,
                label: 'Mark unclear',
                secondary: true,
                onTap: () => showCoreSnack(context, 'Document marked unclear'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _decisionPanel(BuildContext context) {
    final checks = const [
      'Identity document readable',
      'Selfie matches document',
      'Name matches account',
      'Role-specific docs valid',
      'Bank account title matches user',
      'Address proof verified',
      'No duplicate CNIC',
      'No duplicate device risk',
    ];
    return AdminSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionHeader(
            title: 'Review Checklist',
            icon: Icons.checklist_rounded,
          ),
          const SizedBox(height: 8),
          ...checks.map(
            (check) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _checked.contains(check),
              onChanged: (value) {
                setState(() {
                  if (value ?? false) {
                    _checked.add(check);
                  } else {
                    _checked.remove(check);
                  }
                });
              },
              title: Text(check),
            ),
          ),
          const SizedBox(height: 12),
          CoreTextField(
            controller: _note,
            label: 'Add internal risk note...',
            icon: Icons.note_alt_outlined,
            maxLines: 4,
          ),
          const SizedBox(height: 14),
          AdminActionButton(
            icon: Icons.verified_outlined,
            label: 'Approve',
            onTap: () => _decision(
                context, 'User approved. Marketplace access unlocked.'),
          ),
          const SizedBox(height: 10),
          AdminActionButton(
            icon: Icons.cancel_outlined,
            label: 'Reject with Reason',
            secondary: true,
            onTap: () => _noteDialog(
              context,
              'Reject reason: CNIC image unclear / Bank name mismatch / Missing property proof',
            ),
          ),
          const SizedBox(height: 10),
          AdminActionButton(
            icon: Icons.contact_support_outlined,
            label: 'Request More Info',
            secondary: true,
            onTap: () => _noteDialog(context, 'Request more information'),
          ),
        ],
      ),
    );
  }

  void _decision(BuildContext context, String message) {
    showCoreSuccessDialog(
      context,
      title: 'Decision Saved',
      message: message,
      onDone: () => showCoreSnack(context, 'Decision written to audit log.'),
    );
  }
}
