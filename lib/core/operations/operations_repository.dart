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

  Future<LocationPropertyDto> updateLocationProperty({
    required String propertyId,
    String? name,
    String? propertyType,
    String? areaName,
    String? publicAddress,
    String? privateAddress,
    String? description,
    int? capacity,
    int? parkingSpaces,
    bool? powerBackup,
    bool? accessible,
    String? status,
  }) async {
    final response = await _client.patch(
      '/location-properties/$propertyId',
      body: {
        if (name != null) 'name': name,
        if (propertyType != null) 'property_type': propertyType,
        if (areaName != null) 'area_name': areaName,
        if (publicAddress != null) 'public_address': publicAddress,
        if (privateAddress != null) 'private_address': privateAddress,
        if (description != null) 'description': description,
        if (capacity != null) 'capacity': capacity,
        if (parkingSpaces != null) 'parking_spaces': parkingSpaces,
        if (powerBackup != null) 'power_backup': powerBackup,
        if (accessible != null) 'accessible': accessible,
        if (status != null) 'status': status,
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

  Future<void> updateLocationSpace(String spaceId, Map<String, dynamic> body) {
    return _client.patch('/location-spaces/$spaceId', body: body);
  }

  Future<void> createLocationPricing(
      String propertyId, Map<String, dynamic> body) {
    return _client.post('/location-properties/$propertyId/pricing', body: body);
  }

  Future<void> updateLocationPricing(
      String pricingId, Map<String, dynamic> body) {
    return _client.patch('/location-pricing/$pricingId', body: body);
  }

  Future<void> createLocationRule(
      String propertyId, Map<String, dynamic> body) {
    return _client.post('/location-properties/$propertyId/rules', body: body);
  }

  Future<void> updateLocationRule(String ruleId, Map<String, dynamic> body) {
    return _client.patch('/location-rules/$ruleId', body: body);
  }

  Future<String> publishLocationListing({
    required String propertyId,
    required String title,
    required String summary,
    List<String> fileIds = const [],
  }) async {
    final response = await _client.post(
      '/marketplace/listings',
      body: {
        'listing_type': 'location',
        'profile_entity_id': propertyId,
        'title': title,
        'summary': summary,
        if (fileIds.isNotEmpty) 'file_ids': fileIds,
      },
    );
    final listing = (response['data'] as Map<String, dynamic>)['listing']
        as Map<String, dynamic>;
    return listing['public_id'] as String? ?? '';
  }

  Future<List<LocationInspectionDto>> locationInspections({
    String? propertyId,
    String? bookingId,
    String? inspectionType,
  }) async {
    final query = <String>[
      if (propertyId != null && propertyId.isNotEmpty)
        'property_id=${Uri.encodeQueryComponent(propertyId)}',
      if (bookingId != null && bookingId.isNotEmpty)
        'booking_id=${Uri.encodeQueryComponent(bookingId)}',
      if (inspectionType != null && inspectionType.isNotEmpty)
        'type=${Uri.encodeQueryComponent(inspectionType)}',
    ];
    final suffix = query.isEmpty ? '' : '?${query.join('&')}';
    final response = await _client.get('/location-inspections$suffix');
    final data = response['data'] as Map<String, dynamic>;
    return (data['inspections'] as List<dynamic>? ?? const [])
        .map((item) =>
            LocationInspectionDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<DamageClaimDto>> damageClaims({String? bookingId}) async {
    final suffix = bookingId == null || bookingId.isEmpty
        ? ''
        : '?booking_id=${Uri.encodeQueryComponent(bookingId)}';
    final response = await _client.get('/damage-claims$suffix');
    final data = response['data'] as Map<String, dynamic>;
    return (data['claims'] as List<dynamic>? ?? const [])
        .map((item) => DamageClaimDto.fromJson(item as Map<String, dynamic>))
        .toList();
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
    List<String>? accessories,
    String? stage,
    String issueSeverity = 'none',
  }) async {
    final response = await _client.post(
      '/location-inspections/$inspectionId/items',
      body: {
        'area_label': areaLabel,
        if (beforeFileId != null) 'before_file_id': beforeFileId,
        if (afterFileId != null) 'after_file_id': afterFileId,
        if (note != null) 'note': note,
        if (accessories != null) 'accessories': accessories,
        if (stage != null) 'stage': stage,
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
    String? visibility,
  }) async {
    final response = await _client.patch(
      '/equipment/provider-profile',
      body: {
        'name': name,
        'provider_type': providerType,
        if (coverage != null) 'coverage': coverage,
        if (serviceCategories != null) 'service_categories': serviceCategories,
        if (bio != null) 'bio': bio,
        if (visibility != null) 'visibility': visibility,
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

  Future<EquipmentItemDto> updateEquipmentItem(
      String itemId, Map<String, dynamic> body) async {
    final response =
        await _client.patch('/equipment/items/$itemId', body: body);
    return EquipmentItemDto.fromJson(
      (response['data'] as Map<String, dynamic>)['item']
          as Map<String, dynamic>,
    );
  }

  Future<List<EquipmentPackageDto>> equipmentPackages() async {
    final response = await _client.get('/equipment/packages');
    final data = response['data'] as Map<String, dynamic>;
    return (data['packages'] as List<dynamic>? ?? const [])
        .map((item) =>
            EquipmentPackageDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<EquipmentPackageDto> createEquipmentPackage(
      Map<String, dynamic> body) async {
    final response = await _client.post('/equipment/packages', body: body);
    return EquipmentPackageDto.fromJson(
      (response['data'] as Map<String, dynamic>)['package']
          as Map<String, dynamic>,
    );
  }

  Future<EquipmentPackageDto> updateEquipmentPackage(
      String packageId, Map<String, dynamic> body) async {
    final response =
        await _client.patch('/equipment/packages/$packageId', body: body);
    return EquipmentPackageDto.fromJson(
      (response['data'] as Map<String, dynamic>)['package']
          as Map<String, dynamic>,
    );
  }

  Future<void> addEquipmentPackageItem(String packageId, String itemId) {
    return _client.post(
      '/equipment/packages/$packageId/items',
      body: {'equipment_item_id': itemId},
    );
  }

  Future<List<EquipmentTermDto>> equipmentTerms() async {
    final response = await _client.get('/equipment/terms');
    final data = response['data'] as Map<String, dynamic>;
    return (data['terms'] as List<dynamic>? ?? const [])
        .map((item) => EquipmentTermDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<EquipmentTermDto> createEquipmentTerm(
      Map<String, dynamic> body) async {
    final response = await _client.post('/equipment/terms', body: body);
    return EquipmentTermDto.fromJson(
      (response['data'] as Map<String, dynamic>)['term']
          as Map<String, dynamic>,
    );
  }

  Future<EquipmentTermDto> updateEquipmentTerm(
      String termId, Map<String, dynamic> body) async {
    final response =
        await _client.patch('/equipment/terms/$termId', body: body);
    return EquipmentTermDto.fromJson(
      (response['data'] as Map<String, dynamic>)['term']
          as Map<String, dynamic>,
    );
  }

  Future<List<EquipmentInspectionDto>> equipmentInspections({
    String? inspectionType,
  }) async {
    final suffix = inspectionType == null || inspectionType.isEmpty
        ? ''
        : '?inspection_type=${Uri.encodeComponent(inspectionType)}';
    final response = await _client.get('/equipment-inspections$suffix');
    final data = response['data'] as Map<String, dynamic>;
    return (data['inspections'] as List<dynamic>? ?? const [])
        .map((item) =>
            EquipmentInspectionDto.fromJson(item as Map<String, dynamic>))
        .toList();
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
    List<String>? accessories,
    String? stage,
    String? beforeFileId,
    String? afterFileId,
    String? note,
  }) async {
    final response = await _client.post(
      '/equipment-inspections/$inspectionId/items',
      body: {
        'equipment_item_id': equipmentItemId,
        if (accessories != null) 'accessories': accessories,
        if (stage != null) 'stage': stage,
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
