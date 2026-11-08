import 'dart:async';
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
  bool showSimulator = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    selectedDay = widget.scheduleService.getDefaultViewDayKey();
    _loadData();

    // Live countdown timer ticking every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
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

  Future<void> _refreshFromGitHub() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('กำลังซิงค์ข้อมูลล่าสุดจาก GitHub...'),
        duration: Duration(seconds: 1),
      ),
    );
    final updated = await widget.scheduleService.fetchRemoteUpdate();
    if (mounted) {
      setState(() {
        if (widget.scheduleService.scheduleData != null) {
          data = widget.scheduleService.scheduleData;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(updated ? 'อัปเดตข้อมูลตารางเรียนสำเร็จ! ✨' : 'ใช้ข้อมูลล่าสุดในเครื่องเรียบร้อย'),
          backgroundColor: updated ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
    final actualTodayKey = widget.scheduleService.getActualTodayThaiKey();
    final isToday = selectedDay == actualTodayKey;
    final status = widget.scheduleService.getCurrentStatus(selectedDay);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFDFBFB), Color(0xFFF3E7E9), Color(0xFFE3EEFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. Web-Matching Header Bar
              _buildHeaderBar(),

              // 2. Main Content (Daily Timeline or Weekly Table)
              Expanded(
                child: isTableView
                    ? _buildWeeklyTableView()
                    : _buildDailyTimelineView(daySchedule, plan, isToday, status),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo & Title
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/icons/app_icon.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF4338CA), Color(0xFF7E22CE), Color(0xFFDB2777)],
                ).createShader(bounds),
                child: const Text(
                  'TARANG69',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          // Right Actions (View switch + Refresh + Simulator) - NO duplicate plan selector here!
          Row(
            children: [
              // Simulator toggle button
              IconButton(
                icon: Icon(
                  showSimulator ? Icons.timer_rounded : Icons.timer_outlined,
                  size: 20,
                  color: showSimulator ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                ),
                tooltip: 'จำลองเวลา',
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  setState(() {
                    showSimulator = !showSimulator;
                  });
                },
              ),
              // View switch pill (📊 ตารางรวม / 📱 รายวัน)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => setState(() => isTableView = false),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: !isTableView ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: !isTableView
                              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2)]
                              : null,
                        ),
                        child: Row(
                          children: [
                            const Text('📱', style: TextStyle(fontSize: 11)),
                            const SizedBox(width: 3),
                            Text(
                              'รายวัน',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: !isTableView ? const Color(0xFF4338CA) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => isTableView = true),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isTableView ? const Color(0xFF4F46E5) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: isTableView
                              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2)]
                              : null,
                        ),
                        child: Row(
                          children: [
                            const Text('📊', style: TextStyle(fontSize: 11)),
                            const SizedBox(width: 3),
                            Text(
                              'ตารางรวม',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isTableView ? Colors.white : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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
    final actualTodayKey = widget.scheduleService.getActualTodayThaiKey();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        // 1. Day Selection Tabs (Pastel Colors matching DESIGN.md)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: data!.dayOrder.map((dayKey) {
              final isSelected = selectedDay == dayKey;
              final isActualToday = dayKey == actualTodayKey;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: _buildDayTab(dayKey, isSelected, isActualToday),
                ),
              );
            }).toList(),
          ),
        ),

        // 2. Time Simulator Panel (if toggled)
        if (showSimulator)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('⚡ จำลองเวลา: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text(
                          simLabel,
                          style: TextStyle(
                            color: isSimulated ? const Color(0xFFB45309) : const Color(0xFF047857),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (isSimulated)
                      InkWell(
                        onTap: () => _setSimTime(null, null, 'ตามเวลาจริง'),
                        child: const Text('รีเซ็ตเวลาจริง', style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSimChip('เวลาจริง', null, null, !isSimulated),
                      _buildSimChip('คาบ 1 (08:30)', 8, 30, simLabel == 'คาบ 1 (08:30)'),
                      _buildSimChip('พักเบรก (10:05)', 10, 5, simLabel == 'พักเบรก (10:05)'),
                      _buildSimChip('พักเที่ยง (12:00)', 12, 0, simLabel == 'พักเที่ยง (12:00)'),
                      _buildSimChip('บ่าย (13:30)', 13, 30, simLabel == 'บ่าย (13:30)'),
                      _buildSimChip('เลิกเรียน (16:30)', 16, 30, simLabel == 'เลิกเรียน (16:30)'),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // 3. Live Countdown Status Banner
        NowNextBanner(
          currentSubject: status.subjectName,
          room: status.room,
          timeRange: status.timeStr,
          teacher: status.teacher,
          nextSubject: status.nextSubject,
          progressPercent: status.progressPercent,
          remainingSeconds: status.remainingSeconds,
          isWeekend: status.isWeekend,
          isBeforeSchool: status.isBeforeSchool,
          isAfterSchool: status.isAfterSchool,
          code: status.code,
        ),

        // 4. Timeline Header with Dedicated Plan Selector Chip
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'วัน$selectedDay • Timeline',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                  ),
                  if (isToday) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: const Text(
                        'วันนี้',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                      ),
                    ),
                  ],
                ],
              ),

              // Dedicated Plan Selector Button (ONLY here, removed from top-right)
              InkWell(
                onTap: _openPlanSelector,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications_active_outlined, size: 13, color: Color(0xFF4F46E5)),
                      const SizedBox(width: 4),
                      Text(
                        plan?.shortName ?? 'แผน 1 ปกติ',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4338CA)),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_drop_down_rounded, size: 16, color: Color(0xFF4338CA)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 5. Timeline Cards List
        ...daySchedule.items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          String timeStr = '';
          if (plan != null) {
            timeStr = widget.scheduleService.getItemTimeRange(item, plan).timeStr;
          }

          final isActive = isToday && idx == status.activePeriodIndex;

          return TimelineCard(
            item: item,
            timeStr: timeStr,
            isActive: isActive,
          );
        }),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildDayTab(String dayKey, bool isSelected, bool isActualToday) {
    Color activeBg;
    Color activeBorder;
    Color activeText;
    String enSub;

    switch (dayKey) {
      case 'จันทร์':
        activeBg = const Color(0xFFFEF08A);
        activeBorder = const Color(0xFFFDE047);
        activeText = const Color(0xFF854D0E);
        enSub = 'Mon';
        break;
      case 'อังคาร':
        activeBg = const Color(0xFFFBCFE8);
        activeBorder = const Color(0xFFF9A8D4);
        activeText = const Color(0xFF9D174D);
        enSub = 'Tue';
        break;
      case 'พุธ':
        activeBg = const Color(0xFFBBF7D0);
        activeBorder = const Color(0xFF86EFAC);
        activeText = const Color(0xFF166534);
        enSub = 'Wed';
        break;
      case 'พฤหัสบดี':
        activeBg = const Color(0xFFFED7AA);
        activeBorder = const Color(0xFFFDBA74);
        activeText = const Color(0xFF9A3412);
        enSub = 'Thu';
        break;
      case 'ศุกร์':
        activeBg = const Color(0xFFBAE6FD);
        activeBorder = const Color(0xFF7DD3FC);
        activeText = const Color(0xFF075985);
        enSub = 'Fri';
        break;
      default:
        activeBg = const Color(0xFFEEF2FF);
        activeBorder = const Color(0xFFC7D2FE);
        activeText = const Color(0xFF4338CA);
        enSub = '';
    }

    return InkWell(
      onTap: () {
        setState(() {
          selectedDay = dayKey;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeBorder : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeBorder.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              dayKey == 'พฤหัสบดี' ? 'พฤหัส' : dayKey,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? activeText : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              enSub,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeText.withValues(alpha: 0.8) : const Color(0xFF94A3B8),
              ),
            ),
            if (isActualToday) ...[
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
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
            color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFEEF2FF)),
              columns: const [
                DataColumn(label: Text('วัน', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF312E81)))),
                DataColumn(label: Text('คาบ 1', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('คาบ 2', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('คาบ 3', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('คาบ 4', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('คาบ 5', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('คาบ 6', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('คาบ 7', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('คาบ 8', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: data!.dayOrder.map((day) {
                final daySched = data!.schedule[day];
                final subjects = daySched?.items.where((it) => it.type != 'break').toList() ?? [];

                return DataRow(
                  cells: [
                    DataCell(Text(day, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155)))),
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
                                Text(sub.room!, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
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
        ),
      ),
    );
  }
}
