import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const String appGroupId = 'group.com.example.tarang69';
  static const String androidWidgetName = 'Tarang69WidgetProvider';
  static const String iOSWidgetName = 'Tarang69Widget';

  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (_) {}
  }

  static Future<void> updateWidgetData({
    required String subjectName,
    required String subjectRoom,
    required String subjectTime,
    required String subjectTeacher,
    required String statusBadge,
    required String nextSubject,
    required String dayName,
    required int progressPercent,
  }) async {
    if (kIsWeb) return;
    try {
      await HomeWidget.saveWidgetData<String>('subject_name', subjectName);
      await HomeWidget.saveWidgetData<String>('subject_room', subjectRoom);
      await HomeWidget.saveWidgetData<String>('subject_time', subjectTime);
      await HomeWidget.saveWidgetData<String>('subject_teacher', subjectTeacher);
      await HomeWidget.saveWidgetData<String>('status_badge', statusBadge);
      await HomeWidget.saveWidgetData<String>('next_subject', nextSubject);
      await HomeWidget.saveWidgetData<String>('day_name', dayName);
      await HomeWidget.saveWidgetData<int>('progress_percent', progressPercent);

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
        iOSName: iOSWidgetName,
      );
    } catch (_) {}
  }
}
