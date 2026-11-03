import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule_model.dart';
import 'widget_service.dart';

class ScheduleService {
  static const String remoteJsonUrl =
      'https://raw.githubusercontent.com/WE-BORED-afk/tarang69/main/data/schedule.json';
  static const String cacheKey = 'tarang69_schedule_cache';
  static const String planKey = 'tarang69_selected_plan';

  FullScheduleData? scheduleData;
  String selectedPlanId = 'plan1';

  Future<FullScheduleData> loadSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    selectedPlanId = prefs.getString(planKey) ?? 'plan1';

    // 1. Try loading from cache first
    final cachedJson = prefs.getString(cacheKey);
    if (cachedJson != null) {
      try {
        final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
        scheduleData = FullScheduleData.fromJson(decoded);
      } catch (_) {}
    }

    // 2. If no cache, load from local bundled asset
    if (scheduleData == null) {
      final assetContent = await rootBundle.loadString('assets/data/schedule.json');
      final decoded = jsonDecode(assetContent) as Map<String, dynamic>;
      scheduleData = FullScheduleData.fromJson(decoded);
    }

    // 3. Background fetch latest from GitHub (Single Source of Truth)
    fetchRemoteUpdate();

    updateWidget();
    return scheduleData!;
  }

  Future<void> setPlan(String planId) async {
    selectedPlanId = planId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(planKey, planId);
    updateWidget();
  }

  Future<void> fetchRemoteUpdate() async {
    try {
      final response = await http.get(Uri.parse(remoteJsonUrl)).timeout(const Duration(seconds: 4));
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

  void updateWidget() {
    if (scheduleData == null) return;
    final now = DateTime.now();
    final totalMins = now.hour * 60 + now.minute;
    final todayKey = getTodayThaiKey();
    final daySchedule = scheduleData!.schedule[todayKey];
    final plan = scheduleData!.bellPlans[selectedPlanId];

    if (daySchedule == null || plan == null) return;

    // Check school hours (e.g. before 08:20, in class, or after 16:10)
    String subjectName = 'เลิกเรียนแล้ว';
    String room = '-';
    String timeStr = 'พักผ่อนตามอัธยาศัย';
    String teacher = '-';
    String badge = '✨ พักผ่อน';
    String nextSubject = 'คาบถัดไป: -';
    int progress = 100;

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
      // Find current period
      for (int i = 0; i < daySchedule.items.length; i++) {
        final item = daySchedule.items[i];
        final periodKey = (i + 1).toString();
        final timeInfo = plan.periods[periodKey];

        if (timeInfo != null && totalMins >= timeInfo.start && totalMins < timeInfo.end) {
          subjectName = item.name ?? item.title ?? 'กำลังเรียน';
          room = item.room ?? 'ห้องเรียนปกติ';
          timeStr = timeInfo.timeStr;
          teacher = item.teacher ?? '-';
          badge = '🟢 กำลังเรียน';

          if (i + 1 < daySchedule.items.length) {
            final next = daySchedule.items[i + 1];
            nextSubject = 'คาบถัดไป: ${next.name ?? next.title ?? ''}';
          } else {
            nextSubject = 'คาบสุดท้ายของวันแล้ว 🎉';
          }

          final elapsed = totalMins - timeInfo.start;
          final duration = timeInfo.end - timeInfo.start;
          progress = duration > 0 ? ((elapsed / duration) * 100).round() : 50;
          break;
        }
      }
    }

    WidgetService.updateWidgetData(
      subjectName: subjectName,
      subjectRoom: room,
      subjectTime: timeStr,
      subjectTeacher: teacher,
      statusBadge: badge,
      nextSubject: nextSubject,
      dayName: 'วัน$todayKey',
      progressPercent: progress,
    );
  }
}
