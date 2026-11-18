import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../providers/post_store.dart';
import '../../models/recyclable_post.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/launch_helper.dart';
import '../../widgets/cancel_reason_dialog.dart';
import '../../widgets/header_background.dart';
import '../../widgets/osm_map.dart';
import '../../widgets/post_widgets.dart';
import '../../widgets/service_tile.dart';
import '../../widgets/theme_toggle.dart';
import '../auth/logout_loading_page.dart';
import '../shared/location_picker_page.dart';
import '../shared/my_feedback_page.dart';
import '../shared/notifications_page.dart';
import '../shared/provider_profile_page.dart';
import '../shared/post_chat_page.dart';
import '../shared/communication_page.dart';
import '../shared/edit_profile_page.dart';

class HouseholdDashboard extends StatefulWidget {
  const HouseholdDashboard({super.key});

  @override
  State<HouseholdDashboard> createState() => _HouseholdDashboardState();
}

class _HouseholdDashboardState extends State<HouseholdDashboard> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          _HomeTab(onNavigate: _go),
          const _DirectoryTab(),
          _PostTab(onPosted: () => _go(3)), // after posting, jump to History
          const _HistoryTab(),
          const _ProfileTab(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.green,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: () => _go(2),
        child: const Icon(Icons.add_rounded, size: 30),
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
            _nav(1, Icons.groups_rounded, 'Collectors'),
            const SizedBox(width: 72), // space for the center Post button
            _nav(3, Icons.history_rounded, 'History'),
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
// HOME TAB
// =====================================================================
class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.onNavigate});

  /// 1 = Collectors, 2 = Post, 3 = History, 4 = Profile
  final ValueChanged<int> onNavigate;

  static const _cardColors = [
    Color(0xFF2E7D32),
    Color(0xFF00796B),
    Color(0xFF455A64),
    Color(0xFF6A4C93),
    Color(0xFFB26A00),
    Color(0xFF1565C0),
  ];

  static IconData _materialIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('plastic')) return Icons.local_drink_outlined;
    if (n.contains('metal')) return Icons.hardware_outlined;
    if (n.contains('glass')) return Icons.wine_bar_outlined;
    if (n.contains('paper')) return Icons.description_outlined;
    if (n.contains('cardboard')) return Icons.inventory_2_outlined;
    if (n.contains('appliance')) return Icons.kitchen_outlined;
    if (n.contains('electronic')) return Icons.devices_other_outlined;
    return Icons.recycling;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final user = app.currentUser;
    final top = app.providers().take(3).toList();

    // Live numbers from the post store
    final store = context.watch<PostStore>();
    final username = user?.username ?? '';
    final mine = store.forHousehold(username);
    final active = mine.where((p) => !p.status.isClosed).length;
    final ongoing = mine.where((p) => p.status == PostStatus.accepted).length;
    final done = mine
        .where(
          (p) =>
              p.status == PostStatus.collected || p.status == PostStatus.sold,
        )
        .toList();
    final kg = done
        .where((p) => p.unit == 'kg')
        .fold<double>(0, (s, p) => s + p.quantity);
    final unread = store.unreadFor(username);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _header(context, user, unread),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title('Your Recycling Overview'),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.inventory_2_outlined,
                      label: 'Active Posts',
                      value: '$active',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.local_shipping_outlined,
                      label: 'Collections',
                      value: '$ongoing',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.check_circle_outline,
                      label: 'Completed',
                      value: '${done.length}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.recycling,
                      label: 'Recyclables',
                      value: '${kg % 1 == 0 ? kg.toInt() : kg} kg',
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
                    icon: Icons.add_box_outlined,
                    label: 'Post',
                    onTap: () => onNavigate(2),
                  ),
                  ServiceTile(
                    icon: Icons.groups_outlined,
                    label: 'Collectors',
                    onTap: () => onNavigate(1),
                  ),
                  ServiceTile(
                    icon: Icons.star_outline_rounded,
                    label: 'Reviews',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyFeedbackPage()),
                    ),
                  ),
                  ServiceTile(
                    icon: Icons.history,
                    label: 'History',
                    onTap: () => onNavigate(3),
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
              _title('Recycling Materials'),
              SizedBox(
                height: 112,
                child: app.materialCategories.isEmpty
                    ? const Text('No material categories yet.')
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: app.materialCategories.length,
                        itemBuilder: (_, i) {
                          final name = app.materialCategories[i];
                          final c = _cardColors[i % _cardColors.length];
                          return Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [c, c.withValues(alpha: 0.65)],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                  _materialIcon(name),
                                  color: Colors.white,
                                  size: 30,
                                ),
                                Text(
                                  name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Row(
                children: [
                  Expanded(child: _title('Top Rated Collectors & Shops')),
                  TextButton(
                    onPressed: () => onNavigate(1),
                    child: const Text('See all'),
                  ),
                ],
              ),
              if (top.isEmpty)
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Approved collectors and junk shops will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.muted(context)),
                      ),
                    ),
                  ),
                ),
              ...top.map((u) => ProviderCard(user: u)),
              _title('Recent Activity'),
              _recentActivity(context, store, username),
            ],
          ),
        ),
      ],
    );
  }

  Widget _recentActivity(
    BuildContext context,
    PostStore store,
    String username,
  ) {
    final notes = store.notificationsFor(username).take(3).toList();
    if (notes.isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 35,
                  color: AppTheme.brand(context),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No recent activity yet',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your collection updates will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.muted(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Card(
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
    );
  }

  Widget _title(String text) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Text(
      text,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
    ),
  );

  Widget _header(BuildContext context, AppUser? user, int unread) {
    final first = user?.fullName.split(' ').first ?? 'Household';
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
                    child: Icon(Icons.person, color: Colors.white),
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
                            const Icon(
                              Icons.location_on,
                              size: 13,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                (user?.address.isNotEmpty ?? false)
                                    ? user!.address
                                    : 'Oroquieta City',
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
                            'Search collectors and junk shops',
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

// =====================================================================
// COLLECTORS TAB (directory with ratings)
// =====================================================================
class _DirectoryTab extends StatefulWidget {
  const _DirectoryTab();

  @override
  State<_DirectoryTab> createState() => _DirectoryTabState();
}

class _DirectoryTabState extends State<_DirectoryTab> {
  String _query = '';
  UserRole? _role;
  bool _topFirst = true;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final q = _query.trim().toLowerCase();
    final list = app
        .providers(role: _role, topFirst: _topFirst)
        .where(
          (u) =>
              q.isEmpty ||
              u.fullName.toLowerCase().contains(q) ||
              u.address.toLowerCase().contains(q),
        )
        .toList();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const ScreenHeader(
          title: 'Collectors & Shops',
          subtitle: 'Check ratings before you arrange a pickup',
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.softGreen(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 44,
                      color: AppTheme.brand(context),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Map Preview',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'OpenStreetMap will be integrated here.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.muted(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Search by name or address',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _chip(
                      'All',
                      _role == null,
                      () => setState(() => _role = null),
                    ),
                    _chip(
                      'Collectors',
                      _role == UserRole.collector,
                      () => setState(() => _role = UserRole.collector),
                    ),
                    _chip(
                      'Junk Shops',
                      _role == UserRole.junkShop,
                      () => setState(() => _role = UserRole.junkShop),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        avatar: const Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: Color(0xFFF5A623),
                        ),
                        label: const Text('Top rated'),
                        selected: _topFirst,
                        onSelected: (v) => setState(() => _topFirst = v),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Available (${list.length})',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              if (list.isEmpty)
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.person_search_outlined,
                            size: 40,
                            color: AppTheme.brand(context),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'No collectors or junk shops found',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Approved collectors and junk shops will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.muted(context)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ...list.map((u) => ProviderCard(user: u)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    ),
  );
}

// =====================================================================
// POST TAB (saves to PostStore, with OpenStreetMap location pinning)
// =====================================================================
class _PostTab extends StatefulWidget {
  const _PostTab({required this.onPosted});
  final VoidCallback onPosted;

  @override
  State<_PostTab> createState() => _PostTabState();
}

class _PostTabState extends State<_PostTab> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _areaController = TextEditingController();
  final _notesController = TextEditingController();
  final _picker = ImagePicker();

  String? _material;
  String _unit = 'kg';
  String _schedule = 'As soon as possible';
  DateTime? _date;
  TimeOfDay? _time;
  LatLng? _pin;
  bool _pinMissing = false;
  Uint8List? _photo;
  bool _askPrice = true;
  bool _highValue = false;
  bool _anonymous = false;

  @override
  void initState() {
    super.initState();
    final addr = context.read<AppProvider>().currentUser?.address;
    if (addr != null) _areaController.text = addr;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _areaController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ---------------- map pin
  Future<void> _pickLocation() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (_) => LocationPickerPage(initial: _pin)),
    );
    if (result != null && mounted) {
      setState(() {
        _pin = result;
        _pinMissing = false;
      });
    }
  }

  // ---------------- photo
  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final x = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 80,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (!mounted) return;
      setState(() => _photo = bytes);
    } catch (_) {
      if (!mounted) return;
      _snack('Could not open the camera or gallery.');
    }
  }

  void _photoSheet() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- schedule
  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (!mounted) return;
    setState(() {
      _date = d;
      _time = t ?? _time ?? const TimeOfDay(hour: 9, minute: 0);
    });
  }

  // ---------------- submit
  void _submitPost() {
    final valid = _formKey.currentState!.validate();
    setState(() => _pinMissing = _pin == null);
    if (!valid || _pin == null) return;
    if (_schedule == 'Choose a later date' && _date == null) {
      _snack('Please choose a pickup date and time.');
      return;
    }

    final app = context.read<AppProvider>();
    final store = context.read<PostStore>();
    final user = app.currentUser;
    if (user == null) return;

    final materials = app.materialCategories;
    final material = materials.contains(_material)
        ? _material!
        : (materials.isNotEmpty ? materials.first : 'Others');

    DateTime? when;
    var label = _schedule;
    if (_schedule == 'Choose a later date') {
      final t = _time ?? const TimeOfDay(hour: 9, minute: 0);
      when = DateTime(_date!.year, _date!.month, _date!.day, t.hour, t.minute);
      label = fmtDateTime(when);
    }

    store.addPost(
      RecyclablePost(
        id: store.newId('post'),
        householdUsername: user.username,
        householdName: user.fullName,
        householdPhone: user.phone,
        material: material,
        quantity: double.parse(_quantityController.text.trim()),
        unit: _unit,
        location: _pin!,
        address: _areaController.text.trim(),
        scheduleLabel: label,
        scheduledAt: when,
        notes: _notesController.text.trim(),
        photo: _photo,
        priceRequested: _askPrice,
        highValue: _highValue,
        anonymous: _anonymous,
      ),
    );

    _quantityController.clear();
    _notesController.clear();
    setState(() {
      _pin = null;
      _photo = null;
      _date = null;
      _time = null;
      _schedule = 'As soon as possible';
    });
    _snack('Your post is live. Collectors can now see it.');
    widget.onPosted();
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
  );

  Widget _pinCard(BuildContext context) {
    final brand = AppTheme.brand(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _pickLocation,
          child: Container(
            height: _pin == null ? 110 : 170,
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppTheme.softGreen(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _pinMissing ? Colors.red : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: _pin == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_location_alt_outlined,
                        size: 36,
                        color: brand,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tap to pin your pickup location on the map',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: FlutterMap(
                            key: ValueKey(
                              '${_pin!.latitude},${_pin!.longitude}',
                            ),
                            options: MapOptions(
                              initialCenter: _pin!,
                              initialZoom: 16,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none,
                              ),
                            ),
                            children: [
                              osmTileLayer(),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _pin!,
                                    width: 44,
                                    height: 44,
                                    alignment: Alignment.topCenter,
                                    child: pinIcon(),
                                  ),
                                ],
                              ),
                              osmAttribution(),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Change pin',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (_pinMissing)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Please pin your pickup location.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        if (_pin != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Pinned: ${_pin!.latitude.toStringAsFixed(5)}, '
              '${_pin!.longitude.toStringAsFixed(5)}. Collectors only see the '
              'exact pin after you accept their offer.',
              style: TextStyle(fontSize: 12, color: AppTheme.muted(context)),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Material types come from the categories the admin manages.
    final materials = context.watch<AppProvider>().materialCategories;
    final selected = materials.contains(_material)
        ? _material
        : (materials.isNotEmpty ? materials.first : null);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const ScreenHeader(
          title: 'Post Your Recyclables',
          subtitle: 'Provide the details of the materials you want collected',
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Material Type'),
                DropdownButtonFormField<String>(
                  key: ValueKey('${materials.join('|')}-$selected'),
                  initialValue: selected,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.recycling),
                  ),
                  items: materials
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _material = v);
                  },
                ),
                const SizedBox(height: 16),
                _label('Estimated Quantity'),
                TextFormField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Enter estimated quantity',
                    prefixIcon: Icon(Icons.scale_outlined),
                  ),
                  validator: (v) {
                    final n = double.tryParse(v?.trim() ?? '');
                    return (n == null || n <= 0)
                        ? 'Please enter a valid quantity.'
                        : null;
                  },
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'kg', label: Text('Kilograms')),
                    ButtonSegment(value: 'pcs', label: Text('Pieces')),
                  ],
                  selected: {_unit},
                  onSelectionChanged: (s) => setState(() => _unit = s.first),
                ),
                const SizedBox(height: 16),
                _label('Photo (Optional)'),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _photoSheet,
                  child: Container(
                    height: _photo == null ? 90 : 180,
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppTheme.softGreen(context),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _photo == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                color: AppTheme.brand(context),
                              ),
                              const SizedBox(height: 4),
                              const Text('Add a photo of your recyclables'),
                            ],
                          )
                        : Image.memory(_photo!, fit: BoxFit.cover),
                  ),
                ),
                if (_photo != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => setState(() => _photo = null),
                      child: const Text('Remove photo'),
                    ),
                  ),
                const SizedBox(height: 16),
                _label('Barangay / Area (shown to collectors)'),
                TextFormField(
                  controller: _areaController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Brgy. Poblacion I',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Please enter your barangay or area.'
                      : null,
                ),
                const SizedBox(height: 16),
                _label('Pin Pickup Location on Map'),
                _pinCard(context),
                const SizedBox(height: 16),
                _label('Preferred Pickup Schedule'),
                DropdownButtonFormField<String>(
                  initialValue: _schedule,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'As soon as possible',
                      child: Text('As soon as possible'),
                    ),
                    DropdownMenuItem(
                      value: 'Within 1-2 days',
                      child: Text('Within 1-2 days'),
                    ),
                    DropdownMenuItem(
                      value: 'Choose a later date',
                      child: Text('Choose a later date'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _schedule = v);
                  },
                ),
                if (_schedule == 'Choose a later date') ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _pickDateTime,
                    icon: const Icon(Icons.event),
                    label: Text(
                      _date == null
                          ? 'Pick date and time'
                          : '${fmtDate(_date!)} at ${_time!.format(context)}',
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ask collectors for a price'),
                  subtitle: const Text('Collectors can send you an offer.'),
                  value: _askPrice,
                  onChanged: (v) => setState(() => _askPrice = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.star_outline),
                  title: const Text('Mark as high-value material'),
                  subtitle: const Text(
                    'Collectors and junk shops will be notified to review it.',
                  ),
                  value: _highValue,
                  onChanged: (v) => setState(() => _highValue = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.visibility_off_outlined),
                  title: const Text('Post anonymously'),
                  subtitle: const Text(
                    'Hide your name until you accept an offer.',
                  ),
                  value: _anonymous,
                  onChanged: (v) => setState(() => _anonymous = v),
                ),
                const SizedBox(height: 8),
                _label('Additional Notes (Optional)'),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Landmarks, gate color, details about your recyclable materials...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submitPost,
                    icon: const Icon(Icons.send),
                    label: const Text('Submit Post'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// HISTORY TAB (posts, offers, accept/decline, cancel with reason)
// =====================================================================
class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PostStore>();
    final user = context.watch<AppProvider>().currentUser;
    final posts = store.forHousehold(user?.username ?? '');

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const ScreenHeader(
          title: 'Collection History',
          subtitle: 'Track your previous and ongoing requests',
        ),
        if (posts.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.history, size: 60, color: AppTheme.brand(context)),
                const SizedBox(height: 12),
                const Text(
                  'No collection history yet',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  'Your submitted collection posts will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.muted(context)),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: posts.map((p) => _HouseholdPostCard(post: p)).toList(),
            ),
          ),
      ],
    );
  }
}

class _HouseholdPostCard extends StatelessWidget {
  const _HouseholdPostCard({required this.post});
  final RecyclablePost post;

  Future<void> _cancel(BuildContext context) async {
    final reason = await askCancelReason(context);
    if (reason == null || !context.mounted) return;
    final me = context.read<AppProvider>().currentUser;
    final err = context.read<PostStore>().cancelPost(
      post,
      reason: reason,
      by: me?.username ?? '',
    );
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(err ?? 'Post cancelled.')));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.read<PostStore>();
    final muted = TextStyle(fontSize: 12, color: AppTheme.muted(context));

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
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
                        '${post.address}  •  ${fmtDate(post.createdAt)}',
                        style: muted,
                      ),
                    ],
                  ),
                ),
                StatusChip(post.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('Pickup: ${post.scheduleLabel}', style: muted),
            if (post.status == PostStatus.cancelled &&
                post.cancelReason != null)
              Text(
                'Cancelled: ${post.cancelReason}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),

            // ----- offers (only while the post is still open)
            if (post.status == PostStatus.posted) ...[
              const Divider(height: 24),
              Text(
                post.offers.isEmpty
                    ? 'Waiting for collectors to send offers...'
                    : 'Price offers (${post.offers.length})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              ...post.offers.map(
                (o) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${o.collectorName}${o.isJunkShop ? ' (Junk Shop)' : ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              o.label,
                              style: TextStyle(
                                color: AppTheme.brand(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (o.message.isNotEmpty)
                              Text(o.message, style: muted),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PostChatPage(
                                    post: post,
                                    recipientUsername: o.collectorUsername,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.chat_outlined, size: 16),
                              label: const Text('Message'),
                            ),
                          ],
                        ),
                      ),
                      if (o.status == OfferStatus.pending) ...[
                        TextButton(
                          onPressed: () =>
                              store.respondOffer(post, o, accept: false),
                          child: const Text('Decline'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              store.respondOffer(post, o, accept: true),
                          child: const Text('Accept'),
                        ),
                      ] else
                        Text(
                          o.status == OfferStatus.declined
                              ? 'Declined'
                              : 'Accepted',
                          style: muted,
                        ),
                    ],
                  ),
                ),
              ),
            ],

            // ----- accepted: collector contact
            if (post.status == PostStatus.accepted &&
                post.acceptedOffer != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Icon(
                    Icons.handshake_outlined,
                    color: AppTheme.brand(context),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.acceptedOffer!.collectorName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${post.acceptedOffer!.collectorPhone}  •  ${post.acceptedOffer!.label}',
                          style: muted,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.call),
                    onPressed: () =>
                        callPhone(context, post.acceptedOffer!.collectorPhone),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LocationPickerPage(
                        initial: post.location,
                        readOnly: true,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('View pin'),
                ),
                if (!post.status.isClosed)
                  TextButton.icon(
                    onPressed: () => _cancel(context),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    label: const Text(
                      'Cancel post',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// PROFILE TAB
// =====================================================================
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

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
                  Icons.person,
                  size: 48,
                  color: AppTheme.brand(context),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                user?.fullName ?? 'Household User',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Household Account',
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
                label: 'Full Name',
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
                label: 'Address',
                value: (user?.address.isNotEmpty ?? false)
                    ? user!.address
                    : 'Not provided',
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
                    'Ratings you gave and reports you filed',
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
