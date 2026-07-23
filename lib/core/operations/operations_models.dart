class LocationPropertyDto {
  final String publicId;
  final String name;
  final String propertyType;
  final String cityName;
  final String areaName;
  final String publicAddress;
  final String description;
  final int? capacity;
  final int? parkingSpaces;
  final bool powerBackup;
  final bool accessible;
  final double ratingAverage;
  final String status;
  final List<Map<String, dynamic>> spaces;
  final List<LocationPricingDto> pricing;
  final List<LocationRuleDto> rules;
  final List<String> mediaUrls;

  const LocationPropertyDto({
    required this.publicId,
    required this.name,
    required this.propertyType,
    required this.cityName,
    required this.areaName,
    required this.publicAddress,
    required this.description,
    required this.capacity,
    required this.parkingSpaces,
    required this.powerBackup,
    required this.accessible,
    required this.ratingAverage,
    required this.status,
    required this.spaces,
    required this.pricing,
    required this.rules,
    required this.mediaUrls,
  });

  factory LocationPropertyDto.fromJson(Map<String, dynamic> json) {
    final city = json['city'] as Map<String, dynamic>?;
    return LocationPropertyDto(
      publicId: json['public_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Location',
      propertyType: json['property_type'] as String? ?? 'house',
      cityName: city?['name'] as String? ?? '',
      areaName: json['area_name'] as String? ?? '',
      publicAddress: json['public_address'] as String? ?? '',
      description: json['description'] as String? ?? '',
      capacity: (json['capacity'] as num?)?.toInt(),
      parkingSpaces: (json['parking_spaces'] as num?)?.toInt(),
      powerBackup: json['power_backup'] as bool? ?? false,
      accessible: json['accessible'] as bool? ?? false,
      ratingAverage: (json['rating_average'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'draft',
      spaces: (json['spaces'] as List<dynamic>? ?? const [])
          .map((item) => item as Map<String, dynamic>)
          .toList(),
      pricing: (json['pricing'] as List<dynamic>? ?? const [])
          .map((item) =>
              LocationPricingDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      rules: (json['rules'] as List<dynamic>? ?? const [])
          .map((item) => LocationRuleDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      mediaUrls: (json['media_files'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((file) {
            final publicUrl = file['public_url'] as String?;
            if (publicUrl != null && publicUrl.isNotEmpty) return publicUrl;
            return file['download_url'] as String? ?? '';
          })
          .where((url) => url.isNotEmpty)
          .toList(),
    );
  }
}

class LocationPricingDto {
  final String publicId;
  final String label;
  final int amountMinor;
  final String currency;
  final String unit;
  final bool enabled;
  final String? conditions;

  const LocationPricingDto({
    required this.publicId,
    required this.label,
    required this.amountMinor,
    required this.currency,
    required this.unit,
    required this.enabled,
    required this.conditions,
  });

  factory LocationPricingDto.fromJson(Map<String, dynamic> json) {
    return LocationPricingDto(
      publicId: json['public_id'] as String? ?? '',
      label: json['label'] as String? ?? 'Location rate',
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'PKR',
      unit: json['unit'] as String? ?? 'day',
      enabled: json['enabled'] as bool? ?? true,
      conditions: json['conditions'] as String?,
    );
  }
}

class LocationRuleDto {
  final String publicId;
  final String ruleType;
  final String label;
  final String note;
  final bool allowed;

  const LocationRuleDto({
    required this.publicId,
    required this.ruleType,
    required this.label,
    required this.note,
    required this.allowed,
  });

  factory LocationRuleDto.fromJson(Map<String, dynamic> json) {
    return LocationRuleDto(
      publicId: json['public_id'] as String? ?? '',
      ruleType: json['rule_type'] as String? ?? 'general',
      label: json['label'] as String? ?? 'Property rule',
      note: json['note'] as String? ?? '',
      allowed: json['allowed'] as bool? ?? true,
    );
  }
}

class LocationInspectionDto {
  final String publicId;
  final String bookingId;
  final String propertyId;
  final String inspectionType;
  final String status;
  final DateTime? confirmedByOwnerAt;
  final DateTime? confirmedByRenterAt;
  final String? meterReading;
  final String? notes;
  final List<Map<String, dynamic>> items;

  const LocationInspectionDto({
    required this.publicId,
    required this.bookingId,
    required this.propertyId,
    required this.inspectionType,
    required this.status,
    required this.confirmedByOwnerAt,
    required this.confirmedByRenterAt,
    required this.meterReading,
    required this.notes,
    required this.items,
  });

  factory LocationInspectionDto.fromJson(Map<String, dynamic> json) {
    return LocationInspectionDto(
      publicId: json['public_id'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      propertyId: json['property_id'] as String? ?? '',
      inspectionType: json['inspection_type'] as String? ?? 'check_in',
      status: json['status'] as String? ?? 'draft',
      confirmedByOwnerAt:
          DateTime.tryParse(json['confirmed_by_owner_at'] as String? ?? ''),
      confirmedByRenterAt:
          DateTime.tryParse(json['confirmed_by_renter_at'] as String? ?? ''),
      meterReading: json['meter_reading'] as String?,
      notes: json['notes'] as String?,
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((item) => item as Map<String, dynamic>)
          .toList(),
    );
  }
}

class DamageClaimDto {
  final String publicId;
  final String bookingId;
  final int claimedMinor;
  final String currency;
  final String status;
  final String description;
  final String? inspectionId;
  final List<Map<String, dynamic>> evidence;

  const DamageClaimDto({
    required this.publicId,
    required this.bookingId,
    required this.claimedMinor,
    required this.currency,
    required this.status,
    required this.description,
    required this.inspectionId,
    required this.evidence,
  });

  factory DamageClaimDto.fromJson(Map<String, dynamic> json) {
    return DamageClaimDto(
      publicId: json['public_id'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      claimedMinor: (json['claimed_minor'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'PKR',
      status: json['status'] as String? ?? 'submitted',
      description: json['description'] as String? ?? '',
      inspectionId: json['inspection_id'] as String?,
      evidence: (json['evidence'] as List<dynamic>? ?? const [])
          .map((item) => item as Map<String, dynamic>)
          .toList(),
    );
  }
}

class EquipmentProfileDto {
  final String publicId;
  final String name;
  final String coverage;
  final String providerType;
  final String verificationStatus;
  final String serviceCategories;
  final String bio;
  final String? listingId;
  final String visibility;
  final int ratingAverage;

  const EquipmentProfileDto({
    required this.publicId,
    required this.name,
    required this.coverage,
    required this.providerType,
    required this.verificationStatus,
    required this.serviceCategories,
    required this.bio,
    required this.listingId,
    required this.visibility,
    required this.ratingAverage,
  });

  factory EquipmentProfileDto.fromJson(Map<String, dynamic>? json) {
    return EquipmentProfileDto(
      publicId: json?['public_id'] as String? ?? '',
      name: json?['name'] as String? ?? 'Equipment provider',
      coverage: json?['coverage'] as String? ?? '',
      providerType: json?['provider_type'] as String? ?? 'rental_house',
      verificationStatus: json?['verification_status'] as String? ?? 'pending',
      serviceCategories: json?['service_categories'] as String? ?? '',
      bio: json?['bio'] as String? ?? '',
      listingId: json?['listing_id'] as String?,
      visibility: json?['visibility'] as String? ?? 'private',
      ratingAverage: (json?['rating_average'] as num?)?.toInt() ?? 0,
    );
  }
}

class EquipmentItemDto {
  final String publicId;
  final String category;
  final String brand;
  final String modelName;
  final String condition;
  final int dayRateMinor;
  final int depositMinor;
  final String currency;
  final String status;

  const EquipmentItemDto({
    required this.publicId,
    required this.category,
    required this.brand,
    required this.modelName,
    required this.condition,
    required this.dayRateMinor,
    required this.depositMinor,
    required this.currency,
    required this.status,
  });

  factory EquipmentItemDto.fromJson(Map<String, dynamic> json) {
    return EquipmentItemDto(
      publicId: json['public_id'] as String? ?? '',
      category: json['category'] as String? ?? 'Camera',
      brand: json['brand'] as String? ?? '',
      modelName: json['model_name'] as String? ?? 'Equipment item',
      condition: json['condition'] as String? ?? 'good',
      dayRateMinor: (json['day_rate_minor'] as num?)?.toInt() ?? 0,
      depositMinor: (json['deposit_minor'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'PKR',
      status: json['status'] as String? ?? 'available',
    );
  }
}

class EquipmentPackageDto {
  final String publicId;
  final String name;
  final String description;
  final bool operatorIncluded;
  final int priceMinor;
  final String currency;
  final String terms;
  final String status;
  final List<Map<String, dynamic>> items;

  const EquipmentPackageDto({
    required this.publicId,
    required this.name,
    required this.description,
    required this.operatorIncluded,
    required this.priceMinor,
    required this.currency,
    required this.terms,
    required this.status,
    required this.items,
  });

  factory EquipmentPackageDto.fromJson(Map<String, dynamic> json) {
    return EquipmentPackageDto(
      publicId: json['public_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Equipment package',
      description: json['description'] as String? ?? '',
      operatorIncluded: json['operator_included'] as bool? ?? false,
      priceMinor: (json['price_minor'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'PKR',
      terms: json['terms'] as String? ?? '',
      status: json['status'] as String? ?? 'draft',
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((item) => item as Map<String, dynamic>)
          .toList(),
    );
  }
}

class EquipmentTermDto {
  final String publicId;
  final String? equipmentItemId;
  final String label;
  final String note;
  final int amountMinor;
  final String currency;
  final bool enabled;
  final String termType;

  const EquipmentTermDto({
    required this.publicId,
    required this.equipmentItemId,
    required this.label,
    required this.note,
    required this.amountMinor,
    required this.currency,
    required this.enabled,
    required this.termType,
  });

  factory EquipmentTermDto.fromJson(Map<String, dynamic> json) {
    return EquipmentTermDto(
      publicId: json['public_id'] as String? ?? '',
      equipmentItemId: json['equipment_item_id'] as String?,
      label: json['label'] as String? ?? 'Rental term',
      note: json['note'] as String? ?? '',
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'PKR',
      enabled: json['enabled'] as bool? ?? true,
      termType: json['term_type'] as String? ?? 'late_fee',
    );
  }
}

class EquipmentInspectionDto {
  final String publicId;
  final String bookingId;
  final String providerProfileId;
  final String inspectionType;
  final String status;
  final bool signedByProvider;
  final bool signedByRenter;
  final DateTime? handoverAt;
  final DateTime? returnAt;
  final List<Map<String, dynamic>> items;

  const EquipmentInspectionDto({
    required this.publicId,
    required this.bookingId,
    required this.providerProfileId,
    required this.inspectionType,
    required this.status,
    required this.signedByProvider,
    required this.signedByRenter,
    required this.handoverAt,
    required this.returnAt,
    required this.items,
  });

  factory EquipmentInspectionDto.fromJson(Map<String, dynamic> json) {
    return EquipmentInspectionDto(
      publicId: json['public_id'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      providerProfileId: json['provider_profile_id'] as String? ?? '',
      inspectionType: json['inspection_type'] as String? ?? 'handover',
      status: json['status'] as String? ?? 'draft',
      signedByProvider: json['signed_by_provider'] as bool? ?? false,
      signedByRenter: json['signed_by_renter'] as bool? ?? false,
      handoverAt: DateTime.tryParse(json['handover_at'] as String? ?? ''),
      returnAt: DateTime.tryParse(json['return_at'] as String? ?? ''),
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((item) => item as Map<String, dynamic>)
          .toList(),
    );
  }
}

class SafetyCheckDto {
  final String publicId;
  final String projectId;
  final String riskLevel;
  final String status;

  const SafetyCheckDto({
    required this.publicId,
    required this.projectId,
    required this.riskLevel,
    required this.status,
  });

  factory SafetyCheckDto.fromJson(Map<String, dynamic> json) {
    return SafetyCheckDto(
      publicId: json['public_id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      riskLevel: json['risk_level'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'in_review',
    );
  }
}

class IncidentDto {
  final String publicId;
  final String projectId;
  final String title;
  final String severity;
  final String status;

  const IncidentDto({
    required this.publicId,
    required this.projectId,
    required this.title,
    required this.severity,
    required this.status,
  });

  factory IncidentDto.fromJson(Map<String, dynamic> json) {
    return IncidentDto(
      publicId: json['public_id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Incident',
      severity: json['severity'] as String? ?? 'low',
      status: json['status'] as String? ?? 'open',
    );
  }
}
