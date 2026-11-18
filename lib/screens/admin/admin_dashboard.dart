import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import 'admin_activity_tab.dart';
import 'admin_home_tab.dart';
import 'admin_profile_tab.dart';
import 'admin_user_list.dart';
import 'admin_widgets.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pending = context.watch<AppProvider>().pendingCount;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          AdminHomeTab(onNavigate: _go),
          const AdminUserList(title: 'Users'),
          const AdminUserList(title: 'Approvals', pendingOnly: true),
          const AdminActivityTab(),
          const AdminProfileTab(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Badge(
        isLabelVisible: pending > 0,
        label: Text('$pending'),
        child: FloatingActionButton(
          backgroundColor: AdminColors.deep,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          onPressed: () => _go(2),
          child: const Icon(Icons.fact_check_outlined),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 68,
        padding: EdgeInsets.zero,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          children: [
            _nav(0, Icons.home_rounded, 'Home'),
            _nav(1, Icons.people_alt_rounded, 'Users'),
            const SizedBox(width: 72), // space for the center button
            _nav(3, Icons.history_rounded, 'Activity'),
            _nav(4, Icons.person_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _nav(int i, IconData icon, String label) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _index == i;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Expanded(
      child: InkWell(
        onTap: () => _go(i),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
