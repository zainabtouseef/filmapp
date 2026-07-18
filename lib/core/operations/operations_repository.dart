import '../network/api_client.dart';
import 'operations_models.dart';

class OperationsRepository {
  final ApiClient _client;

  const OperationsRepository(this._client);

  Future<List<LocationPropertyDto>> locationProperties() async {
    final response = await _client.get('/location-properties');
    final data = response['data'] as Map<String, dynamic>;
    return (data['properties'] as List<dynamic>? ?? const [])
        .map((item) =>
            LocationPropertyDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<LocationPropertyDto> createLocationProperty({
    required String name,
    required String propertyType,
    String? areaName,
    String? publicAddress,
    String? privateAddress,
    String? description,
    int? capacity,
    int? parkingSpaces,
    bool powerBackup = false,
    bool accessible = false,
    String status = 'draft',
  }) async {
    final response = await _client.post(
      '/location-properties',
      body: {
        'name': name,
        'property_type': propertyType,
        if (areaName != null) 'area_name': areaName,
        if (publicAddress != null) 'public_address': publicAddress,
        if (privateAddress != null) 'private_address': privateAddress,
        if (description != null) 'description': description,
        if (capacity != null) 'capacity': capacity,
        if (parkingSpaces != null) 'parking_spaces': parkingSpaces,
        'power_backup': powerBackup,
        'accessible': accessible,
        'status': status,
      },
    );
    return LocationPropertyDto.fromJson(
      (response['data'] as Map<String, dynamic>)['property']
          as Map<String, dynamic>,
    );
  }

  Future<void> createLocationSpace(
      String propertyId, Map<String, dynamic> body) {
    return _client.post('/location-properties/$propertyId/spaces', body: body);
  }

  Future<void> createLocationPricing(
      String propertyId, Map<String, dynamic> body) {
    return _client.post('/location-properties/$propertyId/pricing', body: body);
  }

  Future<void> createLocationRule(
      String propertyId, Map<String, dynamic> body) {
    return _client.post('/location-properties/$propertyId/rules', body: body);
  }

  Future<LocationInspectionDto> createLocationInspection({
    required String bookingId,
    required String propertyId,
    required String inspectionType,
    String? meterReading,
    String? notes,
  }) async {
    final response = await _client.post(
      '/location-inspections',
      body: {
        'booking_id': bookingId,
        'property_id': propertyId,
        'inspection_type': inspectionType,
        if (meterReading != null) 'meter_reading': meterReading,
        if (notes != null) 'notes': notes,
      },
    );
    return LocationInspectionDto.fromJson(
      (response['data'] as Map<String, dynamic>)['inspection']
          as Map<String, dynamic>,
    );
  }

  Future<LocationInspectionDto> addLocationInspectionItem({
    required String inspectionId,
    required String areaLabel,
    String? beforeFileId,
    String? afterFileId,
    String? note,
    String issueSeverity = 'none',
  }) async {
    final response = await _client.post(
      '/location-inspections/$inspectionId/items',
      body: {
        'area_label': areaLabel,
        if (beforeFileId != null) 'before_file_id': beforeFileId,
        if (afterFileId != null) 'after_file_id': afterFileId,
        if (note != null) 'note': note,
        'issue_severity': issueSeverity,
      },
    );
    return LocationInspectionDto.fromJson(
      (response['data'] as Map<String, dynamic>)['inspection']
          as Map<String, dynamic>,
    );
  }

  Future<LocationInspectionDto> confirmLocationInspection(
      String inspectionId) async {
    final response =
        await _client.post('/location-inspections/$inspectionId/confirm');
    return LocationInspectionDto.fromJson(
      (response['data'] as Map<String, dynamic>)['inspection']
          as Map<String, dynamic>,
    );
  }

  Future<DamageClaimDto> createDamageClaim({
    required String bookingId,
    required String description,
    required int claimedMinor,
    String currency = 'PKR',
    String? inspectionId,
  }) async {
    final response = await _client.post(
      '/damage-claims',
      body: {
        'booking_id': bookingId,
        'description': description,
        'claimed_minor': claimedMinor,
        'currency': currency,
        if (inspectionId != null) 'inspection_id': inspectionId,
      },
    );
    return DamageClaimDto.fromJson(
      (response['data'] as Map<String, dynamic>)['claim']
          as Map<String, dynamic>,
    );
  }

  Future<DamageClaimDto> addDamageClaimEvidence({
    required String claimId,
    String? fileId,
    String evidenceType = 'photo',
    String? caption,
  }) async {
    final response = await _client.post(
      '/damage-claims/$claimId/evidence',
      body: {
        if (fileId != null) 'file_id': fileId,
        'evidence_type': evidenceType,
        if (caption != null) 'caption': caption,
      },
    );
    return DamageClaimDto.fromJson(
      (response['data'] as Map<String, dynamic>)['claim']
          as Map<String, dynamic>,
    );
  }

  Future<EquipmentProfileDto?> equipmentProfile() async {
    final response = await _client.get('/equipment/provider-profile');
    final data = response['data'] as Map<String, dynamic>;
    final profile = data['profile'] as Map<String, dynamic>?;
    return profile == null ? null : EquipmentProfileDto.fromJson(profile);
  }

  Future<EquipmentProfileDto> upsertEquipmentProfile({
    required String name,
    String providerType = 'rental_house',
    String? coverage,
    String? serviceCategories,
    String? bio,
  }) async {
    final response = await _client.patch(
      '/equipment/provider-profile',
      body: {
        'name': name,
        'provider_type': providerType,
        if (coverage != null) 'coverage': coverage,
        if (serviceCategories != null) 'service_categories': serviceCategories,
        if (bio != null) 'bio': bio,
      },
    );
    return EquipmentProfileDto.fromJson(
      (response['data'] as Map<String, dynamic>)['profile']
          as Map<String, dynamic>,
    );
  }

  Future<List<EquipmentItemDto>> equipmentItems() async {
    final response = await _client.get('/equipment/items');
    final data = response['data'] as Map<String, dynamic>;
    return (data['items'] as List<dynamic>? ?? const [])
        .map((item) => EquipmentItemDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<EquipmentItemDto> createEquipmentItem(
      Map<String, dynamic> body) async {
    final response = await _client.post('/equipment/items', body: body);
    return EquipmentItemDto.fromJson(
      (response['data'] as Map<String, dynamic>)['item']
          as Map<String, dynamic>,
    );
  }

  Future<Map<String, dynamic>> createEquipmentPackage(
      Map<String, dynamic> body) {
    return _client.post('/equipment/packages', body: body);
  }

  Future<void> addEquipmentPackageItem(String packageId, String itemId) {
    return _client.post(
      '/equipment/packages/$packageId/items',
      body: {'equipment_item_id': itemId},
    );
  }

  Future<void> createEquipmentTerm(Map<String, dynamic> body) {
    return _client.post('/equipment/terms', body: body);
  }

  Future<EquipmentInspectionDto> createEquipmentInspection({
    required String bookingId,
    required String providerProfileId,
    required String inspectionType,
  }) async {
    final response = await _client.post(
      '/equipment-inspections',
      body: {
        'booking_id': bookingId,
        'provider_profile_id': providerProfileId,
        'inspection_type': inspectionType,
      },
    );
    return EquipmentInspectionDto.fromJson(
      (response['data'] as Map<String, dynamic>)['inspection']
          as Map<String, dynamic>,
    );
  }

  Future<EquipmentInspectionDto> addEquipmentInspectionItem({
    required String inspectionId,
    required String equipmentItemId,
    String? beforeFileId,
    String? afterFileId,
    String? note,
  }) async {
    final response = await _client.post(
      '/equipment-inspections/$inspectionId/items',
      body: {
        'equipment_item_id': equipmentItemId,
        if (beforeFileId != null) 'before_file_id': beforeFileId,
        if (afterFileId != null) 'after_file_id': afterFileId,
        if (note != null) 'note': note,
      },
    );
    return EquipmentInspectionDto.fromJson(
      (response['data'] as Map<String, dynamic>)['inspection']
          as Map<String, dynamic>,
    );
  }

  Future<EquipmentInspectionDto> confirmEquipmentInspection(
      String inspectionId) async {
    final response =
        await _client.post('/equipment-inspections/$inspectionId/confirm');
    return EquipmentInspectionDto.fromJson(
      (response['data'] as Map<String, dynamic>)['inspection']
          as Map<String, dynamic>,
    );
  }

  Future<SafetyCheckDto> createSafetyCheck(Map<String, dynamic> body) async {
    final response = await _client.post('/safety-checks', body: body);
    return SafetyCheckDto.fromJson(
      (response['data'] as Map<String, dynamic>)['safety_check']
          as Map<String, dynamic>,
    );
  }

  Future<SafetyCheckDto> createSafetyCheckItem(
    String checkId,
    Map<String, dynamic> body,
  ) async {
    final response =
        await _client.post('/safety-checks/$checkId/items', body: body);
    return SafetyCheckDto.fromJson(
      (response['data'] as Map<String, dynamic>)['safety_check']
          as Map<String, dynamic>,
    );
  }

  Future<IncidentDto> createIncident(Map<String, dynamic> body) async {
    final response = await _client.post('/incidents', body: body);
    return IncidentDto.fromJson(
      (response['data'] as Map<String, dynamic>)['incident']
          as Map<String, dynamic>,
    );
  }

  Future<Map<String, dynamic>> createSafetyCheckIn(Map<String, dynamic> body) {
    return _client.post('/safety-check-ins', body: body);
  }

  Future<Map<String, dynamic>> completeSafetyCheckIn(
    String checkInId,
    Map<String, dynamic> body,
  ) {
    return _client.post('/safety-check-ins/$checkInId/complete', body: body);
  }
}
