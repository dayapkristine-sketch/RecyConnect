import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child, this.assetPath});
  final Widget child;
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          assetPath ?? 'assets/images/recyconnect_bg.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF102B1A), Color(0xFF244D31)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Container(
          color: dark
              ? Colors.black.withValues(alpha: 0.42)
              : const Color(0xFF102B1A).withValues(alpha: 0.26),
        ),
        child,
      ],
    );
  }
}
