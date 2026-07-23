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
  bool _sending = false;
  String? _notice;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  List<String> get _audienceRoles {
    return switch (_segment) {
      'All actors in Lahore' => const ['actor_talent'],
      'All location owners in Karachi' => const ['location_owner'],
      'All pending KYC users' => const ['all'],
      'All producers with active negotiations' => const ['director_producer'],
      'All payment-pending users' => const ['all'],
      _ => const ['all'],
    };
  }

  Future<void> _saveOrSend({required bool publish}) async {
    if (_sending) return;
    final trustSafety = TrustSafetyScope.of(context);
    setState(() {
      _sending = true;
      _notice = null;
    });
    try {
      final announcement = await trustSafety.createAnnouncement({
        'title': _title.text.trim(),
        'body': _body.text.trim(),
        'priority': _priority.toLowerCase(),
        'audience': {'roles': _audienceRoles},
        'channels': {
          'in_app': true,
          'push': true,
          'email': false,
          'sms': false
        },
      });
      if (publish) {
        await trustSafety.publishAnnouncement(announcement.publicId);
      }
      if (!mounted) return;
      setState(() {
        _status = publish ? 'Sent live' : 'Draft saved';
        _notice = 'Announcement ${announcement.publicId} '
            '${publish ? 'published' : 'saved as draft'}.';
      });
      if (publish) {
        showCoreSuccessDialog(
          context,
          title: 'Broadcast sent',
          message:
              'The live announcement was published to the selected audience.',
        );
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _notice = error.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _TwoPane(
      leftFlex: 5,
      rightFlex: 3,
      left: AdminSurface(
        child: Column(
          children: [
            if (_notice != null) ...[
              InlineNotice(
                message: _notice!,
                tone: _notice!.startsWith('Live')
                    ? CoreStatusTone.info
                    : CoreStatusTone.warning,
              ),
              const SizedBox(height: 12),
            ],
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
                    _sending ? null : () => _saveOrSend(publish: false)),
                _tinyAction(context, _sending ? 'Sending...' : 'Send Now',
                    _sending ? null : () => _saveOrSend(publish: true)),
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
            const SizedBox(height: 14),
            const _LiveAnnouncementsList(),
          ],
        ),
      ),
    );
  }
}

class _LiveAnnouncementsList extends StatefulWidget {
  const _LiveAnnouncementsList();

  @override
  State<_LiveAnnouncementsList> createState() => _LiveAnnouncementsListState();
}

class _LiveAnnouncementsListState extends State<_LiveAnnouncementsList> {
  Future<List<AnnouncementDto>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= TrustSafetyScope.of(context).announcements(force: true);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AnnouncementDto>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator(minHeight: 2);
        }
        if (snapshot.hasError) {
          return const InlineNotice(
            message: 'Live announcement history unavailable.',
            tone: CoreStatusTone.warning,
          );
        }
        final rows = snapshot.data ?? const <AnnouncementDto>[];
        if (rows.isEmpty) {
          return const InlineNotice(message: 'No live announcements yet.');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionHeader(title: 'Recent Live Broadcasts'),
            const SizedBox(height: 8),
            ...rows.take(3).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AdminStatusBadge(
                      label: '${item.publicId} · ${item.status}',
                      tone: item.status == 'published'
                          ? AdminDecisionTone.success
                          : AdminDecisionTone.neutral,
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}
