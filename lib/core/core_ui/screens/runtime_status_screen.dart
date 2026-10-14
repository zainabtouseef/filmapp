import 'package:flutter/material.dart';
import '../../auth/auth_controller.dart';
import '../../network/open_url.dart';
import '../widgets/core_widgets.dart';

class RuntimeStatusScreen extends StatefulWidget {
  final bool maintenance;
  const RuntimeStatusScreen({super.key, required this.maintenance});
  @override
  State<RuntimeStatusScreen> createState() => _RuntimeStatusScreenState();
}

class _RuntimeStatusScreenState extends State<RuntimeStatusScreen> {
  Future<Map<String, dynamic>>? _future;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AuthScope.maybeOf(context)?.bootstrap() ??
        Future.error(StateError('Configuration unavailable'));
  }

  @override
  Widget build(BuildContext context) => CoreScreenScaffold(
      centerContent: true,
      child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const CircularProgressIndicator();
            }
            final data =
                snapshot.data?['data'] as Map<String, dynamic>? ?? const {};
            final state =
                data[widget.maintenance ? 'maintenance' : 'force_update']
                        as Map? ??
                    const {};
            final message = state['message']?.toString();
            final returnAt = state['return_at']?.toString();
            final url = state['store_url']?.toString();
            return Column(mainAxisSize: MainAxisSize.min, children: [
              CoreEmptyState(
                  icon: widget.maintenance
                      ? Icons.construction
                      : Icons.system_update_alt,
                  title: widget.maintenance
                      ? 'CineConnect maintenance'
                      : 'Update required',
                  message: message?.isNotEmpty == true
                      ? message!
                      : (widget.maintenance
                          ? 'Please check back for the latest availability.'
                          : 'A newer app version is required to continue.')),
              if (returnAt?.isNotEmpty == true)
                Text('Estimated return: $returnAt'),
              if (data['release_version'] != null)
                Text('Service release: ${data['release_version']}'),
              if (!widget.maintenance && url?.startsWith('https://') == true)
                CorePrimaryButton(
                    label: 'Open update page',
                    icon: Icons.open_in_new,
                    onTap: () async {
                      final opened = await openUrlInNewTab(url!);
                      if (!opened && context.mounted) {
                        showCoreSnack(
                            context, 'Could not open the update page');
                      }
                    }),
              if (snapshot.hasError)
                const InlineNotice(
                    message: 'Could not refresh the service configuration.'),
              TextButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context, '/', (_) => false),
                  child: const Text('Check again')),
            ]);
          }));
}
