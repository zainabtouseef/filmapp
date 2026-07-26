import '../network/api_client.dart';
import 'credit_models.dart';

class CreditsRepository {
  final ApiClient _client;

  const CreditsRepository(this._client);

  Future<List<CreditEntry>> list(String profileType) async {
    final response = await _client.get(
      '/credits?profile_type=${Uri.encodeQueryComponent(profileType)}',
    );
    final data = response['data'] as Map<String, dynamic>;
    return (data['items'] as List<dynamic>? ?? const [])
        .map((item) => CreditEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<CreditEntry> create({
    required String profileType,
    required String title,
    required String productionName,
    String? roleLabel,
    int? year,
    String? description,
    String? coverFileId,
  }) async {
    final response = await _client.post(
      '/credits',
      body: {
        'profile_type': profileType,
        'title': title,
        'production_name': productionName,
        if (roleLabel != null) 'role_label': roleLabel,
        if (year != null) 'year': year,
        if (description != null) 'description': description,
        if (coverFileId != null) 'cover_file_id': coverFileId,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return CreditEntry.fromJson(data['item'] as Map<String, dynamic>);
  }

  Future<CreditEntry> update(String publicId, Map<String, dynamic> body) async {
    final response = await _client.patch('/credits/$publicId', body: body);
    final data = response['data'] as Map<String, dynamic>;
    return CreditEntry.fromJson(data['item'] as Map<String, dynamic>);
  }

  Future<void> delete(String publicId) {
    return _client.delete('/credits/$publicId');
  }
}
