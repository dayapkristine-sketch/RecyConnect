import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/activity_log.dart';
import '../../providers/app_provider.dart';
import '../../services/biometric_service.dart';
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
  bool _isUnlocked = BiometricService.sessionChecked;
  bool _isAuthenticating = false;

  Future<void> _unlockActivityLog() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);
    final result = await BiometricService.authenticate();
    if (!mounted) return;
    setState(() {
      _isAuthenticating = false;
      _isUnlocked = result == BiometricResult.success;
    });
    if (result == BiometricResult.success) return;

    final message = switch (result) {
      BiometricResult.unavailable =>
        'Biometric authentication is not available on this device.',
      BiometricResult.notEnrolled =>
        'Enroll a fingerprint or other biometric in device settings first.',
      BiometricResult.lockedOut =>
        'Biometrics are temporarily locked. Unlock your device and try again.',
      BiometricResult.cancelled => 'Biometric authentication was cancelled.',
      BiometricResult.failed => 'Biometric authentication failed. Try again.',
      BiometricResult.success => '',
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUnlocked) return _buildLockedView(context);

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

  Widget _buildLockedView(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fingerprint,
                size: 86,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Admin activity log locked',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Use your enrolled fingerprint or other device biometric to continue.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _isAuthenticating ? null : _unlockActivityLog,
                icon: const Icon(Icons.fingerprint),
                label: Text(
                  _isAuthenticating
                      ? 'Authenticating...'
                      : 'Unlock activity log',
                ),
              ),
            ],
          ),
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
