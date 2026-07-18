import 'package:flutter/widgets.dart';

import '../network/api_client.dart';
import 'operations_models.dart';
import 'operations_repository.dart';

class OperationsController extends ChangeNotifier {
  final OperationsRepository _repository;

  List<LocationPropertyDto>? _locationProperties;
  EquipmentProfileDto? _equipmentProfile;
  List<EquipmentItemDto>? _equipmentItems;

  OperationsController({required OperationsRepository repository})
      : _repository = repository;

  factory OperationsController.fromClient(ApiClient client) {
    return OperationsController(repository: OperationsRepository(client));
  }

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

  Future<void> createLocationSpace(
      String propertyId, Map<String, dynamic> body) {
    return _repository.createLocationSpace(propertyId, body);
  }

  Future<void> createLocationPricing(
      String propertyId, Map<String, dynamic> body) {
    return _repository.createLocationPricing(propertyId, body);
  }

  Future<void> createLocationRule(
      String propertyId, Map<String, dynamic> body) {
    return _repository.createLocationRule(propertyId, body);
  }

  Future<LocationInspectionDto> createLocationInspection({
    required String bookingId,
    required String propertyId,
    required String inspectionType,
    String? meterReading,
    String? notes,
  }) {
    return _repository.createLocationInspection(
      bookingId: bookingId,
      propertyId: propertyId,
      inspectionType: inspectionType,
      meterReading: meterReading,
      notes: notes,
    );
  }

  Future<LocationInspectionDto> addLocationInspectionItem({
    required String inspectionId,
    required String areaLabel,
    String? beforeFileId,
    String? afterFileId,
    String? note,
    String issueSeverity = 'none',
  }) {
    return _repository.addLocationInspectionItem(
      inspectionId: inspectionId,
      areaLabel: areaLabel,
      beforeFileId: beforeFileId,
      afterFileId: afterFileId,
      note: note,
      issueSeverity: issueSeverity,
    );
  }

  Future<LocationInspectionDto> confirmLocationInspection(String inspectionId) {
    return _repository.confirmLocationInspection(inspectionId);
  }

  Future<DamageClaimDto> createDamageClaim({
    required String bookingId,
    required String description,
    required int claimedMinor,
    String currency = 'PKR',
    String? inspectionId,
  }) {
    return _repository.createDamageClaim(
      bookingId: bookingId,
      description: description,
      claimedMinor: claimedMinor,
      currency: currency,
      inspectionId: inspectionId,
    );
  }

  Future<DamageClaimDto> addDamageClaimEvidence({
    required String claimId,
    String? fileId,
    String evidenceType = 'photo',
    String? caption,
  }) {
    return _repository.addDamageClaimEvidence(
      claimId: claimId,
      fileId: fileId,
      evidenceType: evidenceType,
      caption: caption,
    );
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
  }) async {
    final profile = await _repository.upsertEquipmentProfile(
      name: name,
      providerType: providerType,
      coverage: coverage,
      serviceCategories: serviceCategories,
      bio: bio,
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

  Future<Map<String, dynamic>> createEquipmentPackage(
      Map<String, dynamic> body) {
    return _repository.createEquipmentPackage(body);
  }

  Future<void> addEquipmentPackageItem(String packageId, String itemId) {
    return _repository.addEquipmentPackageItem(packageId, itemId);
  }

  Future<void> createEquipmentTerm(Map<String, dynamic> body) {
    return _repository.createEquipmentTerm(body);
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
    String? beforeFileId,
    String? afterFileId,
    String? note,
  }) {
    return _repository.addEquipmentInspectionItem(
      inspectionId: inspectionId,
      equipmentItemId: equipmentItemId,
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
