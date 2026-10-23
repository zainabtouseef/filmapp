import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/cineplanner/cineplanner_controller.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/uploads/upload_repository.dart';

class CinePlannerUnlockCard extends StatelessWidget {
  final String section;
  final VoidCallback onOpen;
  const CinePlannerUnlockCard(
      {super.key, required this.section, required this.onOpen});
  @override
  Widget build(BuildContext context) => Center(
      child: SingleChildScrollView(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.lock_open_rounded,
                        size: 44, color: context.appColors.goldDark),
                    const SizedBox(height: 18),
                    Text('Unlock $section',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 25, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    const Text(
                        'Your preview is the beginning. Get the entire breakdown, production planning, exports, and a chat editor to refine your script.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    const Text(r'$20 / month',
                        style: TextStyle(
                            fontSize: 30, fontWeight: FontWeight.w800)),
                    const Text('10 reviewed AI alterations included'),
                    const SizedBox(height: 20),
                    FilledButton(
                        onPressed: onOpen,
                        child: const Text('View Complete plan')),
                  ])))));
}

class CinePlannerPlanPanel extends StatefulWidget {
  final CinePlannerController controller;
  const CinePlannerPlanPanel({super.key, required this.controller});
  @override
  State<CinePlannerPlanPanel> createState() => _CinePlannerPlanPanelState();
}

class _CinePlannerPlanPanelState extends State<CinePlannerPlanPanel> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _busy = false;
  final _reference = TextEditingController();
  final _key = TextEditingController();
  PickedFileData? _receipt;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reference.dispose();
    _key.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final response = await widget.controller.repository.client
          .get('/cineplanner/membership');
      if (mounted) {
        setState(() {
          _data = response['data'] as Map<String, dynamic>;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is ApiException ? e.message : '$e');
      }
    }
  }

  Future<void> _run(Future<void> Function() task) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await task();
      await _load();
      await widget.controller.refresh();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is ApiException ? e.message : '$e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickReceipt() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
        withData: true);
    if (!mounted || result == null || result.files.single.bytes == null) return;
    final file = result.files.single;
    final mime = switch (file.extension?.toLowerCase()) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg'
    };
    setState(() => _receipt =
        PickedFileData(name: file.name, mimeType: mime, bytes: file.bytes!));
  }

  @override
  Widget build(BuildContext context) {
    final access = _data?['access'] as Map<String, dynamic>? ?? {};
    final full = access['full_access'] == true;
    final payments =
        (_data?['payments'] as List? ?? []).cast<Map<String, dynamic>>();
    final pending = payments.any((p) => p['status'] == 'pending');
    return ListView(children: [
      Row(children: [
        Expanded(
            child: Text('CinePlanner Complete',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800))),
        IconButton(
            onPressed: _busy ? null : _load,
            tooltip: 'Refresh plan status',
            icon: const Icon(Icons.refresh))
      ]),
      const SizedBox(height: 8),
      const Text(
          'The complete screenplay workspace, from the first scene to the final shoot day.'),
      const SizedBox(height: 24),
      Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: context.appColors.goldGlow,
              borderRadius: BorderRadius.circular(20)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(r'$20 / month',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            const Text(
                'Full script breakdown • All production sections • PDF and spreadsheet reports • Scene editing through chat',
                style: TextStyle(height: 1.7)),
            const SizedBox(height: 12),
            const Text(
                '10 applied AI alterations per month. Each reviewed request counts once, even when it changes several fields. Questions, proposals, and undo do not use an alteration.'),
            const SizedBox(height: 12),
            const Text(
                'Bank transfer, approved by finance. One calendar month from approval; no automatic renewal. Your scripts and changes are retained when access expires.'),
            if (full) ...[
              const Divider(height: 28),
              Text(
                  access['unlimited_alterations'] == true
                      ? 'Private access active · Unlimited alterations'
                      : 'Plan active · ${access['alterations_remaining']} of 10 alterations remaining',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              if (access['expires_at'] != null)
                Text(
                    'Available until ${access['expires_at'].toString().split('T').first}')
            ],
          ])),
      if (_data == null && _error == null)
        const Padding(
            padding: EdgeInsets.all(20), child: LinearProgressIndicator()),
      if (_error != null)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error))),
      if (_data != null && !full && !pending) ...[
        const SizedBox(height: 24),
        const Text('Activate with bank transfer',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        SelectableText(
            '${access['payment_instructions'] ?? 'Contact support for transfer instructions.'}'),
        const SizedBox(height: 16),
        TextField(
            controller: _reference,
            maxLength: 160,
            decoration: const InputDecoration(
                labelText: 'Bank transfer reference',
                prefixIcon: Icon(Icons.receipt_long_outlined))),
        const SizedBox(height: 10),
        Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
                onPressed: _busy ? null : _pickReceipt,
                icon: const Icon(Icons.attach_file),
                label: Text(_receipt?.name ?? 'Attach payment receipt'))),
        const SizedBox(height: 10),
        Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
                onPressed: _busy || _receipt == null
                    ? null
                    : () => _run(() async {
                          if (_reference.text.trim().length < 3) {
                            throw const ApiException(
                                code: 'reference',
                                message: 'Enter the bank transfer reference.');
                          }
                          final uploaded = await widget
                              .controller.repository.uploads
                              .uploadFile(
                                  purpose: 'payment_proof', file: _receipt!);
                          await widget.controller.repository.client
                              .post('/cineplanner/membership/payments', body: {
                            'file_id': uploaded.publicId,
                            'reference': _reference.text.trim()
                          });
                          _reference.clear();
                          _receipt = null;
                        }),
                child: Text(
                    _busy ? 'Submitting…' : 'Submit for finance approval'))),
      ],
      if (pending)
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: ListTile(
                leading: Icon(Icons.hourglass_top),
                title: Text('Payment awaiting approval'),
                subtitle: Text(
                    'Finance will verify your transfer. Refresh here to check the decision.'))),
      if (payments.isNotEmpty) ...[
        const SizedBox(height: 22),
        const Text('Payment history',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ...payments.map((p) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${p['reference']} · USD 20'),
            subtitle: Text('${p['review_note'] ?? ''}'),
            trailing: Text('${p['status']}')))
      ],
      if (!full) ...[
        const SizedBox(height: 20),
        ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Have an access key?'),
            children: [
              TextField(
                  controller: _key,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration:
                      const InputDecoration(labelText: 'Private access key')),
              const SizedBox(height: 12),
              Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                                final value = _key.text;
                                _key.clear();
                                await widget.controller.repository.client.post(
                                    '/cineplanner/membership/unlock',
                                    body: {'key': value});
                              }),
                      child: const Text('Unlock access'))),
            ]),
      ],
    ]);
  }
}
