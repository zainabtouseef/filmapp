import '../network/api_client.dart';
import 'director_dashboard_models.dart';
import 'director_discovery_models.dart';

class DirectorRepository {
  final ApiClient _client;

  const DirectorRepository(this._client);

  Future<DirectorDashboard> dashboard() async {
    final response = await _client.get('/director/dashboard');
    final data = response['data'] as Map<String, dynamic>;
    return DirectorDashboard.fromJson(
      data['dashboard'] as Map<String, dynamic>,
    );
  }

  Future<DirectorSchedule> schedule({String? projectId}) async {
    final suffix = projectId == null ? '' : '?project_id=$projectId';
    final response = await _client.get('/director/schedule$suffix');
    final data = response['data'] as Map<String, dynamic>;
    return DirectorSchedule.fromJson(
      data['schedule'] as Map<String, dynamic>,
    );
  }

  Future<DirectorDiscoveryBundle> discovery({
    String? category,
    String? query,
  }) async {
    final params = <String, String>{};
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (query != null && query.isNotEmpty) params['q'] = query;
    final suffix = params.isEmpty
        ? ''
        : '?${params.entries.map((item) => '${item.key}=${Uri.encodeComponent(item.value)}').join('&')}';
    final response = await _client.get('/director/discovery$suffix');
    final data = response['data'] as Map<String, dynamic>;
    return DirectorDiscoveryBundle.fromJson(
      data['discovery'] as Map<String, dynamic>,
    );
  }

  Future<DirectorDiscoveryItem> discoveryItem({
    required String kind,
    required String publicId,
  }) async {
    final response = await _client.get(
      '/director/discovery/${Uri.encodeComponent(kind)}/${Uri.encodeComponent(publicId)}',
    );
    final data = response['data'] as Map<String, dynamic>;
    return DirectorDiscoveryItem.fromJson(data['item'] as Map<String, dynamic>);
  }
}
