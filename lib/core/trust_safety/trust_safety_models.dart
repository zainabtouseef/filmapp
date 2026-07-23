class TrustUserDto {
  final String publicId;
  final String displayName;

  const TrustUserDto({required this.publicId, required this.displayName});

  factory TrustUserDto.fromJson(Map<String, dynamic> json) {
    return TrustUserDto(
      publicId: json['public_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Unknown user',
    );
  }
}

class BlockedUserDto {
  final TrustUserDto user;
  final String? reason;

  const BlockedUserDto({required this.user, this.reason});

  factory BlockedUserDto.fromJson(Map<String, dynamic> json) {
    return BlockedUserDto(
      user: TrustUserDto.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      reason: json['reason'] as String?,
    );
  }
}

class ReviewDto {
  final String publicId;
  final String bookingId;
  final TrustUserDto reviewer;
  final TrustUserDto reviewee;
  final int rating;
  final String? text;
  final String status;

  const ReviewDto({
    required this.publicId,
    required this.bookingId,
    required this.reviewer,
    required this.reviewee,
    required this.rating,
    this.text,
    required this.status,
  });

  factory ReviewDto.fromJson(Map<String, dynamic> json) {
    return ReviewDto(
      publicId: json['public_id'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      reviewer: TrustUserDto.fromJson(
          json['reviewer'] as Map<String, dynamic>? ?? {}),
      reviewee: TrustUserDto.fromJson(
          json['reviewee'] as Map<String, dynamic>? ?? {}),
      rating: json['rating'] as int? ?? 0,
      text: json['text'] as String?,
      status: json['status'] as String? ?? 'published',
    );
  }
}

class UserReviewsDto {
  final List<ReviewDto> reviews;
  final double ratingAverage;
  final int reviewCount;

  const UserReviewsDto({
    required this.reviews,
    required this.ratingAverage,
    required this.reviewCount,
  });

  factory UserReviewsDto.fromJson(Map<String, dynamic> json) {
    return UserReviewsDto(
      reviews: (json['reviews'] as List<dynamic>? ?? const [])
          .map((item) => ReviewDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      ratingAverage: (json['rating_average'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] as int? ?? 0,
    );
  }
}

class ReportDto {
  final String publicId;
  final String entityType;
  final String entityId;
  final String reason;
  final String? description;
  final String status;

  const ReportDto({
    required this.publicId,
    required this.entityType,
    required this.entityId,
    required this.reason,
    this.description,
    required this.status,
  });

  factory ReportDto.fromJson(Map<String, dynamic> json) {
    return ReportDto(
      publicId: json['public_id'] as String? ?? '',
      entityType: json['entity_type'] as String? ?? 'user',
      entityId: json['entity_id'] as String? ?? '',
      reason: json['reason'] as String? ?? 'other',
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'open',
    );
  }
}

class ModerationCaseDto {
  final String publicId;
  final String entityType;
  final String entityId;
  final String source;
  final String riskLevel;
  final String status;
  final String? decision;
  final int eventCount;

  const ModerationCaseDto({
    required this.publicId,
    required this.entityType,
    required this.entityId,
    required this.source,
    required this.riskLevel,
    required this.status,
    this.decision,
    required this.eventCount,
  });

  factory ModerationCaseDto.fromJson(Map<String, dynamic> json) {
    return ModerationCaseDto(
      publicId: json['public_id'] as String? ?? '',
      entityType: json['entity_type'] as String? ?? '',
      entityId: json['entity_id'] as String? ?? '',
      source: json['source'] as String? ?? '',
      riskLevel: json['risk_level'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'open',
      decision: json['decision'] as String?,
      eventCount: (json['events'] as List<dynamic>? ?? const []).length,
    );
  }
}

class DisputeDto {
  final String publicId;
  final String bookingId;
  final String type;
  final String description;
  final int? valueMinor;
  final String currency;
  final String severity;
  final String status;
  final int evidenceCount;
  final int eventCount;
  final TrustUserDto? openedBy;
  final TrustUserDto? respondent;
  final TrustUserDto? assignedAdmin;
  final List<DisputeEvidenceDto> evidence;
  final List<DisputeEventDto> events;

  const DisputeDto({
    required this.publicId,
    required this.bookingId,
    required this.type,
    required this.description,
    this.valueMinor,
    required this.currency,
    required this.severity,
    required this.status,
    required this.evidenceCount,
    required this.eventCount,
    this.openedBy,
    this.respondent,
    this.assignedAdmin,
    this.evidence = const [],
    this.events = const [],
  });

  factory DisputeDto.fromJson(Map<String, dynamic> json) {
    final evidence = (json['evidence'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(DisputeEvidenceDto.fromJson)
        .toList();
    final events = (json['events'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(DisputeEventDto.fromJson)
        .toList();
    return DisputeDto(
      publicId: json['public_id'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      description: json['description'] as String? ?? '',
      valueMinor: json['value_minor'] as int?,
      currency: json['currency'] as String? ?? 'PKR',
      severity: json['severity'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'open',
      evidenceCount: evidence.length,
      eventCount: events.length,
      openedBy: json['opened_by'] is Map<String, dynamic>
          ? TrustUserDto.fromJson(json['opened_by'] as Map<String, dynamic>)
          : null,
      respondent: json['respondent'] is Map<String, dynamic>
          ? TrustUserDto.fromJson(json['respondent'] as Map<String, dynamic>)
          : null,
      assignedAdmin: json['assigned_admin'] is Map<String, dynamic>
          ? TrustUserDto.fromJson(
              json['assigned_admin'] as Map<String, dynamic>,
            )
          : null,
      evidence: evidence,
      events: events,
    );
  }
}

class DisputeEvidenceDto {
  final String publicId;
  final String evidenceType;
  final String description;
  final TrustUserDto? submittedBy;

  const DisputeEvidenceDto({
    required this.publicId,
    required this.evidenceType,
    required this.description,
    this.submittedBy,
  });

  factory DisputeEvidenceDto.fromJson(Map<String, dynamic> json) {
    return DisputeEvidenceDto(
      publicId: json['public_id'] as String? ?? '',
      evidenceType: json['evidence_type'] as String? ?? 'evidence',
      description: json['description'] as String? ?? '',
      submittedBy: json['submitted_by'] is Map<String, dynamic>
          ? TrustUserDto.fromJson(
              json['submitted_by'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class DisputeEventDto {
  final String eventType;
  final String? note;
  final TrustUserDto? actor;
  final DateTime? createdAt;

  const DisputeEventDto({
    required this.eventType,
    this.note,
    this.actor,
    this.createdAt,
  });

  factory DisputeEventDto.fromJson(Map<String, dynamic> json) {
    return DisputeEventDto(
      eventType: json['event_type'] as String? ?? 'case_updated',
      note: json['note'] as String?,
      actor: json['actor'] is Map<String, dynamic>
          ? TrustUserDto.fromJson(json['actor'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

class SupportTicketDto {
  final String publicId;
  final String category;
  final String priority;
  final String subject;
  final String status;
  final int messageCount;

  const SupportTicketDto({
    required this.publicId,
    required this.category,
    required this.priority,
    required this.subject,
    required this.status,
    required this.messageCount,
  });

  factory SupportTicketDto.fromJson(Map<String, dynamic> json) {
    return SupportTicketDto(
      publicId: json['public_id'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      priority: json['priority'] as String? ?? 'normal',
      subject: json['subject'] as String? ?? 'Support ticket',
      status: json['status'] as String? ?? 'open',
      messageCount: (json['messages'] as List<dynamic>? ?? const []).length,
    );
  }
}

class AnnouncementDto {
  final String publicId;
  final String title;
  final String body;
  final String status;

  const AnnouncementDto({
    required this.publicId,
    required this.title,
    required this.body,
    required this.status,
  });

  factory AnnouncementDto.fromJson(Map<String, dynamic> json) {
    return AnnouncementDto(
      publicId: json['public_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Announcement',
      body: json['body'] as String? ?? '',
      status: json['status'] as String? ?? 'draft',
    );
  }
}

class NotificationDto {
  final String publicId;
  final String category;
  final String title;
  final String body;
  final String? routeName;
  final bool unread;

  const NotificationDto({
    required this.publicId,
    required this.category,
    required this.title,
    required this.body,
    this.routeName,
    required this.unread,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    return NotificationDto(
      publicId: json['public_id'] as String? ?? '',
      category: json['category'] as String? ?? 'system',
      title: json['title'] as String? ?? 'Notification',
      body: json['body'] as String? ?? '',
      routeName: json['route_name'] as String?,
      unread: json['read_at'] == null,
    );
  }
}

class NotificationsDto {
  final List<NotificationDto> notifications;
  final int unreadCount;

  const NotificationsDto({
    required this.notifications,
    required this.unreadCount,
  });

  factory NotificationsDto.fromJson(Map<String, dynamic> json) {
    return NotificationsDto(
      notifications: (json['notifications'] as List<dynamic>? ?? const [])
          .map((item) => NotificationDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }
}
