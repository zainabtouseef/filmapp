import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists which self-navigation tours a user has already seen, so a
/// portal only auto-shows its tour once. Mirrors the shape of
/// `lib/core/auth/token_store.dart`.
class TourPreferencesStore {
  static const _keyPrefix = 'cineconnect.tour_seen.';

  final FlutterSecureStorage _storage;

  const TourPreferencesStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  Future<bool> hasSeenTour(String tourId) async {
    final value = await _storage.read(key: '$_keyPrefix$tourId');
    return value == 'true';
  }

  Future<void> markSeen(String tourId) {
    return _storage.write(key: '$_keyPrefix$tourId', value: 'true');
  }

  Future<void> reset(String tourId) {
    return _storage.delete(key: '$_keyPrefix$tourId');
  }
}
