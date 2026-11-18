import 'package:flutter/material.dart';

import '../models/recyclable_post.dart';

Color postStatusColor(PostStatus s) {
  switch (s) {
    case PostStatus.posted:
      return const Color(0xFF1565C0);
    case PostStatus.accepted:
      return const Color(0xFFB26A00);
    case PostStatus.collected:
      return const Color(0xFF2E7D32);
    case PostStatus.sold:
      return const Color(0xFF00796B);
    case PostStatus.cancelled:
      return Colors.red;
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final PostStatus status;

  @override
  Widget build(BuildContext context) {
    final c = postStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

IconData materialIconFor(String name) {
  final n = name.toLowerCase();
  if (n.contains('plastic')) return Icons.local_drink_outlined;
  if (n.contains('metal')) return Icons.hardware_outlined;
  if (n.contains('glass')) return Icons.wine_bar_outlined;
  if (n.contains('paper')) return Icons.description_outlined;
  if (n.contains('cardboard')) return Icons.inventory_2_outlined;
  if (n.contains('appliance')) return Icons.kitchen_outlined;
  if (n.contains('electronic')) return Icons.devices_other_outlined;
  return Icons.recycling;
}
