import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/activity_log.dart';
import '../../providers/app_provider.dart';
import 'admin_widgets.dart';

class AdminActivityTab extends StatefulWidget {
  const AdminActivityTab({super.key});

  @override
  State<AdminActivityTab> createState() => _AdminActivityTabState();
}

class _AdminActivityTabState extends State<AdminActivityTab> {
  static const _groups = [
    'All',
    'Registrations',
    'Reports & ratings',
    'Admin actions',
    'Logins',
  ];
  String _group = 'All';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final logs = app.logs
        .where((l) => _group == 'All' || l.type.group == _group)
        .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity log',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              'Registrations, logins, reports and admin actions.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final g in _groups)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(g),
                        selected: g == _group,
                        onSelected: (_) => setState(() => _group = g),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: logs.isEmpty
                  ? const Center(child: Text('No activity recorded yet.'))
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: logs.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final l = logs[i];
                        final (icon, color) = _style(l.type);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.15),
                            child: Icon(icon, color: color, size: 20),
                          ),
                          title: Text(l.message),
                          subtitle: Text(formatDateTime(l.time)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _style(LogType t) {
    switch (t) {
      case LogType.registration:
        return (Icons.person_add_alt_1, Colors.blue);
      case LogType.approval:
        return (Icons.check_circle_outline, const Color(0xFF2E9E57));
      case LogType.rejection:
        return (Icons.cancel_outlined, Colors.red);
      case LogType.suspension:
        return (Icons.block, Colors.blueGrey);
      case LogType.reactivation:
        return (Icons.restart_alt, const Color(0xFF2E9E57));
      case LogType.roleChange:
        return (Icons.swap_horiz, Colors.purple);
      case LogType.deletion:
        return (Icons.delete_outline, Colors.red);
      case LogType.login:
        return (Icons.login, Colors.teal);
      case LogType.failedLogin:
        return (Icons.warning_amber_rounded, Colors.orange);
      case LogType.settings:
        return (Icons.tune, Colors.indigo);
      case LogType.rating:
        return (Icons.star_rounded, const Color(0xFFF5A623));
      case LogType.report:
        return (Icons.flag_rounded, Colors.deepOrange);
      case LogType.reportReview:
        return (Icons.gavel, Colors.indigo);
    }
  }
}
