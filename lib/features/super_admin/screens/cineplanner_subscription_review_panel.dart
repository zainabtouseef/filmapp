import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/save_download.dart';

class CinePlannerSubscriptionReviewPanel extends StatefulWidget {
  final ApiClient client;
  const CinePlannerSubscriptionReviewPanel({super.key, required this.client});
  @override
  State<CinePlannerSubscriptionReviewPanel> createState() =>
      _CinePlannerSubscriptionReviewPanelState();
}

class _CinePlannerSubscriptionReviewPanelState
    extends State<CinePlannerSubscriptionReviewPanel> {
  List<Map<String, dynamic>>? _payments;
  String? _error;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response =
          await widget.client.get('/cineplanner/membership/review');
      if (mounted) {
        setState(() {
          _payments = ((response['data'] as Map)['payments'] as List)
              .cast<Map<String, dynamic>>();
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
    } catch (e) {
      if (mounted) {
        setState(() => _error = e is ApiException ? e.message : '$e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _review(Map<String, dynamic> payment, String decision) async {
    final note = TextEditingController();
    final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text(decision == 'approved'
                    ? 'Verify USD 20 received'
                    : 'Reject payment'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(decision == 'approved'
                      ? 'Approve ${payment['name']} for one month of Complete access and 10 alterations. Confirm the transfer against your bank records.'
                      : 'Explain why this receipt could not be approved.'),
                  const SizedBox(height: 14),
                  TextField(
                      controller: note,
                      maxLength: 2000,
                      minLines: 2,
                      maxLines: 4,
                      decoration:
                          const InputDecoration(labelText: 'Review note'))
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, note.text.trim()),
                      child: Text(decision == 'approved'
                          ? 'Approve payment'
                          : 'Reject payment'))
                ]));
    note.dispose();
    if (result == null || !mounted) return;
    await _run(() async {
      await widget.client.post(
          '/cineplanner/membership/review/${payment['public_id']}',
          body: {'decision': decision, 'note': result});
    });
  }

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Expanded(
              child: Text('CinePlanner subscriptions',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700))),
          IconButton(
              onPressed: _busy ? null : _load,
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh)),
          IconButton(
              onPressed: () => Navigator.pop(context),
              tooltip: 'Close',
              icon: const Icon(Icons.close))
        ]),
        const Text(
            'USD 20 · One calendar month · 10 alterations · Manual bank verification'),
        const SizedBox(height: 14),
        if (_busy) const LinearProgressIndicator(),
        if (_error != null)
          Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error))),
        Expanded(
            child: _payments == null
                ? const Center(child: CircularProgressIndicator())
                : _payments!.isEmpty
                    ? const Center(child: Text('No subscription receipts yet.'))
                    : ListView.builder(
                        itemCount: _payments!.length,
                        itemBuilder: (context, i) {
                          final p = _payments![i];
                          return Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('${p['name']} · USD 20',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700)),
                                        SelectableText(
                                            'Reference: ${p['reference']}'),
                                        Text(
                                            '${p['status']} · ${p['created_at'].toString().split('T').first}'),
                                        if (p['review_note'] != null)
                                          Text('${p['review_note']}'),
                                        const SizedBox(height: 8),
                                        Wrap(spacing: 8, children: [
                                          OutlinedButton.icon(
                                              onPressed: _busy
                                                  ? null
                                                  : () => _run(() async {
                                                        final d = await widget
                                                            .client
                                                            .getBytes(
                                                                '/files/${p['proof_file_id']}/download');
                                                        await saveDownload(
                                                            d.filename,
                                                            d.bytes,
                                                            d.contentType);
                                                      }),
                                              icon: const Icon(
                                                  Icons.receipt_long),
                                              label:
                                                  const Text('View receipt')),
                                          if (p['status'] == 'pending') ...[
                                            FilledButton(
                                                onPressed: _busy
                                                    ? null
                                                    : () =>
                                                        _review(p, 'approved'),
                                                child: const Text('Approve')),
                                            TextButton(
                                                onPressed: _busy
                                                    ? null
                                                    : () =>
                                                        _review(p, 'rejected'),
                                                child: const Text('Reject'))
                                          ],
                                        ]),
                                      ])));
                        })),
      ]);
}
