import 'package:flutter_test/flutter_test.dart';
import 'package:tarang69/main.dart';
import 'package:tarang69/services/schedule_service.dart';

void main() {
  testWidgets('Tarang69App smoke test', (WidgetTester tester) async {
    final scheduleService = ScheduleService();
    await tester.pumpWidget(Tarang69App(scheduleService: scheduleService));
    await tester.pump();
    expect(find.byType(Tarang69App), findsOneWidget);
  });
}
