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
    expect(
      script,
      contains('setTimeout(() => waitForActionOutcome(step, startedAt), 60)'),
    );
  });

  test('modal and project steps wait for confirmed completion', () {
    expect(script, contains('waitForTextCycle: "Add a city"'));
    expect(script, contains('requireTargetTextChange: true'));
    expect(script, contains('hideGuideWhileWaiting: true'));
    expect(
      script,
      contains('setSilentInteraction(Boolean(step.hideGuideWhileWaiting))'),
    );
    expect(script, contains('function setSilentInteraction(active)'));
    expect(
      script,
      contains('pageHasText(step.waitForTextCycle)'),
    );
    expect(
      script,
      contains('beginActionOutcomeWait(step);'),
    );
    expect(
      styles,
      contains('[data-interaction-mode="silent"] .cc-guide-card'),
    );
    expect(
      styles,
      contains('[data-interaction-mode="silent"] .cc-guide-spotlight'),
    );
    expect(
      styles,
      contains('[data-interaction-mode="silent"] .cc-guide-controls'),
    );
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
    expect(
        script, contains('failureTextPatterns: ["Request validation failed"'));
    expect(script, contains('function failCurrentAction(step, message)'));
  });

  test('multi-field input never completes from one broad editing rectangle',
      () {
    expect(script, contains('function requiredInputKeys(step)'));
    expect(script, contains('function inputTargetForEvent(event, step)'));
    expect(
        script, contains('return overlaps.length === 1 ? overlaps[0] : null'));
    expect(
        script, contains('state.inputReady = completedCount >= requiredCount'));
    expect(
        script,
        contains(
            'document.addEventListener("focusout", handleTargetInputCommit'));
    expect(
      script,
      isNot(contains(
          'const requiredCount = step.multipleTargets ? state.currentTargets.length : 1')),
    );
  });

  test('async actions show confirmation and clear stale target outlines', () {
    expect(script, contains('const SUCCESS_CONFIRMATION_MS = 900'));
    expect(script, contains('state.actionCompleting'));
    expect(script, contains('Confirmed — continuing to the next step'));
    expect(
      script,
      contains(
          'if (state.actionPending && hasDeferredOutcome(step)) return []'),
    );
    expect(styles, contains('[data-action-state="success"] .cc-guide-mission'));
  });

  test('file uploads wait for a newly completed upload', () {
    expect(script, contains('expectedTextCountIncrease: "Upload complete"'));
    expect(script, contains('state.outcomeBaselineTextCount'));
    expect(
      shell,
      isNot(contains('Upload complete')),
      reason:
          'The upload completion semantic belongs to the file row, not the shell.',
    );
    final wizard = File(
      'lib/features/director_producer/screens/dp_create_project_wizard_screen.dart',
    ).readAsStringSync();
    expect(wizard, contains("label: 'Upload complete'"));
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

  test('requirement forms keep the full modal bright and unobstructed', () {
    expect(script, contains('keepInteractionScopeBright: true'));
    expect(script, contains('interactionScopePattern: "Add requirement"'));
    expect(script, contains('function resolveInteractionScope(step)'));
    expect(script, contains('const displayRects = scopeTarget'));
    expect(script, contains(r'card.style.width = `${fittedCardWidth}px`'));
    expect(script, contains('function visibleFormControlRects()'));
    expect(script, contains('workAreaOverlap * 50000'));
  });

  test('date range guidance follows start then end then Done', () {
    expect(script, contains('completionFlow: "date-range"'));
    expect(script, contains('startDateInstruction: "Choose the start date."'));
    expect(script, contains('endDateInstruction: "Now choose the end date."'));
    expect(
      script,
      contains('doneDateInstruction: "Date range selected. Tap Done."'),
    );
    expect(script, contains('function handleDateRangeSelection(event, step)'));
    expect(script, contains('function waitForDateRangeReady(step, startedAt)'));
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
    expect(script, contains('region === "marketplace-results"'));
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
    expect(script, contains('updateScrimMask(displayRects)'));
    expect(styles, contains('.cc-guide-scrim-fill'));
    expect(styles, isNot(contains('0 0 0 9999px')));
  });

  test('coach cards are measured and placed outside action targets', () {
    expect(script, contains('function placeCoachMark(rect)'));
    expect(script, contains('const baseCardWidth = Math.min(250'));
    expect(script, contains('targetOverlap * 100000'));
    expect(script, contains('card.dataset.overlapsTarget'));
    expect(script, contains('card.offsetHeight'));
  });

  test('coach cards stay compact with concise workflow copy', () {
    expect(styles, contains('width: min(250px, calc(100vw - 32px))'));
    expect(styles, contains('max-height: min(230px'));
    expect(script, contains('Build a production, start to finish'));
    expect(
      script,
      contains('Create the project, hire by requirement, then manage deals'),
    );
    expect(
      script,
      isNot(contains('Build one complete production from start to finish')),
    );
  });

  test('walkthrough surfaces use glass styling and cache-busted assets', () {
    expect(styles, contains('backdrop-filter: blur(24px) saturate(150%)'));
    expect(styles, contains('rgba(38, 45, 57, 0.78)'));
    expect(
      styles,
      isNot(contains('linear-gradient(160deg, #ffffff 0%, #f7f8fa 100%)')),
    );
    expect(index, contains('director_tutorial.css?v=20260813-35'));
    expect(index, contains('director_tutorial.js?v=20260813-35'));
    expect(
      index,
      contains('no-cache, no-store, must-revalidate'),
    );
  });

  test('web startup is self-hosted and never fails to a blank screen', () {
    expect(index, contains("canvasKitBaseUrl: 'canvaskit/'"));
    expect(index, contains("'flutter-first-frame'"));
    expect(index, contains("document.querySelector('flutter-view')"));
    expect(index, contains('window.requestAnimationFrame(finishBoot)'));
    expect(index, contains('Loading CineConnect…'));
    expect(index, contains('Reload portal'));
    expect(index, contains('window.setTimeout(showBootFailure, 15000)'));
  });
}
