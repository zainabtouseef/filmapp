import '../network/api_client.dart';
import 'trust_safety_models.dart';

class TrustSafetyRepository {
  final ApiClient _client;

  const TrustSafetyRepository(this._client);

  Future<Map<String, dynamic>> reviewEligibility(String bookingId) async {
    final response =
        await _client.get('/bookings/$bookingId/review-eligibility');
    return response['data'] as Map<String, dynamic>;
  }

  Future<ReviewDto> createReview(Map<String, dynamic> body) async {
    final response = await _client.post('/reviews', body: body);
    return ReviewDto.fromJson(
      (response['data'] as Map<String, dynamic>)['review']
          as Map<String, dynamic>,
    );
  }

  Future<UserReviewsDto> userReviews(String userId) async {
    final response = await _client.get('/users/$userId/reviews');
    return UserReviewsDto.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> createReviewRequest(String bookingId) async {
    final response =
        await _client.post('/review-requests', body: {'booking_id': bookingId});
    return (response['data'] as Map<String, dynamic>)['review_request']
        as Map<String, dynamic>;
  }

  Future<List<String>> reportReasons() async {
    final response = await _client.get('/reports/reasons');
    final data = response['data'] as Map<String, dynamic>;
    return (data['reasons'] as List<dynamic>? ?? const [])
        .map((item) => '$item')
        .toList();
  }

  Future<ReportDto> createReport(Map<String, dynamic> body) async {
    final response = await _client.post('/reports', body: body);
    return ReportDto.fromJson(
      (response['data'] as Map<String, dynamic>)['report']
          as Map<String, dynamic>,
    );
  }

  Future<void> blockUser(String userId, {String? reason}) {
    return _client.post(
      '/blocked-users',
      body: {'user_id': userId, if (reason != null) 'reason': reason},
    );
  }

  Future<List<BlockedUserDto>> blockedUsers() async {
    final response = await _client.get('/blocked-users');
    final data = response['data'] as Map<String, dynamic>;
    return (data['blocked_users'] as List<dynamic>? ?? const [])
        .map((item) => BlockedUserDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> unblockUser(String userId) {
    return _client.delete('/blocked-users/$userId');
  }

  Future<List<ModerationCaseDto>> adminModerationCases({
    String? status,
  }) async {
    final response = await _client.get(
        '/admin/moderation-cases${status == null ? '' : '?status=$status'}');
    final data = response['data'] as Map<String, dynamic>;
    return (data['cases'] as List<dynamic>? ?? const [])
        .map((item) => ModerationCaseDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ModerationCaseDto> adminModerationCase(String caseId) async {
    final response = await _client.get('/admin/moderation-cases/$caseId');
    return ModerationCaseDto.fromJson(
      (response['data'] as Map<String, dynamic>)['case']
          as Map<String, dynamic>,
    );
  }

  Future<ModerationCaseDto> decideModerationCase({
    required String caseId,
    required String decision,
    String? reason,
  }) async {
    final response = await _client.post(
      '/admin/moderation-cases/$caseId/decision',
      body: {'decision': decision, if (reason != null) 'reason': reason},
    );
    return ModerationCaseDto.fromJson(
      (response['data'] as Map<String, dynamic>)['case']
          as Map<String, dynamic>,
    );
  }

  Future<DisputeDto> createDispute(Map<String, dynamic> body) async {
    final response = await _client.post('/disputes', body: body);
    return DisputeDto.fromJson(
      (response['data'] as Map<String, dynamic>)['dispute']
          as Map<String, dynamic>,
    );
  }

  Future<List<DisputeDto>> disputes() async {
    final response = await _client.get('/disputes');
    final data = response['data'] as Map<String, dynamic>;
    return (data['disputes'] as List<dynamic>? ?? const [])
        .map((item) => DisputeDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<DisputeDto> dispute(String disputeId) async {
    final response = await _client.get('/disputes/$disputeId');
    return DisputeDto.fromJson(
      (response['data'] as Map<String, dynamic>)['dispute']
          as Map<String, dynamic>,
    );
  }

  Future<DisputeDto> addDisputeEvidence(
    String disputeId,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      '/disputes/$disputeId/evidence',
      body: body,
    );
    return DisputeDto.fromJson(
      (response['data'] as Map<String, dynamic>)['dispute']
          as Map<String, dynamic>,
    );
  }

  Future<List<DisputeDto>> adminDisputes({String? status}) async {
    final response = await _client
        .get('/admin/disputes${status == null ? '' : '?status=$status'}');
    final data = response['data'] as Map<String, dynamic>;
    return (data['disputes'] as List<dynamic>? ?? const [])
        .map((item) => DisputeDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<DisputeDto> adminDispute(String disputeId) async {
    final response = await _client.get('/admin/disputes/$disputeId');
    return DisputeDto.fromJson(
      (response['data'] as Map<String, dynamic>)['dispute']
          as Map<String, dynamic>,
    );
  }

  Future<DisputeDto> decideDispute({
    required String disputeId,
    required String decision,
    String? note,
  }) async {
    final response = await _client.post(
      '/admin/disputes/$disputeId/decision',
      body: {'decision': decision, if (note != null) 'note': note},
    );
    return DisputeDto.fromJson(
      (response['data'] as Map<String, dynamic>)['dispute']
          as Map<String, dynamic>,
    );
  }

  Future<SupportTicketDto> createSupportTicket(
      Map<String, dynamic> body) async {
    final response = await _client.post('/support-tickets', body: body);
    return SupportTicketDto.fromJson(
      (response['data'] as Map<String, dynamic>)['ticket']
          as Map<String, dynamic>,
    );
  }

  Future<List<SupportTicketDto>> supportTickets() async {
    final response = await _client.get('/support-tickets');
    final data = response['data'] as Map<String, dynamic>;
    return (data['tickets'] as List<dynamic>? ?? const [])
        .map((item) => SupportTicketDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<SupportTicketDto>> adminSupportTickets({String? status}) async {
    final response = await _client.get(
      '/admin/support-tickets${status == null ? '' : '?status=$status'}',
    );
    final data = response['data'] as Map<String, dynamic>;
    return (data['tickets'] as List<dynamic>? ?? const [])
        .map((item) => SupportTicketDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<SupportTicketDto> updateSupportTicket(
    String ticketId,
    Map<String, dynamic> body,
  ) async {
    final response =
        await _client.patch('/admin/support-tickets/$ticketId', body: body);
    return SupportTicketDto.fromJson(
      (response['data'] as Map<String, dynamic>)['ticket']
          as Map<String, dynamic>,
    );
  }

  Future<SupportTicketDto> createSupportMessage({
    required String ticketId,
    required String body,
    bool internalNote = false,
  }) async {
    final response = await _client.post(
      '/support-tickets/$ticketId/messages',
      body: {'body': body, 'internal_note': internalNote},
    );
    return SupportTicketDto.fromJson(
      (response['data'] as Map<String, dynamic>)['ticket']
          as Map<String, dynamic>,
    );
  }

  Future<AnnouncementDto> createAnnouncement(Map<String, dynamic> body) async {
    final response = await _client.post('/admin/announcements', body: body);
    return AnnouncementDto.fromJson(
      (response['data'] as Map<String, dynamic>)['announcement']
          as Map<String, dynamic>,
    );
  }

  Future<List<AnnouncementDto>> announcements() async {
    final response = await _client.get('/admin/announcements');
    final data = response['data'] as Map<String, dynamic>;
    return (data['announcements'] as List<dynamic>? ?? const [])
        .map((item) => AnnouncementDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AnnouncementDto> publishAnnouncement(String announcementId) async {
    final response =
        await _client.post('/admin/announcements/$announcementId/publish');
    return AnnouncementDto.fromJson(
      (response['data'] as Map<String, dynamic>)['announcement']
          as Map<String, dynamic>,
    );
  }

  Future<NotificationsDto> notifications({bool unread = false}) async {
    final response =
        await _client.get('/notifications${unread ? '?unread=true' : ''}');
    return NotificationsDto.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<NotificationDto> markNotificationRead(String notificationId) async {
    final response = await _client.patch('/notifications/$notificationId/read');
    return NotificationDto.fromJson(
      (response['data'] as Map<String, dynamic>)['notification']
          as Map<String, dynamic>,
    );
  }

  Future<int> markAllNotificationsRead() async {
    final response = await _client.post('/notifications/read-all');
    final data = response['data'] as Map<String, dynamic>;
    return data['marked_read'] as int? ?? 0;
  }

  Future<void> registerPushDevice(Map<String, dynamic> body) {
    return _client.post('/push-devices', body: body);
  }
}
