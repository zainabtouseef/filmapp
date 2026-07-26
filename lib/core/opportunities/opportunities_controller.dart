import 'package:flutter/widgets.dart';

import '../network/api_client.dart';
import '../scheduling/meeting_models.dart';
import 'opportunities_models.dart';
import 'opportunities_repository.dart';

class OpportunitiesController extends ChangeNotifier {
  final OpportunitiesRepository _repository;

  OpportunitiesController({required OpportunitiesRepository repository})
      : _repository = repository;

  factory OpportunitiesController.fromClient(ApiClient client) {
    return OpportunitiesController(
      repository: OpportunitiesRepository(client),
    );
  }

  Future<OpportunityRolePage> roles({
    required String category,
    String? query,
    String? city,
    bool saved = false,
    int page = 1,
  }) {
    return _repository.roles(
      category: category,
      query: query,
      city: city,
      saved: saved,
      page: page,
    );
  }

  Future<OpportunityRole> role(String publicId) {
    return _repository.role(publicId);
  }

  Future<void> setSaved(OpportunityRole role, bool saved) async {
    if (saved) {
      await _repository.saveRole(role.publicId);
    } else {
      await _repository.unsaveRole(role.publicId);
    }
    notifyListeners();
  }

  Future<OpportunityApplication> createApplication(
    String roleId, {
    required String coverNote,
    List<String> attachmentFileIds = const [],
  }) {
    return _repository.createApplication(
      roleId,
      coverNote: coverNote,
      attachmentFileIds: attachmentFileIds,
    );
  }

  Future<List<OpportunityApplication>> myApplications() {
    return _repository.myApplications();
  }

  Future<OpportunityApplication> withdrawApplication(String publicId) {
    return _repository.withdrawApplication(publicId);
  }

  Future<OpportunityApplication> application(String publicId) {
    return _repository.application(publicId);
  }

  Future<List<OpportunityApplication>> directorApplications(String projectId) {
    return _repository.directorApplications(projectId);
  }

  Future<OpportunityApplication> updateDirectorApplication(
    String publicId,
    Map<String, dynamic> body,
  ) {
    return _repository.updateDirectorApplication(publicId, body);
  }

  Future<MeetingThread?> meetings(String applicationId) {
    return _repository.meetings(applicationId);
  }

  Future<OpportunityApplication> proposeMeeting(
    String applicationId,
    Map<String, dynamic> body,
  ) {
    return _repository.proposeMeeting(applicationId, body);
  }

  Future<OpportunityApplication> acceptMeetingRound(
    String applicationId,
    String roundId,
  ) {
    return _repository.acceptMeetingRound(applicationId, roundId);
  }

  Future<OpportunityApplication> declineMeetingRound(
    String applicationId,
    String roundId, {
    String? reason,
  }) {
    return _repository.declineMeetingRound(
      applicationId,
      roundId,
      reason: reason,
    );
  }

  Future<MeetingThread?> directorMeetings(String applicationId) {
    return _repository.directorMeetings(applicationId);
  }

  Future<OpportunityApplication> proposeDirectorMeeting(
    String applicationId,
    Map<String, dynamic> body,
  ) {
    return _repository.proposeDirectorMeeting(applicationId, body);
  }

  Future<OpportunityApplication> acceptDirectorMeetingRound(
    String applicationId,
    String roundId,
  ) {
    return _repository.acceptDirectorMeetingRound(applicationId, roundId);
  }

  Future<OpportunityApplication> declineDirectorMeetingRound(
    String applicationId,
    String roundId, {
    String? reason,
  }) {
    return _repository.declineDirectorMeetingRound(
      applicationId,
      roundId,
      reason: reason,
    );
  }
}

class OpportunitiesScope extends InheritedNotifier<OpportunitiesController> {
  const OpportunitiesScope({
    super.key,
    required OpportunitiesController controller,
    required super.child,
  }) : super(notifier: controller);

  static OpportunitiesController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<OpportunitiesScope>();
    assert(scope != null, 'OpportunitiesScope is missing from the widget tree');
    return scope!.notifier!;
  }

  static OpportunitiesController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<OpportunitiesScope>()
        ?.notifier;
  }
}
