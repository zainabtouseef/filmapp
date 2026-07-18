import 'package:flutter/widgets.dart';

import '../network/api_client.dart';
import 'payment_models.dart';
import 'payments_repository.dart';

class PaymentsController extends ChangeNotifier {
  final PaymentsRepository _repository;

  PaymentDashboardDto? _dashboard;
  List<LedgerEntryDto>? _ledger;
  List<PaymentProofDto>? _adminProofs;

  PaymentsController({required PaymentsRepository repository})
      : _repository = repository;

  factory PaymentsController.fromClient(ApiClient client) {
    return PaymentsController(repository: PaymentsRepository(client));
  }

  PaymentDashboardDto? get cachedDashboard => _dashboard;
  List<LedgerEntryDto>? get cachedLedger => _ledger;

  Future<PaymentDashboardDto> dashboard({bool force = false}) async {
    if (!force && _dashboard != null) return _dashboard!;
    final value = await _repository.dashboard();
    _dashboard = value;
    notifyListeners();
    return value;
  }

  Future<List<PaymentScheduleDto>> schedules({String? bookingId}) {
    return _repository.schedules(bookingId: bookingId);
  }

  Future<PaymentProofDto> submitProof({
    required String milestoneId,
    required int claimedAmountMinor,
    required String method,
    required String idempotencyKey,
    String? transactionReference,
    String? fileId,
  }) async {
    final proof = await _repository.submitProof(
      milestoneId: milestoneId,
      claimedAmountMinor: claimedAmountMinor,
      method: method,
      idempotencyKey: idempotencyKey,
      transactionReference: transactionReference,
      fileId: fileId,
    );
    await dashboard(force: true);
    await ledger(force: true);
    return proof;
  }

  Future<List<LedgerEntryDto>> ledger({bool force = false}) async {
    if (!force && _ledger != null) return _ledger!;
    final rows = await _repository.ledger();
    _ledger = rows;
    notifyListeners();
    return rows;
  }

  Future<List<PayoutAccountDto>> payoutAccounts() {
    return _repository.payoutAccounts();
  }

  Future<PayoutAccountDto> createSandboxPayoutAccount({
    required String accountName,
  }) {
    return _repository.createPayoutAccount(
      provider: 'sandbox',
      accountName: accountName,
      accountMasked: 'SANDBOX-****-0001',
      accountToken: 'sandbox-token-0001',
    );
  }

  Future<List<PaymentProofDto>> adminProofs({bool force = false}) async {
    if (!force && _adminProofs != null) return _adminProofs!;
    final rows = await _repository.adminPaymentProofs();
    _adminProofs = rows;
    notifyListeners();
    return rows;
  }

  Future<AdminPaymentProofDetailDto> adminProof(String publicId) {
    return _repository.adminPaymentProof(publicId);
  }

  Future<PaymentDecisionResultDto> decideProof({
    required String proofId,
    required String decision,
    String? reason,
  }) async {
    final result = await _repository.decideProof(
      proofId: proofId,
      decision: decision,
      reason: reason,
    );
    await adminProofs(force: true);
    return result;
  }
}

class PaymentsScope extends InheritedNotifier<PaymentsController> {
  const PaymentsScope({
    super.key,
    required PaymentsController controller,
    required super.child,
  }) : super(notifier: controller);

  static PaymentsController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PaymentsScope>();
    assert(scope != null, 'PaymentsScope is missing from the widget tree');
    return scope!.notifier!;
  }

  static PaymentsController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<PaymentsScope>()
        ?.notifier;
  }
}
