import 'package:cineconnect/core/auth/auth_controller.dart';
import 'package:cineconnect/core/auth/auth_repository.dart';
import 'package:cineconnect/core/auth/token_store.dart';
import 'package:cineconnect/core/director/director_dashboard_models.dart';
import 'package:cineconnect/core/network/api_client.dart';
import 'package:cineconnect/features/director_producer/widgets/dp_project_console_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ScheduleAuth extends AuthController {
  final List<DirectorScheduleEvent> events;
  int loads = 0;
  _ScheduleAuth(this.events, ApiClient client)
      : super(
            repository: AuthRepository(client),
            client: client,
            tokenStore: const TokenStore());
  @override
  Future<DirectorSchedule> directorSchedule({String? projectId}) async {
    loads++;
    return DirectorSchedule(
        events: events,
        risks: const [],
        callSheet: DirectorCallSheet.fromJson(<String, dynamic>{}));
  }
}

DirectorScheduleEvent _event(DateTime date, String title) =>
    DirectorScheduleEvent.fromJson({
      'public_id': title,
      'title': title,
      'starts_at': date.toIso8601String(),
    });

Future<void> _mount(WidgetTester tester, _ScheduleAuth auth,
    {ProductionCalendarMode mode = ProductionCalendarMode.month,
    DateTime? month,
    int refresh = 0}) async {
  await tester.pumpWidget(AuthScope(
      controller: auth,
      child: MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: ProductionCalendar(
          initialMode: mode,
          initialMonth: month,
          refreshToken: refresh,
        ))),
      )));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('long schedule titles remain fully readable on mobile',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const title =
        'Production planning meeting with the director, cinematographer and department heads';
    final auth = _ScheduleAuth([_event(DateTime.now(), title)], ApiClient());
    await _mount(tester, auth, mode: ProductionCalendarMode.today);
    expect(find.text(title), findsOneWidget);
    expect(tester.widget<Text>(find.text(title)).maxLines, isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('leap month has valid dates and filters exact year/month/day',
      (tester) async {
    final auth = _ScheduleAuth([
      _event(DateTime(2024, 2, 29), 'Leap-year shoot'),
      _event(DateTime(2028, 2, 29), 'Other-year shoot'),
      _event(DateTime(2024, 3, 29), 'Other-month shoot'),
    ], ApiClient());
    await _mount(tester, auth, month: DateTime(2024, 2));
    expect(find.text('February 2024'), findsOneWidget);
    expect(find.text('29'), findsOneWidget);
    expect(find.text('30'), findsNothing);
    expect(find.text('32'), findsNothing);
    await tester.tap(find.text('29'));
    await tester.pumpAndSettle();
    expect(find.text('Leap-year shoot'), findsOneWidget);
    expect(find.text('Other-year shoot'), findsNothing);
    expect(find.text('Other-month shoot'), findsNothing);
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('March 2024'), findsOneWidget);
    expect(find.text('31'), findsOneWidget);
    expect(find.text('Leap-year shoot'), findsNothing);
  });

  testWidgets('month navigation crosses the year boundary on mobile',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = _ScheduleAuth([], ApiClient());
    await _mount(tester, auth, month: DateTime(2026, 12));
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('January 2027'), findsOneWidget);
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(find.text('December 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Today never substitutes upcoming or historic events',
      (tester) async {
    final auth = _ScheduleAuth([
      _event(DateTime.now().add(const Duration(days: 3)), 'Future shoot'),
      _event(DateTime(2020, 7, 21), 'Old hardcoded date'),
    ], ApiClient());
    await _mount(tester, auth, mode: ProductionCalendarMode.today);
    expect(find.text('No production events scheduled today.'), findsOneWidget);
    expect(find.text('Future shoot'), findsNothing);
    expect(find.text('Old hardcoded date'), findsNothing);
  });

  testWidgets('successful sync token reloads live calendar data',
      (tester) async {
    final auth = _ScheduleAuth([], ApiClient());
    await _mount(tester, auth);
    expect(auth.loads, 1);
    await _mount(tester, auth, refresh: 1);
    expect(auth.loads, 2);
  });
}
