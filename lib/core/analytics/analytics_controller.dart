import 'package:flutter/widgets.dart';

import '../network/api_client.dart';
import 'analytics_models.dart';
import 'analytics_repository.dart';

class AnalyticsController extends ChangeNotifier {
  final AnalyticsRepository _repository;

  PersonalDashboardDto? _personalDashboard;
  AdminDashboardDto? _adminDashboard;
  AdminAnalyticsDto? _adminAnalytics;
  List<ExportJobDto>? _exports;

  AnalyticsController({required AnalyticsRepository repository})
      : _repository = repository;

  factory AnalyticsController.fromClient(ApiClient client) {
    return AnalyticsController(repository: AnalyticsRepository(client));
  }

  Future<PersonalDashboardDto> personalDashboard({bool force = false}) async {
    if (!force && _personalDashboard != null) return _personalDashboard!;
    _personalDashboard = await _repository.personalDashboard();
    notifyListeners();
    return _personalDashboard!;
  }

  Future<AdminDashboardDto> adminDashboard({bool force = false}) async {
    if (!force && _adminDashboard != null) return _adminDashboard!;
    _adminDashboard = await _repository.adminDashboard();
    notifyListeners();
    return _adminDashboard!;
  }

  Future<AdminAnalyticsDto> adminAnalytics({
    bool force = false,
    int days = 30,
  }) async {
    if (!force &&
        _adminAnalytics != null &&
        _adminAnalytics!.rangeDays == days) {
      return _adminAnalytics!;
    }
    _adminAnalytics = await _repository.adminAnalytics(days: days);
    notifyListeners();
    return _adminAnalytics!;
  }

  Future<List<ExportJobDto>> exports({bool force = false}) async {
    if (!force && _exports != null) return _exports!;
    _exports = await _repository.exports();
    notifyListeners();
    return _exports!;
  }

  Future<ExportJobDto> createExport(
    String exportType, {
    Map<String, dynamic> filters = const {},
  }) async {
    final job = await _repository.createExport(exportType, filters: filters);
    await exports(force: true).catchError((_) => <ExportJobDto>[]);
    return job;
  }

  Future<ExportJobDto> export(String exportId) {
    return _repository.export(exportId);
  }
}

class AnalyticsScope extends InheritedNotifier<AnalyticsController> {
  const AnalyticsScope({
    super.key,
    required AnalyticsController controller,
    required super.child,
  }) : super(notifier: controller);

  static AnalyticsController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AnalyticsScope>();
    assert(scope != null, 'AnalyticsScope is missing from the widget tree');
    return scope!.notifier!;
  }

  static AnalyticsController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AnalyticsScope>()
        ?.notifier;
  }
}
