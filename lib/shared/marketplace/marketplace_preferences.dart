import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MarketplacePreferences {
  static const _prefix = 'cineconnect.marketplace.view.';
  final FlutterSecureStorage _storage;

  const MarketplacePreferences({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  Future<bool> usesGrid(String scope) async {
    return await _storage.read(key: '$_prefix$scope') == 'grid';
  }

  Future<void> setGrid(String scope, bool value) {
    return _storage.write(
      key: '$_prefix$scope',
      value: value ? 'grid' : 'list',
    );
  }
}
