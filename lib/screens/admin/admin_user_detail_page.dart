import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../widgets/header_background.dart';
import 'admin_widgets.dart';

class AdminUserDetailPage extends StatelessWidget {
  const AdminUserDetailPage({super.key, required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const HeaderAppBar(title: Text('Account details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AdminColors.mint,
                    child: Icon(
                      roleIcon(user.role),
                      size: 36,
                      color: AdminColors.deep,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.fullName,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(user.role.label),
                  const SizedBox(height: 10),
                  StatusChip(user.status),
                ],
              ),
            ),
          ),

          const SectionHeader('Account information'),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _row(Icons.person_outline, 'Username', '@${user.username}'),
                  _row(Icons.email_outlined, 'Email', user.email),
                  _row(
                    Icons.verified_user_outlined,
                    'ID type',
                    user.idType.label,
                  ),
                  _row(
                    Icons.security_outlined,
                    'Security status',
                    user.isLocked
                        ? 'Temporarily locked until ${user.lockedUntil}'
                        : user.failedLoginAttempts > 0
                        ? '${user.failedLoginAttempts} failed login attempt(s)'
                        : 'No active flags',
                  ),
                  _row(Icons.phone_outlined, 'Contact', user.phone),
                  _row(Icons.location_on_outlined, 'Address', user.address),
                  _row(
                    Icons.event_outlined,
                    'Registered',
                    formatDateTime(user.createdAt),
                  ),
                ],
              ),
            ),
          ),

          if (user.status == AccountStatus.rejected &&
              user.rejectionReason != null) ...[
            const SizedBox(height: 10),
            Card(
              color: Colors.red.withValues(alpha: 0.10),
              child: ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.red),
                title: const Text('Rejection reason'),
                subtitle: Text(user.rejectionReason!),
              ),
            ),
          ],

          const SectionHeader('Submitted documents'),
          DocumentTile(label: 'Valid ID', document: user.idDocument),
          DocumentTile(
            label: 'Valid ID — back side',
            document: user.idBackDocument,
          ),
          if (user.requiresPermit)
            DocumentTile(
              label: 'Business Permit',
              document: user.permitDocument,
            ),

          const SectionHeader('Role assignment'),
          DropdownButtonFormField<UserRole>(
            key: ValueKey(user.role),
            initialValue: user.role == UserRole.admin
                ? UserRole.household
                : user.role,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.swap_horiz),
              labelText: 'Account type',
            ),
            items: const [
              DropdownMenuItem(
                value: UserRole.household,
                child: Text('Household / Resident'),
              ),
              DropdownMenuItem(
                value: UserRole.collector,
                child: Text('Scrap Collector'),
              ),
              DropdownMenuItem(
                value: UserRole.junkShop,
                child: Text('Junk Shop Owner'),
              ),
            ],
            onChanged: (v) async {
              if (v == null || v == user.role) return;
              final ok = await confirmDialog(
                context,
                title: 'Change role?',
                message: '${user.fullName} will become a ${v.label}.',
                confirmLabel: 'Change',
              );
              if (ok) await app.changeRole(user, v);
            },
          ),

          const SectionHeader('Actions'),
          if (user.isLocked || user.failedLoginAttempts > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton.icon(
                onPressed: () => app.clearSecurityLock(user),
                icon: const Icon(Icons.lock_open_outlined),
                label: const Text('Clear temporary security lock'),
              ),
            ),
          if (!user.hasRequiredDocuments &&
              (user.status == AccountStatus.pending ||
                  user.status == AccountStatus.rejected))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Required documents are missing, so this account cannot be approved.',
                style: TextStyle(color: scheme.error),
              ),
            ),
          _actions(context, app),
          const SizedBox(height: 8),
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              final ok = await confirmDialog(
                context,
                title: 'Delete account?',
                message:
                    'This permanently removes ${user.fullName} and their documents.',
                confirmLabel: 'Delete',
                danger: true,
              );
              if (!ok) return;
              await app.deleteUser(user);
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete account'),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return ListTile(
      dense: true,
      leading: Icon(icon),
      title: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      subtitle: Text(
        value.isEmpty ? '—' : value,
        style: const TextStyle(fontSize: 15),
      ),
    );
  }

  Widget _actions(BuildContext context, AppProvider app) {
    final canApprove = user.hasRequiredDocuments;

    Future<void> doReject() async {
      final reason = await showDialog<String>(
        context: context,
        builder: (_) => const _ReasonDialog(),
      );
      if (reason == null) return;
      await app.reject(user, reason: reason);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.fullName} was rejected.')),
        );
      }
    }

    Future<void> doApprove() async {
      await app.approve(user);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.fullName} was approved.')),
        );
      }
    }

    switch (user.status) {
      case AccountStatus.pending:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: doReject,
                icon: const Icon(Icons.close),
                label: const Text('Reject'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: canApprove ? doApprove : null,
                icon: const Icon(Icons.check),
                label: const Text('Approve'),
              ),
            ),
          ],
        );
      case AccountStatus.approved:
        return OutlinedButton.icon(
          onPressed: () async {
            final ok = await confirmDialog(
              context,
              title: 'Suspend account?',
              message: '${user.fullName} will no longer be able to log in.',
              confirmLabel: 'Suspend',
              danger: true,
            );
            if (ok) await app.suspend(user);
          },
          icon: const Icon(Icons.block),
          label: const Text('Suspend account'),
        );
      case AccountStatus.suspended:
        return FilledButton.icon(
          onPressed: () => app.reactivate(user),
          icon: const Icon(Icons.restart_alt),
          label: const Text('Reactivate account'),
        );
      case AccountStatus.rejected:
        return FilledButton.icon(
          onPressed: canApprove ? doApprove : null,
          icon: const Icon(Icons.check),
          label: const Text('Approve instead'),
        );
    }
  }
}

class _ReasonDialog extends StatefulWidget {
  const _ReasonDialog();

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject registration'),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Reason (e.g. ID is blurry, permit expired)',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
