import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/feedback_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/rating_widgets.dart';
import '../../widgets/header_background.dart';
import '../shared/provider_profile_page.dart';
import 'admin_user_detail_page.dart';
import 'admin_widgets.dart';

class AdminReportsPage extends StatelessWidget {
  const AdminReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final open = context.watch<AppProvider>().openReportCount;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: HeaderAppBar(
          title: const Text('Reports & ratings'),
          bottom: TabBar(
            tabs: [
              Tab(text: open > 0 ? 'Reports ($open open)' : 'Reports'),
              const Tab(text: 'Ratings'),
            ],
          ),
        ),
        body: const TabBarView(children: [_ReportsTab(), _RatingsTab()]),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// REPORTS
// ---------------------------------------------------------------------
class _ReportsTab extends StatefulWidget {
  const _ReportsTab();

  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  ReportStatus? _filter = ReportStatus.open;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final list = app.reports
        .where((r) => _filter == null || r.status == _filter)
        .toList()
        .reversed
        .toList();

    return Column(
      children: [
        SizedBox(
          height: 58,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            children: [
              for (final s in <ReportStatus?>[
                ReportStatus.open,
                ReportStatus.resolved,
                ReportStatus.dismissed,
                null,
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(s == null ? 'All' : s.label),
                    selected: _filter == s,
                    onSelected: (_) => setState(() => _filter = s),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        size: 48,
                        color: AppTheme.muted(context),
                      ),
                      const SizedBox(height: 8),
                      const Text('No reports here.'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _card(context, app, list[i]),
                ),
        ),
      ],
    );
  }

  Widget _line(BuildContext context, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$k: ',
              style: TextStyle(color: AppTheme.muted(context)),
            ),
            TextSpan(text: v),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, AppProvider app, UserReport r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flag_rounded, color: Colors.deepOrange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    r.reason,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                ReportChip(r.status),
              ],
            ),
            const SizedBox(height: 10),
            _line(
              context,
              'Reported',
              '${r.reported.fullName} (${r.reported.role.label})',
            ),
            _line(
              context,
              'Reported by',
              '${r.reporter.fullName} (${r.reporter.role.label})',
            ),
            if (r.details.isNotEmpty) _line(context, 'Details', r.details),
            _line(context, 'Date', formatDateTime(r.createdAt)),
            if (r.adminNote != null) _line(context, 'Admin note', r.adminNote!),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminUserDetailPage(user: r.reported),
                    ),
                  ),
                  icon: const Icon(Icons.person_search_outlined),
                  label: const Text('View account'),
                ),
                if (r.status == ReportStatus.open) ...[
                  OutlinedButton(
                    onPressed: () async {
                      final note = await showDialog<String>(
                        context: context,
                        builder: (_) => const _NoteDialog(
                          title: 'Dismiss report',
                          hint: 'Why is this report dismissed? (optional)',
                          confirmLabel: 'Dismiss',
                        ),
                      );
                      if (note != null) app.dismissReport(r, note: note);
                    },
                    child: const Text('Dismiss'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final note = await showDialog<String>(
                        context: context,
                        builder: (_) => const _NoteDialog(
                          title: 'Resolve report',
                          hint: 'What action was taken? (optional)',
                          confirmLabel: 'Resolve',
                        ),
                      );
                      if (note != null) app.resolveReport(r, note: note);
                    },
                    child: const Text('Resolve'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteDialog extends StatefulWidget {
  const _NoteDialog({
    required this.title,
    required this.hint,
    required this.confirmLabel,
  });
  final String title;
  final String hint;
  final String confirmLabel;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        decoration: InputDecoration(hintText: widget.hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// RATINGS
// ---------------------------------------------------------------------
class _RatingsTab extends StatefulWidget {
  const _RatingsTab();

  @override
  State<_RatingsTab> createState() => _RatingsTabState();
}

class _RatingsTabState extends State<_RatingsTab> {
  UserRole? _role;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    final users = app.users
        .where(
          (u) => app.ratingCount(u) > 0 && (_role == null || u.role == _role),
        )
        .toList();
    users.sort((a, b) {
      final c = app.averageRating(b).compareTo(app.averageRating(a));
      return c != 0 ? c : app.ratingCount(b).compareTo(app.ratingCount(a));
    });

    final total = app.ratings.length;
    final overall = total == 0
        ? 0.0
        : app.ratings.fold<int>(0, (s, r) => s + r.stars) / total;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.star_rounded,
                  size: 36,
                  color: const Color(0xFFF5A623),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        total == 0
                            ? 'No ratings yet'
                            : '${overall.toStringAsFixed(1)} average',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$total rating${total == 1 ? '' : 's'} across all roles',
                        style: TextStyle(color: AppTheme.muted(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final r in <UserRole?>[
                null,
                UserRole.collector,
                UserRole.junkShop,
                UserRole.household,
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(r == null ? 'All roles' : r.label),
                    selected: _role == r,
                    onSelected: (_) => setState(() => _role = r),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (users.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No ratings for this role yet.',
                style: TextStyle(color: AppTheme.muted(context)),
              ),
            ),
          ),
        for (final u in users)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.softGreen(context),
                child: Icon(roleIcon(u.role), color: AppTheme.brand(context)),
              ),
              title: Text(
                u.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(u.role.label),
                  const SizedBox(height: 2),
                  RatingLine(
                    average: app.averageRating(u),
                    count: app.ratingCount(u),
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProviderProfilePage(provider: u),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
