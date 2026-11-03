class PeriodItem {
  final String type; // subject, break, activity, free
  final String? period;
  final String? code;
  final String? name;
  final String? teacher;
  final String? room;
  final bool isDouble;
  final String? title;
  final String? time;
  final String? icon;
  final String? color;

  PeriodItem({
    required this.type,
    this.period,
    this.code,
    this.name,
    this.teacher,
    this.room,
    this.isDouble = false,
    this.title,
    this.time,
    this.icon,
    this.color,
  });

  factory PeriodItem.fromJson(Map<String, dynamic> json) {
    return PeriodItem(
      type: json['type'] ?? 'subject',
      period: json['period'],
      code: json['code'],
      name: json['name'],
      teacher: json['teacher'],
      room: json['room'],
      isDouble: json['isDouble'] ?? false,
      title: json['title'],
      time: json['time'],
      icon: json['icon'],
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    if (period != null) 'period': period,
    if (code != null) 'code': code,
    if (name != null) 'name': name,
    if (teacher != null) 'teacher': teacher,
    if (room != null) 'room': room,
    'isDouble': isDouble,
    if (title != null) 'title': title,
    if (time != null) 'time': time,
    if (icon != null) 'icon': icon,
    if (color != null) 'color': color,
  };
}

class DaySchedule {
  final String name;
  final String en;
  final String colorClass;
  final List<PeriodItem> items;

  DaySchedule({
    required this.name,
    required this.en,
    required this.colorClass,
    required this.items,
  });

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    return DaySchedule(
      name: json['name'] ?? '',
      en: json['en'] ?? '',
      colorClass: json['colorClass'] ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => PeriodItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PeriodTimeInfo {
  final int start;
  final int end;
  final String timeStr;
  final String? title;
  final String? icon;

  PeriodTimeInfo({
    required this.start,
    required this.end,
    required this.timeStr,
    this.title,
    this.icon,
  });

  factory PeriodTimeInfo.fromJson(Map<String, dynamic> json) {
    return PeriodTimeInfo(
      start: json['start'] ?? 0,
      end: json['end'] ?? 0,
      timeStr: json['timeStr'] ?? '',
      title: json['title'],
      icon: json['icon'],
    );
  }
}

class BellPlan {
  final String id;
  final String name;
  final String shortName;
  final String desc;
  final Map<String, PeriodTimeInfo> periods;

  BellPlan({
    required this.id,
    required this.name,
    required this.shortName,
    required this.desc,
    required this.periods,
  });

  factory BellPlan.fromJson(Map<String, dynamic> json) {
    final periodsMap = <String, PeriodTimeInfo>{};
    if (json['periods'] is Map<String, dynamic>) {
      (json['periods'] as Map<String, dynamic>).forEach((k, v) {
        periodsMap[k] = PeriodTimeInfo.fromJson(v as Map<String, dynamic>);
      });
    }
    return BellPlan(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      shortName: json['shortName'] ?? '',
      desc: json['desc'] ?? '',
      periods: periodsMap,
    );
  }
}

class FullScheduleData {
  final String updatedAt;
  final List<String> dayOrder;
  final Map<String, DaySchedule> schedule;
  final Map<String, BellPlan> bellPlans;

  FullScheduleData({
    required this.updatedAt,
    required this.dayOrder,
    required this.schedule,
    required this.bellPlans,
  });

  factory FullScheduleData.fromJson(Map<String, dynamic> json) {
    final scheduleMap = <String, DaySchedule>{};
    if (json['schedule'] is Map<String, dynamic>) {
      (json['schedule'] as Map<String, dynamic>).forEach((k, v) {
        scheduleMap[k] = DaySchedule.fromJson(v as Map<String, dynamic>);
      });
    }

    final bellPlansMap = <String, BellPlan>{};
    if (json['bellPlans'] is Map<String, dynamic>) {
      (json['bellPlans'] as Map<String, dynamic>).forEach((k, v) {
        bellPlansMap[k] = BellPlan.fromJson(v as Map<String, dynamic>);
      });
    }

    return FullScheduleData(
      updatedAt: json['updatedAt'] ?? '',
      dayOrder: List<String>.from(json['dayOrder'] ?? []),
      schedule: scheduleMap,
      bellPlans: bellPlansMap,
    );
  }
}
