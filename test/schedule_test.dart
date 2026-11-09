import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarang69/models/schedule_model.dart';
import 'package:tarang69/services/schedule_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, dynamic> rawScheduleJson;
  late FullScheduleData parsedData;

  setUpAll(() {
    final file = File('assets/data/schedule.json');
    rawScheduleJson = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    parsedData = FullScheduleData.fromJson(rawScheduleJson);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('schedule.json can be parsed without error', () {
    expect(parsedData.dayOrder.length, 5);
    expect(parsedData.schedule.containsKey('จันทร์'), isTrue);
    expect(parsedData.bellPlans.containsKey('plan1'), isTrue);
  });

  group('ScheduleService.getCurrentStatus', () {
    ScheduleService createServiceAt(DateTime time, {String planId = 'plan1'}) {
      return ScheduleService(
        clock: () => time,
        httpClient: MockClient((_) async => http.Response('', 404)),
      )
        ..scheduleData = parsedData
        ..selectedPlanId = planId;
    }

    test('before school on Monday shows upcoming first period and countdown', () {
      // Monday 2026-11-09 08:00:00 (20 minutes before 08:20)
      final service = createServiceAt(DateTime(2026, 11, 9, 8, 0, 0));
      final status = service.getCurrentStatus('จันทร์');

      expect(status.isBeforeSchool, isTrue);
      expect(status.isWeekend, isFalse);
      expect(status.isAfterSchool, isFalse);
      expect(status.remainingSeconds, 1200);
      expect(status.nextSubject, 'ชีวะ (ว33103)');
    });

    test('during morning break (10:05) shows break status and double period next', () {
      final service = createServiceAt(DateTime(2026, 11, 9, 10, 5, 0));
      final status = service.getCurrentStatus('จันทร์');

      expect(status.badge, '☕ พักเบรก');
      expect(status.activePeriodIndex, 2);
      expect(status.remainingSeconds, 900);
      expect(status.nextSubject, 'วิชาคอมพิวเตอร์ (10.20 น.)');
    });

    test('during double period 3-4 (11:00) combines time range 10.20 - 12.00 น.', () {
      final service = createServiceAt(DateTime(2026, 11, 9, 11, 0, 0));
      final status = service.getCurrentStatus('จันทร์');

      expect(status.subjectName, 'วิชาคอมพิวเตอร์');
      expect(status.timeStr, '10.20 - 12.00 น.');
      expect(status.remainingSeconds, 3600);
      expect(status.activePeriodIndex, 3);
    });

    test('during lunch break (12:15) shows lunch badge and period 5 next', () {
      final service = createServiceAt(DateTime(2026, 11, 9, 12, 15, 0));
      final status = service.getCurrentStatus('จันทร์');

      expect(status.badge, '🍱 พักกลางวัน');
      expect(status.isAfterSchool, isFalse);
      expect(status.nextSubject, 'คณิตศาสตร์พื้นฐาน (12.50 น.)');
      expect(status.remainingSeconds, 35 * 60);
    });

    test('after school (16:10) shows after-school state', () {
      final service = createServiceAt(DateTime(2026, 11, 9, 16, 10, 0));
      final status = service.getCurrentStatus('จันทร์');

      expect(status.isAfterSchool, isTrue);
      expect(status.remainingSeconds, 0);
      expect(status.subjectName, 'เลิกเรียนแล้ว 🎉');
    });

    test('Saturday and Sunday return weekend holiday regardless of dayKey', () {
      final sat = createServiceAt(DateTime(2026, 11, 14, 10, 30, 0));
      final sun = createServiceAt(DateTime(2026, 11, 15, 10, 30, 0));

      expect(sat.getActualTodayThaiKey(), isNull);
      expect(sat.getCurrentStatus('จันทร์').isWeekend, isTrue);
      expect(sat.getCurrentStatus('จันทร์').subjectName, contains('วันเสาร์'));
      expect(sun.getCurrentStatus('จันทร์').isWeekend, isTrue);
      expect(sun.getCurrentStatus('จันทร์').subjectName, contains('วันอาทิตย์'));
    });

    test('plan4 extended lunch keeps lunch status at 12:30', () {
      final service = createServiceAt(DateTime(2026, 11, 9, 12, 30, 0), planId: 'plan4');
      final status = service.getCurrentStatus('จันทร์');

      expect(status.badge, '🍱 พักกลางวัน');
      expect(status.timeStr, '11.20 - 13.10 น.');
      expect(status.remainingSeconds, 40 * 60);
    });

    test('plan2 assembly-after-school ends at 15:10', () {
      final service = createServiceAt(DateTime(2026, 11, 9, 15, 10, 0), planId: 'plan2');
      final status = service.getCurrentStatus('จันทร์');

      expect(status.isAfterSchool, isTrue);
    });
  });

  test('fetchRemoteUpdate parses Thai UTF-8 payload and updates scheduleData + cache', () async {
    final modified = jsonDecode(jsonEncode(rawScheduleJson)) as Map<String, dynamic>;
    modified['schedule']['จันทร์']['items'][0]['name'] = 'ดาราศาสตร์';

    final service = ScheduleService(
      clock: () => DateTime(2026, 11, 9, 8, 30),
      httpClient: MockClient((_) async => http.Response.bytes(
            utf8.encode(jsonEncode(modified)),
            200,
          )),
    );

    final ok = await service.fetchRemoteUpdate();
    expect(ok, isTrue);
    expect(service.scheduleData!.schedule['จันทร์']!.items[0].name, 'ดาราศาสตร์');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(ScheduleService.cacheKey), contains('ดาราศาสตร์'));
  });

  test('parsePeriodRange handles single, double, triple, and invalid periods', () {
    expect(ScheduleService.parsePeriodRange('คาบที่ 1 (08.20 - 09.10 น.)'), (1, 1));
    expect(ScheduleService.parsePeriodRange('คาบที่ 3 - 4 (10.20 - 12.00 น.)'), (3, 4));
    expect(ScheduleService.parsePeriodRange('คาบที่ 6 - 8 (13.40 - 16.10 น.)'), (6, 8));
    expect(ScheduleService.parsePeriodRange(null), isNull);
    expect(ScheduleService.parsePeriodRange('กิจกรรม'), isNull);
  });

  test('ScheduleService syncs raw schedule JSON, plan ID, and simulation state to HomeWidget', () async {
    final savedWidgetData = <String, dynamic>{};
    const channel = MethodChannel('home_widget');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'saveWidgetData') {
        final args = Map<String, dynamic>.from(call.arguments as Map);
        savedWidgetData[args['id'] as String] = args['data'];
        return true;
      }
      if (call.method == 'updateWidget') {
        return true;
      }
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final service = ScheduleService(
      clock: () => DateTime(2026, 11, 9, 10, 5, 0),
      httpClient: MockClient((_) async => http.Response('', 500)),
    );

    await service.loadSchedule();
    await Future<void>.delayed(Duration.zero);

    expect(savedWidgetData['selected_plan_id'], 'plan1');
    expect(savedWidgetData['simulated_active'], isFalse);
    final widgetJson = jsonDecode(savedWidgetData['schedule_json'] as String) as Map<String, dynamic>;
    expect(widgetJson['schedule']['จันทร์']['items'][0]['name'], 'ชีวะ');

    await service.setPlan('plan4');
    expect(savedWidgetData['selected_plan_id'], 'plan4');

    service.setSimulatedTime(12, 30, 'Test Lunch');
    await pumpEventQueue();
    expect(savedWidgetData['simulated_active'], isTrue);
  });
}
