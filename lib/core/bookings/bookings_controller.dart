import 'package:flutter/widgets.dart';

import '../network/api_client.dart';
import 'booking_models.dart';
import 'bookings_repository.dart';

class BookingsController extends ChangeNotifier {
  final BookingsRepository _repository;

  List<Booking>? _cachedBookings;
  List<Booking>? _cachedOpportunities;

  BookingsController({required BookingsRepository repository})
      : _repository = repository;

  factory BookingsController.fromClient(ApiClient client) {
    return BookingsController(repository: BookingsRepository(client));
  }

  List<Booking>? get cachedBookings => _cachedBookings;
  List<Booking>? get cachedOpportunities => _cachedOpportunities;

  Future<List<Booking>> bookings({String? role, bool force = false}) async {
    if (!force && role == null && _cachedBookings != null) {
      return _cachedBookings!;
    }
    final rows = await _repository.bookings(role: role);
    if (role == null) {
      _cachedBookings = rows;
      notifyListeners();
    }
    return rows;
  }

  Future<List<Booking>> opportunities({bool force = false}) async {
    if (!force && _cachedOpportunities != null) return _cachedOpportunities!;
    final rows = await _repository.opportunities();
    _cachedOpportunities = rows;
    notifyListeners();
    return rows;
  }

  Future<Booking> booking(String publicId) {
    return _repository.booking(publicId);
  }

  Future<Booking> createAndSendBooking({
    required String projectId,
    required String listingId,
    String? requirementId,
    required String startAt,
    required String endAt,
    required int feeMinor,
    String currency = 'PKR',
    String? message,
  }) async {
    final booking = await _repository.createBooking(
      projectId: projectId,
      listingId: listingId,
      requirementId: requirementId,
      startAt: startAt,
      endAt: endAt,
      feeMinor: feeMinor,
      currency: currency,
    );
    final sent = await _repository.sendBooking(
      bookingId: booking.publicId,
      feeMinor: feeMinor,
      currency: currency,
      message: message,
    );
    await bookings(force: true);
    return sent;
  }

  Future<List<NegotiationThread>> negotiations() {
    return _repository.negotiations();
  }

  Future<NegotiationThread> negotiation(String publicId) {
    return _repository.negotiation(publicId);
  }

  Future<BookingOffer> createCounterOffer({
    required String bookingId,
    required int feeMinor,
    String currency = 'PKR',
    String? conditions,
    String? message,
  }) {
    return _repository.createCounterOffer(
      bookingId: bookingId,
      feeMinor: feeMinor,
      currency: currency,
      conditions: conditions,
      message: message,
    );
  }

  Future<Booking> acceptOffer(String offerId) async {
    final booking = await _repository.acceptOffer(offerId);
    await opportunities(force: true);
    return booking;
  }

  Future<Booking> rejectBooking(String bookingId, {String? reason}) {
    return _repository.rejectBooking(bookingId, reason: reason);
  }

  Future<List<AvailabilityEntry>> availability() {
    return _repository.availability();
  }

  Future<AvailabilityEntry> createAvailability({
    required String startAt,
    required String endAt,
    required String status,
    String? note,
  }) {
    return _repository.createAvailability(
      startAt: startAt,
      endAt: endAt,
      status: status,
      note: note,
    );
  }

  Future<BookingConversation> conversation(String conversationId) {
    return _repository.conversation(conversationId);
  }

  Future<ConversationMessage> sendMessage({
    required String conversationId,
    required String body,
  }) {
    return _repository.sendMessage(conversationId: conversationId, body: body);
  }

  Future<void> pinMessage(String messageId) {
    return _repository.pinMessage(messageId);
  }
}

class BookingsScope extends InheritedNotifier<BookingsController> {
  const BookingsScope({
    super.key,
    required BookingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static BookingsController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<BookingsScope>();
    assert(scope != null, 'BookingsScope is missing from the widget tree');
    return scope!.notifier!;
  }

  static BookingsController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<BookingsScope>()
        ?.notifier;
  }
}
