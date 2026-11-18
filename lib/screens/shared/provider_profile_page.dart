import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/header_background.dart';
import '../../widgets/rating_widgets.dart';
import '../admin/admin_widgets.dart'
    show roleIcon, formatDate, timeAgo, confirmDialog;

/// A list card for a collector / junk shop with its star rating.
class ProviderCard extends StatelessWidget {
  const ProviderCard({super.key, required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderProfilePage(provider: user),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.softGreen(context),
                child: Icon(
                  roleIcon(user.role),
                  color: AppTheme.brand(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${user.role.label} • ${user.address}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.muted(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    RatingLine(
                      average: app.averageRating(user),
                      count: app.ratingCount(user),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

/// Profile of a collector / junk shop: rating, reviews, rate + report.
/// The admin can also open it (no rate/report buttons, can remove reviews).
class ProviderProfilePage extends StatelessWidget {
  const ProviderProfilePage({super.key, required this.provider});
  final AppUser provider;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final me = app.currentUser;
    final isAdmin = me?.role == UserRole.admin;
    final canInteract = me != null && !isAdmin && me != provider;
    final reviews = app.ratingsFor(provider);
    final avg = app.averageRating(provider);
    final mine = me == null ? null : app.ratingBy(me, provider);

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          HeaderBackground(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 20, 26),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: Colors.white24,
                      child: Icon(
                        roleIcon(provider.role),
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      provider.fullName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      provider.role.label,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StarDisplay(value: avg, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            reviews.isEmpty
                                ? 'No ratings yet'
                                : '${avg.toStringAsFixed(1)} • ${reviews.length} review${reviews.length == 1 ? '' : 's'}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.phone_outlined,
                          color: AppTheme.brand(context),
                        ),
                        title: const Text('Contact'),
                        subtitle: Text(
                          provider.phone.isEmpty ? '—' : provider.phone,
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          Icons.location_on_outlined,
                          color: AppTheme.brand(context),
                        ),
                        title: const Text('Address'),
                        subtitle: Text(
                          provider.address.isEmpty ? '—' : provider.address,
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          Icons.event_outlined,
                          color: AppTheme.brand(context),
                        ),
                        title: const Text('Member since'),
                        subtitle: Text(formatDate(provider.createdAt)),
                      ),
                    ],
                  ),
                ),
                if (canInteract) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => showRateSheet(context, provider),
                          icon: const Icon(Icons.star_rounded),
                          label: Text(mine == null ? 'Rate' : 'Edit my rating'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => showReportSheet(context, provider),
                          icon: const Icon(Icons.flag_outlined),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          label: const Text('Report'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ratings are public. Reports are private and only the administrator can see them.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.muted(context),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                const Text(
                  'Rating summary',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                for (var s = 5; s >= 1; s--)
                  _bar(
                    context,
                    s,
                    reviews.where((r) => r.stars == s).length,
                    reviews.length,
                  ),
                const SizedBox(height: 22),
                Text(
                  'Reviews (${reviews.length})',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (reviews.isEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'No reviews yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.muted(context)),
                        ),
                      ),
                    ),
                  ),
                for (final r in reviews)
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppTheme.softGreen(context),
                                child: Text(
                                  r.from.fullName.isEmpty
                                      ? '?'
                                      : r.from.fullName[0].toUpperCase(),
                                  style: TextStyle(
                                    color: AppTheme.brand(context),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.from == me
                                          ? '${shortName(r.from.fullName)} (You)'
                                          : shortName(r.from.fullName),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${r.from.role.label} • ${timeAgo(r.createdAt)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.muted(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              StarDisplay(value: r.stars.toDouble(), size: 15),
                              if (isAdmin)
                                IconButton(
                                  tooltip: 'Remove review',
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    final ok = await confirmDialog(
                                      context,
                                      title: 'Remove this review?',
                                      message: 'This permanently deletes the rating and comment.',
                                      confirmLabel: 'Remove',
                                      danger: true,
                                    );
                                    if (ok) app.deleteRating(r);
                                  },
                                ),
                            ],
                          ),
                          if (r.comment.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(r.comment),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(BuildContext context, int star, int count, int total) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text('$star ★')),
          Expanded(
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : count / total,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFF5A623),
              backgroundColor: Theme.of(context).colorScheme.onSurface
                  .withValues(alpha: 0.10),
            ),
          ),
          SizedBox(width: 30, child: Text('$count', textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
