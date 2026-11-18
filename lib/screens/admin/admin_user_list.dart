import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import 'admin_user_detail_page.dart';
import 'admin_widgets.dart';

class AdminUserList extends StatefulWidget {
  const AdminUserList({
    super.key,
    required this.title,
    this.pendingOnly = false,
  });
  final String title;
  final bool pendingOnly;

  @override
  State<AdminUserList> createState() => _AdminUserListState();
}

class _AdminUserListState extends State<AdminUserList> {
  String _query = '';
  UserRole? _role;
  AccountStatus? _status;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final q = _query.trim().toLowerCase();

    final list = app.users
        .where((u) {
          if (widget.pendingOnly && u.status != AccountStatus.pending) {
            return false;
          }
          if (_role != null && u.role != _role) return false;
          if (_status != null && u.status != _status) return false;
          if (q.isEmpty) return true;
          return u.fullName.toLowerCase().contains(q) ||
              u.username.toLowerCase().contains(q) ||
              u.address.toLowerCase().contains(q) ||
              u.phone.contains(q);
        })
        .toList()
        .reversed
        .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              widget.pendingOnly
                  ? 'Review documents before approving an account.'
                  : '${app.users.length} registered account(s)',
            ),
            const SizedBox(height: 14),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search name, username, contact, address',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 10),
            _filterRow<UserRole>(
              options: const <UserRole?>[
                null,
                UserRole.household,
                UserRole.collector,
                UserRole.junkShop,
              ],
              selected: _role,
              label: (r) => r == null ? 'All roles' : r.label,
              onSelected: (r) => setState(() => _role = r),
            ),
            if (!widget.pendingOnly)
              _filterRow<AccountStatus>(
                options: const <AccountStatus?>[
                  null,
                  AccountStatus.pending,
                  AccountStatus.approved,
                  AccountStatus.rejected,
                  AccountStatus.suspended,
                ],
                selected: _status,
                label: (s) => s == null ? 'All status' : s.label,
                onSelected: (s) => setState(() => _status = s),
              ),
            const SizedBox(height: 6),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.pendingOnly
                                ? 'No pending registrations.'
                                : 'No accounts found.',
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _userCard(context, list[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterRow<T>({
    required List<T?> options,
    required T? selected,
    required String Function(T?) label,
    required ValueChanged<T?> onSelected,
  }) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final o in options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label(o)),
                selected: o == selected,
                onSelected: (_) => onSelected(o),
              ),
            ),
        ],
      ),
    );
  }

  Widget _userCard(BuildContext context, AppUser u) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AdminColors.mint,
          child: Icon(roleIcon(u.role), color: AdminColors.deep),
        ),
        title: Text(
          u.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${u.role.label} • @${u.username}\n${u.phone}'),
        isThreeLine: true,
        trailing: StatusChip(u.status),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AdminUserDetailPage(user: u)),
        ),
      ),
    );
  }
}
