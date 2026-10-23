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
  Timer? _poller;
  bool _polling = false;
  bool _disposed = false;

  void _watchJobs() {
    final hasPending = (snapshot?['jobs'] as List? ?? const [])
        .any((j) => ['queued', 'processing'].contains(j['status']));
    if (!hasPending) {
      _poller?.cancel();
      _poller = null;
      return;
    }
    if (_disposed || _poller != null) return;
    _poller = Timer.periodic(const Duration(seconds: 4), (_) => _pollJobs());
  }

  Future<void> _pollJobs() async {
    if (_polling || _disposed) return;
    final id = selectedProductionId;
    final jobs = (snapshot?['jobs'] as List? ?? const []);
    final pending = jobs
        .where((j) => ['queued', 'processing'].contains(j['status']))
        .toList();
    if (id == null || pending.isEmpty) return;
    _polling = true;
    try {
      for (final item in pending) {
        final job = await repository.job(id, item['public_id'] as String);
        if (_disposed || id != selectedProductionId) return;
        snapshot = {
          ...snapshot!,
          'jobs': jobs
              .map((j) => j['public_id'] == job['public_id'] ? job : j)
              .toList()
        };
        notifyListeners();
        if (['completed', 'failed'].contains(job['status'])) {
          final fresh = await repository.production(id);
          if (!_disposed && id == selectedProductionId) {
            snapshot = fresh;
            notifyListeners();
          }
        }
      }
    } catch (_) {
      // A transient network failure must not stop a server-side analysis.
    } finally {
      _polling = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _poller?.cancel();
    super.dispose();
  }

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
        final id = selectedProductionId!;
        final fresh = await repository.production(id);
        if (!_disposed && selectedProductionId == id) snapshot = fresh;
      }
    } catch (error) {
      errorMessage = '$error';
      rethrow;
    } finally {
      loading = false;
      if (!_disposed) {
        _watchJobs();
        notifyListeners();
      }
    }
  }

  Future<void> selectProduction(String publicId) async {
    selectedProductionId = publicId;
    snapshot = null;
    await refresh();
  }

  Future<void> refresh() async {
    final id = selectedProductionId;
    if (id == null) return;
    loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final fresh = await repository.production(id);
      if (!_disposed && selectedProductionId == id) snapshot = fresh;
    } catch (error) {
      errorMessage = '$error';
      rethrow;
    } finally {
      loading = false;
      if (!_disposed) {
        _watchJobs();
        notifyListeners();
      }
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
