class SpecialistUserDto {
  final String publicId;
  final String displayName;
  final String? email;

  const SpecialistUserDto({
    required this.publicId,
    required this.displayName,
    this.email,
  });

  factory SpecialistUserDto.fromJson(Map<String, dynamic> json) {
    return SpecialistUserDto(
      publicId: json['public_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Unknown user',
      email: json['email'] as String?,
    );
  }
}

class AgencyProfileDto {
  final String publicId;
  final String name;
  final int commissionBps;
  final String verificationStatus;

  const AgencyProfileDto({
    required this.publicId,
    required this.name,
    required this.commissionBps,
    required this.verificationStatus,
  });

  factory AgencyProfileDto.fromJson(Map<String, dynamic> json) {
    return AgencyProfileDto(
      publicId: json['public_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Agency',
      commissionBps: json['commission_bps'] as int? ?? 0,
      verificationStatus: json['verification_status'] as String? ?? 'pending',
    );
  }
}

class AgencyInvitationDto {
  final String publicId;
  final String agencyId;
  final String representationType;
  final int commissionBps;
  final String status;

  const AgencyInvitationDto({
    required this.publicId,
    required this.agencyId,
    required this.representationType,
    required this.commissionBps,
    required this.status,
  });

  factory AgencyInvitationDto.fromJson(Map<String, dynamic> json) {
    return AgencyInvitationDto(
      publicId: json['public_id'] as String? ?? '',
      agencyId: json['agency_id'] as String? ?? '',
      representationType:
          json['representation_type'] as String? ?? 'non_exclusive',
      commissionBps: json['commission_bps'] as int? ?? 0,
      status: json['status'] as String? ?? 'pending',
    );
  }
}

class AgencyTalentDto {
  final String talentProfileId;
  final String screenName;
  final String representationType;
  final int commissionBps;
  final String status;

  const AgencyTalentDto({
    required this.talentProfileId,
    required this.screenName,
    required this.representationType,
    required this.commissionBps,
    required this.status,
  });

  factory AgencyTalentDto.fromJson(Map<String, dynamic> json) {
    return AgencyTalentDto(
      talentProfileId: json['talent_profile_id'] as String? ?? '',
      screenName: json['screen_name'] as String? ?? 'Talent',
      representationType:
          json['representation_type'] as String? ?? 'non_exclusive',
      commissionBps: json['commission_bps'] as int? ?? 0,
      status: json['status'] as String? ?? 'active',
    );
  }
}

class AuditionCandidateDto {
  final String publicId;
  final String talentProfileId;
  final String screenName;
  final String status;
  final int rank;
  final int selfTapeCount;
  final int selectionNoteCount;

  const AuditionCandidateDto({
    required this.publicId,
    required this.talentProfileId,
    required this.screenName,
    required this.status,
    required this.rank,
    required this.selfTapeCount,
    required this.selectionNoteCount,
  });

  factory AuditionCandidateDto.fromJson(Map<String, dynamic> json) {
    final talent = json['talent_profile'] as Map<String, dynamic>? ?? const {};
    return AuditionCandidateDto(
      publicId: json['public_id'] as String? ?? '',
      talentProfileId: talent['public_id'] as String? ?? '',
      screenName: talent['screen_name'] as String? ?? 'Candidate',
      status: json['status'] as String? ?? 'submitted',
      rank: json['rank'] as int? ?? 100,
      selfTapeCount: (json['self_tapes'] as List<dynamic>? ?? const []).length,
      selectionNoteCount:
          (json['selection_notes'] as List<dynamic>? ?? const []).length,
    );
  }
}

class AuditionDto {
  final String publicId;
  final String agencyId;
  final String projectId;
  final String roleTitle;
  final int? budgetMinor;
  final String currency;
  final String status;
  final List<AuditionCandidateDto> candidates;

  const AuditionDto({
    required this.publicId,
    required this.agencyId,
    required this.projectId,
    required this.roleTitle,
    this.budgetMinor,
    required this.currency,
    required this.status,
    required this.candidates,
  });

  factory AuditionDto.fromJson(Map<String, dynamic> json) {
    return AuditionDto(
      publicId: json['public_id'] as String? ?? '',
      agencyId: json['agency_id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      roleTitle: json['role_title'] as String? ?? 'Role',
      budgetMinor: json['budget_minor'] as int?,
      currency: json['currency'] as String? ?? 'PKR',
      status: json['status'] as String? ?? 'requested',
      candidates: (json['candidates'] as List<dynamic>? ?? const [])
          .map((item) =>
              AuditionCandidateDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AgencyCommissionDto {
  final String publicId;
  final String bookingId;
  final int commissionMinor;
  final String currency;
  final String status;

  const AgencyCommissionDto({
    required this.publicId,
    required this.bookingId,
    required this.commissionMinor,
    required this.currency,
    required this.status,
  });

  factory AgencyCommissionDto.fromJson(Map<String, dynamic> json) {
    return AgencyCommissionDto(
      publicId: json['public_id'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      commissionMinor: json['commission_minor'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'PKR',
      status: json['status'] as String? ?? 'pending',
    );
  }
}

class BrandProfileDto {
  final String publicId;
  final String name;
  final String? category;
  final String? representative;
  final String trustStatus;
  final String? description;

  const BrandProfileDto({
    required this.publicId,
    required this.name,
    this.category,
    this.representative,
    required this.trustStatus,
    this.description,
  });

  factory BrandProfileDto.fromJson(Map<String, dynamic> json) {
    return BrandProfileDto(
      publicId: json['public_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Brand',
      category: json['category'] as String?,
      representative: json['representative'] as String?,
      trustStatus: json['trust_status'] as String? ?? 'pending',
      description: json['description'] as String?,
    );
  }
}

class BrandOpportunityDto {
  final String publicId;
  final String title;
  final String category;
  final int? budgetMinor;
  final String currency;
  final String status;
  final int applicationCount;

  const BrandOpportunityDto({
    required this.publicId,
    required this.title,
    required this.category,
    this.budgetMinor,
    required this.currency,
    required this.status,
    required this.applicationCount,
  });

  factory BrandOpportunityDto.fromJson(Map<String, dynamic> json) {
    return BrandOpportunityDto(
      publicId: json['public_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Opportunity',
      category: json['category'] as String? ?? 'sponsorship',
      budgetMinor: json['budget_minor'] as int?,
      currency: json['currency'] as String? ?? 'PKR',
      status: json['status'] as String? ?? 'draft',
      applicationCount:
          (json['applications'] as List<dynamic>? ?? const []).length,
    );
  }
}

class BrandApplicationDto {
  final String publicId;
  final String status;
  final int? budgetAskMinor;
  final String currency;
  final int termsCount;

  const BrandApplicationDto({
    required this.publicId,
    required this.status,
    this.budgetAskMinor,
    required this.currency,
    required this.termsCount,
  });

  factory BrandApplicationDto.fromJson(Map<String, dynamic> json) {
    return BrandApplicationDto(
      publicId: json['public_id'] as String? ?? '',
      status: json['status'] as String? ?? 'submitted',
      budgetAskMinor: json['budget_ask_minor'] as int?,
      currency: json['currency'] as String? ?? 'PKR',
      termsCount: (json['terms'] as List<dynamic>? ?? const []).length,
    );
  }
}

class CampaignDeliverableDto {
  final String publicId;
  final String opportunityId;
  final String label;
  final String status;
  final int metricCount;

  const CampaignDeliverableDto({
    required this.publicId,
    required this.opportunityId,
    required this.label,
    required this.status,
    required this.metricCount,
  });

  factory CampaignDeliverableDto.fromJson(Map<String, dynamic> json) {
    return CampaignDeliverableDto(
      publicId: json['public_id'] as String? ?? '',
      opportunityId: json['opportunity_id'] as String? ?? '',
      label: json['label'] as String? ?? 'Deliverable',
      status: json['status'] as String? ?? 'pending',
      metricCount: (json['metrics'] as List<dynamic>? ?? const []).length,
    );
  }
}

class ModelProfileDto {
  final String publicId;
  final String talentProfileId;
  final String? brandSafetyNotes;
  final bool publicVisibility;
  final List<ModelCampaignCategoryDto> campaignCategories;
  final List<ModelUsageRightDto> usageRights;
  final List<ModelUsageRateDto> usageRates;
  final List<ModelRestrictedCategoryDto> restrictedCategories;

  const ModelProfileDto({
    required this.publicId,
    required this.talentProfileId,
    this.brandSafetyNotes,
    required this.publicVisibility,
    required this.campaignCategories,
    required this.usageRights,
    required this.usageRates,
    required this.restrictedCategories,
  });

  factory ModelProfileDto.fromJson(Map<String, dynamic> json) {
    return ModelProfileDto(
      publicId: json['public_id'] as String? ?? '',
      talentProfileId: json['talent_profile_id'] as String? ?? '',
      brandSafetyNotes: json['brand_safety_notes'] as String?,
      publicVisibility: json['public_visibility'] as bool? ?? true,
      campaignCategories: (json['campaign_categories'] as List<dynamic>? ??
              const [])
          .map((item) =>
              ModelCampaignCategoryDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      usageRights: (json['usage_rights'] as List<dynamic>? ?? const [])
          .map((item) =>
              ModelUsageRightDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      usageRates: (json['usage_rates'] as List<dynamic>? ?? const [])
          .map((item) =>
              ModelUsageRateDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      restrictedCategories: (json['restricted_categories'] as List<dynamic>? ??
              const [])
          .map((item) =>
              ModelRestrictedCategoryDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ModelCampaignCategoryDto {
  final String category;
  final bool selected;
  final bool publicVisible;

  const ModelCampaignCategoryDto({
    required this.category,
    required this.selected,
    required this.publicVisible,
  });

  factory ModelCampaignCategoryDto.fromJson(Map<String, dynamic> json) {
    return ModelCampaignCategoryDto(
      category: json['category'] as String? ?? '',
      selected: json['selected'] as bool? ?? true,
      publicVisible: json['public_visible'] as bool? ?? true,
    );
  }
}

class ModelUsageRightDto {
  final String publicId;
  final String platform;
  final String territory;
  final int? durationMonths;
  final bool exclusive;
  final String status;

  const ModelUsageRightDto({
    required this.publicId,
    required this.platform,
    required this.territory,
    this.durationMonths,
    required this.exclusive,
    required this.status,
  });

  factory ModelUsageRightDto.fromJson(Map<String, dynamic> json) {
    return ModelUsageRightDto(
      publicId: json['public_id'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      territory: json['territory'] as String? ?? '',
      durationMonths: json['duration_months'] as int?,
      exclusive: json['exclusive'] as bool? ?? false,
      status: json['status'] as String? ?? 'active',
    );
  }
}

class ModelUsageRateDto {
  final String publicId;
  final String label;
  final String? scope;
  final int amountMinor;
  final String currency;
  final bool requiresReview;
  final bool negotiable;

  const ModelUsageRateDto({
    required this.publicId,
    required this.label,
    this.scope,
    required this.amountMinor,
    required this.currency,
    required this.requiresReview,
    required this.negotiable,
  });

  factory ModelUsageRateDto.fromJson(Map<String, dynamic> json) {
    return ModelUsageRateDto(
      publicId: json['public_id'] as String? ?? '',
      label: json['label'] as String? ?? 'Usage rate',
      scope: json['scope'] as String?,
      amountMinor: json['amount_minor'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'PKR',
      requiresReview: json['requires_review'] as bool? ?? false,
      negotiable: json['negotiable'] as bool? ?? true,
    );
  }
}

class ModelRestrictedCategoryDto {
  final String category;
  final bool blocked;
  final String? reason;

  const ModelRestrictedCategoryDto({
    required this.category,
    required this.blocked,
    this.reason,
  });

  factory ModelRestrictedCategoryDto.fromJson(Map<String, dynamic> json) {
    return ModelRestrictedCategoryDto(
      category: json['category'] as String? ?? '',
      blocked: json['blocked'] as bool? ?? true,
      reason: json['reason'] as String?,
    );
  }
}

class DistributionProfileDto {
  final String publicId;
  final String name;
  final String? channels;
  final String? territories;
  final String status;

  const DistributionProfileDto({
    required this.publicId,
    required this.name,
    this.channels,
    this.territories,
    required this.status,
  });

  factory DistributionProfileDto.fromJson(Map<String, dynamic> json) {
    return DistributionProfileDto(
      publicId: json['public_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Distribution partner',
      channels: json['channels'] as String?,
      territories: json['territories'] as String?,
      status: json['status'] as String? ?? 'active',
    );
  }
}

class DistributionProjectDto {
  final String publicId;
  final String projectId;
  final String partnerProfileId;
  final String? territories;
  final String? missingItems;
  final String? statusNote;
  final String status;
  final int handoverCount;
  final int releaseWindowCount;

  const DistributionProjectDto({
    required this.publicId,
    required this.projectId,
    required this.partnerProfileId,
    this.territories,
    this.missingItems,
    this.statusNote,
    required this.status,
    required this.handoverCount,
    required this.releaseWindowCount,
  });

  factory DistributionProjectDto.fromJson(Map<String, dynamic> json) {
    return DistributionProjectDto(
      publicId: json['public_id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      partnerProfileId: json['partner_profile_id'] as String? ?? '',
      territories: json['territories'] as String?,
      missingItems: json['missing_items'] as String?,
      statusNote: json['status_note'] as String?,
      status: json['status'] as String? ?? 'onboarding',
      handoverCount:
          (json['handover_items'] as List<dynamic>? ?? const []).length,
      releaseWindowCount:
          (json['release_windows'] as List<dynamic>? ?? const []).length,
    );
  }
}

class DistributorContactDto {
  final String publicId;
  final String name;
  final String channel;
  final String? territory;
  final String? contactRole;
  final String? priorProject;
  final String? notes;
  final String status;

  const DistributorContactDto({
    required this.publicId,
    required this.name,
    required this.channel,
    this.territory,
    this.contactRole,
    this.priorProject,
    this.notes,
    required this.status,
  });

  factory DistributorContactDto.fromJson(Map<String, dynamic> json) {
    return DistributorContactDto(
      publicId: json['public_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Distributor',
      channel: json['channel'] as String? ?? 'cinema',
      territory: json['territory'] as String?,
      contactRole: json['contact_role'] as String?,
      priorProject: json['prior_project'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'active',
    );
  }
}

class DistributionReportDto {
  final String publicId;
  final String distributionProjectId;
  final String territory;
  final String channel;
  final int audienceCount;
  final int revenueMinor;
  final String currency;
  final String status;

  const DistributionReportDto({
    required this.publicId,
    required this.distributionProjectId,
    required this.territory,
    required this.channel,
    required this.audienceCount,
    required this.revenueMinor,
    required this.currency,
    required this.status,
  });

  factory DistributionReportDto.fromJson(Map<String, dynamic> json) {
    return DistributionReportDto(
      publicId: json['public_id'] as String? ?? '',
      distributionProjectId: json['distribution_project_id'] as String? ?? '',
      territory: json['territory'] as String? ?? '',
      channel: json['channel'] as String? ?? '',
      audienceCount: json['audience_count'] as int? ?? 0,
      revenueMinor: json['revenue_minor'] as int? ?? 0,
      currency: json['currency'] as String? ?? 'PKR',
      status: json['status'] as String? ?? 'submitted',
    );
  }
}
