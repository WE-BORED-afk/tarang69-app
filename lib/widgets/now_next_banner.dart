import 'package:flutter/material.dart';

class NowNextBanner extends StatelessWidget {
  final String currentSubject;
  final String room;
  final String timeRange;
  final String teacher;
  final String nextSubject;
  final int progressPercent;
  final int remainingSeconds;
  final bool isWeekend;
  final bool isBeforeSchool;
  final bool isAfterSchool;
  final String? code;

  const NowNextBanner({
    super.key,
    required this.currentSubject,
    required this.room,
    required this.timeRange,
    required this.teacher,
    required this.nextSubject,
    required this.progressPercent,
    this.remainingSeconds = 0,
    this.isWeekend = false,
    this.isBeforeSchool = false,
    this.isAfterSchool = false,
    this.code,
  });

  String _formatCountdown(int totalSecs) {
    if (totalSecs <= 0) return '00:00';
    final h = totalSecs ~/ 3600;
    final m = (totalSecs % 3600) ~/ 60;
    final s = totalSecs % 60;
    final mStr = m.toString().padLeft(2, '0');
    final sStr = s.toString().padLeft(2, '0');
    if (h > 0) {
      final hStr = h.toString().padLeft(2, '0');
      return '$hStr:$mStr:$sStr';
    }
    return '$mStr:$sStr';
  }

  @override
  Widget build(BuildContext context) {
    // 1. Weekend Theme
    if (isWeekend) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF9333EA), Color(0xFFDB2777)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Text('🎉 ', style: TextStyle(fontSize: 12)),
                      Text(
                        'วันหยุดสุดสัปดาห์',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Holiday Rest',
                    style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              currentSubject,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'พักผ่อนเติมพลังให้เต็มที่ หรือเลือกแท็บวันจันทร์-ศุกร์เพื่อดูตารางเรียนล่วงหน้าได้เลย!',
              style: TextStyle(color: Color(0xFFF3E8FF), fontSize: 12, height: 1.4),
            ),
          ],
        ),
      );
    }

    // 2. Regular Weekday (Live Period / Before / After)
    final bool hasCountdown = remainingSeconds > 0;
    final countdownText = _formatCountdown(remainingSeconds);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAfterSchool
              ? const [Color(0xFF312E81), Color(0xFF4338CA), Color(0xFF4F46E5)]
              : isBeforeSchool
                  ? const [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFF7C3AED)]
                  : const [Color(0xFF4338CA), Color(0xFF4F46E5), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isAfterSchool
                          ? Icons.stars_rounded
                          : isBeforeSchool
                              ? Icons.wb_sunny_rounded
                              : Icons.radio_button_checked,
                      size: 14,
                      color: isAfterSchool ? Colors.amberAccent : Colors.greenAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isAfterSchool
                          ? 'เลิกเรียนแล้ว'
                          : isBeforeSchool
                              ? 'เตรียมตัวเข้าเรียน'
                              : 'คาบเรียนปัจจุบัน',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (hasCountdown)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 13, color: Color(0xFFFDE047)),
                      const SizedBox(width: 4),
                      Text(
                        'เหลือ $countdownText',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  timeRange,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  code != null && code!.isNotEmpty && code != '-'
                      ? '$currentSubject ($code)'
                      : currentSubject,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '📍 $room',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              if (teacher != '-') ...[
                const SizedBox(width: 8),
                Text(
                  '👨‍🏫 $teacher',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
              const Spacer(),
              if (hasCountdown)
                Text(
                  timeRange,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressPercent / 100,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    nextSubject,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
