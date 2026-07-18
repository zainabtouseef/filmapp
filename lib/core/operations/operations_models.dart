class LocationPropertyDto {
  final String publicId;
  final String name;
  final String propertyType;
  final String areaName;
  final String publicAddress;
  final int? capacity;
  final int? parkingSpaces;
  final String status;
  final List<Map<String, dynamic>> spaces;

  const LocationPropertyDto({
    required this.publicId,
    required this.name,
    required this.propertyType,
    required this.areaName,
    required this.publicAddress,
    required this.capacity,
    required this.parkingSpaces,
    required this.status,
    required this.spaces,
  });

  factory LocationPropertyDto.fromJson(Map<String, dynamic> json) {
    return LocationPropertyDto(
      publicId: json['public_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Location',
      propertyType: json['property_type'] as String? ?? 'house',
      areaName: json['area_name'] as String? ?? '',
      publicAddress: json['public_address'] as String? ?? '',
      capacity: (json['capacity'] as num?)?.toInt(),
      parkingSpaces: (json['parking_spaces'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'draft',
      spaces: (json['spaces'] as List<dynamic>? ?? const [])
          .map((item) => item as Map<String, dynamic>)
          .toList(),
    );
  }
}

class LocationInspectionDto {
  final String publicId;
  final String bookingId;
  final String propertyId;
  final String inspectionType;
  final String status;
  final List<Map<String, dynamic>> items;

  const LocationInspectionDto({
    required this.publicId,
    required this.bookingId,
    required this.propertyId,
    required this.inspectionType,
    required this.status,
    required this.items,
  });

  factory LocationInspectionDto.fromJson(Map<String, dynamic> json) {
    return LocationInspectionDto(
      publicId: json['public_id'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      propertyId: json['property_id'] as String? ?? '',
      inspectionType: json['inspection_type'] as String? ?? 'check_in',
      status: json['status'] as String? ?? 'draft',
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

  const DamageClaimDto({
    required this.publicId,
    required this.bookingId,
    required this.claimedMinor,
    required this.currency,
    required this.status,
  });

  factory DamageClaimDto.fromJson(Map<String, dynamic> json) {
    return DamageClaimDto(
      publicId: json['public_id'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      claimedMinor: (json['claimed_minor'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'PKR',
      status: json['status'] as String? ?? 'submitted',
    );
  }
}

class EquipmentProfileDto {
  final String publicId;
  final String name;
  final String coverage;
  final String providerType;
  final String verificationStatus;

  const EquipmentProfileDto({
    required this.publicId,
    required this.name,
    required this.coverage,
    required this.providerType,
    required this.verificationStatus,
  });

  factory EquipmentProfileDto.fromJson(Map<String, dynamic>? json) {
    return EquipmentProfileDto(
      publicId: json?['public_id'] as String? ?? '',
      name: json?['name'] as String? ?? 'Equipment provider',
      coverage: json?['coverage'] as String? ?? '',
      providerType: json?['provider_type'] as String? ?? 'rental_house',
      verificationStatus: json?['verification_status'] as String? ?? 'pending',
    );
  }
}

class EquipmentItemDto {
  final String publicId;
  final String category;
  final String brand;
  final String modelName;
  final int dayRateMinor;
  final int depositMinor;
  final String status;

  const EquipmentItemDto({
    required this.publicId,
    required this.category,
    required this.brand,
    required this.modelName,
    required this.dayRateMinor,
    required this.depositMinor,
    required this.status,
  });

  factory EquipmentItemDto.fromJson(Map<String, dynamic> json) {
    return EquipmentItemDto(
      publicId: json['public_id'] as String? ?? '',
      category: json['category'] as String? ?? 'Camera',
      brand: json['brand'] as String? ?? '',
      modelName: json['model_name'] as String? ?? 'Equipment item',
      dayRateMinor: (json['day_rate_minor'] as num?)?.toInt() ?? 0,
      depositMinor: (json['deposit_minor'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'available',
    );
  }
}

class EquipmentInspectionDto {
  final String publicId;
  final String bookingId;
  final String providerProfileId;
  final String inspectionType;
  final String status;
  final List<Map<String, dynamic>> items;

  const EquipmentInspectionDto({
    required this.publicId,
    required this.bookingId,
    required this.providerProfileId,
    required this.inspectionType,
    required this.status,
    required this.items,
  });

  factory EquipmentInspectionDto.fromJson(Map<String, dynamic> json) {
    return EquipmentInspectionDto(
      publicId: json['public_id'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      providerProfileId: json['provider_profile_id'] as String? ?? '',
      inspectionType: json['inspection_type'] as String? ?? 'handover',
      status: json['status'] as String? ?? 'draft',
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
