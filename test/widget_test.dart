import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarang69/main.dart';
import 'package:tarang69/services/schedule_service.dart';
import 'package:tarang69/widgets/now_next_banner.dart';

String _cellText(DataCell cell) {
  final child = cell.child;
  if (child is Text) return child.data ?? '';
  if (child is Column) {
    return child.children.whereType<Text>().map((t) => t.data ?? '').join(' ');
  }
  return '';
}

Future<void> _pumpUntilLoaded(WidgetTester tester) async {
  for (int i = 0; i < 40 && find.text('📊').evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 25)));
    await tester.pump();
  }
}

ScheduleService _createOfflineService({DateTime Function()? clock}) {
  return ScheduleService(
    clock: clock,
    httpClient: MockClient((_) async => http.Response('', 404)),
  );
}

void main() {
  setUp(() {
    rootBundle.clear();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Tarang69App smoke test', (WidgetTester tester) async {
    final scheduleService = _createOfflineService();
    await tester.pumpWidget(Tarang69App(scheduleService: scheduleService));
    await _pumpUntilLoaded(tester);
    expect(find.byType(Tarang69App), findsOneWidget);
  });

  testWidgets('Weekly table aligns subjects to true period columns 1..8 across double/triple periods',
      (WidgetTester tester) async {
    final scheduleService = _createOfflineService(
      clock: () => DateTime(2026, 11, 9, 9, 30),
    );
    await tester.pumpWidget(Tarang69App(scheduleService: scheduleService));
    await _pumpUntilLoaded(tester);

    await tester.tap(find.text('📊'));
    await tester.pump();

    final table = tester.widget<DataTable>(find.byType(DataTable));
    final monCells = table.rows[0].cells;
    final wedCells = table.rows[2].cells;
    final friCells = table.rows[4].cells;

    expect(_cellText(monCells[3]), 'วิชาคอมพิวเตอร์');
    expect(_cellText(monCells[4]), 'วิชาคอมพิวเตอร์');
    expect(_cellText(monCells[5]), 'คณิตศาสตร์พื้นฐาน');
    expect(_cellText(monCells[8]), 'อบรมคุณธรรม');

    expect(_cellText(wedCells[2]), 'ฟิสิกส์');
    expect(_cellText(wedCells[4]), 'การงานอาชีพพื้นฐาน');
    expect(_cellText(wedCells[8]), 'โฮมรูม');

    expect(_cellText(friCells[6]), 'คาบอิสระ (3 คาบ)');
    expect(_cellText(friCells[7]), 'คาบอิสระ (3 คาบ)');
    expect(_cellText(friCells[8]), 'คาบอิสระ (3 คาบ)');
  });

  testWidgets('NowNextBanner stays locked to today even when inspecting another weekday tab',
      (WidgetTester tester) async {
    // Monday 09:30 -> Period 2: ภาษาอังกฤษอ่าน-เขียน (อ33202)
    final scheduleService = _createOfflineService(
      clock: () => DateTime(2026, 11, 9, 9, 30),
    );
    await tester.pumpWidget(Tarang69App(scheduleService: scheduleService));
    await _pumpUntilLoaded(tester);

    final bannerBefore = tester.widget<NowNextBanner>(find.byType(NowNextBanner));
    expect(bannerBefore.currentSubject, 'ภาษาอังกฤษอ่าน-เขียน');
    expect(find.text('🟢 สด'), findsOneWidget);

    // Switch tab to Tuesday (Tue Period 2 is ดนตรี นาฏศิลป์)
    await tester.tap(find.text('อังคาร'));
    await tester.pump();

    expect(find.text('วันอังคาร • Timeline'), findsOneWidget);
    final bannerAfter = tester.widget<NowNextBanner>(find.byType(NowNextBanner));
    expect(bannerAfter.currentSubject, 'ภาษาอังกฤษอ่าน-เขียน');
    expect(find.text('ดนตรี นาฏศิลป์ (ศ33102)', findRichText: true), findsOneWidget);
    expect(find.text('🟢 สด'), findsNothing);
  });

  testWidgets('HomeScreen refreshes automatically when background fetchRemoteUpdate finishes',
      (WidgetTester tester) async {
    final modified = jsonDecode(File('assets/data/schedule.json').readAsStringSync()) as Map<String, dynamic>;
    modified['schedule']['จันทร์']['items'][0]['name'] = 'ดาราศาสตร์ออนไลน์';

    final responseCompleter = Completer<http.Response>();
    final scheduleService = ScheduleService(
      clock: () => DateTime(2026, 11, 9, 8, 30),
      httpClient: MockClient((_) => responseCompleter.future),
    );

    await tester.pumpWidget(Tarang69App(scheduleService: scheduleService));
    await _pumpUntilLoaded(tester);

    // Initial asset load shows ชีวะ in NowNextBanner
    expect(tester.widget<NowNextBanner>(find.byType(NowNextBanner)).currentSubject, 'ชีวะ');

    // Remote fetch completes later in background
    responseCompleter.complete(
      http.Response.bytes(utf8.encode(jsonEncode(modified)), 200),
    );
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump();

    expect(tester.widget<NowNextBanner>(find.byType(NowNextBanner)).currentSubject, 'ดาราศาสตร์ออนไลน์');
  });

  testWidgets('NowNextBanner renders long teacher name without RenderFlex overflow on 320px width',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: NowNextBanner(
              currentSubject: 'วิชาคอมพิวเตอร์',
              timeRange: '10.20 - 12.00 น.',
              teacher: 'ครูผู้สอนชื่อยาวมากพิเศษสำหรับทดสอบหน้าจอแคบ',
              nextSubject: 'พักกลางวัน 50 นาที (12.00 น.)',
              progressPercent: 50,
              remainingSeconds: 1800,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
