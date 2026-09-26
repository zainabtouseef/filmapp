import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final index = File('web/index.html').readAsStringSync();
  final routes = File(
    'lib/core/core_ui/core_routes.dart',
  ).readAsStringSync();
  final splash = File(
    'lib/core/core_ui/screens/splash_screen.dart',
  ).readAsStringSync();

  test('web startup is cache safe and has a renderer fallback', () {
    expect(index, isNot(contains('{{flutter_service_worker_version}}')));
    expect(index, contains("releaseVersion = '20260926-unified-ux-v17'"));
    expect(
      index,
      contains(r'mainJsPath = `${build.mainJsPath}?v=${requestVersion}`'),
    );
    expect(index, contains('self.dartDeferredLibraryMultiLoader'));
    expect(index, contains("chunkUrl.searchParams.set('v', requestVersion)"));
    expect(
      index,
      contains(
        "config: recoveryMode ? { canvasKitBaseUrl: 'canvaskit/' } : {}",
      ),
    );
    expect(index, contains("searchParams.set('cc-recovery', releaseVersion)"));
    expect(index, contains('window.location.replace(recoveryUrl.toString())'));
    expect(index, isNot(contains('serviceWorkerSettings')));
    expect(index, contains('navigator.serviceWorker.getRegistrations()'));
    expect(index, contains('registration.unregister()'));
    expect(index, contains("'flutter-first-frame'"));
    expect(index, contains("document.querySelector('flutter-view')"));
    expect(index, contains('window.setTimeout(showSlowBoot, 12000)'));
    expect(index, contains('window.setTimeout(showManualReload, 45000)'));
    expect(index, isNot(contains('setTimeout(showBootFailure')));
  });

  test('native walkthrough release removes legacy web tutorial assets', () {
    expect(index, isNot(contains('director_tutorial')));
    expect(File('web/director_tutorial.js').existsSync(), isFalse);
    expect(File('web/director_tutorial.css').existsSync(), isFalse);
    expect(File('web/director_tutorial_bootstrap.js').existsSync(), isFalse);
  });

  test('startup defers portal code and keeps the splash compact', () {
    expect(
      RegExp(r'deferred as \w+_portal;').allMatches(routes),
      hasLength(16),
    );
    expect(routes, contains('class _DeferredRouteScreen'));
    expect(routes, contains('await _loader();'));
    expect(splash, contains('Duration(milliseconds: 1800)'));
  });
}
