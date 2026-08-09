import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final script = File('web/director_tutorial.js').readAsStringSync();
  final styles = File('web/director_tutorial.css').readAsStringSync();
  final index = File('web/index.html').readAsStringSync();

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
    expect(
      script,
      contains('completionDismissedPattern: "Save requirement"'),
    );
    expect(script, contains('expectedTextPattern: "Project created"'));
  });

  test('navigation targets adapt to bottom navigation and desktop sidebar', () {
    expect(script, contains('const SIDEBAR_BREAKPOINT_PX = 1200'));
    expect(script, contains('function currentNavigationMode()'));
    expect(script, contains('stepForCurrentLayout(steps[state.index])'));
    expect(script, contains('targetLabels: ["Productions"]'));
    expect(script, contains('targetLabels: ["Projects"]'));
    expect(script, contains('targetLabels: ["Deals"]'));
    expect(script, contains('targetLabels: ["Bargaining"]'));
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
  });

  test('walkthrough surfaces use glass styling and cache-busted assets', () {
    expect(styles, contains('backdrop-filter: blur(24px) saturate(150%)'));
    expect(styles, contains('rgba(38, 45, 57, 0.78)'));
    expect(
      styles,
      isNot(contains('linear-gradient(160deg, #ffffff 0%, #f7f8fa 100%)')),
    );
    expect(index, contains('director_tutorial.css?v=20260809-27'));
    expect(index, contains('director_tutorial.js?v=20260809-27'));
  });
}
