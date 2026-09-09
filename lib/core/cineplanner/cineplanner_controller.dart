import 'dart:async';

import 'package:flutter/widgets.dart';

import '../network/api_client.dart';
import '../uploads/upload_repository.dart';
import 'cineplanner_repository.dart';

class CinePlannerController extends ChangeNotifier {
  final CinePlannerRepository repository;

  CinePlannerController({required this.repository});

  factory CinePlannerController.fromClient(ApiClient client) =>
      CinePlannerController(repository: CinePlannerRepository(client));

  List<Map<String, dynamic>> productions = const [];
  Map<String, dynamic>? snapshot;
  String? selectedProductionId;
  bool loading = false;
  String? errorMessage;

  Future<void> loadProductions({bool selectFirst = true}) async {
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      productions = await repository.productions();
      final selectedStillExists = productions.any(
        (item) => item['public_id'] == selectedProductionId,
      );
      if (selectFirst && !selectedStillExists && productions.isNotEmpty) {
        selectedProductionId = productions.first['public_id'] as String?;
      }
      if (productions.isEmpty) {
        selectedProductionId = null;
        snapshot = null;
      }
      if (selectedProductionId != null) {
        snapshot = await repository.production(selectedProductionId!);
      }
    } catch (error) {
      errorMessage = '$error';
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> selectProduction(String publicId) async {
    selectedProductionId = publicId;
    await refresh();
  }

  Future<void> refresh() async {
    final id = selectedProductionId;
    if (id == null) return;
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      snapshot = await repository.production(id);
    } catch (error) {
      errorMessage = '$error';
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> createProduction({
    required String title,
    String? projectId,
    String? startDate,
    int maximumShootDays = 30,
    int workingHoursLimit = 12,
    int? budgetCeilingMinor,
  }) async {
    final created = await repository.createProduction(
      title: title,
      projectId: projectId,
      startDate: startDate,
      maximumShootDays: maximumShootDays,
      workingHoursLimit: workingHoursLimit,
      budgetCeilingMinor: budgetCeilingMinor,
    );
    selectedProductionId = created['public_id'] as String;
    await loadProductions(selectFirst: false);
  }

  Future<Map<String, dynamic>> uploadScreenplay({
    required PickedFileData file,
    required String label,
    void Function(int sent, int total)? onProgress,
    void Function(String status)? onStatus,
  }) async {
    final id = selectedProductionId!;
    final result = await repository.uploadScreenplay(
      productionId: id,
      file: file,
      label: label,
      onProgress: onProgress,
      onStatus: onStatus,
    );
    await refresh();
    return result;
  }

  Future<Map<String, dynamic>> waitForJob(
    String jobId, {
    void Function(Map<String, dynamic>)? onProgress,
  }) async {
    final productionId = selectedProductionId!;
    for (var attempt = 0; attempt < 900; attempt++) {
      final job = await repository.job(productionId, jobId);
      onProgress?.call(job);
      if (job['status'] == 'completed') {
        await refresh();
        return job;
      }
      if (job['status'] == 'failed') return job;
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    throw TimeoutException('Screenplay processing is still running.');
  }

  Future<void> mutate(Future<void> Function() operation) async {
    await operation();
    await refresh();
  }
}

class CinePlannerScope extends InheritedNotifier<CinePlannerController> {
  const CinePlannerScope({
    super.key,
    required CinePlannerController controller,
    required super.child,
  }) : super(notifier: controller);

  static CinePlannerController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<CinePlannerScope>();
    assert(scope != null, 'CinePlannerScope is missing from the widget tree');
    return scope!.notifier!;
  }
}
