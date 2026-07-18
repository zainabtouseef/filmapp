class PersonalDashboardDto {
  final double ratingAverage;
  final int reviewCount;
  final int pendingOffers;
  final int securedValueMinor;
  final int unreadNotifications;
  final int openDisputes;
  final int openSupportTickets;
  final int pendingKyc;

  const PersonalDashboardDto({
    required this.ratingAverage,
    required this.reviewCount,
    required this.pendingOffers,
    required this.securedValueMinor,
    required this.unreadNotifications,
    required this.openDisputes,
    required this.openSupportTickets,
    required this.pendingKyc,
  });

  factory PersonalDashboardDto.fromJson(Map<String, dynamic> json) {
    return PersonalDashboardDto(
      ratingAverage: (json['rating_average'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] as int? ?? 0,
      pendingOffers: json['pending_offers'] as int? ?? 0,
      securedValueMinor: json['secured_value_minor'] as int? ?? 0,
      unreadNotifications: json['unread_notifications'] as int? ?? 0,
      openDisputes: json['open_disputes'] as int? ?? 0,
      openSupportTickets: json['open_support_tickets'] as int? ?? 0,
      pendingKyc: json['pending_kyc'] as int? ?? 0,
    );
  }
}

class AdminDashboardDto {
  final int pendingKycCount;
  final double oldestPendingKycHours;
  final int pendingPaymentProofs;
  final int pendingModerationCases;
  final int openDisputes;
  final int openSupportTickets;
  final int totalUsers;
  final int calculatedPlatformFeesMinor;
  final int securedBookings;
  final double conversionRate;

  const AdminDashboardDto({
    required this.pendingKycCount,
    required this.oldestPendingKycHours,
    required this.pendingPaymentProofs,
    required this.pendingModerationCases,
    required this.openDisputes,
    required this.openSupportTickets,
    required this.totalUsers,
    required this.calculatedPlatformFeesMinor,
    required this.securedBookings,
    required this.conversionRate,
  });

  factory AdminDashboardDto.fromJson(Map<String, dynamic> json) {
    return AdminDashboardDto(
      pendingKycCount: json['pending_kyc_count'] as int? ?? 0,
      oldestPendingKycHours:
          (json['oldest_pending_kyc_hours'] as num?)?.toDouble() ?? 0,
      pendingPaymentProofs: json['pending_payment_proofs'] as int? ?? 0,
      pendingModerationCases: json['pending_moderation_cases'] as int? ?? 0,
      openDisputes: json['open_disputes'] as int? ?? 0,
      openSupportTickets: json['open_support_tickets'] as int? ?? 0,
      totalUsers: json['total_users'] as int? ?? 0,
      calculatedPlatformFeesMinor:
          json['calculated_platform_fees_minor'] as int? ?? 0,
      securedBookings: json['secured_bookings'] as int? ?? 0,
      conversionRate: (json['conversion_rate'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AdminAnalyticsDto {
  final int rangeDays;
  final Map<String, int> newUsersByDay;
  final Map<String, int> newBookingsByDay;
  final Map<String, int> securedBookingsByDay;

  const AdminAnalyticsDto({
    required this.rangeDays,
    required this.newUsersByDay,
    required this.newBookingsByDay,
    required this.securedBookingsByDay,
  });

  factory AdminAnalyticsDto.fromJson(Map<String, dynamic> json) {
    return AdminAnalyticsDto(
      rangeDays: json['range_days'] as int? ?? 30,
      newUsersByDay: _intMap(json['new_users_by_day']),
      newBookingsByDay: _intMap(json['new_bookings_by_day']),
      securedBookingsByDay: _intMap(json['secured_bookings_by_day']),
    );
  }

  static Map<String, int> _intMap(Object? value) {
    if (value is! Map<String, dynamic>) return const {};
    return value.map((key, row) => MapEntry(key, (row as num?)?.toInt() ?? 0));
  }
}

class ExportJobDto {
  final String publicId;
  final String exportType;
  final String status;
  final int rowCount;
  final String? errorMessage;
  final String requestedAt;
  final String? completedAt;
  final String? csvContent;

  const ExportJobDto({
    required this.publicId,
    required this.exportType,
    required this.status,
    required this.rowCount,
    this.errorMessage,
    required this.requestedAt,
    this.completedAt,
    this.csvContent,
  });

  factory ExportJobDto.fromJson(Map<String, dynamic> json) {
    return ExportJobDto(
      publicId: json['public_id'] as String? ?? '',
      exportType: json['export_type'] as String? ?? '',
      status: json['status'] as String? ?? 'processing',
      rowCount: json['row_count'] as int? ?? 0,
      errorMessage: json['error_message'] as String?,
      requestedAt: json['requested_at'] as String? ?? '',
      completedAt: json['completed_at'] as String?,
      csvContent: json['csv_content'] as String?,
    );
  }
}
