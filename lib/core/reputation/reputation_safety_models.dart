class ReputationSafetyMetrics {
  final int score;
  final String label;
  final bool verified;
  final double ratingAverage;
  final int reviewCount;
  final double? completionRate;
  final int completedBookings;
  final int totalBookings;
  final int openDisputes;
  final int resolvedDisputes;
  final double? avgResponseHours;
  final List<ReputationSafetyFactor> factors;

  const ReputationSafetyMetrics({
    required this.score,
    required this.label,
    required this.verified,
    required this.ratingAverage,
    required this.reviewCount,
    required this.completionRate,
    required this.completedBookings,
    required this.totalBookings,
    required this.openDisputes,
    required this.resolvedDisputes,
    required this.avgResponseHours,
    required this.factors,
  });

  factory ReputationSafetyMetrics.fromJson(Map<String, dynamic> json) {
    return ReputationSafetyMetrics(
      score: (json['score'] as num?)?.toInt() ?? 0,
      label: json['label'] as String? ?? 'Building',
      verified: json['verified'] as bool? ?? false,
      ratingAverage: (json['rating_average'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble(),
      completedBookings: (json['completed_bookings'] as num?)?.toInt() ?? 0,
      totalBookings: (json['total_bookings'] as num?)?.toInt() ?? 0,
      openDisputes: (json['open_disputes'] as num?)?.toInt() ?? 0,
      resolvedDisputes: (json['resolved_disputes'] as num?)?.toInt() ?? 0,
      avgResponseHours: (json['avg_response_hours'] as num?)?.toDouble(),
      factors: (json['factors'] as List<dynamic>? ?? const [])
          .map((item) => ReputationSafetyFactor.fromJson(
                item as Map<String, dynamic>,
              ))
          .toList(),
    );
  }

  String get completionLabel {
    if (completionRate == null || totalBookings == 0) return 'History building';
    return '${(completionRate! * 100).round()}% completion';
  }

  String get responseLabel {
    final hours = avgResponseHours;
    if (hours == null) return 'Response history building';
    if (hours < 1) return 'Replies under 1h';
    return 'Replies in ${hours.toStringAsFixed(1)}h avg';
  }
}

class ReputationSafetyFactor {
  final String key;
  final String label;
  final int score;
  final int maxScore;
  final String status;
  final String summary;

  const ReputationSafetyFactor({
    required this.key,
    required this.label,
    required this.score,
    required this.maxScore,
    required this.status,
    required this.summary,
  });

  factory ReputationSafetyFactor.fromJson(Map<String, dynamic> json) {
    return ReputationSafetyFactor(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? 'Factor',
      score: (json['score'] as num?)?.toInt() ?? 0,
      maxScore: (json['max_score'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'unknown',
      summary: json['summary'] as String? ?? '',
    );
  }
}
