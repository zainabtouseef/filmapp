import '../network/api_client.dart';
import '../scheduling/meeting_models.dart';
import 'opportunities_models.dart';

class OpportunitiesRepository {
  final ApiClient _client;

  const OpportunitiesRepository(this._client);

  Future<OpportunityRolePage> roles({
    required String category,
    String? query,
    String? city,
    bool saved = false,
    int page = 1,
    int perPage = 24,
  }) async {
    final params = <String, String>{
      'category': category,
      'page': '$page',
      'per_page': '$perPage',
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
      if (saved) 'saved': '1',
    };
    final suffix = params.entries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');
    final response = await _client.get('/opportunities/roles?$suffix');
    final data = response['data'] as Map<String, dynamic>;
    final pagination = data['pagination'] as Map<String, dynamic>? ?? const {};
    return OpportunityRolePage(
      roles: (data['roles'] as List<dynamic>? ?? const [])
          .map((item) => OpportunityRole.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: pagination['page'] as int? ?? page,
      perPage: pagination['per_page'] as int? ?? perPage,
      total: pagination['total'] as int? ?? 0,
    );
  }

  Future<OpportunityRole> role(String publicId) async {
    final response = await _client.get('/opportunities/roles/$publicId');
    final data = response['data'] as Map<String, dynamic>;
    return OpportunityRole.fromJson(data['role'] as Map<String, dynamic>);
  }

  Future<OpportunityRole> saveRole(String publicId) async {
    final response = await _client.post('/opportunities/roles/$publicId/save');
    final data = response['data'] as Map<String, dynamic>;
    return OpportunityRole.fromJson(data['role'] as Map<String, dynamic>);
  }

  Future<void> unsaveRole(String publicId) {
    return _client.delete('/opportunities/roles/$publicId/save');
  }

  Future<OpportunityApplication> createApplication(
    String roleId, {
    required String coverNote,
    List<String> attachmentFileIds = const [],
    bool submit = true,
  }) async {
    final response = await _client.post(
      '/opportunities/roles/$roleId/applications',
      body: {
        'cover_note': coverNote,
        if (attachmentFileIds.isNotEmpty) 'attachment_file_ids': attachmentFileIds,
        'submit': submit,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return OpportunityApplication.fromJson(
      data['application'] as Map<String, dynamic>,
    );
  }

  Future<List<OpportunityApplication>> myApplications() async {
    final response = await _client.get('/opportunities/applications');
    final data = response['data'] as Map<String, dynamic>;
    return (data['applications'] as List<dynamic>? ?? const [])
        .map((item) =>
            OpportunityApplication.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<OpportunityApplication> withdrawApplication(String publicId) async {
    final response =
        await _client.post('/opportunities/applications/$publicId/withdraw');
    final data = response['data'] as Map<String, dynamic>;
    return OpportunityApplication.fromJson(
      data['application'] as Map<String, dynamic>,
    );
  }

  Future<OpportunityApplication> application(String publicId) async {
    final response = await _client.get('/opportunities/applications/$publicId');
    final data = response['data'] as Map<String, dynamic>;
    return OpportunityApplication.fromJson(
      data['application'] as Map<String, dynamic>,
    );
  }

  Future<List<OpportunityApplication>> directorApplications(
    String projectId,
  ) async {
    final response = await _client.get(
      '/director/projects/$projectId/opportunity-applications',
    );
    final data = response['data'] as Map<String, dynamic>;
    return (data['applications'] as List<dynamic>? ?? const [])
        .map((item) =>
            OpportunityApplication.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<OpportunityApplication> updateDirectorApplication(
    String publicId,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.patch(
      '/director/opportunity-applications/$publicId',
      body: body,
    );
    final data = response['data'] as Map<String, dynamic>;
    return OpportunityApplication.fromJson(
      data['application'] as Map<String, dynamic>,
    );
  }

  Future<MeetingThread?> meetings(String applicationId) async {
    final response = await _client.get(
      '/opportunities/applications/$applicationId/meetings',
    );
    final data = response['data'] as Map<String, dynamic>;
    return MeetingThread.fromJsonOrNull(
      data['thread'] as Map<String, dynamic>?,
    );
  }

  Future<OpportunityApplication> proposeMeeting(
    String applicationId,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      '/opportunities/applications/$applicationId/meetings/propose',
      body: body,
    );
    final data = response['data'] as Map<String, dynamic>;
    return OpportunityApplication.fromJson(
      data['application'] as Map<String, dynamic>,
    );
  }

  Future<OpportunityApplication> acceptMeetingRound(
    String applicationId,
    String roundId,
  ) async {
    final response = await _client.post(
      '/opportunities/applications/$applicationId/meetings/rounds/$roundId/accept',
    );
    final data = response['data'] as Map<String, dynamic>;
    return OpportunityApplication.fromJson(
      data['application'] as Map<String, dynamic>,
    );
  }

  Future<OpportunityApplication> declineMeetingRound(
    String applicationId,
    String roundId, {
    String? reason,
  }) async {
    final response = await _client.post(
      '/opportunities/applications/$applicationId/meetings/rounds/$roundId/decline',
      body: {if (reason != null) 'reason': reason},
    );
    final data = response['data'] as Map<String, dynamic>;
    return OpportunityApplication.fromJson(
      data['application'] as Map<String, dynamic>,
    );
  }

  Future<MeetingThread?> directorMeetings(String applicationId) async {
    final response = await _client.get(
      '/director/opportunity-applications/$applicationId/meetings',
    );
    final data = response['data'] as Map<String, dynamic>;
    return MeetingThread.fromJsonOrNull(
      data['thread'] as Map<String, dynamic>?,
    );
  }

  Future<OpportunityApplication> proposeDirectorMeeting(
    String applicationId,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      '/director/opportunity-applications/$applicationId/meetings/propose',
      body: body,
    );
    final data = response['data'] as Map<String, dynamic>;
    return OpportunityApplication.fromJson(
      data['application'] as Map<String, dynamic>,
    );
  }

  Future<OpportunityApplication> acceptDirectorMeetingRound(
    String applicationId,
    String roundId,
  ) async {
    final response = await _client.post(
      '/director/opportunity-applications/$applicationId/meetings/rounds/$roundId/accept',
    );
    final data = response['data'] as Map<String, dynamic>;
    return OpportunityApplication.fromJson(
      data['application'] as Map<String, dynamic>,
    );
  }

  Future<OpportunityApplication> declineDirectorMeetingRound(
    String applicationId,
    String roundId, {
    String? reason,
  }) async {
    final response = await _client.post(
      '/director/opportunity-applications/$applicationId/meetings/rounds/$roundId/decline',
      body: {if (reason != null) 'reason': reason},
    );
    final data = response['data'] as Map<String, dynamic>;
    return OpportunityApplication.fromJson(
      data['application'] as Map<String, dynamic>,
    );
  }
}
