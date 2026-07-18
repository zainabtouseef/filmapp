import 'package:flutter/widgets.dart';

import '../network/api_client.dart';
import 'contract_models.dart';
import 'contracts_repository.dart';

class ContractsController extends ChangeNotifier {
  final ContractsRepository _repository;

  List<CineContract>? _cachedContracts;
  List<LegalReviewDto>? _cachedReviews;

  ContractsController({required ContractsRepository repository})
      : _repository = repository;

  factory ContractsController.fromClient(ApiClient client) {
    return ContractsController(repository: ContractsRepository(client));
  }

  Future<List<CineContract>> contracts({bool force = false}) async {
    if (!force && _cachedContracts != null) return _cachedContracts!;
    final rows = await _repository.contracts();
    _cachedContracts = rows;
    notifyListeners();
    return rows;
  }

  Future<CineContract> contract(String publicId) {
    return _repository.contract(publicId);
  }

  Future<CineContract> generateForBooking(String bookingId) async {
    final contract = await _repository.generateForBooking(bookingId);
    await contracts(force: true);
    return contract;
  }

  Future<CineContract> sign(String contractId) async {
    final contract = await _repository.sign(contractId);
    await contracts(force: true);
    return contract;
  }

  Future<ContractAddendum> createAddendum({
    required String contractId,
    required String reason,
    required String content,
  }) {
    return _repository.createAddendum(
      contractId: contractId,
      reason: reason,
      content: content,
    );
  }

  Future<LegalReviewDto> requestLegalReview({
    required String contractId,
    String risk = 'medium',
  }) {
    return _repository.requestLegalReview(contractId: contractId, risk: risk);
  }

  Future<List<ContractTemplate>> templates() {
    return _repository.templates();
  }

  Future<List<LegalReviewDto>> legalReviews({bool force = false}) async {
    if (!force && _cachedReviews != null) return _cachedReviews!;
    final rows = await _repository.legalReviews();
    _cachedReviews = rows;
    notifyListeners();
    return rows;
  }

  Future<LegalReviewDto> legalReview(String publicId) {
    return _repository.legalReview(publicId);
  }

  Future<LegalReviewDto> decideLegalReview({
    required String reviewId,
    required String status,
    String? decisionNotes,
  }) async {
    final review = await _repository.decideLegalReview(
      reviewId: reviewId,
      status: status,
      decisionNotes: decisionNotes,
      amountMinor: 500000,
    );
    await legalReviews(force: true);
    return review;
  }
}

class ContractsScope extends InheritedNotifier<ContractsController> {
  const ContractsScope({
    super.key,
    required ContractsController controller,
    required super.child,
  }) : super(notifier: controller);

  static ContractsController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ContractsScope>();
    assert(scope != null, 'ContractsScope is missing from the widget tree');
    return scope!.notifier!;
  }

  static ContractsController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ContractsScope>()
        ?.notifier;
  }
}
