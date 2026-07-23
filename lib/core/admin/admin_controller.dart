import 'package:flutter/widgets.dart';

import '../network/api_client.dart';
import 'admin_models.dart';
import 'admin_repository.dart';

class AdminController extends ChangeNotifier {
  final AdminRepository _repository;

  List<AdminBookingRecordDto>? _bookings;
  List<AdminUserRecordDto>? _users;
  List<AdminListingRecordDto>? _listings;
  List<AdminContractTemplateDto>? _templates;
  List<AdminFeeRuleDto>? _feeRules;
  AdminRolesBundleDto? _roles;
  List<AdminAuditEventDto>? _auditEvents;

  AdminController({required AdminRepository repository})
      : _repository = repository;

  factory AdminController.fromClient(ApiClient client) {
    return AdminController(repository: AdminRepository(client));
  }

  Future<List<AdminBookingRecordDto>> bookings({bool force = false}) async {
    if (!force && _bookings != null) return _bookings!;
    _bookings = await _repository.bookings();
    notifyListeners();
    return _bookings!;
  }

  Future<AdminBookingRecordDto> booking(
    String publicId, {
    bool force = false,
  }) async {
    if (!force && _bookings != null) {
      for (final item in _bookings!) {
        if (item.publicId == publicId) return item;
      }
    }
    final item = await _repository.booking(publicId);
    _replaceBooking(item);
    notifyListeners();
    return item;
  }

  Future<AdminBookingRecordDto> updateBooking(
    String publicId, {
    required String status,
    String? reason,
  }) async {
    final item = await _repository.updateBooking(
      publicId,
      status: status,
      reason: reason,
    );
    _replaceBooking(item);
    notifyListeners();
    return item;
  }

  Future<List<AdminUserRecordDto>> users({bool force = false}) async {
    if (!force && _users != null) return _users!;
    _users = await _repository.users();
    notifyListeners();
    return _users!;
  }

  Future<AdminUserRecordDto> updateUser(
    String publicId, {
    String? status,
    String? roleCode,
    String? roleStatus,
  }) async {
    final item = await _repository.updateUser(
      publicId,
      status: status,
      roleCode: roleCode,
      roleStatus: roleStatus,
    );
    _replaceById(_users, item.publicId, item, (entry) => entry.publicId);
    notifyListeners();
    return item;
  }

  Future<List<AdminListingRecordDto>> listings({bool force = false}) async {
    if (!force && _listings != null) return _listings!;
    _listings = await _repository.listings();
    notifyListeners();
    return _listings!;
  }

  Future<AdminListingRecordDto> updateListing(
    String publicId, {
    String? moderationStatus,
    String? visibility,
    String? reason,
  }) async {
    final item = await _repository.updateListing(
      publicId,
      moderationStatus: moderationStatus,
      visibility: visibility,
      reason: reason,
    );
    _replaceById(_listings, item.publicId, item, (entry) => entry.publicId);
    notifyListeners();
    return item;
  }

  Future<List<AdminContractTemplateDto>> contractTemplates({
    bool force = false,
  }) async {
    if (!force && _templates != null) return _templates!;
    _templates = await _repository.contractTemplates();
    notifyListeners();
    return _templates!;
  }

  Future<AdminContractTemplateDto> createContractTemplate({
    required String name,
    required String category,
    String jurisdiction = 'PK',
  }) async {
    final item = await _repository.createContractTemplate(
      name: name,
      category: category,
      jurisdiction: jurisdiction,
    );
    _templates = [item, ...?_templates];
    notifyListeners();
    return item;
  }

  Future<AdminContractTemplateDto> updateContractTemplate(
    String publicId, {
    String? name,
    String? category,
    String? status,
    List<AdminTemplateClauseDto>? clauses,
  }) async {
    final item = await _repository.updateContractTemplate(
      publicId,
      name: name,
      category: category,
      status: status,
      clauses: clauses,
    );
    _replaceById(_templates, item.publicId, item, (entry) => entry.publicId);
    notifyListeners();
    return item;
  }

  Future<List<AdminFeeRuleDto>> feeRules({bool force = false}) async {
    if (!force && _feeRules != null) return _feeRules!;
    _feeRules = await _repository.feeRules();
    notifyListeners();
    return _feeRules!;
  }

  Future<AdminFeeRuleDto> createFeeRule({
    required String name,
    required String category,
    required int basisPoints,
    int fixedMinor = 0,
    String currency = 'PKR',
  }) async {
    final item = await _repository.createFeeRule(
      name: name,
      category: category,
      basisPoints: basisPoints,
      fixedMinor: fixedMinor,
      currency: currency,
    );
    _feeRules = [item, ...?_feeRules];
    notifyListeners();
    return item;
  }

  Future<AdminFeeRuleDto> updateFeeRule(
    String publicId, {
    String? name,
    String? category,
    int? basisPoints,
    int? fixedMinor,
    bool? active,
  }) async {
    final item = await _repository.updateFeeRule(
      publicId,
      name: name,
      category: category,
      basisPoints: basisPoints,
      fixedMinor: fixedMinor,
      active: active,
    );
    _replaceById(_feeRules, item.publicId, item, (entry) => entry.publicId);
    notifyListeners();
    return item;
  }

  Future<AdminRolesBundleDto> roles({bool force = false}) async {
    if (!force && _roles != null) return _roles!;
    _roles = await _repository.roles();
    notifyListeners();
    return _roles!;
  }

  Future<AdminRoleRecordDto> updateRolePermissions(
    String roleCode,
    Set<String> permissions,
  ) async {
    final item = await _repository.updateRolePermissions(
      roleCode,
      permissions,
    );
    final current = _roles;
    if (current != null) {
      final roles = [...current.roles];
      final index = roles.indexWhere((entry) => entry.code == item.code);
      if (index >= 0) roles[index] = item;
      _roles = AdminRolesBundleDto(
        roles: roles,
        permissions: current.permissions,
      );
    }
    notifyListeners();
    return item;
  }

  Future<List<AdminAuditEventDto>> auditEvents({bool force = false}) async {
    if (!force && _auditEvents != null) return _auditEvents!;
    _auditEvents = await _repository.auditEvents();
    notifyListeners();
    return _auditEvents!;
  }

  void _replaceBooking(AdminBookingRecordDto item) {
    _replaceById(_bookings, item.publicId, item, (entry) => entry.publicId);
  }

  void _replaceById<T>(
    List<T>? values,
    String id,
    T replacement,
    String Function(T value) readId,
  ) {
    if (values == null) return;
    final index = values.indexWhere((entry) => readId(entry) == id);
    if (index >= 0) {
      values[index] = replacement;
    } else {
      values.insert(0, replacement);
    }
  }
}

class AdminScope extends InheritedNotifier<AdminController> {
  const AdminScope({
    super.key,
    required AdminController controller,
    required super.child,
  }) : super(notifier: controller);

  static AdminController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AdminScope>();
    assert(scope != null, 'AdminScope is missing from the widget tree');
    return scope!.notifier!;
  }

  static AdminController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AdminScope>()?.notifier;
  }
}
