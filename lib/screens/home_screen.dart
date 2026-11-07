import 'package:flutter/material.dart';
import '../models/schedule_model.dart';
import '../services/schedule_service.dart';
import '../widgets/now_next_banner.dart';
import '../widgets/timeline_card.dart';
import '../widgets/plan_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  final ScheduleService scheduleService;

  const HomeScreen({super.key, required this.scheduleService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedDay = 'จันทร์';
  bool isTableView = false;
  FullScheduleData? data;
  bool isLoading = true;
  bool showSimulator = true;

  @override
  void initState() {
    super.initState();
    selectedDay = widget.scheduleService.getTodayThaiKey();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final result = await widget.scheduleService.loadSchedule();
      if (mounted) {
        setState(() {
          data = result;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('HomeScreen _loadData error: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _openPlanSelector() {
    if (data == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PlanBottomSheet(
        plans: data!.bellPlans,
        currentPlanId: widget.scheduleService.selectedPlanId,
        onPlanSelected: (newPlanId) {
          setState(() {
            widget.scheduleService.setPlan(newPlanId);
          });
        },
      ),
    );
  }

  void _setSimTime(int? h, int? m, String label) {
    setState(() {
      widget.scheduleService.setSimulatedTime(h, m, label);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || data == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
        ),
      );
    }

    final daySchedule = data!.schedule[selectedDay];
    final plan = data!.bellPlans[widget.scheduleService.selectedPlanId];
    final isToday = selectedDay == widget.scheduleService.getTodayThaiKey();
    final status = widget.scheduleService.getCurrentStatus(selectedDay);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'TARANG69',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'ม.6/9',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                  ),
                ),
              ],
            ),
            const Text(
              'ตารางเรียนอัจฉริยะ • Daily Timeline',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              showSimulator ? Icons.timer_rounded : Icons.timer_outlined,
              color: showSimulator ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
            ),
            tooltip: 'เปิด/ปิด แถบจำลองเวลา',
            onPressed: () {
              setState(() {
                showSimulator = !showSimulator;
              });
            },
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Text('📊', style: TextStyle(fontSize: 14)),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => isTableView = true),
                  color: isTableView ? const Color(0xFF4F46E5) : Colors.grey,
                ),
                IconButton(
                  icon: const Text('📱', style: TextStyle(fontSize: 14)),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => isTableView = false),
                  color: !isTableView ? const Color(0xFF4F46E5) : Colors.grey,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF1E293B)),
            onPressed: _openPlanSelector,
            tooltip: 'เลือกแผนตารางเรียน',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await widget.scheduleService.fetchRemoteUpdate();
          setState(() {
            data = widget.scheduleService.scheduleData;
          });
        },
        child: isTableView
            ? _buildWeeklyTableView()
            : _buildDailyTimelineView(daySchedule, plan, isToday, status),
      ),
    );
  }

  Widget _buildDailyTimelineView(
      DaySchedule? daySchedule, BellPlan? plan, bool isToday, CurrentPeriodStatus status) {
    if (daySchedule == null) {
      return const Center(child: Text('ไม่พบข้อมูลตารางเรียน'));
    }

    final simLabel = widget.scheduleService.simulatedLabel ?? 'ตามเวลาจริง';
    final isSimulated = widget.scheduleService.simulatedHour != null;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        // Day tabs
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: data!.dayOrder.map((day) {
              final isSelected = day == selectedDay;
              final isThisDayToday = day == widget.scheduleService.getTodayThaiKey();

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => selectedDay = day),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border: isThisDayToday && !isSelected
                          ? Border.all(color: const Color(0xFF4F46E5), width: 1.5)
                          : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          day,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.grey.shade800,
                          ),
                        ),
                        if (isThisDayToday)
                          Text(
                            'วันนี้',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white70 : const Color(0xFF4F46E5),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Time Simulator Bar
        if (showSimulator)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSimulated ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                width: isSimulated ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Text('⏱️ ', style: TextStyle(fontSize: 14)),
                        Text(
                          'จำลองเวลาเรียน:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSimulated ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        simLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSimulated ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSimChip('⏰ เวลาจริง', null, null, !isSimulated),
                      _buildSimChip('คาบ 1 (08:45)', 8, 45, simLabel.contains('08:45')),
                      _buildSimChip('คาบ 2 (09:30)', 9, 30, simLabel.contains('09:30')),
                      _buildSimChip('พักเบรก (10:10)', 10, 10, simLabel.contains('10:10')),
                      _buildSimChip('คาบ 4 (11:30)', 11, 30, simLabel.contains('11:30')),
                      _buildSimChip('พักเที่ยง (12:20)', 12, 20, simLabel.contains('12:20')),
                      _buildSimChip('คาบ 6 (14:00)', 14, 0, simLabel.contains('14:00')),
                      _buildSimChip('เลิกเรียน (16:30)', 16, 30, simLabel.contains('16:30')),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Live/Simulated Status Banner
        NowNextBanner(
          currentSubject: status.subjectName,
          room: status.room,
          timeRange: status.timeStr,
          teacher: status.teacher,
          nextSubject: status.nextSubject,
          progressPercent: status.progressPercent,
        ),

        // Plan Badge Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'วัน$selectedDay • Timeline',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
              InkWell(
                onTap: _openPlanSelector,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.indigo.shade200),
                  ),
                  child: Text(
                    plan?.shortName ?? 'แผน 1',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo.shade700),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Timeline items
        ...daySchedule.items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          String timeStr = '';
          if (plan != null) {
            final periodKey = (idx + 1).toString();
            if (plan.periods.containsKey(periodKey)) {
              timeStr = plan.periods[periodKey]!.timeStr;
            }
          }

          final isActive = idx == status.activePeriodIndex;

          return TimelineCard(
            item: item,
            timeStr: timeStr,
            isActive: isActive,
          );
        }),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSimChip(String label, int? h, int? m, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => _setSimTime(h, m, label),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyTableView() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
          columns: const [
            DataColumn(label: Text('วัน', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('คาบ 1')),
            DataColumn(label: Text('คาบ 2')),
            DataColumn(label: Text('คาบ 3')),
            DataColumn(label: Text('คาบ 4')),
            DataColumn(label: Text('คาบ 5')),
            DataColumn(label: Text('คาบ 6')),
            DataColumn(label: Text('คาบ 7')),
            DataColumn(label: Text('คาบ 8')),
          ],
          rows: data!.dayOrder.map((day) {
            final daySched = data!.schedule[day];
            final subjects = daySched?.items.where((it) => it.type != 'break').toList() ?? [];

            return DataRow(
              cells: [
                DataCell(Text(day, style: const TextStyle(fontWeight: FontWeight.bold))),
                ...List.generate(8, (i) {
                  if (i < subjects.length) {
                    final sub = subjects[i];
                    return DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sub.name ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                          if (sub.room != null)
                            Text(sub.room!, style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
                        ],
                      ),
                    );
                  }
                  return const DataCell(Text('-'));
                }),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
