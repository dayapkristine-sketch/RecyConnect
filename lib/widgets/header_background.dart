import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Image background for the top (header) area of a dashboard.
/// Wrap your header content with it:
///   HeaderBackground(child: SafeArea(...))
class HeaderBackground extends StatelessWidget {
  const HeaderBackground({super.key, required this.child, this.radius = 32});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    // Light status-bar icons so the clock/battery stay visible on green.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/recyconnect_bg.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF14573A), Color(0xFF238B45)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF14573A).withValues(alpha: 0.88),
                      const Color(0xFF238B45).withValues(alpha: 0.68),
                    ],
                  ),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

/// A simple page header (title + optional subtitle) with the background.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return HeaderBackground(
      radius: 28,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 24),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
