import '../network/api_client.dart';
import 'analytics_models.dart';

class AnalyticsRepository {
  final ApiClient _client;

  const AnalyticsRepository(this._client);

  Future<PersonalDashboardDto> personalDashboard() async {
    final response = await _client.get('/me/dashboard');
    return PersonalDashboardDto.fromJson(
      response['data'] as Map<String, dynamic>,
    );
  }

  Future<AdminDashboardDto> adminDashboard() async {
    final response = await _client.get('/admin/dashboard');
    return AdminDashboardDto.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<AdminAnalyticsDto> adminAnalytics({int days = 30}) async {
    final response = await _client.get('/admin/analytics?days=$days');
    return AdminAnalyticsDto.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<ExportJobDto> createExport(
    String exportType, {
    Map<String, dynamic> filters = const {},
  }) async {
    final response = await _client.post(
      '/exports',
      body: {'export_type': exportType, 'filters': filters},
    );
    return ExportJobDto.fromJson(
      (response['data'] as Map<String, dynamic>)['export']
          as Map<String, dynamic>,
    );
  }

  Future<List<ExportJobDto>> exports() async {
    final response = await _client.get('/exports');
    final data = response['data'] as Map<String, dynamic>;
    return (data['exports'] as List<dynamic>? ?? const [])
        .map((item) => ExportJobDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ExportJobDto> export(String exportId) async {
    final response = await _client.get('/exports/$exportId');
    return ExportJobDto.fromJson(
      (response['data'] as Map<String, dynamic>)['export']
          as Map<String, dynamic>,
    );
  }
}
