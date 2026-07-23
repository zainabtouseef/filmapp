import '../network/api_client.dart';
import 'admin_models.dart';

class AdminRepository {
  final ApiClient _client;

  const AdminRepository(this._client);

  Future<List<AdminBookingRecordDto>> bookings() async {
    final data = await _data('/admin/control/bookings');
    return _list(data['bookings']).map(AdminBookingRecordDto.fromJson).toList();
  }

  Future<AdminBookingRecordDto> booking(String publicId) async {
    final data = await _data('/admin/control/bookings/$publicId');
    return AdminBookingRecordDto.fromJson(_map(data['booking']));
  }

  Future<AdminBookingRecordDto> updateBooking(
    String publicId, {
    required String status,
    String? reason,
  }) async {
    final response = await _client.patch(
      '/admin/control/bookings/$publicId',
      body: {
        'status': status,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    final data = _map(response['data']);
    return AdminBookingRecordDto.fromJson(_map(data['booking']));
  }

  Future<List<AdminUserRecordDto>> users() async {
    final data = await _data('/admin/control/users');
    return _list(data['users']).map(AdminUserRecordDto.fromJson).toList();
  }

  Future<AdminUserRecordDto> updateUser(
    String publicId, {
    String? status,
    String? roleCode,
    String? roleStatus,
  }) async {
    final response = await _client.patch(
      '/admin/control/users/$publicId',
      body: {
        if (status != null) 'status': status,
        if (roleCode != null) 'role_code': roleCode,
        if (roleStatus != null) 'role_status': roleStatus,
      },
    );
    final data = _map(response['data']);
    return AdminUserRecordDto.fromJson(_map(data['user']));
  }

  Future<List<AdminListingRecordDto>> listings() async {
    final data = await _data('/admin/control/listings');
    return _list(data['listings']).map(AdminListingRecordDto.fromJson).toList();
  }

  Future<AdminListingRecordDto> updateListing(
    String publicId, {
    String? moderationStatus,
    String? visibility,
    String? reason,
  }) async {
    final response = await _client.patch(
      '/admin/control/listings/$publicId',
      body: {
        if (moderationStatus != null) 'moderation_status': moderationStatus,
        if (visibility != null) 'visibility': visibility,
        if (reason != null) 'reason': reason,
      },
    );
    final data = _map(response['data']);
    return AdminListingRecordDto.fromJson(_map(data['listing']));
  }

  Future<List<AdminContractTemplateDto>> contractTemplates() async {
    final data = await _data('/admin/control/contract-templates');
    return _list(data['templates'])
        .map(AdminContractTemplateDto.fromJson)
        .toList();
  }

  Future<AdminContractTemplateDto> createContractTemplate({
    required String name,
    required String category,
    String jurisdiction = 'PK',
  }) async {
    final response = await _client.post(
      '/admin/control/contract-templates',
      body: {
        'name': name,
        'category': category,
        'jurisdiction': jurisdiction,
      },
    );
    final data = _map(response['data']);
    return AdminContractTemplateDto.fromJson(_map(data['template']));
  }

  Future<AdminContractTemplateDto> updateContractTemplate(
    String publicId, {
    String? name,
    String? category,
    String? status,
    List<AdminTemplateClauseDto>? clauses,
  }) async {
    final response = await _client.patch(
      '/admin/control/contract-templates/$publicId',
      body: {
        if (name != null) 'name': name,
        if (category != null) 'category': category,
        if (status != null) 'status': status,
        if (clauses != null)
          'clauses': clauses.map((item) => item.toJson()).toList(),
      },
    );
    final data = _map(response['data']);
    return AdminContractTemplateDto.fromJson(_map(data['template']));
  }

  Future<List<AdminFeeRuleDto>> feeRules() async {
    final data = await _data('/admin/control/fee-rules');
    return _list(data['fee_rules']).map(AdminFeeRuleDto.fromJson).toList();
  }

  Future<AdminFeeRuleDto> createFeeRule({
    required String name,
    required String category,
    required int basisPoints,
    int fixedMinor = 0,
    String currency = 'PKR',
  }) async {
    final response = await _client.post(
      '/admin/control/fee-rules',
      body: {
        'name': name,
        'category': category,
        'basis_points': basisPoints,
        'fixed_minor': fixedMinor,
        'currency': currency,
      },
    );
    final data = _map(response['data']);
    return AdminFeeRuleDto.fromJson(_map(data['fee_rule']));
  }

  Future<AdminFeeRuleDto> updateFeeRule(
    String publicId, {
    String? name,
    String? category,
    int? basisPoints,
    int? fixedMinor,
    bool? active,
  }) async {
    final response = await _client.patch(
      '/admin/control/fee-rules/$publicId',
      body: {
        if (name != null) 'name': name,
        if (category != null) 'category': category,
        if (basisPoints != null) 'basis_points': basisPoints,
        if (fixedMinor != null) 'fixed_minor': fixedMinor,
        if (active != null) 'active': active,
      },
    );
    final data = _map(response['data']);
    return AdminFeeRuleDto.fromJson(_map(data['fee_rule']));
  }

  Future<AdminRolesBundleDto> roles() async {
    return AdminRolesBundleDto.fromJson(
      await _data('/admin/control/roles'),
    );
  }

  Future<AdminRoleRecordDto> updateRolePermissions(
    String roleCode,
    Set<String> permissions,
  ) async {
    final response = await _client.patch(
      '/admin/control/roles/$roleCode/permissions',
      body: {'permissions': permissions.toList()..sort()},
    );
    final data = _map(response['data']);
    return AdminRoleRecordDto.fromJson(_map(data['role']));
  }

  Future<List<AdminAuditEventDto>> auditEvents() async {
    final data = await _data('/admin/control/audit-events');
    return _list(data['events']).map(AdminAuditEventDto.fromJson).toList();
  }

  Future<Map<String, dynamic>> _data(String path) async {
    final response = await _client.get(path);
    return _map(response['data']);
  }

  Map<String, dynamic> _map(Object? value) {
    return value is Map<String, dynamic> ? value : const {};
  }

  List<Map<String, dynamic>> _list(Object? value) {
    if (value is! List<dynamic>) return const [];
    return value.whereType<Map<String, dynamic>>().toList();
  }
}
