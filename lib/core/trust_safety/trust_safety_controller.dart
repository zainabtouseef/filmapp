import 'package:flutter/widgets.dart';

import '../network/api_client.dart';
import 'trust_safety_models.dart';
import 'trust_safety_repository.dart';

class TrustSafetyController extends ChangeNotifier {
  final TrustSafetyRepository _repository;

  NotificationsDto? _notifications;
  List<BlockedUserDto>? _blockedUsers;
  List<ModerationCaseDto>? _moderationCases;
  List<DisputeDto>? _adminDisputes;
  List<SupportTicketDto>? _adminSupportTickets;
  List<AnnouncementDto>? _announcements;

  TrustSafetyController({required TrustSafetyRepository repository})
      : _repository = repository;

  factory TrustSafetyController.fromClient(ApiClient client) {
    return TrustSafetyController(repository: TrustSafetyRepository(client));
  }

  Future<ReviewDto> createReview(Map<String, dynamic> body) {
    return _repository.createReview(body);
  }

  Future<UserReviewsDto> userReviews(String userId) {
    return _repository.userReviews(userId);
  }

  Future<List<String>> reportReasons() {
    return _repository.reportReasons();
  }

  Future<ReportDto> createReport(Map<String, dynamic> body) {
    return _repository.createReport(body);
  }

  Future<void> blockUser(String userId, {String? reason}) {
    return _repository.blockUser(userId, reason: reason).then((_) async {
      await blockedUsers(force: true).catchError((_) => <BlockedUserDto>[]);
    });
  }

  Future<List<BlockedUserDto>> blockedUsers({bool force = false}) async {
    if (!force && _blockedUsers != null) return _blockedUsers!;
    _blockedUsers = await _repository.blockedUsers();
    notifyListeners();
    return _blockedUsers!;
  }

  Future<void> unblockUser(String userId) async {
    await _repository.unblockUser(userId);
    await blockedUsers(force: true);
  }

  Future<DisputeDto> createDispute(Map<String, dynamic> body) async {
    final dispute = await _repository.createDispute(body);
    await adminDisputes(force: true).catchError((_) => <DisputeDto>[]);
    return dispute;
  }

  Future<List<DisputeDto>> disputes() {
    return _repository.disputes();
  }

  Future<List<ModerationCaseDto>> adminModerationCases({
    bool force = false,
    String? status,
  }) async {
    if (!force && _moderationCases != null && status == null) {
      return _moderationCases!;
    }
    final rows = await _repository.adminModerationCases(status: status);
    if (status == null) _moderationCases = rows;
    notifyListeners();
    return rows;
  }

  Future<ModerationCaseDto> decideModerationCase({
    required String caseId,
    required String decision,
    String? reason,
  }) async {
    final row = await _repository.decideModerationCase(
      caseId: caseId,
      decision: decision,
      reason: reason,
    );
    await adminModerationCases(force: true);
    return row;
  }

  Future<List<DisputeDto>> adminDisputes({
    bool force = false,
    String? status,
  }) async {
    if (!force && _adminDisputes != null && status == null) {
      return _adminDisputes!;
    }
    final rows = await _repository.adminDisputes(status: status);
    if (status == null) _adminDisputes = rows;
    notifyListeners();
    return rows;
  }

  Future<DisputeDto> decideDispute({
    required String disputeId,
    required String decision,
    String? note,
  }) async {
    final row = await _repository.decideDispute(
      disputeId: disputeId,
      decision: decision,
      note: note,
    );
    await adminDisputes(force: true);
    return row;
  }

  Future<SupportTicketDto> createSupportTicket(
      Map<String, dynamic> body) async {
    final ticket = await _repository.createSupportTicket(body);
    await adminSupportTickets(force: true).catchError(
      (_) => <SupportTicketDto>[],
    );
    return ticket;
  }

  Future<List<SupportTicketDto>> supportTickets() {
    return _repository.supportTickets();
  }

  Future<List<SupportTicketDto>> adminSupportTickets({
    bool force = false,
    String? status,
  }) async {
    if (!force && _adminSupportTickets != null && status == null) {
      return _adminSupportTickets!;
    }
    final rows = await _repository.adminSupportTickets(status: status);
    if (status == null) _adminSupportTickets = rows;
    notifyListeners();
    return rows;
  }

  Future<SupportTicketDto> updateSupportTicket(
    String ticketId,
    Map<String, dynamic> body,
  ) async {
    final row = await _repository.updateSupportTicket(ticketId, body);
    await adminSupportTickets(force: true);
    return row;
  }

  Future<SupportTicketDto> createSupportMessage({
    required String ticketId,
    required String body,
    bool internalNote = false,
  }) async {
    final row = await _repository.createSupportMessage(
      ticketId: ticketId,
      body: body,
      internalNote: internalNote,
    );
    await adminSupportTickets(force: true).catchError(
      (_) => <SupportTicketDto>[],
    );
    return row;
  }

  Future<List<AnnouncementDto>> announcements({bool force = false}) async {
    if (!force && _announcements != null) return _announcements!;
    _announcements = await _repository.announcements();
    notifyListeners();
    return _announcements!;
  }

  Future<AnnouncementDto> createAnnouncement(Map<String, dynamic> body) async {
    final row = await _repository.createAnnouncement(body);
    await announcements(force: true);
    return row;
  }

  Future<AnnouncementDto> publishAnnouncement(String announcementId) async {
    final row = await _repository.publishAnnouncement(announcementId);
    await announcements(force: true);
    await notifications(force: true).catchError(
      (_) => const NotificationsDto(notifications: [], unreadCount: 0),
    );
    return row;
  }

  Future<NotificationsDto> notifications({
    bool force = false,
    bool unread = false,
  }) async {
    if (!force && _notifications != null && !unread) return _notifications!;
    final rows = await _repository.notifications(unread: unread);
    if (!unread) _notifications = rows;
    notifyListeners();
    return rows;
  }

  Future<NotificationDto> markNotificationRead(String notificationId) async {
    final row = await _repository.markNotificationRead(notificationId);
    await notifications(force: true);
    return row;
  }

  Future<int> markAllNotificationsRead() async {
    final count = await _repository.markAllNotificationsRead();
    await notifications(force: true);
    return count;
  }

  Future<void> registerPushDevice(Map<String, dynamic> body) {
    return _repository.registerPushDevice(body);
  }
}

class TrustSafetyScope extends InheritedNotifier<TrustSafetyController> {
  const TrustSafetyScope({
    super.key,
    required TrustSafetyController controller,
    required super.child,
  }) : super(notifier: controller);

  static TrustSafetyController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<TrustSafetyScope>();
    assert(scope != null, 'TrustSafetyScope is missing from the widget tree');
    return scope!.notifier!;
  }

  static TrustSafetyController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<TrustSafetyScope>()
        ?.notifier;
  }
}
