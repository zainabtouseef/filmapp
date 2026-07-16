part of '../super_admin_screens.dart';

class BroadcastAnnouncementsScreen extends StatefulWidget {
  const BroadcastAnnouncementsScreen({super.key});

  @override
  State<BroadcastAnnouncementsScreen> createState() =>
      _BroadcastAnnouncementsScreenState();
}

class _BroadcastAnnouncementsScreenState
    extends State<BroadcastAnnouncementsScreen> {
  final _title = TextEditingController(text: 'Payment verification update');
  final _body = TextEditingController(
      text: 'Your uploaded payment proof has moved to admin review.');
  String _priority = 'Normal';
  String _segment = 'All actors in Lahore';
  String _status = 'Draft';

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _TwoPane(
      leftFlex: 5,
      rightFlex: 3,
      left: AdminSurface(
        child: Column(
          children: [
            CoreTextField(
                controller: _title,
                label: 'Announcement title',
                icon: Icons.title_rounded,
                onChanged: (_) => setState(() {})),
            const SizedBox(height: 12),
            CoreTextField(
                controller: _body,
                label: 'Message body',
                icon: Icons.notes_outlined,
                maxLines: 5,
                onChanged: (_) => setState(() {})),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _dropdown(
                    context,
                    'Priority',
                    _priority,
                    const ['Normal', 'High', 'Urgent'],
                    (v) => setState(() => _priority = v)),
                _dropdown(
                    context,
                    'Audience',
                    _segment,
                    const [
                      'All actors in Lahore',
                      'All location owners in Karachi',
                      'All pending KYC users',
                      'All producers with active negotiations',
                      'All payment-pending users'
                    ],
                    (v) => setState(() => _segment = v)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                AdminStatusBadge(label: 'In-app', tone: AdminDecisionTone.info),
                AdminStatusBadge(label: 'Push', tone: AdminDecisionTone.info),
                AdminStatusBadge(
                    label: 'Email', tone: AdminDecisionTone.neutral),
                AdminStatusBadge(label: 'SMS', tone: AdminDecisionTone.neutral),
                AdminStatusBadge(
                    label: 'WhatsApp', tone: AdminDecisionTone.warning),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _tinyAction(context, 'Save Draft',
                    () => setState(() => _status = 'Draft saved')),
                _tinyAction(context, 'Schedule',
                    () => setState(() => _status = 'Scheduled')),
                _tinyAction(
                    context,
                    'Send Now',
                    () => showCoreSuccessDialog(context,
                        title: 'Broadcast sent',
                        message: 'Static audience segment notified.')),
                _tinyAction(context, 'Test Send',
                    () => showCoreSnack(context, 'Test notification sent')),
              ],
            ),
          ],
        ),
      ),
      right: AdminSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionHeader(title: 'Notification Preview'),
            const SizedBox(height: 12),
            NotificationCardPreview(
                title: _title.text,
                body: _body.text,
                priority: _priority,
                segment: _segment,
                status: _status),
          ],
        ),
      ),
    );
  }
}
