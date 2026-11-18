import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Rounded green icon button with a label (like "Our Services" in the design).
class ServiceTile extends StatelessWidget {
  const ServiceTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: SizedBox(
        width: 74,
        child: Column(
          children: [
            Badge(
              isLabelVisible: badge > 0,
              label: Text('$badge'),
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.green, AppTheme.deepGreen],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
