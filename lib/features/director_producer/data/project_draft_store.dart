import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists an in-progress "Create Project" form so it survives the user
/// leaving the screen (navigating away, backgrounding the app, an upload
/// failing mid-way) — cleared only on explicit Cancel or a successful
/// Create Project.
class ProjectDraftStore {
  static const _key = 'cineconnect.create_project.draft';

  final FlutterSecureStorage _storage;

  const ProjectDraftStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  Future<void> save(Map<String, dynamic> draft) {
    return _storage.write(key: _key, value: jsonEncode(draft));
  }

  Future<Map<String, dynamic>?> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() => _storage.delete(key: _key);
}
