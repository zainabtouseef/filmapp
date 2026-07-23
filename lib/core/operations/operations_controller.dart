import 'package:flutter/widgets.dart';

import '../network/api_client.dart';
import 'operations_models.dart';
import 'operations_repository.dart';

class OperationsController extends ChangeNotifier {
  final OperationsRepository _repository;

  List<LocationPropertyDto>? _locationProperties;
  List<LocationInspectionDto>? _locationInspections;
  List<DamageClaimDto>? _damageClaims;
  EquipmentProfileDto? _equipmentProfile;
  List<EquipmentItemDto>? _equipmentItems;
  List<EquipmentPackageDto>? _equipmentPackages;
  List<EquipmentTermDto>? _equipmentTerms;
  List<EquipmentInspectionDto>? _equipmentInspections;

  OperationsController({required OperationsRepository repository})
      : _repository = repository;

  EquipmentProfileDto? get cachedEquipmentProfile => _equipmentProfile;
  List<EquipmentItemDto>? get cachedEquipmentItems => _equipmentItems;
  List<EquipmentPackageDto>? get cachedEquipmentPackages => _equipmentPackages;
  List<EquipmentTermDto>? get cachedEquipmentTerms => _equipmentTerms;
  List<EquipmentInspectionDto>? get cachedEquipmentInspections =>
      _equipmentInspections;

  factory OperationsController.fromClient(ApiClient client) {
    return OperationsController(repository: OperationsRepository(client));
  }

  List<LocationPropertyDto>? get cachedLocationProperties =>
      _locationProperties;
  List<LocationInspectionDto>? get cachedLocationInspections =>
      _locationInspections;
  List<DamageClaimDto>? get cachedDamageClaims => _damageClaims;

  Future<List<LocationPropertyDto>> locationProperties(
      {bool force = false}) async {
    if (!force && _locationProperties != null) return _locationProperties!;
    final rows = await _repository.locationProperties();
    _locationProperties = rows;
    notifyListeners();
    return rows;
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
    final property = await _repository.createLocationProperty(
      name: name,
      propertyType: propertyType,
      areaName: areaName,
      publicAddress: publicAddress,
      privateAddress: privateAddress,
      description: description,
      capacity: capacity,
      parkingSpaces: parkingSpaces,
      powerBackup: powerBackup,
      accessible: accessible,
      status: status,
    );
    await locationProperties(force: true);
    return property;
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
    final property = await _repository.updateLocationProperty(
      propertyId: propertyId,
      name: name,
      propertyType: propertyType,
      areaName: areaName,
      publicAddress: publicAddress,
      privateAddress: privateAddress,
      description: description,
      capacity: capacity,
      parkingSpaces: parkingSpaces,
      powerBackup: powerBackup,
      accessible: accessible,
      status: status,
    );
    await locationProperties(force: true);
    return property;
  }

  Future<void> createLocationSpace(String propertyId, Map<String, dynamic> body,
      {bool refresh = true}) async {
    await _repository.createLocationSpace(propertyId, body);
    if (refresh) await locationProperties(force: true);
  }

  Future<void> updateLocationSpace(String spaceId, Map<String, dynamic> body,
      {bool refresh = true}) async {
    await _repository.updateLocationSpace(spaceId, body);
    if (refresh) await locationProperties(force: true);
  }

  Future<void> createLocationPricing(
      String propertyId, Map<String, dynamic> body,
      {bool refresh = true}) async {
    await _repository.createLocationPricing(propertyId, body);
    if (refresh) await locationProperties(force: true);
  }

  Future<void> updateLocationPricing(
      String pricingId, Map<String, dynamic> body,
      {bool refresh = true}) async {
    await _repository.updateLocationPricing(pricingId, body);
    if (refresh) await locationProperties(force: true);
  }

  Future<void> createLocationRule(String propertyId, Map<String, dynamic> body,
      {bool refresh = true}) async {
    await _repository.createLocationRule(propertyId, body);
    if (refresh) await locationProperties(force: true);
  }

  Future<void> updateLocationRule(String ruleId, Map<String, dynamic> body,
      {bool refresh = true}) async {
    await _repository.updateLocationRule(ruleId, body);
    if (refresh) await locationProperties(force: true);
  }

  Future<String> publishLocationListing({
    required String propertyId,
    required String title,
    required String summary,
    List<String> fileIds = const [],
  }) {
    return _repository.publishLocationListing(
      propertyId: propertyId,
      title: title,
      summary: summary,
      fileIds: fileIds,
    );
  }

  Future<List<LocationInspectionDto>> locationInspections({
    String? propertyId,
    String? bookingId,
    String? inspectionType,
    bool force = false,
  }) async {
    final unfiltered =
        propertyId == null && bookingId == null && inspectionType == null;
    if (!force && unfiltered && _locationInspections != null) {
      return _locationInspections!;
    }
    final rows = await _repository.locationInspections(
      propertyId: propertyId,
      bookingId: bookingId,
      inspectionType: inspectionType,
    );
    if (unfiltered) {
      _locationInspections = rows;
      notifyListeners();
    }
    return rows;
  }

  Future<List<DamageClaimDto>> damageClaims({
    String? bookingId,
    bool force = false,
  }) async {
    if (!force && bookingId == null && _damageClaims != null) {
      return _damageClaims!;
    }
    final rows = await _repository.damageClaims(bookingId: bookingId);
    if (bookingId == null) {
      _damageClaims = rows;
      notifyListeners();
    }
    return rows;
  }

  Future<LocationInspectionDto> createLocationInspection({
    required String bookingId,
    required String propertyId,
    required String inspectionType,
    String? meterReading,
    String? notes,
  }) async {
    final inspection = await _repository.createLocationInspection(
      bookingId: bookingId,
      propertyId: propertyId,
      inspectionType: inspectionType,
      meterReading: meterReading,
      notes: notes,
    );
    await locationInspections(force: true);
    return inspection;
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
    final inspection = await _repository.addLocationInspectionItem(
      inspectionId: inspectionId,
      areaLabel: areaLabel,
      beforeFileId: beforeFileId,
      afterFileId: afterFileId,
      note: note,
      accessories: accessories,
      stage: stage,
      issueSeverity: issueSeverity,
    );
    await locationInspections(force: true);
    return inspection;
  }

  Future<LocationInspectionDto> confirmLocationInspection(
      String inspectionId) async {
    final inspection =
        await _repository.confirmLocationInspection(inspectionId);
    await locationInspections(force: true);
    return inspection;
  }

  Future<DamageClaimDto> createDamageClaim({
    required String bookingId,
    required String description,
    required int claimedMinor,
    String currency = 'PKR',
    String? inspectionId,
  }) async {
    final claim = await _repository.createDamageClaim(
      bookingId: bookingId,
      description: description,
      claimedMinor: claimedMinor,
      currency: currency,
      inspectionId: inspectionId,
    );
    await damageClaims(force: true);
    return claim;
  }

  Future<DamageClaimDto> addDamageClaimEvidence({
    required String claimId,
    String? fileId,
    String evidenceType = 'photo',
    String? caption,
  }) async {
    final claim = await _repository.addDamageClaimEvidence(
      claimId: claimId,
      fileId: fileId,
      evidenceType: evidenceType,
      caption: caption,
    );
    await damageClaims(force: true);
    return claim;
  }

  Future<EquipmentProfileDto?> equipmentProfile({bool force = false}) async {
    if (!force && _equipmentProfile != null) return _equipmentProfile;
    _equipmentProfile = await _repository.equipmentProfile();
    notifyListeners();
    return _equipmentProfile;
  }

  Future<EquipmentProfileDto> upsertEquipmentProfile({
    required String name,
    String providerType = 'rental_house',
    String? coverage,
    String? serviceCategories,
    String? bio,
    String? visibility,
  }) async {
    final profile = await _repository.upsertEquipmentProfile(
      name: name,
      providerType: providerType,
      coverage: coverage,
      serviceCategories: serviceCategories,
      bio: bio,
      visibility: visibility,
    );
    _equipmentProfile = profile;
    notifyListeners();
    return profile;
  }

  Future<List<EquipmentItemDto>> equipmentItems({bool force = false}) async {
    if (!force && _equipmentItems != null) return _equipmentItems!;
    _equipmentItems = await _repository.equipmentItems();
    notifyListeners();
    return _equipmentItems!;
  }

  Future<EquipmentItemDto> createEquipmentItem(
      Map<String, dynamic> body) async {
    final item = await _repository.createEquipmentItem(body);
    await equipmentItems(force: true);
    return item;
  }

  Future<EquipmentItemDto> updateEquipmentItem(
      String itemId, Map<String, dynamic> body) async {
    final item = await _repository.updateEquipmentItem(itemId, body);
    await equipmentItems(force: true);
    return item;
  }

  Future<List<EquipmentPackageDto>> equipmentPackages({
    bool force = false,
  }) async {
    if (!force && _equipmentPackages != null) return _equipmentPackages!;
    _equipmentPackages = await _repository.equipmentPackages();
    notifyListeners();
    return _equipmentPackages!;
  }

  Future<EquipmentPackageDto> createEquipmentPackage(
      Map<String, dynamic> body) async {
    final package = await _repository.createEquipmentPackage(body);
    await equipmentPackages(force: true);
    return package;
  }

  Future<EquipmentPackageDto> updateEquipmentPackage(
      String packageId, Map<String, dynamic> body) async {
    final package = await _repository.updateEquipmentPackage(packageId, body);
    await equipmentPackages(force: true);
    return package;
  }

  Future<void> addEquipmentPackageItem(String packageId, String itemId) {
    return _repository.addEquipmentPackageItem(packageId, itemId);
  }

  Future<List<EquipmentTermDto>> equipmentTerms({bool force = false}) async {
    if (!force && _equipmentTerms != null) return _equipmentTerms!;
    _equipmentTerms = await _repository.equipmentTerms();
    notifyListeners();
    return _equipmentTerms!;
  }

  Future<EquipmentTermDto> createEquipmentTerm(
      Map<String, dynamic> body) async {
    final term = await _repository.createEquipmentTerm(body);
    await equipmentTerms(force: true);
    return term;
  }

  Future<EquipmentTermDto> updateEquipmentTerm(
      String termId, Map<String, dynamic> body) async {
    final term = await _repository.updateEquipmentTerm(termId, body);
    await equipmentTerms(force: true);
    return term;
  }

  Future<List<EquipmentInspectionDto>> equipmentInspections({
    String? inspectionType,
    bool force = false,
  }) async {
    if (inspectionType == null && !force && _equipmentInspections != null) {
      return _equipmentInspections!;
    }
    final rows = await _repository.equipmentInspections(
      inspectionType: inspectionType,
    );
    if (inspectionType == null) {
      _equipmentInspections = rows;
      notifyListeners();
    }
    return rows;
  }

  Future<EquipmentInspectionDto> createEquipmentInspection({
    required String bookingId,
    required String providerProfileId,
    required String inspectionType,
  }) {
    return _repository.createEquipmentInspection(
      bookingId: bookingId,
      providerProfileId: providerProfileId,
      inspectionType: inspectionType,
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
  }) {
    return _repository.addEquipmentInspectionItem(
      inspectionId: inspectionId,
      equipmentItemId: equipmentItemId,
      accessories: accessories,
      stage: stage,
      beforeFileId: beforeFileId,
      afterFileId: afterFileId,
      note: note,
    );
  }

  Future<EquipmentInspectionDto> confirmEquipmentInspection(
      String inspectionId) {
    return _repository.confirmEquipmentInspection(inspectionId);
  }

  Future<SafetyCheckDto> createSafetyCheck(Map<String, dynamic> body) {
    return _repository.createSafetyCheck(body);
  }

  Future<SafetyCheckDto> createSafetyCheckItem(
    String checkId,
    Map<String, dynamic> body,
  ) {
    return _repository.createSafetyCheckItem(checkId, body);
  }

  Future<IncidentDto> createIncident(Map<String, dynamic> body) {
    return _repository.createIncident(body);
  }

  Future<Map<String, dynamic>> createSafetyCheckIn(Map<String, dynamic> body) {
    return _repository.createSafetyCheckIn(body);
  }

  Future<Map<String, dynamic>> completeSafetyCheckIn(
    String checkInId,
    Map<String, dynamic> body,
  ) {
    return _repository.completeSafetyCheckIn(checkInId, body);
  }
}

class OperationsScope extends InheritedNotifier<OperationsController> {
  const OperationsScope({
    super.key,
    required OperationsController controller,
    required super.child,
  }) : super(notifier: controller);

  static OperationsController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<OperationsScope>();
    assert(scope != null, 'OperationsScope is missing from the widget tree');
    return scope!.notifier!;
  }

  static OperationsController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<OperationsScope>()
        ?.notifier;
  }
}
