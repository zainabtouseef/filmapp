import 'package:flutter/widgets.dart';

import '../network/api_client.dart';
import '../scheduling/meeting_models.dart';
import 'casting_models.dart';
import 'casting_repository.dart';

class CastingController extends ChangeNotifier {
  final CastingRepository _repository;

  CastingRolePage? _rolePage;
  List<CastingApplication>? _actorApplications;

  CastingController({required CastingRepository repository})
      : _repository = repository;

  factory CastingController.fromClient(ApiClient client) {
    return CastingController(repository: CastingRepository(client));
  }

  CastingRolePage? get cachedRolePage => _rolePage;
  List<CastingApplication>? get cachedActorApplications => _actorApplications;

  Future<CastingRolePage> roles({
    String? query,
    String? city,
    String? auditionMode,
    bool saved = false,
    int page = 1,
    bool force = false,
  }) async {
    final canUseCache = !force &&
        !saved &&
        auditionMode == null &&
        page == 1 &&
        (query == null || query.isEmpty) &&
        (city == null || city.isEmpty) &&
        _rolePage != null;
    if (canUseCache) return _rolePage!;
    final result = await _repository.roles(
      query: query,
      city: city,
      auditionMode: auditionMode,
      saved: saved,
      page: page,
    );
    if (!saved &&
        auditionMode == null &&
        page == 1 &&
        (query == null || query.isEmpty)) {
      _rolePage = result;
      notifyListeners();
    }
    return result;
  }

  Future<CastingRole> role(String publicId) {
    return _repository.role(publicId);
  }

  Future<void> setSaved(CastingRole role, bool saved) async {
    if (saved) {
      await _repository.saveRole(role.publicId);
    } else {
      await _repository.unsaveRole(role.publicId);
    }
    _rolePage = null;
    notifyListeners();
  }

  Future<CastingRole> publishRole(
    String publicId,
    Map<String, dynamic> body,
  ) {
    return _repository.publishRole(publicId, body);
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
    final result = await _repository.createApplication(
      roleId,
      coverNote: coverNote,
      availabilityNote: availabilityNote,
      answers: answers,
      portfolioItemIds: portfolioItemIds,
      selfTapeFileId: selfTapeFileId,
      submit: submit,
    );
    await actorApplications(force: true);
    _rolePage = null;
    return result;
  }

  Future<List<CastingApplication>> actorApplications({
    String? status,
    bool force = false,
  }) async {
    if (status == null && !force && _actorApplications != null) {
      return _actorApplications!;
    }
    final result = await _repository.actorApplications(status: status);
    if (status == null) {
      _actorApplications = result;
      notifyListeners();
    }
    return result;
  }

  Future<CastingApplication> application(String publicId) {
    return _repository.application(publicId);
  }

  Future<CastingApplication> updateApplication(
    String publicId,
    Map<String, dynamic> body,
  ) async {
    final result = await _repository.updateApplication(publicId, body);
    await actorApplications(force: true);
    return result;
  }

  Future<CastingApplication> submitApplication(String publicId) async {
    final result = await _repository.submitApplication(publicId);
    await actorApplications(force: true);
    return result;
  }

  Future<CastingApplication> withdrawApplication(String publicId) async {
    final result = await _repository.withdrawApplication(publicId);
    await actorApplications(force: true);
    return result;
  }

  Future<CastingApplication> confirmAudition(String publicId) async {
    final result = await _repository.confirmAudition(publicId);
    await actorApplications(force: true);
    return result;
  }

  Future<CastingApplication> submitSelfTape(
    String publicId,
    String fileId,
  ) async {
    final result = await _repository.submitSelfTape(publicId, fileId);
    await actorApplications(force: true);
    return result;
  }

  Future<String> ensureConversation(String publicId) {
    return _repository.ensureConversation(publicId);
  }

  Future<List<CastingApplication>> directorApplications(
    String projectId,
  ) {
    return _repository.directorApplications(projectId);
  }

  Future<CastingApplication> updateDirectorApplication(
    String publicId,
    Map<String, dynamic> body,
  ) {
    return _repository.updateDirectorApplication(publicId, body);
  }

  Future<MeetingThread?> meetings(String applicationId) {
    return _repository.meetings(applicationId);
  }

  Future<CastingApplication> proposeMeeting(
    String applicationId,
    Map<String, dynamic> body,
  ) async {
    final result = await _repository.proposeMeeting(applicationId, body);
    await actorApplications(force: true);
    return result;
  }

  Future<CastingApplication> acceptMeetingRound(
    String applicationId,
    String roundId,
  ) async {
    final result =
        await _repository.acceptMeetingRound(applicationId, roundId);
    await actorApplications(force: true);
    return result;
  }

  Future<CastingApplication> declineMeetingRound(
    String applicationId,
    String roundId, {
    String? reason,
  }) async {
    final result = await _repository.declineMeetingRound(
      applicationId,
      roundId,
      reason: reason,
    );
    await actorApplications(force: true);
    return result;
  }

  Future<MeetingThread?> directorMeetings(String applicationId) {
    return _repository.directorMeetings(applicationId);
  }

  Future<CastingApplication> proposeDirectorMeeting(
    String applicationId,
    Map<String, dynamic> body,
  ) {
    return _repository.proposeDirectorMeeting(applicationId, body);
  }

  Future<CastingApplication> acceptDirectorMeetingRound(
    String applicationId,
    String roundId,
  ) {
    return _repository.acceptDirectorMeetingRound(applicationId, roundId);
  }

  Future<CastingApplication> declineDirectorMeetingRound(
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

class CastingScope extends InheritedNotifier<CastingController> {
  const CastingScope({
    super.key,
    required CastingController controller,
    required super.child,
  }) : super(notifier: controller);

  static CastingController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CastingScope>();
    assert(scope != null, 'CastingScope is missing from the widget tree');
    return scope!.notifier!;
  }

  static CastingController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CastingScope>()?.notifier;
  }
}
