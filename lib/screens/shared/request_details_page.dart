import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import '../../models/recyclable_post.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/post_store.dart';
import '../../theme/app_theme.dart';
import '../../utils/launch_helper.dart';
import '../../utils/location_helper.dart';
import '../../widgets/cancel_reason_dialog.dart';
import '../../widgets/osm_map.dart';
import '../../widgets/post_widgets.dart';
import 'route_map_page.dart';
import 'post_chat_page.dart';

class RequestDetailsPage extends StatefulWidget {
  const RequestDetailsPage({super.key, required this.post, required this.loc});

  final RecyclablePost post;
  final LocationResult loc;

  @override
  State<RequestDetailsPage> createState() => _RequestDetailsPageState();
}

class _RequestDetailsPageState extends State<RequestDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _message = TextEditingController();
  String _unit = kOfferUnits.first;

  @override
  void dispose() {
    _amount.dispose();
    _message.dispose();
    super.dispose();
  }

  void _sendOffer() {
    if (!_formKey.currentState!.validate()) return;
    final me = context.read<AppProvider>().currentUser;
    if (me == null) return;
    final err = context.read<PostStore>().sendOffer(
      widget.post,
      collectorUsername: me.username,
      collectorName: me.fullName,
      collectorPhone: me.phone,
      isJunkShop: me.role == UserRole.junkShop,
      amount: double.parse(_amount.text.trim()),
      unit: _unit,
      message: _message.text.trim(),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'Offer sent to the household.')),
    );
    if (err == null) {
      _amount.clear();
      _message.clear();
    }
  }

  Widget _row(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.brand(context)),
        const SizedBox(width: 10),
        SizedBox(
          width: 84,
          child: Text(label, style: TextStyle(color: AppTheme.muted(context))),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  Widget _mapPreview(bool exact) {
    final point = exact ? widget.post.location : widget.post.approxLocation;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 180,
        child: IgnorePointer(
          child: FlutterMap(
            key: ValueKey('${point.latitude},${point.longitude},$exact'),
            options: MapOptions(
              initialCenter: point,
              initialZoom: exact ? 16 : 14,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              osmTileLayer(),
              if (!exact)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: point,
                      radius: 450,
                      useRadiusInMeter: true,
                      color: AppTheme.green.withValues(alpha: 0.25),
                      borderColor: AppTheme.green,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              if (exact)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<PostStore>();
    final me = context.watch<AppProvider>().currentUser;
    final post = widget.post;
    final isMine = me != null && post.collectorUsername == me.username;
    final revealed = isMine; // exact pin + contact only after acceptance
    final km = distanceKm(widget.loc.point, post.location);
    final myOffer = post.offerBy(me?.username ?? '');

    return Scaffold(
      appBar: AppBar(title: const Text('Request Details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (post.photo != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                post.photo!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          if (post.photo != null) const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${post.material} • ${post.quantityLabel}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              StatusChip(post.status),
            ],
          ),
          const SizedBox(height: 16),
          _row(Icons.near_me_outlined, 'Distance', fmtKm(km)),
          _row(Icons.schedule, 'Schedule', post.scheduleLabel),
          _row(Icons.place_outlined, 'Area', post.address),
          _row(
            Icons.event_note_outlined,
            'Posted',
            fmtDateTime(post.createdAt),
          ),
          if (post.priceRequested)
            _row(
              Icons.request_quote_outlined,
              'Price',
              'Household asks for a price',
            ),
          if (post.highValue)
            _row(Icons.star_rounded, 'Value', 'High-value material'),
          if (post.notes.isNotEmpty)
            _row(Icons.notes_outlined, 'Notes', post.notes),
          if (!widget.loc.isReal)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Distance is from Oroquieta City center because your location is unavailable.',
                style: TextStyle(fontSize: 12, color: AppTheme.muted(context)),
              ),
            ),
          const SizedBox(height: 6),
          _mapPreview(revealed),
          const SizedBox(height: 6),
          Text(
            revealed
                ? 'Exact pickup pin.'
                : 'Approximate area only. The exact pin and contact details '
                      'appear after the household accepts your offer.',
            style: TextStyle(fontSize: 12, color: AppTheme.muted(context)),
          ),
          const SizedBox(height: 20),

          if (me != null &&
              (me.username == post.householdUsername ||
                  post.collectorUsername == me.username)) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PostChatPage(post: post)),
                ),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Message about this post'),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ---------------- status specific section
          if (post.status == PostStatus.posted) ...[
            const Text(
              'Send a price offer',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (myOffer != null)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    Icons.local_offer_outlined,
                    color: AppTheme.brand(context),
                  ),
                  title: Text('Your offer: ${myOffer.label}'),
                  subtitle: Text(
                    myOffer.status == OfferStatus.declined
                        ? 'Declined by the household'
                        : 'Waiting for the household. Sending again replaces it.',
                  ),
                ),
              ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _amount,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Amount',
                            prefixText: '₱ ',
                          ),
                          validator: (v) {
                            final n = double.tryParse(v?.trim() ?? '');
                            return (n == null || n <= 0)
                                ? 'Enter a valid amount'
                                : null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 140,
                        child: DropdownButtonFormField<String>(
                          initialValue: _unit,
                          isExpanded: true,
                          items: kOfferUnits
                              .map(
                                (u) =>
                                    DropdownMenuItem(value: u, child: Text(u)),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _unit = v ?? _unit),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _message,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Message (optional), e.g. pickup time',
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _sendOffer,
                      icon: const Icon(Icons.send),
                      label: const Text('Send Offer'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Offers are for information only. No payment is processed in the app.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.muted(context),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (post.status == PostStatus.accepted && isMine) ...[
            const Text(
              'Household contact',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(Icons.person, color: AppTheme.brand(context)),
                title: Text(post.displayHouseholdName),
                subtitle: Text(post.householdPhone),
                trailing: IconButton(
                  icon: const Icon(Icons.call),
                  onPressed: () => callPhone(context, post.householdPhone),
                ),
              ),
            ),
            if (post.acceptedOffer != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Agreed offer: ${post.acceptedOffer!.label}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            const SizedBox(height: 14),
            JobActions(post: post, loc: widget.loc),
          ] else if (post.status == PostStatus.accepted)
            const Text('This request was accepted by another collector.')
          else ...[
            Text(
              'Final status: ${post.status.label}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (post.cancelReason != null) Text('Reason: ${post.cancelReason}'),
          ],
        ],
      ),
    );
  }
}

/// Navigate / Call / Collected / Sold / Cancel buttons for an accepted job.
class JobActions extends StatelessWidget {
  const JobActions({super.key, required this.post, required this.loc});

  final RecyclablePost post;
  final LocationResult loc;

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
        .showSnackBar(SnackBar(content: Text(err ?? 'Collection cancelled.')));
  }

  void _complete(BuildContext context, {required bool sold}) {
    context.read<PostStore>().completeCollection(post, sold: sold);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Marked as ${sold ? 'Sold' : 'Collected'}.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RouteMapPage(
                from: loc.point,
                to: post.location,
                title: post.displayHouseholdName,
                fromIsReal: loc.isReal,
                phone: post.householdPhone,
              ),
            ),
          ),
          icon: const Icon(Icons.navigation_outlined),
          label: const Text('Navigate'),
        ),
        OutlinedButton.icon(
          onPressed: () => callPhone(context, post.householdPhone),
          icon: const Icon(Icons.call_outlined),
          label: const Text('Call'),
        ),
        FilledButton.icon(
          onPressed: () => _complete(context, sold: false),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Collected'),
        ),
        FilledButton.tonalIcon(
          onPressed: () => _complete(context, sold: true),
          icon: const Icon(Icons.sell_outlined),
          label: const Text('Sold'),
        ),
        TextButton.icon(
          onPressed: () => _cancel(context),
          icon: const Icon(Icons.cancel_outlined, color: Colors.red),
          label: const Text('Cancel', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
