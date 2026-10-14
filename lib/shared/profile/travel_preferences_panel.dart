import 'package:flutter/material.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/core_ui/widgets/core_widgets.dart';
import '../../core/profile/profile_models.dart';

class TravelPreferencesPanel extends StatefulWidget {
  const TravelPreferencesPanel({super.key});
  @override
  State<TravelPreferencesPanel> createState() => _TravelPreferencesPanelState();
}

class _TravelPreferencesPanelState extends State<TravelPreferencesPanel> {
  bool _started = false, _loading = true, _saving = false, _willing = false;
  String? _error;
  List<ProfileCity> _cities = const [];
  final Set<String> _selected = {};
  final _radius = TextEditingController();
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
    _radius.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final auth = AuthScope.maybeOf(context);
      if (auth == null) {
        throw StateError('Sign in to manage travel preferences');
      }
      final response = await auth.apiClient.get('/talent/travel-preferences');
      final cities = await auth.cities();
      final data = response['data'] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _cities = cities;
        _willing = data['willing_to_travel'] == true;
        _radius.text = '${data['radius_km'] ?? 0}';
        _selected.addAll(
            (data['city_ids'] as List<dynamic>? ?? const []).cast<String>());
        _loading = false;
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
      await AuthScope.of(context)
          .apiClient
          .patch('/talent/travel-preferences', body: {
        'willing_to_travel': _willing,
        'radius_km': int.tryParse(_radius.text),
        'city_ids': _selected.toList(),
      });
      if (mounted) showCoreSnack(context, 'Travel preferences saved online');
    } catch (error) {
      if (mounted) {
        showCoreSnack(context, 'Travel preferences were not saved: $error');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LinearProgressIndicator();
    if (_error != null) return InlineNotice(message: _error!);
    return Column(children: [
      SwitchListTile(
          title: const Text('Willing to travel'),
          value: _willing,
          onChanged: (value) => setState(() => _willing = value)),
      CoreTextField(
          controller: _radius,
          label: 'Travel radius (km, 0-1000)',
          icon: Icons.route,
          keyboardType: TextInputType.number),
      Wrap(
          spacing: 8,
          children: _cities
              .map((city) => FilterChip(
                  label: Text(city.name),
                  selected: _selected.contains(city.publicId),
                  onSelected: (value) => setState(() {
                        if (value) {
                          _selected.add(city.publicId);
                        } else {
                          _selected.remove(city.publicId);
                        }
                      })))
              .toList()),
      const SizedBox(height: 10),
      CorePrimaryButton(
          label: 'Save travel preferences',
          icon: Icons.save_outlined,
          loading: _saving,
          onTap: _saving ? null : _save),
    ]);
  }
}
