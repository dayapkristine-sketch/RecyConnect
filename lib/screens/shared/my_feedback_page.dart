import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:application_recyconnect/models/user_model.dart';

import '../../models/feedback_model.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/rating_widgets.dart';
import '../admin/admin_widgets.dart' show formatDateTime, timeAgo;
import 'provider_profile_page.dart';

class MyFeedbackPage extends StatelessWidget {
  const MyFeedbackPage({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final me = app.currentUser;
    final reviews = me == null
        ? <Rating>[]
        : app.ratings.where((r) => r.from == me).toList().reversed.toList();
    final reports = me == null
        ? <UserReport>[]
        : app.reportsBy(me).reversed.toList();

    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reviews & Reports'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My reviews'),
              Tab(text: 'My reports'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _reviewList(context, reviews),
            _reportList(context, reports),
          ],
        ),
      ),
    );
  }

  Widget _empty(BuildContext context, IconData icon, String title, String sub) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppTheme.brand(context)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.muted(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reviewList(BuildContext context, List<Rating> reviews) {
    if (reviews.isEmpty) {
      return _empty(
        context,
        Icons.star_outline_rounded,
        'No reviews yet',
        'Ratings you give to collectors and junk shops will appear here.',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final r in reviews)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProviderProfilePage(provider: r.to),
                ),
              ),
              title: Text(
                r.to.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${r.to.role.label} • ${timeAgo(r.createdAt)}'),
                  const SizedBox(height: 4),
                  StarDisplay(value: r.stars.toDouble()),
                  if (r.comment.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(r.comment),
                  ],
                ],
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
      ],
    );
  }

  Widget _reportList(BuildContext context, List<UserReport> reports) {
    if (reports.isEmpty) {
      return _empty(
        context,
        Icons.flag_outlined,
        'No reports filed',
        'If something goes wrong, you can report a collector or junk shop from their profile. Reports are private.',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final r in reports)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.reason,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ReportChip(r.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'About: ${r.reported.fullName} (${r.reported.role.label})',
                  ),
                  if (r.details.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(r.details),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    formatDateTime(r.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.muted(context),
                    ),
                  ),
                  if (r.adminNote != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.softGreen(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('Admin response: ${r.adminNote}'),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
