import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarang69/models/schedule_model.dart';

void main() {
  test('schedule.json can be parsed without error', () {
    final file = File('assets/data/schedule.json');
    expect(file.existsSync(), isTrue);
    final jsonStr = file.readAsStringSync();
    final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
    final data = FullScheduleData.fromJson(jsonMap);
    
    expect(data.dayOrder.length, 5);
    expect(data.schedule.containsKey('จันทร์'), isTrue);
    expect(data.bellPlans.containsKey('plan1'), isTrue);
  });
}
