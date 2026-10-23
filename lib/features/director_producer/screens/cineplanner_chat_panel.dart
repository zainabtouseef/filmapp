import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/cineplanner/cineplanner_controller.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/save_download.dart';
import '../../../core/theme/app_color_scheme.dart';

class CinePlannerChatPanel extends StatefulWidget {
  final String productionId;
  final CinePlannerController controller;
  const CinePlannerChatPanel(
      {super.key, required this.productionId, required this.controller});
  @override
  State<CinePlannerChatPanel> createState() => _CinePlannerChatPanelState();
}

class _CinePlannerChatPanelState extends State<CinePlannerChatPanel> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  Timer? _timer;
  bool _busy = false, _loading = true, _fetching = false;
  String? _error, _scene;
  String get _path => '/cineplanner/productions/${widget.productionId}';
  bool get _pending =>
      _messages.any((m) => ['queued', 'processing'].contains(m['status']));
  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_pending) _load();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_fetching) return;
    _fetching = true;
    try {
      final data = await widget.controller.repository.client
          .get('$_path/assistant/messages');
      if (mounted) {
        setState(() {
          _messages = ((data['data'] as Map)['messages'] as List)
              .cast<Map<String, dynamic>>();
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is ApiException ? e.message : '$e';
          _loading = false;
        });
      }
    } finally {
      _fetching = false;
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
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is ApiException ? e.message : '$e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() => _run(() async {
        final value = _input.text.trim();
        if (value.length < 3) return;
        await widget.controller.repository.client.post(
            '$_path/assistant/messages',
            body: {'question': value, if (_scene != null) 'scene_id': _scene});
        _input.clear();
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent + 300,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut);
        }
      });
  Future<void> _decision(Map<String, dynamic> message, String action) =>
      _run(() async {
        await widget.controller.repository.client
            .post('$_path/assistant/messages/${message['public_id']}/$action');
        await widget.controller.refresh();
      });
  String _value(dynamic value) => value is String
      ? value
      : const JsonEncoder.withIndent('  ').convert(value);
  @override
  Widget build(BuildContext context) {
    final scenes = (widget.controller.snapshot?['scenes'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final access =
        widget.controller.snapshot?['access'] as Map<String, dynamic>? ?? {};
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Script studio',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                          final download = await widget
                              .controller.repository.client
                              .getBytes('$_path/screenplay.pdf');
                          await saveDownload(download.filename, download.bytes,
                              download.contentType);
                        }),
                icon: const Icon(Icons.download_outlined),
                label: const Text('Working draft')),
          ]),
      Text(access['unlimited_alterations'] == true
          ? 'Private access · Unlimited alterations'
          : '${access['alterations_remaining'] ?? 0} alterations remaining this month'),
      const SizedBox(height: 8),
      const Text(
          'Ask, review, then apply. Only the fields in your proposal change. Questions and undo do not use an alteration.',
          style: TextStyle(fontSize: 12)),
      const Divider(height: 24),
      if (_loading) const LinearProgressIndicator(),
      Expanded(
          child: _messages.isEmpty && !_loading
              ? ListView(children: [
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Text('What would you like to improve?',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w700))),
                  for (final prompt in [
                    'Improve the dialogue in the selected scene while preserving its plot.',
                    'Check the selected scene for continuity issues before proposing changes.',
                    'Add a short new scene. Ask me for its purpose and placement first.'
                  ])
                    Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: OutlinedButton(
                            onPressed: () =>
                                setState(() => _input.text = prompt),
                            child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(prompt)))),
                ])
              : ListView.builder(
                  controller: _scroll,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final user = message['role'] == 'user';
                    final changes = (message['changes'] as List? ?? [])
                        .cast<Map<String, dynamic>>();
                    return Container(
                        margin: EdgeInsets.only(
                            bottom: 14,
                            left: user ? 28 : 0,
                            right: user ? 0 : 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: user
                                ? context.appColors.goldGlow
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16)),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  user
                                      ? 'You'
                                      : 'CinePlanner · ${message['status']}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12)),
                              const SizedBox(height: 8),
                              SelectableText('${message['content']}',
                                  style: const TextStyle(height: 1.5)),
                              if (['queued', 'processing']
                                  .contains(message['status']))
                                const Padding(
                                    padding: EdgeInsets.only(top: 12),
                                    child: LinearProgressIndicator()),
                              if (changes.isNotEmpty)
                                ExpansionTile(
                                    tilePadding: EdgeInsets.zero,
                                    title: Text(
                                        'Review ${changes.length} proposed item${changes.length == 1 ? '' : 's'}'),
                                    children: changes.map((change) {
                                      final after = change['after'] as Map;
                                      final before = change['before'] as Map;
                                      return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 14),
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Text(
                                                    '${change['action']} · ${change['resource']}',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700)),
                                                for (final entry
                                                    in after.entries)
                                                  Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 12),
                                                      child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                                '${entry.key}'
                                                                    .replaceAll(
                                                                        '_json',
                                                                        '')
                                                                    .replaceAll(
                                                                        '_',
                                                                        ' '),
                                                                style: const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600)),
                                                            if (before
                                                                .containsKey(entry
                                                                    .key)) ...[
                                                              const Text(
                                                                  'Current',
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          11)),
                                                              SelectableText(
                                                                  _value(before[
                                                                      entry
                                                                          .key]))
                                                            ],
                                                            const SizedBox(
                                                                height: 6),
                                                            const Text(
                                                                'Proposed',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        11)),
                                                            SelectableText(
                                                                _value(entry
                                                                    .value))
                                                          ])),
                                              ]));
                                    }).toList()),
                              if (message['status'] == 'proposed')
                                Wrap(spacing: 8, children: [
                                  FilledButton(
                                      onPressed: _busy
                                          ? null
                                          : () => _decision(message, 'apply'),
                                      child:
                                          const Text('Apply · 1 alteration')),
                                  TextButton(
                                      onPressed: _busy
                                          ? null
                                          : () => _decision(message, 'discard'),
                                      child: const Text('Discard'))
                                ]),
                              if (message['status'] == 'applied')
                                TextButton.icon(
                                    onPressed: _busy
                                        ? null
                                        : () => _decision(message, 'undo'),
                                    icon: const Icon(Icons.undo),
                                    label: const Text('Undo these changes')),
                            ]));
                  })),
      if (_error != null)
        Row(children: [
          Expanded(
              child: Text(_error!,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error))),
          IconButton(
              onPressed: _load,
              tooltip: 'Refresh conversation',
              icon: const Icon(Icons.refresh))
        ]),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
          initialValue: _scene,
          isExpanded: true,
          decoration: const InputDecoration(
              labelText: 'Focus scene (optional)', isDense: true),
          items: [
            const DropdownMenuItem(
                value: null,
                child: Text('Find relevant scenes from my request')),
            ...scenes.map((s) => DropdownMenuItem(
                value: s['public_id'] as String,
                child: Text('${s['scene_number']} · ${s['slugline']}',
                    overflow: TextOverflow.ellipsis)))
          ],
          onChanged:
              _busy || _pending ? null : (v) => setState(() => _scene = v)),
      const SizedBox(height: 10),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
            child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 4,
                maxLength: 8000,
                decoration: const InputDecoration(
                    hintText: 'Describe the change or ask a question…',
                    counterText: ''),
                onChanged: (_) => setState(() {}))),
        const SizedBox(width: 8),
        IconButton.filled(
            onPressed: _busy || _pending || _input.text.trim().length < 3
                ? null
                : _send,
            tooltip: 'Send request',
            icon: Icon(_pending ? Icons.hourglass_top : Icons.arrow_upward))
      ]),
    ]);
  }
}
