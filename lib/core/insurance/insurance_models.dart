class InsuranceProfileDto {
  final String publicId;
  final String name;
  final String coverageRegions;
  final String status;

  const InsuranceProfileDto({
    required this.publicId,
    required this.name,
    required this.coverageRegions,
    required this.status,
  });

  factory InsuranceProfileDto.fromJson(Map<String, dynamic>? json) {
    return InsuranceProfileDto(
      publicId: json?['public_id'] as String? ?? '',
      name: json?['name'] as String? ?? 'Insurance partner',
      coverageRegions: json?['coverage_regions'] as String? ?? '',
      status: json?['status'] as String? ?? 'pending',
    );
  }
}

class InsurancePolicyDto {
  final String publicId;
  final String? projectId;
  final String? bookingId;
  final String providerProfileId;
  final String insuredUserName;
  final String coverageSummary;
  final String riskLevel;
  final String status;

  const InsurancePolicyDto({
    required this.publicId,
    required this.projectId,
    required this.bookingId,
    required this.providerProfileId,
    required this.insuredUserName,
    required this.coverageSummary,
    required this.riskLevel,
    required this.status,
  });

  factory InsurancePolicyDto.fromJson(Map<String, dynamic> json) {
    final insured = json['insured_user'] as Map<String, dynamic>?;
    return InsurancePolicyDto(
      publicId: json['public_id'] as String? ?? '',
      projectId: json['project_id'] as String?,
      bookingId: json['booking_id'] as String?,
      providerProfileId: json['provider_profile_id'] as String? ?? '',
      insuredUserName: insured?['display_name'] as String? ?? 'Insured user',
      coverageSummary: json['coverage_summary'] as String? ?? '',
      riskLevel: json['risk_level'] as String? ?? 'low',
      status: json['status'] as String? ?? 'active',
    );
  }
}

class InsuranceClaimDto {
  final String publicId;
  final String policyId;
  final String? bookingId;
  final String title;
  final int? estimateMinor;
  final String currency;
  final String status;
  final List<Map<String, dynamic>> evidence;

  const InsuranceClaimDto({
    required this.publicId,
    required this.policyId,
    required this.bookingId,
    required this.title,
    required this.estimateMinor,
    required this.currency,
    required this.status,
    required this.evidence,
  });

  factory InsuranceClaimDto.fromJson(Map<String, dynamic> json) {
    return InsuranceClaimDto(
      publicId: json['public_id'] as String? ?? '',
      policyId: json['policy_id'] as String? ?? '',
      bookingId: json['booking_id'] as String?,
      title: json['title'] as String? ?? 'Insurance claim',
      estimateMinor: (json['estimate_minor'] as num?)?.toInt(),
      currency: json['currency'] as String? ?? 'PKR',
      status: json['status'] as String? ?? 'submitted',
      evidence: (json['evidence'] as List<dynamic>? ?? const [])
          .map((item) => item as Map<String, dynamic>)
          .toList(),
    );
  }
}

class InsuranceDashboardDto {
  final int policyCount;
  final int activePolicyCount;
  final int openClaims;

  const InsuranceDashboardDto({
    required this.policyCount,
    required this.activePolicyCount,
    required this.openClaims,
  });

  factory InsuranceDashboardDto.fromJson(Map<String, dynamic> json) {
    return InsuranceDashboardDto(
      policyCount: (json['policy_count'] as num?)?.toInt() ?? 0,
      activePolicyCount: (json['active_policy_count'] as num?)?.toInt() ?? 0,
      openClaims: (json['open_claims'] as num?)?.toInt() ?? 0,
    );
  }
}
