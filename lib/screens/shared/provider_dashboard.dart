import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import '../../models/recyclable_post.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/post_store.dart';
import '../../theme/app_theme.dart';
import '../../utils/location_helper.dart';
import '../../widgets/header_background.dart';
import '../../widgets/osm_map.dart';
import '../../widgets/post_widgets.dart';
import '../../widgets/service_tile.dart';
import '../../widgets/theme_toggle.dart';
import '../auth/logout_loading_page.dart';
import 'my_feedback_page.dart';
import 'notifications_page.dart';
import 'request_details_page.dart';
import 'suki_page.dart';
import 'communication_page.dart';
import 'edit_profile_page.dart';

class ProviderDashboard extends StatefulWidget {
  const ProviderDashboard({super.key, required this.isJunkShop});

  final bool isJunkShop;

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  int _index = 0;
  LocationResult _loc = const LocationResult(oroquietaCenter, false);

  void _go(int i) => setState(() => _index = i);

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final r = await getCurrentLocation();
    if (!mounted) return;
    setState(() => _loc = r);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          _HomeTab(
            isJunkShop: widget.isJunkShop,
            loc: _loc,
            onNavigate: _go,
            onRefreshLocation: _loadLocation,
          ),
          _RequestsTab(loc: _loc, onRefreshLocation: _loadLocation),
          // Built only when opened so tiles are not fetched in the background.
          _index == 2 ? _MapTab(loc: _loc) : const SizedBox.shrink(),
          _JobsTab(loc: _loc),
          _ProfileTab(isJunkShop: widget.isJunkShop),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.green,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: () => _go(2),
        child: const Icon(Icons.map_rounded, size: 28),
      ),
      bottomNavigationBar: BottomAppBar(
        height: 68,
        padding: EdgeInsets.zero,
        color: Theme.of(context).cardTheme.color,
        surfaceTintColor: Colors.transparent,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          children: [
            _nav(0, Icons.home_rounded, 'Home'),
            _nav(1, Icons.list_alt_rounded, 'Requests'),
            const SizedBox(width: 72), // space for the center Map button
            _nav(3, Icons.local_shipping_rounded, 'My Jobs'),
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

// =====================================================================
// SHARED SMALL WIDGETS
// =====================================================================
class _InfoPill extends StatelessWidget {
  const _InfoPill(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppTheme.brand(context)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: AppTheme.muted(context)),
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.post, required this.loc});
  final RecyclablePost post;
  final LocationResult loc;

  @override
  Widget build(BuildContext context) {
    final km = distanceKm(loc.point, post.location);
    final me = context.read<AppProvider>().currentUser?.username ?? '';
    final myOffer = post.offerBy(me);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RequestDetailsPage(post: post, loc: loc),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.softGreen(context),
                    child: Icon(
                      materialIconFor(post.material),
                      color: AppTheme.brand(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${post.material} • ${post.quantityLabel}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          post.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.muted(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  _InfoPill(Icons.near_me_outlined, fmtKm(km)),
                  _InfoPill(Icons.schedule, post.scheduleLabel),
                  if (post.priceRequested)
                    const _InfoPill(
                      Icons.request_quote_outlined,
                      'Asks for price',
                    ),
                  if (post.highValue)
                    const _InfoPill(Icons.star_rounded, 'High value'),
                  if (myOffer != null)
                    _InfoPill(
                      Icons.local_offer_outlined,
                      'Your offer: ${myOffer.label}',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.brand(context), size: 25),
            const SizedBox(height: 13),
            Text(
              value,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: AppTheme.muted(context)),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _emptyCard(
  BuildContext context,
  IconData icon,
  String title,
  String sub,
) {
  return SizedBox(
    width: double.infinity,
    child: Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppTheme.brand(context)),
            const SizedBox(height: 8),
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
    ),
  );
}

// =====================================================================
// HOME TAB
// =====================================================================
class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.isJunkShop,
    required this.loc,
    required this.onNavigate,
    required this.onRefreshLocation,
  });

  final bool isJunkShop;
  final LocationResult loc;

  /// 1 = Requests, 2 = Map, 3 = My Jobs, 4 = Profile
  final ValueChanged<int> onNavigate;
  final VoidCallback onRefreshLocation;

  Widget _title(String text) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Text(
      text,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final store = context.watch<PostStore>();
    final user = app.currentUser;
    final me = user?.username ?? '';
    store.registerProvider(me);

    final open = store.openPosts();
    final nearby = List<RecyclablePost>.of(open)
      ..sort(
        (a, b) => distanceKm(
          loc.point,
          a.location,
        ).compareTo(distanceKm(loc.point, b.location)),
      );
    final pendingOffers = store.offeredBy(me).length;
    final accepted = store.acceptedFor(me).length;
    final highValue = open.where((p) => p.highValue).length;
    final completed = store
        .historyFor(me)
        .where(
          (p) =>
              p.status == PostStatus.collected || p.status == PostStatus.sold,
        )
        .length;
    final notes = store.notificationsFor(me).take(3).toList();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _header(context, user, store.unreadFor(me)),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _opportunityHero(context, user, highValue),
              _title('Your Collection Overview'),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.inventory_2_outlined,
                      label: 'Open Requests',
                      value: '${open.length}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.local_offer_outlined,
                      label: 'Pending Offers',
                      value: '$pendingOffers',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.handshake_outlined,
                      label: 'Accepted Jobs',
                      value: '$accepted',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.check_circle_outline,
                      label: 'Completed',
                      value: '$completed',
                    ),
                  ),
                ],
              ),
              _title('Our Services'),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                runSpacing: 14,
                children: [
                  ServiceTile(
                    icon: Icons.list_alt_outlined,
                    label: 'Requests',
                    onTap: () => onNavigate(1),
                  ),
                  ServiceTile(
                    icon: Icons.map_outlined,
                    label: 'Map',
                    onTap: () => onNavigate(2),
                  ),
                  ServiceTile(
                    icon: Icons.local_shipping_outlined,
                    label: 'My Jobs',
                    onTap: () => onNavigate(3),
                  ),
                  ServiceTile(
                    icon: Icons.favorite_border_rounded,
                    label: 'Suki',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SukiPage()),
                    ),
                  ),
                  ServiceTile(
                    icon: Icons.forum_outlined,
                    label: 'Messages',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CommunicationPage(),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _title('Nearest Requests')),
                  TextButton(
                    onPressed: () => onNavigate(1),
                    child: const Text('See all'),
                  ),
                ],
              ),
              if (nearby.isEmpty)
                _emptyCard(
                  context,
                  Icons.inbox_outlined,
                  'No requests posted yet',
                  'New household posts will appear here.',
                ),
              ...nearby.take(3).map((p) => _RequestCard(post: p, loc: loc)),
              _title('Recent Activity'),
              if (notes.isEmpty)
                _emptyCard(
                  context,
                  Icons.notifications_none_rounded,
                  'No recent activity yet',
                  'Offers, acceptances and updates will appear here.',
                )
              else
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: notes
                        .map(
                          (n) => ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.notifications_none_rounded,
                              color: AppTheme.brand(context),
                            ),
                            title: Text(n.message),
                            subtitle: Text(fmtDateTime(n.sentAt)),
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _opportunityHero(BuildContext context, AppUser? user, int highValue) {
    final shop = isJunkShop;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [AppTheme.green, AppTheme.green.withValues(alpha: 0.72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.green.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  shop ? Icons.storefront_rounded : Icons.recycling_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  shop ? 'Grow your shop today' : 'Find your next collection',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (highValue > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$highValue high-value',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            shop
                ? 'Review household materials and make competitive offers.'
                : 'Browse nearby household posts and send your best offer.',
            style: const TextStyle(color: Colors.white, height: 1.35),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => onNavigate(1),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.green,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(Icons.explore_outlined),
            label: const Text('Explore requests'),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, AppUser? user, int unread) {
    final first =
        user?.fullName.split(' ').first ??
        (isJunkShop ? 'Junk Shop' : 'Collector');
    return HeaderBackground(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 24),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      isJunkShop ? Icons.store : Icons.person,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, $first!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              loc.isReal
                                  ? Icons.my_location
                                  : Icons.location_off_outlined,
                              size: 13,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                loc.isReal
                                    ? 'Location on'
                                    : 'Using Oroquieta City center',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onRefreshLocation,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsPage(),
                      ),
                    ),
                    icon: Badge(
                      isLabelVisible: unread > 0,
                      label: Text('$unread'),
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
                            'Search recyclable requests',
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
}

// =====================================================================
// REQUESTS TAB (browse + filter: area, material, quantity, distance)
// =====================================================================
enum _Sort { nearest, newest, biggest }

class _RequestsTab extends StatefulWidget {
  const _RequestsTab({required this.loc, required this.onRefreshLocation});
  final LocationResult loc;
  final VoidCallback onRefreshLocation;

  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab> {
  String _query = '';
  String? _material;
  double _minQty = 0;
  double? _maxKm;
  _Sort _sort = _Sort.nearest;

  Widget _chipRow<T>({
    required String title,
    required List<(String, T)> options,
    required T selected,
    required ValueChanged<T> onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            child: Text(
              title,
              style: TextStyle(fontSize: 12, color: AppTheme.muted(context)),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: options
                    .map(
                      (o) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(o.$1),
                          selected: o.$2 == selected,
                          onSelected: (_) => onSelected(o.$2),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final store = context.watch<PostStore>();
    final q = _query.trim().toLowerCase();
    final loc = widget.loc;

    final list = store.openPosts().where((p) {
      if (_material != null && p.material != _material) return false;
      if (p.quantity < _minQty) return false;
      if (_maxKm != null && distanceKm(loc.point, p.location) > _maxKm!) {
        return false;
      }
      if (q.isNotEmpty &&
          !p.address.toLowerCase().contains(q) &&
          !p.material.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();

    switch (_sort) {
      case _Sort.nearest:
        list.sort(
          (a, b) => distanceKm(
            loc.point,
            a.location,
          ).compareTo(distanceKm(loc.point, b.location)),
        );
      case _Sort.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _Sort.biggest:
        list.sort((a, b) => b.quantity.compareTo(a.quantity));
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const ScreenHeader(
          title: 'Available Requests',
          subtitle: 'Check distance and quantity before you travel',
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!loc.isReal)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.location_off_outlined),
                    title: Text(loc.message ?? 'Location unavailable.'),
                    subtitle: const Text(
                      'Distances are measured from Oroquieta City center.',
                    ),
                    trailing: TextButton(
                      onPressed: widget.onRefreshLocation,
                      child: const Text('Retry'),
                    ),
                  ),
                ),
              TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Search by area / barangay or material',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 10),
              _chipRow<String?>(
                title: 'Material',
                options: <(String, String?)>[
                  ('All', null),
                  for (final m in app.materialCategories) (m, m),
                ],
                selected: _material,
                onSelected: (v) => setState(() => _material = v),
              ),
              _chipRow<double>(
                title: 'Quantity',
                options: const [
                  ('Any', 0),
                  ('5+', 5),
                  ('10+', 10),
                  ('20+', 20),
                ],
                selected: _minQty,
                onSelected: (v) => setState(() => _minQty = v),
              ),
              _chipRow<double?>(
                title: 'Distance',
                options: const <(String, double?)>[
                  ('Any', null),
                  ('≤ 1 km', 1),
                  ('≤ 3 km', 3),
                  ('≤ 5 km', 5),
                  ('≤ 10 km', 10),
                ],
                selected: _maxKm,
                onSelected: (v) => setState(() => _maxKm = v),
              ),
              _chipRow<_Sort>(
                title: 'Sort by',
                options: const [
                  ('Nearest', _Sort.nearest),
                  ('Newest', _Sort.newest),
                  ('Biggest', _Sort.biggest),
                ],
                selected: _sort,
                onSelected: (v) => setState(() => _sort = v),
              ),
              const SizedBox(height: 8),
              Text(
                'Requests (${list.length})',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              if (list.isEmpty)
                _emptyCard(
                  context,
                  Icons.search_off_rounded,
                  'No matching requests',
                  'Try clearing a filter or check again later.',
                ),
              ...list.map((p) => _RequestCard(post: p, loc: loc)),
            ],
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// MAP TAB (center button)
// =====================================================================
class _MapTab extends StatefulWidget {
  const _MapTab({required this.loc});
  final LocationResult loc;

  @override
  State<_MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<_MapTab> {
  final MapController _controller = MapController();
  bool _tileError = false;
  int _mapVersion = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showPost(RecyclablePost p) {
    final km = distanceKm(widget.loc.point, p.location);
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${p.material} • ${p.quantityLabel}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text('${p.address}  •  ${fmtKm(km)} away'),
            Text(p.scheduleLabel),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RequestDetailsPage(post: p, loc: widget.loc),
                    ),
                  );
                },
                child: const Text('View details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PostStore>();
    final me = context.read<AppProvider>().currentUser?.username ?? '';
    final open = store.openPosts();
    final mine = store.acceptedFor(me);

    return Column(
      children: [
        const ScreenHeader(
          title: 'Request Map',
          subtitle: 'Circles show approximate areas. Exact pins appear after acceptance.',
        ),
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                key: ValueKey(_mapVersion),
                mapController: _controller,
                options: MapOptions(
                  initialCenter: widget.loc.point,
                  initialZoom: 13.5,
                ),
                children: [
                  osmTileLayer(
                    onTileError: () {
                      if (mounted && !_tileError) {
                        setState(() => _tileError = true);
                      }
                    },
                  ),
                  CircleLayer(
                    circles: [
                      for (final p in open)
                        CircleMarker(
                          point: p.approxLocation,
                          radius: 450,
                          useRadiusInMeter: true,
                          color: AppTheme.green.withValues(alpha: 0.25),
                          borderColor: AppTheme.green,
                          borderStrokeWidth: 2,
                        ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      for (final p in open)
                        Marker(
                          point: p.approxLocation,
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => _showPost(p),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                materialIconFor(p.material),
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      for (final p in mine)
                        Marker(
                          point: p.location,
                          width: 44,
                          height: 44,
                          alignment: Alignment.topCenter,
                          child: GestureDetector(
                            onTap: () => _showPost(p),
                            child: pinIcon(color: Colors.deepOrange),
                          ),
                        ),
                      Marker(
                        point: widget.loc.point,
                        width: 22,
                        height: 22,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                    ],
                  ),
                  osmAttribution(),
                ],
              ),
              if (_tileError)
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: MapErrorBanner(
                    onRetry: () => setState(() {
                      _tileError = false;
                      _mapVersion++;
                    }),
                  ),
                ),
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton.small(
                  heroTag: 'provider_map_my_location',
                  onPressed: () => _controller.move(widget.loc.point, 14),
                  child: const Icon(Icons.my_location),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// MY JOBS TAB (accepted / offers sent / history)
// =====================================================================
class _JobsTab extends StatefulWidget {
  const _JobsTab({required this.loc});
  final LocationResult loc;

  @override
  State<_JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<_JobsTab> {
  int _seg = 0;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PostStore>();
    final me = context.read<AppProvider>().currentUser?.username ?? '';

    Widget body;
    if (_seg == 0) {
      final list = store.acceptedFor(me);
      body = list.isEmpty
          ? _emptyCard(
              context,
              Icons.handshake_outlined,
              'No accepted jobs yet',
              'When a household accepts your offer, it shows up here.',
            )
          : Column(children: list.map((p) => _jobCard(context, p)).toList());
    } else if (_seg == 1) {
      final list = store.offeredBy(me);
      body = list.isEmpty
          ? _emptyCard(
              context,
              Icons.local_offer_outlined,
              'No pending offers',
              'Open a request and send a price offer.',
            )
          : Column(
              children: list
                  .map((p) => _RequestCard(post: p, loc: widget.loc))
                  .toList(),
            );
    } else {
      final list = store.historyFor(me);
      body = list.isEmpty
          ? _emptyCard(
              context,
              Icons.history,
              'No collection history yet',
              'Completed and cancelled collections will appear here.',
            )
          : Column(
              children: list.map((p) => _historyCard(context, p)).toList(),
            );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const ScreenHeader(
          title: 'My Jobs',
          subtitle: 'Track your offers, pickups and history',
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Accepted')),
                    ButtonSegment(value: 1, label: Text('Offers')),
                    ButtonSegment(value: 2, label: Text('History')),
                  ],
                  selected: {_seg},
                  onSelectionChanged: (s) => setState(() => _seg = s.first),
                ),
              ),
              const SizedBox(height: 16),
              body,
            ],
          ),
        ),
      ],
    );
  }

  Widget _jobCard(BuildContext context, RecyclablePost p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${p.material} • ${p.quantityLabel}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                StatusChip(p.status),
              ],
            ),
            const SizedBox(height: 6),
            Text('${p.householdName}  •  ${p.householdPhone}'),
            Text(
              p.scheduleLabel,
              style: TextStyle(color: AppTheme.muted(context)),
            ),
            if (p.acceptedOffer != null)
              Text(
                'Agreed: ${p.acceptedOffer!.label}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 12),
            JobActions(post: p, loc: widget.loc),
          ],
        ),
      ),
    );
  }

  Widget _historyCard(BuildContext context, RecyclablePost p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.softGreen(context),
          child: Icon(
            materialIconFor(p.material),
            color: AppTheme.brand(context),
          ),
        ),
        title: Text(
          '${p.material} • ${p.quantityLabel}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            p.householdName,
            p.address,
            fmtDate(p.completedAt ?? p.createdAt),
            if (p.cancelReason != null) 'Reason: ${p.cancelReason}',
          ].join('\n'),
        ),
        isThreeLine: true,
        trailing: StatusChip(p.status),
      ),
    );
  }
}

// =====================================================================
// PROFILE TAB
// =====================================================================
class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.isJunkShop});
  final bool isJunkShop;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final user = app.currentUser;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const ScreenHeader(title: 'My Profile'),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: AppTheme.softGreen(context),
                child: Icon(
                  isJunkShop ? Icons.store : Icons.person,
                  size: 48,
                  color: AppTheme.brand(context),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                user?.fullName ?? (isJunkShop ? 'Junk Shop' : 'Collector'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                isJunkShop ? 'Junk Shop Account' : 'Collector Account',
                style: TextStyle(color: AppTheme.muted(context)),
              ),
              const SizedBox(height: 22),
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Icon(
                    Icons.edit_outlined,
                    color: AppTheme.brand(context),
                  ),
                  title: const Text('Edit profile'),
                  subtitle: const Text('Update your name, phone and address'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfilePage()),
                  ),
                ),
              ),
              _ProfileInfo(
                icon: Icons.person_outline,
                label: isJunkShop ? 'Owner / Shop Name' : 'Full Name',
                value: user?.fullName ?? 'Not available',
              ),
              _ProfileInfo(
                icon: Icons.account_circle_outlined,
                label: 'Username',
                value: user?.username ?? 'Not available',
              ),
              _ProfileInfo(
                icon: Icons.email_outlined,
                label: 'Email',
                value: user?.email ?? 'Not provided',
              ),
              _ProfileInfo(
                icon: Icons.phone_outlined,
                label: 'Phone Number',
                value: (user?.phone.isNotEmpty ?? false)
                    ? user!.phone
                    : 'Not provided',
              ),
              _ProfileInfo(
                icon: Icons.location_on_outlined,
                label: isJunkShop ? 'Shop Address' : 'Address',
                value: (user?.address.isNotEmpty ?? false)
                    ? user!.address
                    : 'Not provided',
              ),
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Icon(
                    Icons.favorite_border_rounded,
                    color: AppTheme.brand(context),
                  ),
                  title: const Text('Regular contacts (suki)'),
                  subtitle: Text(
                    'Save and notify your regular households',
                    style: TextStyle(color: AppTheme.muted(context)),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SukiPage()),
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Icon(
                    Icons.star_outline_rounded,
                    color: AppTheme.brand(context),
                  ),
                  title: const Text('My reviews & reports'),
                  subtitle: Text(
                    'Ratings you received and reports you filed',
                    style: TextStyle(color: AppTheme.muted(context)),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyFeedbackPage()),
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: SwitchListTile(
                  secondary: Icon(
                    Icons.dark_mode_outlined,
                    color: AppTheme.brand(context),
                  ),
                  title: const Text('Dark mode'),
                  value: app.isDarkMode,
                  onChanged: (_) => app.toggleTheme(),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LogoutLoadingPage(),
                      ),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Log Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileInfo extends StatelessWidget {
  const _ProfileInfo({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.brand(context)),
        title: Text(
          label,
          style: TextStyle(fontSize: 12, color: AppTheme.muted(context)),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
