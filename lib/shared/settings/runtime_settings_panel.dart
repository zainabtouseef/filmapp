import 'package:flutter/material.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/core_ui/widgets/core_widgets.dart';

class RuntimeSettingsPanel extends StatefulWidget {
  const RuntimeSettingsPanel({super.key});
  @override
  State<RuntimeSettingsPanel> createState() => _RuntimeSettingsPanelState();
}

class _RuntimeSettingsPanelState extends State<RuntimeSettingsPanel> {
  bool _started = false, _loading = true, _saving = false;
  bool _maintenance = false, _forceUpdate = false;
  String? _error;
  final _message = TextEditingController();
  final _returnAt = TextEditingController();
  final _storeUrl = TextEditingController();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _load();
    }
  }

  @override
  void dispose() {
    _message.dispose();
    _returnAt.dispose();
    _storeUrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final auth = AuthScope.maybeOf(context);
      if (auth == null) throw StateError('Sign in as Super Admin');
      final response = await auth.apiClient.get('/admin/app-settings');
      final data = response['data'] as Map<String, dynamic>;
      final maintenance = data['maintenance'] as Map;
      final update = data['force_update'] as Map;
      if (!mounted) return;
      setState(() {
        _maintenance = maintenance['enabled'] == true;
        _forceUpdate = update['required'] == true;
        _message.text = maintenance['message']?.toString() ?? '';
        _returnAt.text = maintenance['return_at']?.toString() ?? '';
        _storeUrl.text = update['store_url']?.toString() ?? '';
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '$error';
        });
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await AuthScope.of(context).apiClient.patch('/admin/app-settings', body: {
        'maintenance': {
          'enabled': _maintenance,
          'message': _message.text.trim(),
          'return_at': _returnAt.text.trim()
        },
        'force_update': {
          'required': _forceUpdate,
          'store_url': _storeUrl.text.trim()
        },
      });
      if (mounted) showCoreSnack(context, 'Runtime settings saved online');
    } catch (error) {
      if (mounted) showCoreSnack(context, 'Settings were not saved: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LinearProgressIndicator();
    if (_error != null) {
      return InlineNotice(message: 'Runtime configuration: $_error');
    }
    return CoreGlassCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionLabel(text: 'App availability and updates'),
      const SizedBox(height: 8),
      const Text(
          'These settings are read at startup by every client. Enabling maintenance affects sign-in routing.'),
      SwitchListTile(
          title: const Text('Maintenance mode'),
          value: _maintenance,
          onChanged: _saving ? null : (v) => setState(() => _maintenance = v)),
      CoreTextField(
          controller: _message,
          label: 'Maintenance message',
          icon: Icons.message_outlined),
      const SizedBox(height: 10),
      CoreTextField(
          controller: _returnAt,
          label: 'Estimated return (ISO date/time, optional)',
          icon: Icons.schedule_outlined),
      SwitchListTile(
          title: const Text('Require app update'),
          value: _forceUpdate,
          onChanged: _saving ? null : (v) => setState(() => _forceUpdate = v)),
      CoreTextField(
          controller: _storeUrl, label: 'HTTPS update URL', icon: Icons.link),
      const SizedBox(height: 12),
      CorePrimaryButton(
          label: 'Save runtime settings',
          icon: Icons.save_outlined,
          loading: _saving,
          onTap: _saving ? null : _save),
    ]));
  }
}
