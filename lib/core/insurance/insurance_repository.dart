import '../network/api_client.dart';
import 'insurance_models.dart';

class InsuranceRepository {
  final ApiClient _client;

  const InsuranceRepository(this._client);

  Future<InsuranceProfileDto?> profile() async {
    final response = await _client.get('/insurance/profile');
    final data = response['data'] as Map<String, dynamic>;
    final profile = data['profile'] as Map<String, dynamic>?;
    return profile == null ? null : InsuranceProfileDto.fromJson(profile);
  }

  Future<InsuranceProfileDto> upsertProfile({
    required String name,
    String? coverageRegions,
    String? licenseNumber,
  }) async {
    final response = await _client.patch(
      '/insurance/profile',
      body: {
        'name': name,
        if (coverageRegions != null) 'coverage_regions': coverageRegions,
        if (licenseNumber != null) 'license_number': licenseNumber,
      },
    );
    return InsuranceProfileDto.fromJson(
      (response['data'] as Map<String, dynamic>)['profile']
          as Map<String, dynamic>,
    );
  }

  Future<InsuranceDashboardDto> dashboard() async {
    final response = await _client.get('/insurance/dashboard');
    return InsuranceDashboardDto.fromJson(
        response['data'] as Map<String, dynamic>);
  }

  Future<List<InsurancePolicyDto>> policies() async {
    final response = await _client.get('/insurance/policies');
    final data = response['data'] as Map<String, dynamic>;
    return (data['policies'] as List<dynamic>? ?? const [])
        .map(
            (item) => InsurancePolicyDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<InsurancePolicyDto> policy(String publicId) async {
    final response = await _client.get('/insurance/policies/$publicId');
    return InsurancePolicyDto.fromJson(
      (response['data'] as Map<String, dynamic>)['policy']
          as Map<String, dynamic>,
    );
  }

  Future<InsurancePolicyDto> createPolicy(Map<String, dynamic> body) async {
    final response = await _client.post('/insurance/policies', body: body);
    return InsurancePolicyDto.fromJson(
      (response['data'] as Map<String, dynamic>)['policy']
          as Map<String, dynamic>,
    );
  }

  Future<List<InsuranceClaimDto>> claims() async {
    final response = await _client.get('/insurance/claims');
    final data = response['data'] as Map<String, dynamic>;
    return (data['claims'] as List<dynamic>? ?? const [])
        .map((item) => InsuranceClaimDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<InsuranceClaimDto> claim(String publicId) async {
    final response = await _client.get('/insurance/claims/$publicId');
    return InsuranceClaimDto.fromJson(
      (response['data'] as Map<String, dynamic>)['claim']
          as Map<String, dynamic>,
    );
  }

  Future<InsuranceClaimDto> createClaim(Map<String, dynamic> body) async {
    final response = await _client.post('/insurance/claims', body: body);
    return InsuranceClaimDto.fromJson(
      (response['data'] as Map<String, dynamic>)['claim']
          as Map<String, dynamic>,
    );
  }

  Future<InsuranceClaimDto> addClaimEvidence({
    required String claimId,
    String? fileId,
    String evidenceType = 'photo',
    bool mandatory = false,
    String? caption,
  }) async {
    final response = await _client.post(
      '/insurance/claims/$claimId/evidence',
      body: {
        if (fileId != null) 'file_id': fileId,
        'evidence_type': evidenceType,
        'mandatory': mandatory,
        if (caption != null) 'caption': caption,
      },
    );
    return InsuranceClaimDto.fromJson(
      (response['data'] as Map<String, dynamic>)['claim']
          as Map<String, dynamic>,
    );
  }

  Future<InsuranceClaimDto> decideClaim({
    required String claimId,
    required String status,
    int? estimateMinor,
    String? adjusterUserId,
  }) async {
    final response = await _client.post(
      '/insurance/claims/$claimId/decision',
      body: {
        'status': status,
        if (estimateMinor != null) 'estimate_minor': estimateMinor,
        if (adjusterUserId != null) 'adjuster_user_id': adjusterUserId,
      },
    );
    return InsuranceClaimDto.fromJson(
      (response['data'] as Map<String, dynamic>)['claim']
          as Map<String, dynamic>,
    );
  }
}
