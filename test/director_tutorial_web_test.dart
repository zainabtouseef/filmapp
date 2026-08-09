import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final script = File('web/director_tutorial.js').readAsStringSync();
  final styles = File('web/director_tutorial.css').readAsStringSync();
  final index = File('web/index.html').readAsStringSync();
  final shell = File(
    'lib/features/director_producer/widgets/dp_shell.dart',
  ).readAsStringSync();

  test('hiring loop waits for real routes and preserves the reviewed profile',
      () {
    expect(script, contains('expectedHashPrefix: "#/director/profile"'));
    expect(script, contains('expectedHash: "#/director/booking-request"'));
    expect(script, contains('expectedHash: "#/director/bargaining"'));
    expect(script, contains('expectedHash: "#/director/accounts"'));
    expect(
      script,
      contains('preserveRoutePrefixes: ["#/director/profile"]'),
    );
    expect(script, isNot(contains('Date.now() - startedAt >= 2200')));
    expect(script, contains('waitForActionOutcome(step, Date.now())'));
  });

  test('modal and project steps wait for confirmed completion', () {
    expect(script, contains('waitForTextCycle: "Add a city"'));
    expect(script, contains('requireTargetTextChange: true'));
    expect(script, contains('function semanticOutcomeTarget(step)'));
    expect(script, contains('state.outcomeBaselineTargetRect'));
    expect(
      script,
      contains('split(/\\s*\\+\\s*/)'),
    );
    expect(
      script,
      contains('completionDismissedPattern: "Save requirement"'),
    );
    expect(script, contains('expectedTextPattern: "Project created"'));
  });

  test('two-stage requirement actions are handled once per click', () {
    expect(
      RegExp(
        r'addEventListener\("click", handleTargetPointer',
      ).allMatches(script).length,
      1,
    );
    expect(
      script,
      isNot(contains('addEventListener("pointerup", handleTargetPointer')),
    );
    expect(
      script,
      isNot(contains('targetItem.node.addEventListener')),
    );
    expect(script, contains('state.targetRetryCount < 40'));
  });

  test('navigation targets adapt to bottom navigation and desktop sidebar', () {
    expect(script, contains('const SIDEBAR_BREAKPOINT_PX = 1200'));
    expect(script, contains('function currentNavigationMode()'));
    expect(script, contains('stepForCurrentLayout(steps[state.index])'));
    expect(script, contains('targetLabels: ["Productions"]'));
    expect(script, contains('targetLabels: ["Projects"]'));
    expect(script, contains('targetLabels: ["Deals"]'));
    expect(script, contains('targetLabels: ["Bargaining"]'));
    expect(script, contains('rectMatchesTargetRegion(rect, region)'));
    expect(script, contains('region === "bottom-nav"'));
    expect(script, contains('region === "side-nav"'));
    expect(script, contains('region === "floating-menu"'));
    expect(script, contains('compactLandmarks >= 2'));
    expect(script, contains('sideLandmarks >= 3'));
    for (final destination in [
      'Contracts',
      'Payments',
      'Schedule',
      'Room',
      'Reports',
      'Accounts',
    ]) {
      expect(script, contains('routeLabel: "Sidebar > $destination"'));
    }
    expect(
      shell,
      contains('route: DirectorProducerRoutes.console'),
    );
    expect(
      shell,
      contains('currentRoute == DirectorProducerRoutes.console'),
    );
  });

  test('every selectable target gets a real bright mask hole', () {
    expect(script, contains('<svg class="cc-guide-scrim"'));
    expect(script, contains('function updateScrimMask(rects)'));
    expect(script, contains('holes.replaceChildren()'));
    expect(script, contains('updateScrimMask(state.currentRects)'));
    expect(styles, contains('.cc-guide-scrim-fill'));
    expect(styles, isNot(contains('0 0 0 9999px')));
  });

  test('coach cards are measured and placed outside action targets', () {
    expect(script, contains('function placeCoachMark(rect)'));
    expect(script, contains('targetOverlap * 100000'));
    expect(script, contains('card.dataset.overlapsTarget'));
    expect(script, contains('card.offsetHeight'));
  });

  test('walkthrough surfaces use glass styling and cache-busted assets', () {
    expect(styles, contains('backdrop-filter: blur(24px) saturate(150%)'));
    expect(styles, contains('rgba(38, 45, 57, 0.78)'));
    expect(
      styles,
      isNot(contains('linear-gradient(160deg, #ffffff 0%, #f7f8fa 100%)')),
    );
    expect(index, contains('director_tutorial.css?v=20260809-30'));
    expect(index, contains('director_tutorial.js?v=20260809-30'));
  });
}
