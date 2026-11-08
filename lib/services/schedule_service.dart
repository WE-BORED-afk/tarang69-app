import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule_model.dart';
import 'widget_service.dart';

class CurrentPeriodStatus {
  final String subjectName;
  final String room;
  final String timeStr;
  final String teacher;
  final String badge;
  final String nextSubject;
  final String laterSubject;
  final int progressPercent;
  final int activePeriodIndex;
  final int remainingSeconds;
  final String countdownText;
  final bool isWeekend;
  final bool isBeforeSchool;
  final bool isAfterSchool;
  final String? code;

  CurrentPeriodStatus({
    required this.subjectName,
    required this.room,
    required this.timeStr,
    required this.teacher,
    required this.badge,
    required this.nextSubject,
    this.laterSubject = '',
    required this.progressPercent,
    required this.activePeriodIndex,
    this.remainingSeconds = 0,
    this.countdownText = '',
    this.isWeekend = false,
    this.isBeforeSchool = false,
    this.isAfterSchool = false,
    this.code,
  });
}

class ItemTimeRange {
  final int start;
  final int end;
  final String timeStr;

  ItemTimeRange({required this.start, required this.end, required this.timeStr});
}

class ScheduleService {
  static const String remoteJsonUrl =
      'https://raw.githubusercontent.com/WE-BORED-afk/tarang69/main/data/schedule.json';
  static const String cacheKey = 'tarang69_schedule_cache';
  static const String planKey = 'tarang69_selected_plan';

  FullScheduleData? scheduleData;
  String selectedPlanId = 'plan1';

  int? simulatedHour;
  int? simulatedMinute;
  String? simulatedLabel;

  void setSimulatedTime(int? hour, int? minute, [String? label]) {
    simulatedHour = hour;
    simulatedMinute = minute;
    simulatedLabel = label;
    updateWidget();
  }

  bool isRealWeekend() {
    final weekday = DateTime.now().weekday;
    return weekday == DateTime.saturday || weekday == DateTime.sunday;
  }

  String getRealDayThaiName() {
    final weekday = DateTime.now().weekday;
    switch (weekday) {
      case 1:
        return 'วันจันทร์';
      case 2:
        return 'วันอังคาร';
      case 3:
        return 'วันพุธ';
      case 4:
        return 'วันพฤหัสบดี';
      case 5:
        return 'วันศุกร์';
      case 6:
        return 'วันเสาร์';
      case 7:
        return 'วันอาทิตย์';
      default:
        return 'วันจันทร์';
    }
  }

  String? getActualTodayThaiKey() {
    final weekday = DateTime.now().weekday;
    switch (weekday) {
      case 1:
        return 'จันทร์';
      case 2:
        return 'อังคาร';
      case 3:
        return 'พุธ';
      case 4:
        return 'พฤหัสบดี';
      case 5:
        return 'ศุกร์';
      default:
        return null;
    }
  }

  String getDefaultViewDayKey() {
    return getActualTodayThaiKey() ?? 'จันทร์';
  }

  ItemTimeRange getItemTimeRange(PeriodItem item, BellPlan plan) {
    if (item.type == 'break') {
      final title = item.title ?? '';
      if (title.contains('20') || title.contains('สาย') || title.contains('เช้า')) {
        final b1 = plan.periods['break1'];
        if (b1 != null) {
          return ItemTimeRange(start: b1.start, end: b1.end, timeStr: b1.timeStr);
        }
        return ItemTimeRange(start: 600, end: 620, timeStr: '10.00 - 10.20 น.');
      } else {
        final lunch = plan.periods['lunch'];
        if (lunch != null) {
          return ItemTimeRange(start: lunch.start, end: lunch.end, timeStr: lunch.timeStr);
        }
        return ItemTimeRange(start: 720, end: 770, timeStr: '12.00 - 12.50 น.');
      }
    }

    final pStr = item.period ?? '';
    final match = RegExp(r'(\d+)(?:\s*-\s*(\d+))?').firstMatch(pStr);
    if (match != null) {
      final p1 = match.group(1)!;
      final p2 = match.group(2) ?? p1;
      final p1Info = plan.periods[p1];
      final p2Info = plan.periods[p2];
      if (p1Info != null && p2Info != null) {
        final startTime = p1Info.timeStr.split(' - ')[0];
        final p2Parts = p2Info.timeStr.split(' - ');
        final endTime = p2Parts.length > 1 ? p2Parts[1] : p2Info.timeStr;
        return ItemTimeRange(
          start: p1Info.start,
          end: p2Info.end,
          timeStr: '$startTime - $endTime',
        );
      }
    }

    // Default fallback to period 1
    final p1 = plan.periods['1'];
    return ItemTimeRange(
      start: p1?.start ?? 500,
      end: p1?.end ?? 550,
      timeStr: p1?.timeStr ?? '08.20 - 09.10 น.',
    );
  }

  Future<FullScheduleData> loadSchedule() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      selectedPlanId = prefs.getString(planKey) ?? 'plan1';
    } catch (e) {
      debugPrint('Error loading SharedPreferences: $e');
    }

    // 1. Cache
    if (prefs != null) {
      final cachedJson = prefs.getString(cacheKey);
      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
          scheduleData = FullScheduleData.fromJson(decoded);
        } catch (e) {
          debugPrint('Error parsing cached schedule: $e');
        }
      }
    }

    // 2. Bundled local asset
    if (scheduleData == null) {
      try {
        final assetContent = await rootBundle.loadString('assets/data/schedule.json');
        final decoded = jsonDecode(assetContent) as Map<String, dynamic>;
        scheduleData = FullScheduleData.fromJson(decoded);
      } catch (e) {
        debugPrint('Error loading asset schedule: $e');
      }
    }

    // 3. Fallback dummy
    if (scheduleData == null) {
      scheduleData = FullScheduleData(
        updatedAt: DateTime.now().toIso8601String(),
        dayOrder: ['จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี', 'ศุกร์'],
        schedule: {
          'จันทร์': DaySchedule(name: 'วันจันทร์', en: 'Monday', colorClass: '', items: []),
          'อังคาร': DaySchedule(name: 'วันอังคาร', en: 'Tuesday', colorClass: '', items: []),
          'พุธ': DaySchedule(name: 'วันพุธ', en: 'Wednesday', colorClass: '', items: []),
          'พฤหัสบดี': DaySchedule(name: 'วันพฤหัสบดี', en: 'Thursday', colorClass: '', items: []),
          'ศุกร์': DaySchedule(name: 'วันศุกร์', en: 'Friday', colorClass: '', items: []),
        },
        bellPlans: {
          'plan1': BellPlan(id: 'plan1', name: 'แผน 1 (ปกติ)', shortName: 'แผน 1 ปกติ', desc: '', periods: {}),
        },
      );
    }

    // 4. Remote update
    try {
      fetchRemoteUpdate();
    } catch (_) {}

    // 5. Widget update
    try {
      updateWidget();
    } catch (_) {}

    return scheduleData!;
  }

  Future<void> setPlan(String planId) async {
    selectedPlanId = planId;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(planKey, planId);
    } catch (_) {}
    try {
      updateWidget();
    } catch (_) {}
  }

  Future<bool> fetchRemoteUpdate() async {
    try {
      final response = await http
          .get(Uri.parse(remoteJsonUrl))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final parsed = FullScheduleData.fromJson(decoded);
        scheduleData = parsed;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(cacheKey, jsonEncode(decoded));
        } catch (_) {}
        updateWidget();
        return true;
      }
    } catch (e) {
      debugPrint('fetchRemoteUpdate error: $e');
    }
    return false;
  }

  CurrentPeriodStatus getCurrentStatus(String dayKey) {
    if (scheduleData == null) {
      return CurrentPeriodStatus(
        subjectName: 'ไม่มีข้อมูล',
        room: '-',
        timeStr: '-',
        teacher: '-',
        badge: '✨ พักผ่อน',
        nextSubject: '-',
        progressPercent: 0,
        activePeriodIndex: -1,
      );
    }

    final now = DateTime.now();
    final isWeekend = (simulatedHour == null) && isRealWeekend();

    if (isWeekend) {
      return CurrentPeriodStatus(
        subjectName: 'วันหยุดสุดสัปดาห์ (${getRealDayThaiName()})',
        room: 'พักผ่อนตามอัธยาศัย',
        timeStr: 'Weekend Holiday',
        teacher: '-',
        badge: '🎉 วันหยุด',
        nextSubject: 'วันจันทร์เจอกันใหม่นะ!',
        laterSubject: 'ดูตารางเรียนวันจันทร์ล่วงหน้าได้',
        progressPercent: 100,
        activePeriodIndex: -1,
        remainingSeconds: 0,
        countdownText: '🎉 วันหยุด',
        isWeekend: true,
      );
    }

    final hour = simulatedHour ?? now.hour;
    final minute = simulatedMinute ?? now.minute;
    final second = simulatedHour != null ? 0 : now.second;
    final totalMins = hour * 60 + minute;
    final totalSecs = totalMins * 60 + second;

    final daySchedule = scheduleData!.schedule[dayKey];
    final plan = scheduleData!.bellPlans[selectedPlanId];

    if (daySchedule == null || plan == null || daySchedule.items.isEmpty) {
      return CurrentPeriodStatus(
        subjectName: 'ไม่มีข้อมูล',
        room: '-',
        timeStr: '-',
        teacher: '-',
        badge: '✨ พักผ่อน',
        nextSubject: '-',
        progressPercent: 0,
        activePeriodIndex: -1,
      );
    }

    // Resolve time range for every item in today's schedule
    final itemsWithTime = daySchedule.items.map((item) {
      return {
        'item': item,
        'time': getItemTimeRange(item, plan),
      };
    }).toList();

    final firstItem = itemsWithTime.first['item'] as PeriodItem;
    final firstTime = itemsWithTime.first['time'] as ItemTimeRange;
    final lastTime = itemsWithTime.last['time'] as ItemTimeRange;

    // 1. Before School
    if (totalMins < firstTime.start) {
      final remSecs = (firstTime.start * 60) - totalSecs;
      final remMins = (remSecs / 60).ceil();
      final nextName = firstItem.name ?? firstItem.title ?? 'คาบแรก';
      final nextCode = firstItem.code != null && firstItem.code != '-' ? ' (${firstItem.code})' : '';

      String later = '';
      if (itemsWithTime.length > 1) {
        final secondItem = itemsWithTime[1]['item'] as PeriodItem;
        later = 'ต่อไป: ${secondItem.name ?? secondItem.title ?? ''}';
      }

      return CurrentPeriodStatus(
        subjectName: 'ยังไม่เริ่มคาบเรียน',
        room: firstItem.room ?? 'ห้องเรียนประจำ',
        timeStr: 'เริ่ม ${firstTime.timeStr.split(" - ")[0]} น.',
        teacher: firstItem.teacher ?? '-',
        badge: '⏰ กำลังจะเริ่ม',
        nextSubject: '$nextName$nextCode',
        laterSubject: later,
        progressPercent: 0,
        activePeriodIndex: -1,
        remainingSeconds: remSecs > 0 ? remSecs : 0,
        countdownText: '⏱ เริ่มใน $remMins น.',
        isBeforeSchool: true,
        code: firstItem.code,
      );
    }

    // 2. After School (all periods ended)
    if (totalMins >= lastTime.end) {
      return CurrentPeriodStatus(
        subjectName: 'เลิกเรียนแล้ว 🎉',
        room: 'พักผ่อนตามอัธยาศัย',
        timeStr: 'หมดคาบเรียนวันนี้',
        teacher: '-',
        badge: '✨ พักผ่อน',
        nextSubject: 'พรุ่งนี้เจอกันใหม่นะ!',
        laterSubject: 'ดูตารางเรียนวันต่อไปได้',
        progressPercent: 100,
        activePeriodIndex: -1,
        remainingSeconds: 0,
        countdownText: '✨ เลิกเรียนแล้ว',
        isAfterSchool: true,
      );
    }

    // 3. During School (Check each period OR break!)
    for (int i = 0; i < itemsWithTime.length; i++) {
      final item = itemsWithTime[i]['item'] as PeriodItem;
      final timeInfo = itemsWithTime[i]['time'] as ItemTimeRange;
      final startSecs = timeInfo.start * 60;
      final endSecs = timeInfo.end * 60;

      if (totalSecs >= startSecs && totalSecs < endSecs) {
        final remSecs = endSecs - totalSecs;
        final remMins = (remSecs / 60).ceil();
        final durationSecs = endSecs - startSecs;
        final elapsedSecs = totalSecs - startSecs;
        final progress = durationSecs > 0 ? ((elapsedSecs / durationSecs) * 100).round().clamp(0, 100) : 50;

        final isBreak = item.type == 'break';
        final isLunch = isBreak && (item.title?.contains('กลางวัน') == true || item.title?.contains('อาหาร') == true);

        String subjectName;
        String room;
        String badge;

        if (isBreak) {
          subjectName = item.title ?? (isLunch ? 'พักกลางวัน' : 'พักเบรก');
          room = item.room ?? (isLunch ? 'โรงอาหาร' : 'พักผ่อนตามอัธยาศัย');
          badge = isLunch ? '🍱 พักกลางวัน' : '☕ พักเบรก';
        } else {
          subjectName = item.name ?? item.title ?? 'กำลังเรียน';
          room = item.room ?? 'ห้องเรียนปกติ';
          badge = '🟢 กำลังเรียน';
        }

        String nextSub = 'คาบสุดท้ายของวันแล้ว 🎉';
        if (i + 1 < itemsWithTime.length) {
          final nextItem = itemsWithTime[i + 1]['item'] as PeriodItem;
          final nextTime = itemsWithTime[i + 1]['time'] as ItemTimeRange;
          final nextTimeStart = nextTime.timeStr.split(' - ')[0];
          final nextTitle = nextItem.name ?? nextItem.title ?? '';
          nextSub = '$nextTitle ($nextTimeStart น.)';
        }

        String laterSub = '';
        if (i + 2 < itemsWithTime.length) {
          final laterItem = itemsWithTime[i + 2]['item'] as PeriodItem;
          final laterTime = itemsWithTime[i + 2]['time'] as ItemTimeRange;
          final laterStart = laterTime.timeStr.split(' - ')[0];
          laterSub = 'ต่อไปอีก: ${laterItem.name ?? laterItem.title ?? ''} ($laterStart น.)';
        }

        return CurrentPeriodStatus(
          subjectName: subjectName,
          room: room,
          timeStr: timeInfo.timeStr,
          teacher: item.teacher ?? '-',
          badge: badge,
          nextSubject: nextSub,
          laterSubject: laterSub,
          progressPercent: progress,
          activePeriodIndex: i,
          remainingSeconds: remSecs > 0 ? remSecs : 0,
          countdownText: '⏱ เหลือ $remMins น.',
          code: item.code,
        );
      }
    }

    // Fallback if between gaps
    return CurrentPeriodStatus(
      subjectName: 'พักผ่อน',
      room: '-',
      timeStr: 'ระหว่างคาบ',
      teacher: '-',
      badge: '☕ พักเบรก',
      nextSubject: '-',
      progressPercent: 50,
      activePeriodIndex: -1,
      countdownText: '⏱ พักผ่อน',
    );
  }

  void updateWidget() {
    try {
      final actualTodayKey = getActualTodayThaiKey();
      final status = getCurrentStatus(actualTodayKey ?? 'จันทร์');

      WidgetService.updateWidgetData(
        subjectName: status.subjectName,
        subjectRoom: status.room,
        subjectTime: status.timeStr,
        subjectTeacher: status.teacher,
        statusBadge: status.badge,
        nextSubject: status.nextSubject,
        dayName: actualTodayKey != null ? 'วัน$actualTodayKey' : getRealDayThaiName(),
        progressPercent: status.progressPercent,
        countdownText: status.countdownText,
        laterSubject: status.laterSubject,
      );
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }
}
