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
    if (item.type == 'break') {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.amber.shade50.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.shade200.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Text(item.icon ?? '🧃', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.title ?? 'พัก',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade900,
                ),
              ),
            ),
            Text(
              timeStr.isNotEmpty ? timeStr : (item.time ?? ''),
              style: TextStyle(fontSize: 12, color: Colors.amber.shade800),
            ),
          ],
        ),
      );
    }

    final isSpecialRoom = item.room != null && (item.room!.contains('Lab') || item.room!.contains('คอม'));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isActive ? Colors.indigo.shade50.withOpacity(0.8) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive ? Colors.indigo.shade400 : Colors.grey.shade200,
          width: isActive ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive ? Colors.indigo.withOpacity(0.08) : Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? Colors.indigo.shade600 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              item.period?.replaceAll(RegExp(r'\(.*\)'), '').trim() ?? 'คาบ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : Colors.grey.shade700,
              ),
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
                  children: [
                    Expanded(
                      child: Text(
                        item.name ?? '',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.indigo.shade900 : Colors.grey.shade900,
                        ),
                      ),
                    ),
                    Text(
                      timeStr.isNotEmpty ? timeStr : (item.time ?? ''),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (item.room != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSpecialRoom ? Colors.pink.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSpecialRoom ? Colors.pink.shade200 : Colors.grey.shade200,
                          ),
                        ),
                        child: Text(
                          item.room!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSpecialRoom ? Colors.pink.shade700 : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    if (item.teacher != null && item.teacher != '-')
                      Text(
                        item.teacher!,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
