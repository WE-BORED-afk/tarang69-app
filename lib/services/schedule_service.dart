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
  final int progressPercent;
  final int activePeriodIndex;
  final int remainingSeconds;
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
    required this.progressPercent,
    required this.activePeriodIndex,
    this.remainingSeconds = 0,
    this.isWeekend = false,
    this.isBeforeSchool = false,
    this.isAfterSchool = false,
    this.code,
  });
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

  /// Returns the day key (e.g. 'จันทร์') ONLY if today is a weekday Monday-Friday.
  /// On weekends, returns null to avoid marking Monday as 'Today'.
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
        return null; // Saturday or Sunday
    }
  }

  /// Default selected tab when opening the app (if weekend, preview 'จันทร์')
  String getDefaultViewDayKey() {
    return getActualTodayThaiKey() ?? 'จันทร์';
  }

  Future<FullScheduleData> loadSchedule() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      selectedPlanId = prefs.getString(planKey) ?? 'plan1';
    } catch (e) {
      debugPrint('Error loading SharedPreferences: $e');
    }

    // 1. Try loading from cache first
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

    // 2. If no cache, load from local bundled asset
    if (scheduleData == null) {
      try {
        final assetContent = await rootBundle.loadString('assets/data/schedule.json');
        final decoded = jsonDecode(assetContent) as Map<String, dynamic>;
        scheduleData = FullScheduleData.fromJson(decoded);
      } catch (e) {
        debugPrint('Error loading asset schedule: $e');
      }
    }

    // 3. Fallback dummy data if both failed
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

    // 4. Background fetch latest from GitHub safely
    try {
      fetchRemoteUpdate();
    } catch (_) {}

    // 5. Update widget safely
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

    // If real weekend and not simulating, show Weekend Rest status
    if (isWeekend) {
      return CurrentPeriodStatus(
        subjectName: 'วันหยุดสุดสัปดาห์ (${getRealDayThaiName()})',
        room: 'พักผ่อนตามอัธยาศัย 🎉',
        timeStr: 'Weekend Holiday',
        teacher: '-',
        badge: '🎉 วันหยุด',
        nextSubject: 'วันจันทร์เจอกันใหม่นะ!',
        progressPercent: 100,
        activePeriodIndex: -1,
        remainingSeconds: 0,
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

    if (daySchedule == null || plan == null) {
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

    // Default: After school
    String subjectName = 'เลิกเรียนแล้ว 🎉';
    String room = '-';
    String timeStr = 'พักผ่อนตามอัธยาศัย';
    String teacher = '-';
    String badge = '✨ พักผ่อน';
    String nextSubject = 'พรุ่งนี้เจอกันใหม่นะ!';
    String? code;
    int progress = 100;
    int activeIdx = -1;
    int remainingSecs = 0;
    bool isBefore = false;
    bool isAfter = false;

    // Find the first period start
    final firstPeriodInfo = plan.periods['1'];
    final firstStartMins = firstPeriodInfo?.start ?? 500; // 08:20 AM = 500 mins

    if (totalMins < firstStartMins) {
      isBefore = true;
      subjectName = 'ยังไม่เริ่มคาบเรียน';
      room = 'ห้องเรียนประจำ';
      timeStr = 'เริ่ม 08.20 น.';
      badge = '⏰ กำลังจะเริ่ม';
      remainingSecs = (firstStartMins * 60) - totalSecs;
      if (remainingSecs < 0) remainingSecs = 0;

      if (daySchedule.items.isNotEmpty) {
        final first = daySchedule.items.first;
        nextSubject = 'คาบที่ 1: ${first.name ?? first.title ?? ''}';
        code = first.code;
      }
      progress = 0;
    } else {
      bool foundActive = false;
      for (int i = 0; i < daySchedule.items.length; i++) {
        final item = daySchedule.items[i];
        final periodKey = (i + 1).toString();
        final timeInfo = plan.periods[periodKey];

        if (timeInfo != null) {
          final startSecs = timeInfo.start * 60;
          final endSecs = timeInfo.end * 60;

          if (totalSecs >= startSecs && totalSecs < endSecs) {
            foundActive = true;
            activeIdx = i;
            subjectName = item.name ?? item.title ?? (item.type == 'break' ? 'พักเบรก' : 'กำลังเรียน');
            room = item.room ?? (item.type == 'break' ? 'โรงอาหาร / พักผ่อน' : 'ห้องเรียนปกติ');
            timeStr = timeInfo.timeStr;
            teacher = item.teacher ?? '-';
            badge = item.type == 'break' ? '☕ พักเบรก' : '🟢 กำลังเรียน';
            code = item.code;
            remainingSecs = endSecs - totalSecs;

            if (i + 1 < daySchedule.items.length) {
              final next = daySchedule.items[i + 1];
              nextSubject = 'คาบถัดไป: ${next.name ?? next.title ?? ''}';
            } else {
              nextSubject = 'คาบสุดท้ายของวันแล้ว 🎉';
            }

            final durationSecs = endSecs - startSecs;
            final elapsedSecs = totalSecs - startSecs;
            progress = durationSecs > 0 ? ((elapsedSecs / durationSecs) * 100).round().clamp(0, 100) : 50;
            break;
          }
        }
      }

      if (!foundActive) {
        isAfter = true;
      }
    }

    return CurrentPeriodStatus(
      subjectName: subjectName,
      room: room,
      timeStr: timeStr,
      teacher: teacher,
      badge: badge,
      nextSubject: nextSubject,
      progressPercent: progress,
      activePeriodIndex: activeIdx,
      remainingSeconds: remainingSecs,
      isBeforeSchool: isBefore,
      isAfterSchool: isAfter,
      code: code,
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
      );
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }
}
