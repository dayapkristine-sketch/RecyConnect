import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../widgets/header_background.dart';
import '../../widgets/service_tile.dart';
import '../../widgets/theme_toggle.dart';
import 'admin_reports_page.dart';
import 'admin_settings_page.dart';
import 'admin_user_detail_page.dart';
import 'admin_widgets.dart';

class AdminHomeTab extends StatelessWidget {
  const AdminHomeTab({super.key, required this.onNavigate});

  /// 1 = Users, 2 = Approvals, 3 = Activity, 4 = Profile
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final pendingUsers = app.users
        .where((u) => u.status == AccountStatus.pending)
        .toList()
        .reversed
        .take(3)
        .toList();
    final logs = app.logs.take(4).toList();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _header(context, app),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader('Overview'),
              Row(
                children: [
                  _stat(
                    context,
                    'Total users',
                    app.users.length,
                    Icons.people_alt_outlined,
                    AdminColors.mid,
                  ),
                  const SizedBox(width: 12),
                  _stat(
                    context,
                    'Pending',
                    app.countStatus(AccountStatus.pending),
                    Icons.pending_actions,
                    Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _stat(
                    context,
                    'Suspicious',
                    app.suspiciousUsers.length,
                    Icons.security_outlined,
                    Colors.redAccent,
                  ),
                  const SizedBox(width: 12),
                  _stat(
                    context,
                    'Inactive 30d+',
                    app.inactiveUsers.length,
                    Icons.person_off_outlined,
                    Colors.amber.shade800,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _stat(
                    context,
                    'Approved',
                    app.countStatus(AccountStatus.approved),
                    Icons.verified_outlined,
                    const Color(0xFF2E9E57),
                  ),
                  const SizedBox(width: 12),
                  _stat(
                    context,
                    'Suspended',
                    app.countStatus(AccountStatus.suspended),
                    Icons.block,
                    Colors.blueGrey,
                  ),
                ],
              ),
              const SectionHeader('Admin Services'),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 14,
                children: [
                  ServiceTile(
                    icon: Icons.fact_check_outlined,
                    label: 'Approvals',
                    badge: app.pendingCount,
                    onTap: () => onNavigate(2),
                  ),
                  ServiceTile(
                    icon: Icons.people_alt_outlined,
                    label: 'Users',
                    onTap: () => onNavigate(1),
                  ),
                  ServiceTile(
                    icon: Icons.flag_outlined,
                    label: 'Reports',
                    badge: app.openReportCount,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminReportsPage(),
                      ),
                    ),
                  ),
                  ServiceTile(
                    icon: Icons.history_rounded,
                    label: 'Activity',
                    onTap: () => onNavigate(3),
                  ),
                  ServiceTile(
                    icon: Icons.security_outlined,
                    label: 'Security',
                    badge: app.suspiciousUsers.length,
                    onTap: () => onNavigate(1),
                  ),
                  ServiceTile(
                    icon: Icons.tune_rounded,
                    label: 'Settings',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminSettingsPage(),
                      ),
                    ),
                  ),
                ],
              ),
              const SectionHeader('Accounts by role'),
              SizedBox(
                height: 128,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _roleCard(app, UserRole.household, const Color(0xFF2E7D32)),
                    _roleCard(app, UserRole.collector, const Color(0xFF00796B)),
                    _roleCard(app, UserRole.junkShop, const Color(0xFF455A64)),
                  ],
                ),
              ),
              SectionHeader(
                'Needs review',
                actionLabel: 'See all',
                onAction: () => onNavigate(2),
              ),
              if (pendingUsers.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: AdminColors.mid,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'All caught up. No pending registrations.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ...pendingUsers.map((u) => _pendingCard(context, u)),
              SectionHeader(
                'Recent activity',
                actionLabel: 'See all',
                onAction: () => onNavigate(3),
              ),
              if (logs.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No activity yet.'),
                  ),
                ),
              ...logs.map(
                (l) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    radius: 16,
                    backgroundColor: AdminColors.mint,
                    child: Icon(Icons.bolt, size: 16, color: AdminColors.deep),
                  ),
                  title: Text(l.message),
                  subtitle: Text(timeAgo(l.time)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Recent activity from this session.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header(BuildContext context, AppProvider app) {
    return HeaderBackground(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 24),
          child: Column(
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      Icons.admin_panel_settings_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, Admin',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.eco, size: 13, color: Colors.white70),
                            SizedBox(width: 4),
                            Text(
                              'RecyConnect • Oroquieta City',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => onNavigate(2),
                    icon: Badge(
                      isLabelVisible: app.pendingCount > 0,
                      label: Text('${app.pendingCount}'),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const ThemeToggle(iconOnly: true),
                ],
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onNavigate(1),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Search users, usernames, addresses',
                            style: TextStyle(color: Colors.black45),
                          ),
                        ),
                        Icon(Icons.search, color: Colors.black45),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(
    BuildContext context,
    String label,
    int value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(label, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleCard(AppProvider app, UserRole role, Color color) {
    final total = app.countRole(role);
    final approved = app.users
        .where((u) => u.role == role && u.status == AccountStatus.approved)
        .length;
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.65)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(roleIcon(role), color: Colors.white),
          Text(
            '$total',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            role.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '$approved approved',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _pendingCard(BuildContext context, AppUser u) {
    final docs = StringBuffer(u.idDocument != null ? 'ID ✓' : 'ID missing');
    if (u.requiresPermit) {
      docs.write(
        u.permitDocument != null ? '  •  Permit ✓' : '  •  Permit missing',
      );
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AdminColors.mint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(roleIcon(u.role), color: AdminColors.deep),
        ),
        title: Text(
          u.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${u.role.label} • ${timeAgo(u.createdAt)}\n$docs'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AdminUserDetailPage(user: u)),
        ),
      ),
    );
  }
}
