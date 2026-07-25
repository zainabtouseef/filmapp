import '../network/api_client.dart';
import 'casting_models.dart';

class CastingRepository {
  final ApiClient _client;

  const CastingRepository(this._client);

  Future<CastingRolePage> roles({
    String? query,
    String? city,
    String? auditionMode,
    bool saved = false,
    int page = 1,
    int perPage = 24,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
      if (auditionMode != null && auditionMode.trim().isNotEmpty)
        'audition_mode': auditionMode.trim(),
      if (saved) 'saved': '1',
    };
    final suffix = params.entries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');
    final response = await _client.get('/casting/roles?$suffix');
    final data = response['data'] as Map<String, dynamic>;
    final pagination = data['pagination'] as Map<String, dynamic>? ?? const {};
    return CastingRolePage(
      roles: (data['roles'] as List<dynamic>? ?? const [])
          .map((item) => CastingRole.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: pagination['page'] as int? ?? page,
      perPage: pagination['per_page'] as int? ?? perPage,
      total: pagination['total'] as int? ?? 0,
    );
  }

  Future<CastingRole> role(String publicId) async {
    final response = await _client.get('/casting/roles/$publicId');
    final data = response['data'] as Map<String, dynamic>;
    return CastingRole.fromJson(data['role'] as Map<String, dynamic>);
  }

  Future<CastingRole> saveRole(String publicId) async {
    final response = await _client.post('/casting/roles/$publicId/save');
    final data = response['data'] as Map<String, dynamic>;
    return CastingRole.fromJson(data['role'] as Map<String, dynamic>);
  }

  Future<void> unsaveRole(String publicId) {
    return _client.delete('/casting/roles/$publicId/save');
  }

  Future<CastingRole> publishRole(
    String publicId,
    Map<String, dynamic> body,
  ) async {
    final response =
        await _client.patch('/casting/roles/$publicId', body: body);
    final data = response['data'] as Map<String, dynamic>;
    return CastingRole.fromJson(data['role'] as Map<String, dynamic>);
  }

  Future<CastingApplication> createApplication(
    String roleId, {
    required String coverNote,
    required String availabilityNote,
    required Map<String, String> answers,
    required List<String> portfolioItemIds,
    String? selfTapeFileId,
    bool submit = false,
  }) async {
    final response = await _client.post(
      '/casting/roles/$roleId/applications',
      body: {
        'cover_note': coverNote,
        'availability_note': availabilityNote,
        'answers': answers,
        'portfolio_item_ids': portfolioItemIds,
        if (selfTapeFileId != null) 'self_tape_file_id': selfTapeFileId,
        'submit': submit,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return CastingApplication.fromJson(
      data['application'] as Map<String, dynamic>,
    );
  }

  Future<List<CastingApplication>> actorApplications({
    String? status,
  }) async {
    final suffix = status == null || status.isEmpty
        ? ''
        : '?status=${Uri.encodeQueryComponent(status)}';
    final response = await _client.get('/casting/applications$suffix');
    final data = response['data'] as Map<String, dynamic>;
    return (data['applications'] as List<dynamic>? ?? const [])
        .map(
          (item) => CastingApplication.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<CastingApplication> application(String publicId) async {
    final response = await _client.get('/casting/applications/$publicId');
    final data = response['data'] as Map<String, dynamic>;
    return CastingApplication.fromJson(
      data['application'] as Map<String, dynamic>,
    );
  }

  Future<CastingApplication> updateApplication(
    String publicId,
    Map<String, dynamic> body,
  ) async {
    final response =
        await _client.patch('/casting/applications/$publicId', body: body);
    final data = response['data'] as Map<String, dynamic>;
    return CastingApplication.fromJson(
      data['application'] as Map<String, dynamic>,
    );
  }

  Future<CastingApplication> submitApplication(String publicId) {
    return _applicationAction(publicId, 'submit');
  }

  Future<CastingApplication> withdrawApplication(String publicId) {
    return _applicationAction(publicId, 'withdraw');
  }

  Future<CastingApplication> confirmAudition(String publicId) {
    return _applicationAction(publicId, 'confirm-audition');
  }

  Future<CastingApplication> submitSelfTape(
    String publicId,
    String fileId,
  ) async {
    final response = await _client.post(
      '/casting/applications/$publicId/self-tape',
      body: {'file_id': fileId},
    );
    final data = response['data'] as Map<String, dynamic>;
    return CastingApplication.fromJson(
      data['application'] as Map<String, dynamic>,
    );
  }

  Future<String> ensureConversation(String publicId) async {
    final response =
        await _client.post('/casting/applications/$publicId/conversation');
    final data = response['data'] as Map<String, dynamic>;
    return data['conversation_id'] as String;
  }

  Future<List<CastingApplication>> directorApplications(
    String projectId,
  ) async {
    final response = await _client.get(
      '/director/projects/$projectId/casting-applications',
    );
    final data = response['data'] as Map<String, dynamic>;
    return (data['applications'] as List<dynamic>? ?? const [])
        .map(
          (item) => CastingApplication.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<CastingApplication> updateDirectorApplication(
    String publicId,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.patch(
      '/director/casting-applications/$publicId',
      body: body,
    );
    final data = response['data'] as Map<String, dynamic>;
    return CastingApplication.fromJson(
      data['application'] as Map<String, dynamic>,
    );
  }

  Future<CastingApplication> _applicationAction(
    String publicId,
    String action,
  ) async {
    final response =
        await _client.post('/casting/applications/$publicId/$action');
    final data = response['data'] as Map<String, dynamic>;
    return CastingApplication.fromJson(
      data['application'] as Map<String, dynamic>,
    );
  }
}
