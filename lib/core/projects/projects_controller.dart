import 'package:flutter/widgets.dart';

import '../network/api_client.dart';
import 'project_models.dart';
import 'projects_repository.dart';

class ProjectsController extends ChangeNotifier {
  final ProjectsRepository _repository;

  List<Project>? _cachedProjects;

  ProjectsController({required ProjectsRepository repository})
      : _repository = repository;

  factory ProjectsController.fromClient(ApiClient client) {
    return ProjectsController(repository: ProjectsRepository(client));
  }

  List<Project>? get cachedProjects => _cachedProjects;

  Future<List<Project>> projects({bool force = false}) async {
    if (!force && _cachedProjects != null) return _cachedProjects!;
    final rows = await _repository.projects();
    _cachedProjects = rows;
    notifyListeners();
    return rows;
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
    String? coverFileId,
  }) async {
    final project = await _repository.createProject(
      title: title,
      projectType: projectType,
      description: description,
      cityId: cityId,
      startDate: startDate,
      endDate: endDate,
      estimatedBudgetMinor: estimatedBudgetMinor,
      currency: currency,
      coverFileId: coverFileId,
    );
    await projects(force: true);
    return project;
  }

  Future<Project> project(String publicId) {
    return _repository.project(publicId);
  }

  Future<List<ProjectSkill>> skills({String? category}) {
    return _repository.skills(category: category);
  }

  Future<List<ProjectRequirement>> requirements(String projectId) {
    return _repository.requirements(projectId);
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
    List<String> skillIds = const [],
    String visibility = 'all',
    int quantity = 1,
    List<String> requiredDocuments = const [],
  }) {
    return _repository.createRequirement(
      projectId: projectId,
      category: category,
      title: title,
      summary: summary,
      budgetMinMinor: budgetMinMinor,
      budgetMaxMinor: budgetMaxMinor,
      currency: currency,
      startDate: startDate,
      endDate: endDate,
      skillIds: skillIds,
      visibility: visibility,
      quantity: quantity,
      requiredDocuments: requiredDocuments,
    );
  }

  Future<ProjectRoom> room(String projectId) {
    return _repository.room(projectId);
  }

  Future<ProjectRoomItem> createRoomItem({
    required String projectId,
    required String title,
    required String body,
  }) {
    return _repository.createRoomItem(
      projectId: projectId,
      title: title,
      body: body,
    );
  }

  Future<ProjectFile> linkProjectFile({
    required String projectId,
    required String fileId,
    required String label,
    String folder = 'briefs',
  }) {
    return _repository.linkProjectFile(
      projectId: projectId,
      fileId: fileId,
      label: label,
      folder: folder,
    );
  }
}

class ProjectsScope extends InheritedNotifier<ProjectsController> {
  const ProjectsScope({
    super.key,
    required ProjectsController controller,
    required super.child,
  }) : super(notifier: controller);

  static ProjectsController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ProjectsScope>();
    assert(scope != null, 'ProjectsScope is missing from the widget tree');
    return scope!.notifier!;
  }

  static ProjectsController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ProjectsScope>()
        ?.notifier;
  }
}
