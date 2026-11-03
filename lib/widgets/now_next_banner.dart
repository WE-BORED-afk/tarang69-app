import 'package:flutter/material.dart';

class NowNextBanner extends StatelessWidget {
  final String currentSubject;
  final String room;
  final String timeRange;
  final String teacher;
  final String nextSubject;
  final int progressPercent;

  const NowNextBanner({
    super.key,
    required this.currentSubject,
    required this.room,
    required this.timeRange,
    required this.teacher,
    required this.nextSubject,
    required this.progressPercent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
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
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.radio_button_checked, size: 14, color: Colors.greenAccent),
                    SizedBox(width: 6),
                    Text(
                      'คาบเรียนปัจจุบัน',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Text(
                timeRange,
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            currentSubject,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
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
