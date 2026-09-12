class AdminUserRefDto {
  final String publicId;
  final String displayName;

  const AdminUserRefDto({
    required this.publicId,
    required this.displayName,
  });

  factory AdminUserRefDto.fromJson(Map<String, dynamic> json) {
    return AdminUserRefDto(
      publicId: json['public_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Unknown member',
    );
  }
}

class AdminBookingEventDto {
  final String? fromStatus;
  final String toStatus;
  final String? reason;
  final String actor;
  final DateTime? createdAt;

  const AdminBookingEventDto({
    this.fromStatus,
    required this.toStatus,
    this.reason,
    required this.actor,
    this.createdAt,
  });

  factory AdminBookingEventDto.fromJson(Map<String, dynamic> json) {
    return AdminBookingEventDto(
      fromStatus: json['from_status'] as String?,
      toStatus: json['to_status'] as String? ?? 'unknown',
      reason: json['reason'] as String?,
      actor: json['actor'] as String? ?? 'System',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

class AdminBookingRecordDto {
  final String publicId;
  final String projectId;
  final String projectTitle;
  final String listingId;
  final String listingTitle;
  final String listingType;
  final String? city;
  final String category;
  final String status;
  final AdminUserRefDto requester;
  final AdminUserRefDto provider;
  final int? agreedAmountMinor;
  final String currency;
  final DateTime? startAt;
  final DateTime? endAt;
  final String? conversationId;
  final String? negotiationId;
  final int offersCount;
  final String? contractId;
  final String contractStatus;
  final String paymentStatus;
  final DateTime? updatedAt;
  final List<AdminBookingEventDto> statusEvents;

  const AdminBookingRecordDto({
    required this.publicId,
    required this.projectId,
    required this.projectTitle,
    required this.listingId,
    required this.listingTitle,
    required this.listingType,
    this.city,
    required this.category,
    required this.status,
    required this.requester,
    required this.provider,
    this.agreedAmountMinor,
    required this.currency,
    this.startAt,
    this.endAt,
    this.conversationId,
    this.negotiationId,
    required this.offersCount,
    this.contractId,
    required this.contractStatus,
    required this.paymentStatus,
    this.updatedAt,
    required this.statusEvents,
  });

  factory AdminBookingRecordDto.fromJson(Map<String, dynamic> json) {
    return AdminBookingRecordDto(
      publicId: json['public_id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      projectTitle: json['project_title'] as String? ?? 'Untitled project',
      listingId: json['listing_id'] as String? ?? '',
      listingTitle: json['listing_title'] as String? ?? 'Untitled listing',
      listingType: json['listing_type'] as String? ?? 'service',
      city: json['city'] as String?,
      category: json['category'] as String? ?? 'general',
      status: json['status'] as String? ?? 'unknown',
      requester: AdminUserRefDto.fromJson(
        _jsonMap(json['requester']),
      ),
      provider: AdminUserRefDto.fromJson(
        _jsonMap(json['provider']),
      ),
      agreedAmountMinor: (json['agreed_amount_minor'] as num?)?.toInt(),
      currency: json['currency'] as String? ?? 'PKR',
      startAt: DateTime.tryParse(json['start_at'] as String? ?? ''),
      endAt: DateTime.tryParse(json['end_at'] as String? ?? ''),
      conversationId: json['conversation_id'] as String?,
      negotiationId: json['negotiation_id'] as String?,
      offersCount: (json['offers_count'] as num?)?.toInt() ?? 0,
      contractId: json['contract_id'] as String?,
      contractStatus: json['contract_status'] as String? ?? 'not_generated',
      paymentStatus: json['payment_status'] as String? ?? 'not_scheduled',
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
      statusEvents: _jsonList(json['status_events'])
          .map(AdminBookingEventDto.fromJson)
          .toList(),
    );
  }
}

class AdminUserRoleDto {
  final String code;
  final String name;
  final String status;
  final bool isPrimary;

  const AdminUserRoleDto({
    required this.code,
    required this.name,
    required this.status,
    required this.isPrimary,
  });

  factory AdminUserRoleDto.fromJson(Map<String, dynamic> json) {
    return AdminUserRoleDto(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? 'Member',
      status: json['status'] as String? ?? 'active',
      isPrimary: json['is_primary'] as bool? ?? false,
    );
  }
}

class AdminUserRecordDto {
  final String publicId;
  final String displayName;
  final String email;
  final String status;
  final List<AdminUserRoleDto> roles;
  final String kycStatus;
  final String kycRiskLevel;
  final int bookingsCount;
  final int disputesCount;
  final int activeSessions;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;

  const AdminUserRecordDto({
    required this.publicId,
    required this.displayName,
    required this.email,
    required this.status,
    required this.roles,
    required this.kycStatus,
    required this.kycRiskLevel,
    required this.bookingsCount,
    required this.disputesCount,
    required this.activeSessions,
    this.lastLoginAt,
    this.createdAt,
  });

  factory AdminUserRecordDto.fromJson(Map<String, dynamic> json) {
    return AdminUserRecordDto(
      publicId: json['public_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Unknown member',
      email: json['email'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      roles: _jsonList(json['roles']).map(AdminUserRoleDto.fromJson).toList(),
      kycStatus: json['kyc_status'] as String? ?? 'not_started',
      kycRiskLevel: json['kyc_risk_level'] as String? ?? 'unknown',
      bookingsCount: (json['bookings_count'] as num?)?.toInt() ?? 0,
      disputesCount: (json['disputes_count'] as num?)?.toInt() ?? 0,
      activeSessions: (json['active_sessions'] as num?)?.toInt() ?? 0,
      lastLoginAt: DateTime.tryParse(json['last_login_at'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

class AdminListingRecordDto {
  final String publicId;
  final String title;
  final String summary;
  final String listingType;
  final String profileEntityId;
  final AdminUserRefDto owner;
  final String? city;
  final int? priceFromMinor;
  final String currency;
  final String pricingMode;
  final bool showsPrice;
  final bool allowsBargaining;
  final String verificationStatus;
  final String moderationStatus;
  final String visibility;
  final DateTime? publishedAt;
  final int mediaCount;
  final DateTime? updatedAt;

  const AdminListingRecordDto({
    required this.publicId,
    required this.title,
    required this.summary,
    required this.listingType,
    required this.profileEntityId,
    required this.owner,
    this.city,
    this.priceFromMinor,
    required this.currency,
    this.pricingMode = 'negotiable',
    this.showsPrice = true,
    this.allowsBargaining = true,
    required this.verificationStatus,
    required this.moderationStatus,
    required this.visibility,
    this.publishedAt,
    required this.mediaCount,
    this.updatedAt,
  });

  factory AdminListingRecordDto.fromJson(Map<String, dynamic> json) {
    return AdminListingRecordDto(
      publicId: json['public_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled listing',
      summary: json['summary'] as String? ?? '',
      listingType: json['listing_type'] as String? ?? 'service',
      profileEntityId: json['profile_entity_id'] as String? ?? '',
      owner: AdminUserRefDto.fromJson(_jsonMap(json['owner'])),
      city: json['city'] as String?,
      priceFromMinor: (json['price_from_minor'] as num?)?.toInt(),
      currency: json['currency'] as String? ?? 'PKR',
      pricingMode: json['pricing_mode'] as String? ?? 'negotiable',
      showsPrice: json['shows_price'] as bool? ?? true,
      allowsBargaining: json['allows_bargaining'] as bool? ?? true,
      verificationStatus: json['verification_status'] as String? ?? 'pending',
      moderationStatus: json['moderation_status'] as String? ?? 'pending',
      visibility: json['visibility'] as String? ?? 'private',
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
      mediaCount: (json['media_count'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }
}

class AdminTemplateClauseDto {
  final String clauseKey;
  final String title;
  final String bodyText;
  final int sortOrder;
  final bool required;
  final bool editable;

  const AdminTemplateClauseDto({
    required this.clauseKey,
    required this.title,
    required this.bodyText,
    required this.sortOrder,
    required this.required,
    required this.editable,
  });

  factory AdminTemplateClauseDto.fromJson(Map<String, dynamic> json) {
    return AdminTemplateClauseDto(
      clauseKey: json['clause_key'] as String? ?? '',
      title: json['title'] as String? ?? 'Clause',
      bodyText: json['body_text'] as String? ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      required: json['required'] as bool? ?? true,
      editable: json['editable'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clause_key': clauseKey,
      'title': title,
      'body_text': bodyText,
      'sort_order': sortOrder,
      'required': required,
      'editable': editable,
    };
  }
}

class AdminContractTemplateDto {
  final String publicId;
  final String name;
  final String category;
  final String jurisdiction;
  final int versionNumber;
  final String status;
  final DateTime? publishedAt;
  final DateTime? updatedAt;
  final List<AdminTemplateClauseDto> clauses;

  const AdminContractTemplateDto({
    required this.publicId,
    required this.name,
    required this.category,
    required this.jurisdiction,
    required this.versionNumber,
    required this.status,
    this.publishedAt,
    this.updatedAt,
    required this.clauses,
  });

  factory AdminContractTemplateDto.fromJson(Map<String, dynamic> json) {
    return AdminContractTemplateDto(
      publicId: json['public_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled template',
      category: json['category'] as String? ?? 'general',
      jurisdiction: json['jurisdiction'] as String? ?? 'PK',
      versionNumber: (json['version_number'] as num?)?.toInt() ?? 1,
      status: json['status'] as String? ?? 'draft',
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
      clauses: _jsonList(json['clauses'])
          .map(AdminTemplateClauseDto.fromJson)
          .toList(),
    );
  }
}

class AdminFeeRuleDto {
  final String publicId;
  final String name;
  final String category;
  final int basisPoints;
  final int fixedMinor;
  final String currency;
  final bool active;
  final DateTime? updatedAt;

  const AdminFeeRuleDto({
    required this.publicId,
    required this.name,
    required this.category,
    required this.basisPoints,
    required this.fixedMinor,
    required this.currency,
    required this.active,
    this.updatedAt,
  });

  factory AdminFeeRuleDto.fromJson(Map<String, dynamic> json) {
    return AdminFeeRuleDto(
      publicId: json['public_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Fee rule',
      category: json['category'] as String? ?? 'general',
      basisPoints: (json['basis_points'] as num?)?.toInt() ?? 0,
      fixedMinor: (json['fixed_minor'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'PKR',
      active: json['active'] as bool? ?? true,
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }
}

class AdminPermissionDto {
  final String code;
  final String description;

  const AdminPermissionDto({
    required this.code,
    required this.description,
  });

  factory AdminPermissionDto.fromJson(Map<String, dynamic> json) {
    return AdminPermissionDto(
      code: json['code'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

class AdminRoleRecordDto {
  final String code;
  final String name;
  final String portalRoute;
  final bool requiresKyc;
  final int displayOrder;
  final bool isActive;
  final int adminUsers;
  final Set<String> permissions;

  const AdminRoleRecordDto({
    required this.code,
    required this.name,
    required this.portalRoute,
    required this.requiresKyc,
    required this.displayOrder,
    required this.isActive,
    required this.adminUsers,
    required this.permissions,
  });

  factory AdminRoleRecordDto.fromJson(Map<String, dynamic> json) {
    return AdminRoleRecordDto(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? 'Admin role',
      portalRoute: json['portal_route'] as String? ?? '',
      requiresKyc: json['requires_kyc'] as bool? ?? true,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      adminUsers: (json['admin_users'] as num?)?.toInt() ?? 0,
      permissions: (json['permissions'] as List<dynamic>? ?? const [])
          .map((item) => '$item')
          .toSet(),
    );
  }
}

class AdminRolesBundleDto {
  final List<AdminRoleRecordDto> roles;
  final List<AdminPermissionDto> permissions;

  const AdminRolesBundleDto({
    required this.roles,
    required this.permissions,
  });

  factory AdminRolesBundleDto.fromJson(Map<String, dynamic> json) {
    return AdminRolesBundleDto(
      roles: _jsonList(json['roles']).map(AdminRoleRecordDto.fromJson).toList(),
      permissions: _jsonList(json['permissions'])
          .map(AdminPermissionDto.fromJson)
          .toList(),
    );
  }
}

class AdminAuditEventDto {
  final String eventId;
  final DateTime? occurredAt;
  final String eventType;
  final String actor;
  final String affectedUser;
  final String entityType;
  final String entityId;
  final String risk;
  final String description;
  final String route;

  const AdminAuditEventDto({
    required this.eventId,
    this.occurredAt,
    required this.eventType,
    required this.actor,
    required this.affectedUser,
    required this.entityType,
    required this.entityId,
    required this.risk,
    required this.description,
    required this.route,
  });

  factory AdminAuditEventDto.fromJson(Map<String, dynamic> json) {
    return AdminAuditEventDto(
      eventId: json['event_id'] as String? ?? '',
      occurredAt: DateTime.tryParse(json['occurred_at'] as String? ?? ''),
      eventType: json['event_type'] as String? ?? 'platform_event',
      actor: json['actor'] as String? ?? 'System',
      affectedUser: json['affected_user'] as String? ?? 'Platform',
      entityType: json['entity_type'] as String? ?? 'system',
      entityId: json['entity_id'] as String? ?? '',
      risk: json['risk'] as String? ?? 'low',
      description: json['description'] as String? ?? '',
      route: json['route'] as String? ?? '',
    );
  }
}

Map<String, dynamic> _jsonMap(Object? value) {
  return value is Map<String, dynamic> ? value : const {};
}

List<Map<String, dynamic>> _jsonList(Object? value) {
  if (value is! List<dynamic>) return const [];
  return value.whereType<Map<String, dynamic>>().toList();
}
