import 'package:flutter/material.dart';
import '../models/schedule_model.dart';

class TimelineCard extends StatelessWidget {
  final PeriodItem item;
  final String timeStr;
  final bool isActive;
  final bool isPast;

  const TimelineCard({
    super.key,
    required this.item,
    required this.timeStr,
    this.isActive = false,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Break / Lunch Card
    if (item.type == 'break') {
      final isLunch = item.title?.contains('อาหาร') == true || item.title?.contains('กลางวัน') == true;
      final bgColor = isLunch ? const Color(0xFFFFF1F2) : const Color(0xFFFAF5FF);
      final borderColor = isLunch ? const Color(0xFFFECDD3) : const Color(0xFFE9D5FF);
      final textColor = isLunch ? const Color(0xFFBE123C) : const Color(0xFF7E22CE);
      final icon = isLunch ? '🍱' : '☕';

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.title ?? 'พักเบรก',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                timeStr.isNotEmpty ? timeStr : (item.time ?? ''),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
              ),
            ),
          ],
        ),
      );
    }

    // 2. Regular Period Card
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFF5F3FF) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
          width: isActive ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? const Color(0xFF4F46E5).withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: isActive ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period number badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF4F46E5) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  item.period?.replaceAll(RegExp(r'\(.*\)'), '').trim() ?? 'คาบ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : const Color(0xFF475569),
                  ),
                ),
                if (isActive)
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text('🟢 สด', style: TextStyle(fontSize: 9, color: Colors.greenAccent)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          text: item.name ?? '',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isActive ? const Color(0xFF312E81) : const Color(0xFF0F172A),
                            fontFamily: 'sans-serif',
                          ),
                          children: [
                            if (item.code != null && item.code!.isNotEmpty && item.code != '-')
                              TextSpan(
                                text: ' (${item.code})',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isActive ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      timeStr.isNotEmpty ? timeStr : (item.time ?? ''),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isActive ? const Color(0xFF4338CA) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (item.teacher != null && item.teacher != '-') ...[
                  const SizedBox(height: 6),
                  Text(
                    '👨‍🏫 ${item.teacher!}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
