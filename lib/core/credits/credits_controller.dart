import 'package:flutter/widgets.dart';

import '../network/api_client.dart';
import 'credit_models.dart';
import 'credits_repository.dart';

class CreditsController extends ChangeNotifier {
  final CreditsRepository _repository;

  CreditsController({required CreditsRepository repository})
      : _repository = repository;

  factory CreditsController.fromClient(ApiClient client) {
    return CreditsController(repository: CreditsRepository(client));
  }

  Future<List<CreditEntry>> list(String profileType) {
    return _repository.list(profileType);
  }

  Future<CreditEntry> create({
    required String profileType,
    required String title,
    required String productionName,
    String? roleLabel,
    int? year,
    String? description,
    String? coverFileId,
  }) {
    return _repository.create(
      profileType: profileType,
      title: title,
      productionName: productionName,
      roleLabel: roleLabel,
      year: year,
      description: description,
      coverFileId: coverFileId,
    );
  }

  Future<CreditEntry> update(String publicId, Map<String, dynamic> body) {
    return _repository.update(publicId, body);
  }

  Future<void> delete(String publicId) {
    return _repository.delete(publicId);
  }
}

class CreditsScope extends InheritedNotifier<CreditsController> {
  const CreditsScope({
    super.key,
    required CreditsController controller,
    required super.child,
  }) : super(notifier: controller);

  static CreditsController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CreditsScope>();
    assert(scope != null, 'CreditsScope is missing from the widget tree');
    return scope!.notifier!;
  }

  static CreditsController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CreditsScope>()?.notifier;
  }
}
