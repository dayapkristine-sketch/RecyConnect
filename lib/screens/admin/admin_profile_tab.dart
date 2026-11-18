import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../auth/logout_loading_page.dart';
import '../shared/edit_profile_page.dart';
import 'admin_settings_page.dart';
import 'admin_widgets.dart';

class AdminProfileTab extends StatelessWidget {
  const AdminProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final user = app.currentUser;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Profile',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: AdminColors.mint,
                    child: Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 32,
                      color: AdminColors.deep,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'System Administrator',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '@${user?.username ?? 'admin'} • IT Administrator',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.tune_rounded),
                  title: const Text('System settings'),
                  subtitle: const Text(
                    'Material categories, status labels, cancellation reasons',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminSettingsPage(),
                    ),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Dark mode'),
                  value: app.isDarkMode,
                  onChanged: (_) => app.toggleTheme(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.edit_outlined, color: AdminColors.deep),
              title: const Text('Edit administrator profile'),
              subtitle: const Text('Update your name and contact details'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              ),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () async {
              final ok = await confirmDialog(
                context,
                title: 'Log out?',
                message: 'You will return to the login screen.',
                confirmLabel: 'Log out',
              );
              if (!ok || !context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LogoutLoadingPage()),
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}
