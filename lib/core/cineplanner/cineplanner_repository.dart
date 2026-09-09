import '../network/api_client.dart';
import '../uploads/upload_repository.dart';

class CinePlannerRepository {
  final ApiClient client;
  final UploadRepository uploads;

  CinePlannerRepository(this.client) : uploads = UploadRepository(client);

  Future<List<Map<String, dynamic>>> productions() async {
    final response = await client.get('/cineplanner/productions');
    final data = response['data'] as Map<String, dynamic>;
    return (data['productions'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createProduction({
    required String title,
    String? projectId,
    String? startDate,
    int maximumShootDays = 30,
    int workingHoursLimit = 12,
    int? budgetCeilingMinor,
    String currency = 'PKR',
  }) async {
    final response = await client.post(
      '/cineplanner/productions',
      body: {
        'title': title,
        if (projectId != null && projectId.isNotEmpty) 'project_id': projectId,
        if (startDate != null && startDate.isNotEmpty)
          'production_start_date': startDate,
        'maximum_shoot_days': maximumShootDays,
        'working_hours_limit': workingHoursLimit,
        if (budgetCeilingMinor != null)
          'budget_ceiling_minor': budgetCeilingMinor,
        'currency': currency,
      },
    );
    return (response['data'] as Map<String, dynamic>)['production']
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> production(String publicId) async {
    final response = await client.get('/cineplanner/productions/$publicId');
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadScreenplay({
    required String productionId,
    required PickedFileData file,
    required String label,
    void Function(int sent, int total)? onProgress,
    void Function(String status)? onStatus,
  }) async {
    final uploaded = await uploads.uploadFile(
      purpose: 'screenplay',
      file: file,
      onProgress: onProgress,
      onStatus: onStatus,
    );
    onStatus?.call('Starting secure screenplay analysis...');
    final response = await client.post(
      '/cineplanner/productions/$productionId/scripts',
      body: {'file_id': uploaded.publicId, 'label': label},
    );
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> job(
    String productionId,
    String jobId,
  ) async {
    final response = await client.get(
      '/cineplanner/productions/$productionId/jobs/$jobId',
    );
    return (response['data'] as Map<String, dynamic>)['job']
        as Map<String, dynamic>;
  }

  Future<void> retryJob(String productionId, String jobId) async {
    await client.post(
      '/cineplanner/productions/$productionId/jobs/$jobId/retry',
    );
  }

  Future<void> approveBreakdown(String productionId) async {
    await client.post(
      '/cineplanner/productions/$productionId/approve-breakdown',
    );
  }

  Future<void> updateItem({
    required String productionId,
    required String resource,
    required String itemId,
    required Map<String, dynamic> values,
  }) async {
    await client.patch(
      '/cineplanner/productions/$productionId/$resource/$itemId',
      body: values,
    );
  }

  Future<void> createActor(Map<String, dynamic> values) async {
    await client.post('/cineplanner/actors', body: values);
  }

  Future<void> addActorAvailability({
    required String actorId,
    required Map<String, dynamic> values,
  }) async {
    await client.post(
      '/cineplanner/actors/$actorId/availability',
      body: values,
    );
  }

  Future<void> assignActor({
    required String productionId,
    required String characterId,
    required String actorId,
    required String status,
  }) async {
    await client.post(
      '/cineplanner/productions/$productionId/cast-assignments',
      body: {
        'character_id': characterId,
        'actor_id': actorId,
        'status': status,
      },
    );
  }

  Future<void> createLocation({
    required String productionId,
    required Map<String, dynamic> values,
  }) async {
    await client.post(
      '/cineplanner/productions/$productionId/locations',
      body: values,
    );
  }

  Future<void> createElement({
    required String productionId,
    required Map<String, dynamic> values,
  }) async {
    await client.post(
      '/cineplanner/productions/$productionId/elements',
      body: values,
    );
  }

  Future<void> createCrewMember({
    required String productionId,
    required Map<String, dynamic> values,
  }) async {
    await client.post(
      '/cineplanner/productions/$productionId/crew',
      body: values,
    );
  }

  Future<Map<String, dynamic>> generateSchedule({
    required String productionId,
    String? strategy,
    bool apply = false,
  }) async {
    final response = await client.post(
      '/cineplanner/productions/$productionId/schedule/generate',
      body: {
        if (strategy != null) 'strategy': strategy,
        'apply': apply,
      },
    );
    return response['data'] as Map<String, dynamic>;
  }

  Future<void> moveScheduleEvent({
    required String productionId,
    required String eventId,
    required String shootDayId,
    required String startsAt,
    required String endsAt,
  }) async {
    await client.patch(
      '/cineplanner/productions/$productionId/schedule/events/$eventId',
      body: {
        'shoot_day_id': shootDayId,
        'starts_at': startsAt,
        'ends_at': endsAt,
      },
    );
  }

  Future<Map<String, dynamic>> optimizeSchedule({
    required String productionId,
    bool apply = false,
  }) async {
    final response = await client.post(
      '/cineplanner/productions/$productionId/schedule/optimize',
      body: {'apply': apply},
    );
    return response['data'] as Map<String, dynamic>;
  }

  Future<void> lockSchedule(String productionId, bool locked) async {
    await client.post(
      '/cineplanner/productions/$productionId/schedule/lock',
      body: {'locked': locked},
    );
  }

  Future<void> updateBudgetLine({
    required String productionId,
    required String lineId,
    required Map<String, dynamic> values,
  }) async {
    await client.patch(
      '/cineplanner/productions/$productionId/budget/$lineId',
      body: values,
    );
  }

  Future<Map<String, dynamic>> generateCallSheet({
    required String productionId,
    required String shootDayId,
  }) async {
    final response = await client.post(
      '/cineplanner/productions/$productionId/call-sheets',
      body: {'shoot_day_id': shootDayId},
    );
    return (response['data'] as Map<String, dynamic>)['call_sheet']
        as Map<String, dynamic>;
  }

  Future<ApiDownload> downloadCallSheet({
    required String productionId,
    required String callSheetId,
  }) {
    return client.getBytes(
      '/cineplanner/productions/$productionId/call-sheets/$callSheetId.pdf',
      fallbackFilename: 'cineplanner-call-sheet.pdf',
    );
  }

  Future<List<Map<String, dynamic>>> report({
    required String productionId,
    required String reportType,
  }) async {
    final response = await client.get(
      '/cineplanner/productions/$productionId/reports/$reportType',
    );
    final data = response['data'] as Map<String, dynamic>;
    return (data['rows'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
  }

  Future<ApiDownload> downloadReport({
    required String productionId,
    required String reportType,
    required String format,
  }) {
    return client.getBytes(
      '/cineplanner/productions/$productionId/reports/$reportType.$format',
      fallbackFilename: 'cineplanner-$reportType.$format',
    );
  }

  Future<Map<String, dynamic>> ask({
    required String productionId,
    required String question,
  }) async {
    final response = await client.post(
      '/cineplanner/productions/$productionId/assistant',
      body: {'question': question},
    );
    return response['data'] as Map<String, dynamic>;
  }
}
