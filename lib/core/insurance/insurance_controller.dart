import 'package:flutter/widgets.dart';

import '../network/api_client.dart';
import 'insurance_models.dart';
import 'insurance_repository.dart';

class InsuranceController extends ChangeNotifier {
  final InsuranceRepository _repository;

  InsuranceProfileDto? _profile;
  InsuranceDashboardDto? _dashboard;
  List<InsurancePolicyDto>? _policies;
  List<InsuranceClaimDto>? _claims;

  InsuranceController({required InsuranceRepository repository})
      : _repository = repository;

  factory InsuranceController.fromClient(ApiClient client) {
    return InsuranceController(repository: InsuranceRepository(client));
  }

  Future<InsuranceProfileDto?> profile({bool force = false}) async {
    if (!force && _profile != null) return _profile;
    _profile = await _repository.profile();
    notifyListeners();
    return _profile;
  }

  Future<InsuranceProfileDto> upsertProfile({
    required String name,
    String? coverageRegions,
    String? licenseNumber,
  }) async {
    _profile = await _repository.upsertProfile(
      name: name,
      coverageRegions: coverageRegions,
      licenseNumber: licenseNumber,
    );
    notifyListeners();
    return _profile!;
  }

  Future<InsuranceDashboardDto> dashboard({bool force = false}) async {
    if (!force && _dashboard != null) return _dashboard!;
    _dashboard = await _repository.dashboard();
    notifyListeners();
    return _dashboard!;
  }

  Future<List<InsurancePolicyDto>> policies({bool force = false}) async {
    if (!force && _policies != null) return _policies!;
    _policies = await _repository.policies();
    notifyListeners();
    return _policies!;
  }

  Future<InsurancePolicyDto> createPolicy(Map<String, dynamic> body) async {
    final policy = await _repository.createPolicy(body);
    await policies(force: true);
    await dashboard(force: true);
    return policy;
  }

  Future<List<InsuranceClaimDto>> claims({bool force = false}) async {
    if (!force && _claims != null) return _claims!;
    _claims = await _repository.claims();
    notifyListeners();
    return _claims!;
  }

  Future<InsuranceClaimDto> createClaim(Map<String, dynamic> body) async {
    final claim = await _repository.createClaim(body);
    await claims(force: true);
    await dashboard(force: true);
    return claim;
  }

  Future<InsuranceClaimDto> addClaimEvidence({
    required String claimId,
    String? fileId,
    String evidenceType = 'photo',
    bool mandatory = false,
    String? caption,
  }) {
    return _repository.addClaimEvidence(
      claimId: claimId,
      fileId: fileId,
      evidenceType: evidenceType,
      mandatory: mandatory,
      caption: caption,
    );
  }

  Future<InsuranceClaimDto> decideClaim({
    required String claimId,
    required String status,
    int? estimateMinor,
    String? adjusterUserId,
  }) async {
    final claim = await _repository.decideClaim(
      claimId: claimId,
      status: status,
      estimateMinor: estimateMinor,
      adjusterUserId: adjusterUserId,
    );
    await claims(force: true);
    await dashboard(force: true);
    return claim;
  }
}

class InsuranceScope extends InheritedNotifier<InsuranceController> {
  const InsuranceScope({
    super.key,
    required InsuranceController controller,
    required super.child,
  }) : super(notifier: controller);

  static InsuranceController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<InsuranceScope>();
    assert(scope != null, 'InsuranceScope is missing from the widget tree');
    return scope!.notifier!;
  }

  static InsuranceController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InsuranceScope>()
        ?.notifier;
  }
}
