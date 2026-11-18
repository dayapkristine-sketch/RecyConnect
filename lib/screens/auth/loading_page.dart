import 'package:flutter/material.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key, this.message, this.icon});

  final String? message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/green_envi.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                Container(color: const Color(0xFF102B1A)),
          ),
          Container(color: Colors.black.withValues(alpha: 0.58)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    color: Color(0xCC102B1A),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon ?? Icons.recycling_rounded,
                    size: 72,
                    color: Color(0xFF4ADE80),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'RecyConnect',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Connecting communities for a greener tomorrow',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 28),
                const SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF4ADE80),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  message ?? 'Preparing your experience...',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
