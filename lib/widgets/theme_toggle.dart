import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({
    super.key,
    this.iconOnly = false,
    this.color = Colors.white,
  });
  final bool iconOnly;

  /// White by default because it is used on dark / green backgrounds.
  /// Pass a different color if you ever place it on a light surface.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final tooltip = app.isDarkMode
        ? 'Switch to light mode'
        : 'Switch to dark mode';
    final icon = Icon(app.isDarkMode ? Icons.light_mode : Icons.dark_mode);

    return Tooltip(
      message: tooltip,
      child: iconOnly
          ? IconButton(onPressed: app.toggleTheme, icon: icon, color: color)
          : TextButton.icon(
              onPressed: app.toggleTheme,
              icon: icon,
              label: Text(app.isDarkMode ? 'Light mode' : 'Dark mode'),
              style: TextButton.styleFrom(foregroundColor: color),
            ),
    );
  }
}
