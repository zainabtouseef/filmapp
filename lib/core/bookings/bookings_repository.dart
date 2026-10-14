import '../network/api_client.dart';
import 'booking_models.dart';

class BookingsRepository {
  final ApiClient _client;

  const BookingsRepository(this._client);

  Future<List<Booking>> bookings({String? role, String? status}) async {
    final params = <String, String>{};
    if (role != null) params['role'] = role;
    if (status != null) params['status'] = status;
    final suffix = params.isEmpty
        ? ''
        : '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
    final response = await _client.get('/bookings$suffix');
    final data = response['data'] as Map<String, dynamic>;
    return (data['bookings'] as List<dynamic>? ?? const [])
        .map((item) => Booking.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Booking>> opportunities() async {
    final response = await _client.get('/talent/opportunities');
    final data = response['data'] as Map<String, dynamic>;
    return (data['bookings'] as List<dynamic>? ?? const [])
        .map((item) => Booking.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Booking> booking(String publicId) async {
    final response = await _client.get('/bookings/$publicId');
    final data = response['data'] as Map<String, dynamic>;
    return Booking.fromJson(data['booking'] as Map<String, dynamic>);
  }

  Future<Booking> createBooking({
    String? projectId,
    required String listingId,
    String? requirementId,
    required String startAt,
    required String endAt,
    required int feeMinor,
    String currency = 'PKR',
    Map<String, dynamic> terms = const {},
    String? expiresAt,
  }) async {
    final response = await _client.post(
      '/bookings',
      body: {
        if (projectId != null) 'project_id': projectId,
        'listing_id': listingId,
        if (requirementId != null) 'requirement_id': requirementId,
        'start_at': startAt,
        'end_at': endAt,
        'fee_minor': feeMinor,
        'currency': currency,
        'terms': terms,
        if (expiresAt != null) 'expires_at': expiresAt,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return Booking.fromJson(data['booking'] as Map<String, dynamic>);
  }

  Future<Booking> sendBooking({
    required String bookingId,
    required int feeMinor,
    String currency = 'PKR',
    String? message,
    Map<String, dynamic> terms = const {},
  }) async {
    final response = await _client.post(
      '/bookings/$bookingId/send',
      body: {
        'fee_minor': feeMinor,
        'currency': currency,
        if (message != null) 'message': message,
        if (terms['payment_schedule'] != null)
          'payment_schedule': terms['payment_schedule'],
        if (terms['conditions'] != null) 'conditions': terms['conditions'],
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return Booking.fromJson(data['booking'] as Map<String, dynamic>);
  }

  Future<List<NegotiationThread>> negotiations() async {
    final response = await _client.get('/negotiations');
    final data = response['data'] as Map<String, dynamic>;
    return (data['negotiations'] as List<dynamic>? ?? const [])
        .map((item) => NegotiationThread.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Booking> updateDraft(String id, Map<String, dynamic> body) async {
    final response = await _client.patch('/bookings/$id', body: body);
    return Booking.fromJson((response['data']
        as Map<String, dynamic>)['booking'] as Map<String, dynamic>);
  }

  Future<NegotiationThread> negotiation(String publicId) async {
    final response = await _client.get('/negotiations/$publicId');
    final data = response['data'] as Map<String, dynamic>;
    return NegotiationThread.fromJson(
      data['negotiation'] as Map<String, dynamic>,
    );
  }

  Future<BookingOffer> createCounterOffer({
    required String bookingId,
    required int feeMinor,
    String currency = 'PKR',
    String? conditions,
    String? message,
    List<Map<String, dynamic>>? paymentSchedule,
  }) async {
    final response = await _client.post(
      '/bookings/$bookingId/offers',
      body: {
        'fee_minor': feeMinor,
        'currency': currency,
        if (conditions != null) 'conditions': conditions,
        if (message != null) 'message': message,
        if (paymentSchedule != null) 'payment_schedule': paymentSchedule,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return BookingOffer.fromJson(data['offer'] as Map<String, dynamic>);
  }

  Future<Booking> acceptOffer(String offerId) async {
    final response = await _client.post('/offers/$offerId/accept');
    final data = response['data'] as Map<String, dynamic>;
    return Booking.fromJson(data['booking'] as Map<String, dynamic>);
  }

  Future<Booking> rejectBooking(String bookingId, {String? reason}) async {
    final response = await _client.post(
      '/bookings/$bookingId/reject',
      body: {'reason': reason ?? 'Rejected from app.'},
    );
    final data = response['data'] as Map<String, dynamic>;
    return Booking.fromJson(data['booking'] as Map<String, dynamic>);
  }

  Future<Booking> cancelBooking(
    String bookingId, {
    required String reason,
  }) async {
    final response = await _client.post(
      '/bookings/$bookingId/cancel',
      body: {'reason': reason},
    );
    final data = response['data'] as Map<String, dynamic>;
    return Booking.fromJson(data['booking'] as Map<String, dynamic>);
  }

  Future<List<AvailabilityEntry>> availability() async {
    final response = await _client.get('/availability');
    final data = response['data'] as Map<String, dynamic>;
    return (data['availability'] as List<dynamic>? ?? const [])
        .map((item) => AvailabilityEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AvailabilityEntry> createAvailability({
    required String startAt,
    required String endAt,
    required String status,
    String? note,
    String? resourceType,
    String? resourceId,
  }) async {
    final response = await _client.post(
      '/availability',
      body: {
        'start_at': startAt,
        'end_at': endAt,
        'status': status,
        if (note != null) 'note': note,
        if (resourceType != null) 'resource_type': resourceType,
        if (resourceId != null) 'resource_id': resourceId,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return AvailabilityEntry.fromJson(data['entry'] as Map<String, dynamic>);
  }

  Future<AvailabilityEntry> updateAvailability({
    required String entryId,
    required String status,
    String? note,
  }) async {
    final response = await _client.patch(
      '/availability/$entryId',
      body: {
        'status': status,
        if (note != null) 'note': note,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return AvailabilityEntry.fromJson(data['entry'] as Map<String, dynamic>);
  }

  Future<BookingConversation> conversation(String conversationId) async {
    final response =
        await _client.get('/conversations/$conversationId/messages');
    final data = response['data'] as Map<String, dynamic>;
    return BookingConversation.fromJson(
      data['conversation'] as Map<String, dynamic>,
    );
  }

  Future<ConversationMessage> sendMessage({
    required String conversationId,
    required String body,
    List<ConversationAttachmentInput> attachments = const [],
  }) async {
    final response = await _client.post(
      '/conversations/$conversationId/messages',
      body: {
        'body': body,
        if (attachments.isNotEmpty)
          'attachments': attachments.map((item) => item.toJson()).toList(),
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return ConversationMessage.fromJson(
      data['message'] as Map<String, dynamic>,
    );
  }

  Future<void> pinMessage(String messageId) {
    return _client.post('/messages/$messageId/pin');
  }
}
