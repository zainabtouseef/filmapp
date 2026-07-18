import '../network/api_client.dart';
import 'payment_models.dart';

class PaymentsRepository {
  final ApiClient _client;

  const PaymentsRepository(this._client);

  Future<PaymentDashboardDto> dashboard() async {
    final response = await _client.get('/payments/dashboard');
    return PaymentDashboardDto.fromJson(
        response['data'] as Map<String, dynamic>);
  }

  Future<List<PaymentScheduleDto>> schedules({String? bookingId}) async {
    final suffix = bookingId == null || bookingId.isEmpty
        ? ''
        : '?booking_id=${Uri.encodeComponent(bookingId)}';
    final response = await _client.get('/payment-schedules$suffix');
    final data = response['data'] as Map<String, dynamic>;
    return (data['schedules'] as List<dynamic>? ?? const [])
        .map(
            (item) => PaymentScheduleDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<PaymentScheduleDto> schedule(String publicId) async {
    final response = await _client.get('/payment-schedules/$publicId');
    final data = response['data'] as Map<String, dynamic>;
    return PaymentScheduleDto.fromJson(
        data['schedule'] as Map<String, dynamic>);
  }

  Future<PaymentProofDto> submitProof({
    required String milestoneId,
    required int claimedAmountMinor,
    required String method,
    required String idempotencyKey,
    String? transactionReference,
    String? fileId,
  }) async {
    final response = await _client.post(
      '/payment-proofs',
      body: {
        'milestone_id': milestoneId,
        'claimed_amount_minor': claimedAmountMinor,
        'method': method,
        'idempotency_key': idempotencyKey,
        if (transactionReference != null)
          'transaction_reference': transactionReference,
        if (fileId != null) 'file_id': fileId,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return PaymentProofDto.fromJson(data['proof'] as Map<String, dynamic>);
  }

  Future<List<LedgerEntryDto>> ledger() async {
    final response = await _client.get('/ledger');
    final data = response['data'] as Map<String, dynamic>;
    return (data['entries'] as List<dynamic>? ?? const [])
        .map((item) => LedgerEntryDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ReceiptDto> receipt(String publicId) async {
    final response = await _client.get('/receipts/$publicId');
    final data = response['data'] as Map<String, dynamic>;
    return ReceiptDto.fromJson(data['receipt'] as Map<String, dynamic>);
  }

  Future<List<PayoutAccountDto>> payoutAccounts() async {
    final response = await _client.get('/payout-accounts');
    final data = response['data'] as Map<String, dynamic>;
    return (data['accounts'] as List<dynamic>? ?? const [])
        .map((item) => PayoutAccountDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<PayoutAccountDto> createPayoutAccount({
    required String provider,
    required String accountName,
    required String accountMasked,
    required String accountToken,
    bool isDefault = true,
  }) async {
    final response = await _client.post(
      '/payout-accounts',
      body: {
        'provider': provider,
        'account_name': accountName,
        'account_masked': accountMasked,
        'account_token': accountToken,
        'is_default': isDefault,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    return PayoutAccountDto.fromJson(data['account'] as Map<String, dynamic>);
  }

  Future<List<PaymentProofDto>> adminPaymentProofs() async {
    final response = await _client.get('/admin/payment-proofs');
    final data = response['data'] as Map<String, dynamic>;
    return (data['proofs'] as List<dynamic>? ?? const [])
        .map((item) => PaymentProofDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AdminPaymentProofDetailDto> adminPaymentProof(String publicId) async {
    final response = await _client.get('/admin/payment-proofs/$publicId');
    return AdminPaymentProofDetailDto.fromJson(
        response['data'] as Map<String, dynamic>);
  }

  Future<PaymentDecisionResultDto> decideProof({
    required String proofId,
    required String decision,
    String? reason,
  }) async {
    final response = await _client.post(
      '/admin/payment-proofs/$proofId/decision',
      body: {
        'decision': decision,
        if (reason != null) 'reason': reason,
      },
    );
    return PaymentDecisionResultDto.fromJson(
        response['data'] as Map<String, dynamic>);
  }
}
