import '../../features/actor_talent/models/actor_talent_models.dart';
import '../../features/director_producer/models/dp_negotiation.dart';

class BookingUser {
  final String publicId;
  final String displayName;

  const BookingUser({required this.publicId, required this.displayName});

  factory BookingUser.fromJson(Map<String, dynamic> json) {
    return BookingUser(
      publicId: json['public_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'CineConnect member',
    );
  }
}

class BookingOffer {
  final String publicId;
  final int revision;
  final BookingUser sender;
  final BookingUser recipient;
  final int feeMinor;
  final String currency;
  final String? conditions;
  final String status;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  const BookingOffer({
    required this.publicId,
    required this.revision,
    required this.sender,
    required this.recipient,
    required this.feeMinor,
    required this.currency,
    required this.conditions,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
  });

  factory BookingOffer.fromJson(Map<String, dynamic> json) {
    return BookingOffer(
      publicId: json['public_id'] as String,
      revision: json['revision'] as int? ?? 1,
      sender: BookingUser.fromJson(json['sender'] as Map<String, dynamic>),
      recipient:
          BookingUser.fromJson(json['recipient'] as Map<String, dynamic>),
      feeMinor: json['fee_minor'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'PKR',
      conditions: json['conditions'] as String?,
      status: json['status'] as String? ?? 'active',
      expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  String get feeLabel => '$currency ${_short(feeMinor ~/ 100)}';
}

class Booking {
  final String publicId;
  final String projectId;
  final String projectTitle;
  final String projectType;
  final String? projectCity;
  final String? requirementId;
  final String? requirementTitle;
  final String listingId;
  final String listingTitle;
  final String pricingMode;
  final bool allowsBargaining;
  final String category;
  final String status;
  final BookingUser requester;
  final BookingUser provider;
  final int? agreedAmountMinor;
  final String currency;
  final DateTime startAt;
  final DateTime endAt;
  final DateTime? expiresAt;
  final DateTime? securedAt;
  final String? conversationId;
  final String? negotiationId;
  final List<BookingOffer> offers;

  const Booking({
    required this.publicId,
    required this.projectId,
    required this.projectTitle,
    required this.projectType,
    required this.projectCity,
    required this.requirementId,
    required this.requirementTitle,
    required this.listingId,
    required this.listingTitle,
    this.pricingMode = 'negotiable',
    this.allowsBargaining = true,
    required this.category,
    required this.status,
    required this.requester,
    required this.provider,
    required this.agreedAmountMinor,
    required this.currency,
    required this.startAt,
    required this.endAt,
    required this.expiresAt,
    required this.securedAt,
    required this.conversationId,
    required this.negotiationId,
    required this.offers,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    final rawOffers = json['offers'] as List<dynamic>? ?? const [];
    return Booking(
      publicId: json['public_id'] as String,
      projectId: json['project_id'] as String? ?? '',
      projectTitle: json['project_title'] as String? ?? 'Untitled project',
      projectType: json['project_type'] as String? ?? 'production',
      projectCity: json['project_city'] as String?,
      requirementId: json['requirement_id'] as String?,
      requirementTitle: json['requirement_title'] as String?,
      listingId: json['listing_id'] as String? ?? '',
      listingTitle: json['listing_title'] as String? ?? 'Talent booking',
      pricingMode: json['pricing_mode'] as String? ?? 'negotiable',
      allowsBargaining: json['allows_bargaining'] as bool? ?? true,
      category: json['category'] as String? ?? 'talent',
      status: json['status'] as String? ?? 'draft',
      requester:
          BookingUser.fromJson(json['requester'] as Map<String, dynamic>),
      provider: BookingUser.fromJson(json['provider'] as Map<String, dynamic>),
      agreedAmountMinor: json['agreed_amount_minor'] as int?,
      currency: json['currency'] as String? ?? 'PKR',
      startAt: DateTime.parse(json['start_at'] as String),
      endAt: DateTime.parse(json['end_at'] as String),
      expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? ''),
      securedAt: DateTime.tryParse(json['secured_at'] as String? ?? ''),
      conversationId: json['conversation_id'] as String?,
      negotiationId: json['negotiation_id'] as String?,
      offers: rawOffers
          .map((item) => BookingOffer.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  BookingOffer? get activeOffer {
    for (final offer in offers.reversed) {
      if (offer.status == 'active') return offer;
    }
    return offers.isEmpty ? null : offers.last;
  }

  ActorOpportunity toActorOpportunity() {
    return ActorOpportunity(
      id: publicId,
      type: ActorOpportunityType.directOffer,
      projectTitle: projectTitle,
      role: requirementTitle ?? _titleCase(category),
      producer: requester.displayName,
      city: projectCity ?? 'Location to be confirmed',
      dates: '${_shortDate(startAt)} - ${_shortDate(endAt)}',
      fee: activeOffer?.feeLabel ??
          (agreedAmountMinor == null
              ? 'Rate TBD'
              : '$currency ${_short(agreedAmountMinor! ~/ 100)}'),
      directorRating: 0,
      expiry: expiresAt == null ? 'Open' : 'Expires ${_shortDate(expiresAt!)}',
      status: _actorStatus,
      imageUrl: '',
      notes: 'Live booking ${_titleCase(status)}',
    );
  }

  ActorBookingStatus get _actorStatus {
    return switch (status) {
      'accepted' => ActorBookingStatus.termsApproved,
      'secured' => ActorBookingStatus.secured,
      'under_negotiation' => ActorBookingStatus.underNegotiation,
      'rejected' || 'cancelled' => ActorBookingStatus.closed,
      _ => ActorBookingStatus.sent,
    };
  }
}

class NegotiationRound {
  final int roundNumber;
  final BookingUser sender;
  final String? message;
  final BookingOffer offer;
  final DateTime? createdAt;

  const NegotiationRound({
    required this.roundNumber,
    required this.sender,
    required this.message,
    required this.offer,
    required this.createdAt,
  });

  factory NegotiationRound.fromJson(Map<String, dynamic> json) {
    return NegotiationRound(
      roundNumber: json['round_number'] as int? ?? 1,
      sender: BookingUser.fromJson(json['sender'] as Map<String, dynamic>),
      message: json['message'] as String?,
      offer: BookingOffer.fromJson(json['offer'] as Map<String, dynamic>),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  DpNegotiationRound toDpRound() {
    return DpNegotiationRound(
      round: roundNumber,
      sentBy: sender.displayName,
      rate: offer.feeLabel,
      dates: '',
      schedule: 'Structured schedule',
      conditions: offer.conditions ?? 'No special conditions',
      message: message ?? 'Offer revision ${offer.revision}',
      timestamp: _relative(createdAt),
      expiry: offer.expiresAt == null ? 'Open' : _shortDate(offer.expiresAt!),
    );
  }
}

class NegotiationThread {
  final String publicId;
  final String status;
  final Booking booking;
  final BookingOffer? currentOffer;
  final DateTime? lockedAt;
  final List<NegotiationRound> rounds;

  const NegotiationThread({
    required this.publicId,
    required this.status,
    required this.booking,
    required this.currentOffer,
    required this.lockedAt,
    required this.rounds,
  });

  factory NegotiationThread.fromJson(Map<String, dynamic> json) {
    final rawRounds = json['rounds'] as List<dynamic>? ?? const [];
    return NegotiationThread(
      publicId: json['public_id'] as String,
      status: json['status'] as String? ?? 'open',
      booking: Booking.fromJson(json['booking'] as Map<String, dynamic>),
      currentOffer: json['current_offer'] is Map<String, dynamic>
          ? BookingOffer.fromJson(json['current_offer'] as Map<String, dynamic>)
          : null,
      lockedAt: DateTime.tryParse(json['locked_at'] as String? ?? ''),
      rounds: rawRounds
          .map(
              (item) => NegotiationRound.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AvailabilityEntry {
  final String publicId;
  final String resourceType;
  final String resourceId;
  final DateTime startAt;
  final DateTime endAt;
  final String status;
  final String? sourceBookingId;
  final String? note;

  const AvailabilityEntry({
    required this.publicId,
    required this.resourceType,
    required this.resourceId,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.sourceBookingId,
    required this.note,
  });

  factory AvailabilityEntry.fromJson(Map<String, dynamic> json) {
    return AvailabilityEntry(
      publicId: json['public_id'] as String,
      resourceType: json['resource_type'] as String? ?? 'user',
      resourceId: json['resource_id'] as String? ?? '',
      startAt: DateTime.parse(json['start_at'] as String),
      endAt: DateTime.parse(json['end_at'] as String),
      status: json['status'] as String? ?? 'available',
      sourceBookingId: json['source_booking_id'] as String?,
      note: json['note'] as String?,
    );
  }
}

class ConversationMessage {
  final String publicId;
  final BookingUser sender;
  final String? body;
  final String messageType;
  final DateTime? createdAt;

  const ConversationMessage({
    required this.publicId,
    required this.sender,
    required this.body,
    required this.messageType,
    required this.createdAt,
  });

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      publicId: json['public_id'] as String,
      sender: BookingUser.fromJson(json['sender'] as Map<String, dynamic>),
      body: json['body'] as String?,
      messageType: json['message_type'] as String? ?? 'text',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

class BookingConversation {
  final String publicId;
  final String? bookingId;
  final String title;
  final List<ConversationMessage> messages;

  const BookingConversation({
    required this.publicId,
    required this.bookingId,
    required this.title,
    required this.messages,
  });

  factory BookingConversation.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'] as List<dynamic>? ?? const [];
    return BookingConversation(
      publicId: json['public_id'] as String,
      bookingId: json['booking_id'] as String?,
      title: json['title'] as String? ?? 'Booking chat',
      messages: rawMessages
          .map((item) =>
              ConversationMessage.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

String _short(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).round()}k';
  return '$value';
}

String _shortDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return '${months[date.month - 1]} ${date.day}';
}

String _relative(DateTime? date) {
  if (date == null) return 'now';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inDays < 1) return '${diff.inHours}h';
  return '${diff.inDays}d';
}

String _titleCase(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.trim().isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
