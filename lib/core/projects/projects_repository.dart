import '../network/api_client.dart';
import 'project_models.dart';

class ProjectsRepository {
  final ApiClient _client;

  const ProjectsRepository(this._client);

  Future<List<ProjectSkill>> skills({String? category}) async {
    final suffix = category == null || category.isEmpty
        ? ''
        : '?category=${Uri.encodeComponent(category)}';
    final response = await _client.get('/skills$suffix');
    final data = response['data'] as Map<String, dynamic>;
    return (data['skills'] as List<dynamic>? ?? const [])
        .map((item) => ProjectSkill.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Project>> projects() async {
    final response = await _client.get('/projects');
    final data = response['data'] as Map<String, dynamic>;
    return (data['projects'] as List<dynamic>? ?? const [])
        .map((item) => Project.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Project> createProject({
    required String title,
    required String projectType,
    String? description,
    String? cityId,
    String? startDate,
    String? endDate,
    int? estimatedBudgetMinor,
    String currency = 'PKR',
    String status = 'active',
    String? coverFileId,
  }) async {
    final response = await _client.post(
      '/projects',
      body: {
        'title': title,
        'project_type': projectType,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
        if (cityId != null) 'city_id': cityId,
        if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
        if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
        if (estimatedBudgetMinor != null)
          'estimated_budget_minor': estimatedBudgetMinor,
        if (coverFileId != null && coverFileId.isNotEmpty)
          'cover_file_id': coverFileId,
        'currency': currency,
        'status': status,
        'visibility': 'project_members',
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return Project.fromJson(data['project'] as Map<String, dynamic>);
  }

  Future<Project> project(String publicId) async {
    final response = await _client.get('/projects/$publicId');
    final data = response['data'] as Map<String, dynamic>;
    return Project.fromJson(data['project'] as Map<String, dynamic>);
  }

  Future<List<ProjectRequirement>> requirements(String projectId) async {
    final response = await _client.get('/projects/$projectId/requirements');
    final data = response['data'] as Map<String, dynamic>;
    return (data['requirements'] as List<dynamic>? ?? const [])
        .map(
            (item) => ProjectRequirement.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ProjectRequirement> createRequirement({
    required String projectId,
    required String category,
    required String title,
    String? summary,
    int? budgetMinMinor,
    int? budgetMaxMinor,
    String currency = 'PKR',
    String? startDate,
    String? endDate,
    String status = 'open',
    List<String> skillIds = const [],
    String visibility = 'all',
    int quantity = 1,
    List<String> requiredDocuments = const [],
  }) async {
    final response = await _client.post(
      '/projects/$projectId/requirements',
      body: {
        'category': category,
        'title': title,
        if (summary != null && summary.trim().isNotEmpty)
          'summary': summary.trim(),
        if (budgetMinMinor != null) 'budget_min_minor': budgetMinMinor,
        if (budgetMaxMinor != null) 'budget_max_minor': budgetMaxMinor,
        'currency': currency,
        if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
        if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
        'status': status,
        if (skillIds.isNotEmpty) 'skills': skillIds,
        'visibility': visibility,
        'quantity': quantity,
        if (requiredDocuments.isNotEmpty) 'required_documents': requiredDocuments,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return ProjectRequirement.fromJson(
      data['requirement'] as Map<String, dynamic>,
    );
  }

  Future<ProjectRoom> room(String projectId) async {
    final response = await _client.get('/projects/$projectId/room');
    final data = response['data'] as Map<String, dynamic>;
    return ProjectRoom.fromJson(data['room'] as Map<String, dynamic>);
  }

  Future<ProjectRoomItem> createRoomItem({
    required String projectId,
    required String title,
    required String body,
    String itemType = 'decision',
    bool pinned = true,
  }) async {
    final response = await _client.post(
      '/projects/$projectId/room/items',
      body: {
        'item_type': itemType,
        'title': title,
        if (body.trim().isNotEmpty) 'body': body.trim(),
        'pinned': pinned,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return ProjectRoomItem.fromJson(data['item'] as Map<String, dynamic>);
  }

  Future<ProjectFile> linkProjectFile({
    required String projectId,
    required String fileId,
    required String label,
    String folder = 'briefs',
  }) async {
    final response = await _client.post(
      '/projects/$projectId/files',
      body: {
        'file_id': fileId,
        'label': label,
        'folder': folder,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return ProjectFile.fromJson(data['file'] as Map<String, dynamic>);
  }
}
