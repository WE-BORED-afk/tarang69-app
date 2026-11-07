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

  CurrentPeriodStatus({
    required this.subjectName,
    required this.room,
    required this.timeStr,
    required this.teacher,
    required this.badge,
    required this.nextSubject,
    required this.progressPercent,
    required this.activePeriodIndex,
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
          'plan1': BellPlan(id: 'plan1', name: 'แผนปกติ', shortName: 'แผนปกติ', desc: '', periods: {}),
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

  Future<void> fetchRemoteUpdate() async {
    try {
      final response = await http
          .get(Uri.parse(remoteJsonUrl))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final newSchedule = FullScheduleData.fromJson(decoded);
        scheduleData = newSchedule;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, response.body);
        updateWidget();
      }
    } catch (_) {
      // Offline fallback is silent
    }
  }

  String getTodayThaiKey() {
    final weekday = DateTime.now().weekday; // 1 = Monday, 5 = Friday
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
        return 'จันทร์';
    }
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
    final hour = simulatedHour ?? now.hour;
    final minute = simulatedMinute ?? now.minute;
    final totalMins = hour * 60 + minute;

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

    String subjectName = 'เลิกเรียนแล้ว 🎉';
    String room = '-';
    String timeStr = 'พักผ่อนตามอัธยาศัย';
    String teacher = '-';
    String badge = '✨ พักผ่อน';
    String nextSubject = 'พรุ่งนี้เจอกันใหม่นะ!';
    int progress = 100;
    int activeIdx = -1;

    if (totalMins < 500) {
      subjectName = 'ยังไม่เริ่มคาบเรียน';
      room = 'ห้องเรียนประจำ';
      timeStr = 'เริ่ม 08.20 น.';
      badge = '⏰ กำลังจะเริ่ม';
      if (daySchedule.items.isNotEmpty) {
        final first = daySchedule.items.first;
        nextSubject = 'คาบที่ 1: ${first.name ?? first.title ?? ''}';
      }
      progress = 0;
    } else {
      for (int i = 0; i < daySchedule.items.length; i++) {
        final item = daySchedule.items[i];
        final periodKey = (i + 1).toString();
        final timeInfo = plan.periods[periodKey];

        if (timeInfo != null && totalMins >= timeInfo.start && totalMins < timeInfo.end) {
          activeIdx = i;
          subjectName = item.name ?? item.title ?? (item.type == 'break' ? 'พักเบรก' : 'กำลังเรียน');
          room = item.room ?? (item.type == 'break' ? 'โรงอาหาร / พักผ่อน' : 'ห้องเรียนปกติ');
          timeStr = timeInfo.timeStr;
          teacher = item.teacher ?? '-';
          badge = item.type == 'break' ? '☕ พักเบรก' : '🟢 กำลังเรียน';

          if (i + 1 < daySchedule.items.length) {
            final next = daySchedule.items[i + 1];
            nextSubject = 'คาบถัดไป: ${next.name ?? next.title ?? ''}';
          } else {
            nextSubject = 'คาบสุดท้ายของวันแล้ว 🎉';
          }

          final elapsed = totalMins - timeInfo.start;
          final duration = timeInfo.end - timeInfo.start;
          progress = duration > 0 ? ((elapsed / duration) * 100).round().clamp(0, 100) : 50;
          break;
        }
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
    );
  }

  void updateWidget() {
    try {
      final todayKey = getTodayThaiKey();
      final status = getCurrentStatus(todayKey);

      WidgetService.updateWidgetData(
        subjectName: status.subjectName,
        subjectRoom: status.room,
        subjectTime: status.timeStr,
        subjectTeacher: status.teacher,
        statusBadge: status.badge,
        nextSubject: status.nextSubject,
        dayName: 'วัน$todayKey',
        progressPercent: status.progressPercent,
      );
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }
}
