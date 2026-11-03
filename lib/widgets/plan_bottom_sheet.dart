import 'package:flutter/material.dart';
import '../models/schedule_model.dart';

class PlanBottomSheet extends StatelessWidget {
  final Map<String, BellPlan> plans;
  final String currentPlanId;
  final Function(String) onPlanSelected;

  const PlanBottomSheet({
    super.key,
    required this.plans,
    required this.currentPlanId,
    required this.onPlanSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'เลือกแผนตารางเรียน (Bell Plans)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'เลือกแผนเวลาเรียนให้ตรงกับกิจกรรมของโรงเรียนในแต่ละวัน',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ...plans.values.map((plan) {
            final isSelected = plan.id == currentPlanId;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.indigo.shade50 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? Colors.indigo.shade500 : Colors.grey.shade200,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: ListTile(
                title: Text(
                  plan.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.indigo.shade900 : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  plan.desc,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded, color: Colors.indigo)
                    : null,
                onTap: () {
                  onPlanSelected(plan.id);
                  Navigator.pop(context);
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
