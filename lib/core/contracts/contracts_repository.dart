import '../network/api_client.dart';
import 'contract_models.dart';

class ContractsRepository {
  final ApiClient _client;

  const ContractsRepository(this._client);

  Future<List<ContractTemplate>> templates() async {
    final response = await _client.get('/contract-templates');
    final data = response['data'] as Map<String, dynamic>;
    return (data['templates'] as List<dynamic>? ?? const [])
        .map((item) => ContractTemplate.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<CineContract>> contracts() async {
    final response = await _client.get('/contracts');
    final data = response['data'] as Map<String, dynamic>;
    return (data['contracts'] as List<dynamic>? ?? const [])
        .map((item) => CineContract.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<CineContract> contract(String publicId) async {
    final response = await _client.get('/contracts/$publicId');
    final data = response['data'] as Map<String, dynamic>;
    return CineContract.fromJson(data['contract'] as Map<String, dynamic>);
  }

  Future<CineContract> generateForBooking(String bookingId) async {
    final response = await _client.post('/bookings/$bookingId/contracts');
    final data = response['data'] as Map<String, dynamic>;
    return CineContract.fromJson(data['contract'] as Map<String, dynamic>);
  }

  Future<CineContract> sign(String contractId,
      {String? signatureFileId}) async {
    final response = await _client.post(
      '/contracts/$contractId/signatures',
      body: {
        if (signatureFileId != null) 'signature_file_id': signatureFileId,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return CineContract.fromJson(data['contract'] as Map<String, dynamic>);
  }

  Future<ContractAddendum> createAddendum({
    required String contractId,
    required String reason,
    required String content,
  }) async {
    final response = await _client.post(
      '/contracts/$contractId/addendums',
      body: {'reason': reason, 'content': content},
    );
    final data = response['data'] as Map<String, dynamic>;
    return ContractAddendum.fromJson(data['addendum'] as Map<String, dynamic>);
  }

  Future<LegalReviewDto> requestLegalReview({
    required String contractId,
    String? contractType,
    String risk = 'medium',
  }) async {
    final response = await _client.post(
      '/legal-reviews',
      body: {
        'contract_id': contractId,
        if (contractType != null) 'contract_type': contractType,
        'risk': risk,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return LegalReviewDto.fromJson(data['review'] as Map<String, dynamic>);
  }

  Future<List<LegalReviewDto>> legalReviews() async {
    final response = await _client.get('/legal/reviews');
    final data = response['data'] as Map<String, dynamic>;
    return (data['reviews'] as List<dynamic>? ?? const [])
        .map((item) => LegalReviewDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<LegalReviewDto> legalReview(String publicId) async {
    final response = await _client.get('/legal-reviews/$publicId');
    final data = response['data'] as Map<String, dynamic>;
    return LegalReviewDto.fromJson(data['review'] as Map<String, dynamic>);
  }

  Future<LegalReviewDto> decideLegalReview({
    required String reviewId,
    required String status,
    String? decisionNotes,
    int minutes = 30,
    int amountMinor = 0,
  }) async {
    final response = await _client.post(
      '/legal-reviews/$reviewId/decision',
      body: {
        'status': status,
        if (decisionNotes != null) 'decision_notes': decisionNotes,
        'minutes': minutes,
        'amount_minor': amountMinor,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return LegalReviewDto.fromJson(data['review'] as Map<String, dynamic>);
  }
}
