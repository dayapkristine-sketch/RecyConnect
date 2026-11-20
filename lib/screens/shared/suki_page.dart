import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/recyclable_post.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/post_store.dart';
import '../../theme/app_theme.dart';
import '../../utils/launch_helper.dart';
import '../../widgets/header_background.dart';
import 'direct_chat_page.dart';

/// Regular ("suki") contacts. Works for households, collectors and junk shops.
class SukiPage extends StatelessWidget {
  const SukiPage({super.key});

  void _notify(BuildContext context, SukiContact c) {
    final user = context.read<AppProvider>().currentUser;
    if (user == null) return;
    final isProvider =
        user.role == UserRole.collector || user.role == UserRole.junkShop;
    final msg = isProvider
        ? '${user.fullName} will be collecting recyclables in your area soon. '
              'Post yours on RecyConnect!'
        : '${user.fullName} has recyclables ready for pickup.';
    final ok = context.read<PostStore>().notifySuki(c, msg);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Notification sent to ${c.name}.'
              : '${c.name} has no linked RecyConnect account. Call or text them instead.',
        ),
      ),
    );
  }

  void _openAdd(BuildContext context, String owner) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddSukiSheet(owner: owner),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PostStore>();
    final owner = context.read<AppProvider>().currentUser?.username ?? '';
    final list = store.sukiFor(owner);

    return Scaffold(
      appBar: const HeaderAppBar(title: Text('Regular Contacts (Suki)')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _openAdd(context, owner),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add'),
      ),
      body: list.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite_border_rounded,
                      size: 56,
                      color: AppTheme.brand(context),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No regular contacts yet',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Save your suki so you can notify them when materials '
                      'or pickups are available.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.muted(context)),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final c = list[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.softGreen(context),
                      child: Text(
                        c.name.isEmpty ? '?' : c.name[0].toUpperCase(),
                        style: TextStyle(color: AppTheme.brand(context)),
                      ),
                    ),
                    title: Text(
                      c.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      [
                        c.phone,
                        if (c.address.isNotEmpty) c.address,
                      ].join('  •  '),
                      style: TextStyle(color: AppTheme.muted(context)),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'notify') _notify(context, c);
                        if (v == 'call') callPhone(context, c.phone);
                        if (v == 'message' && c.linkedUsername != null) {
                          final linked = context
                              .read<AppProvider>()
                              .userByUsername(c.linkedUsername!);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DirectChatPage(
                                otherUsername: c.linkedUsername!,
                                otherName: linked?.fullName ?? c.name,
                              ),
                            ),
                          );
                        }
                        if (v == 'remove') store.removeSuki(c);
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'notify',
                          child: Text('Send notification'),
                        ),
                        PopupMenuItem(value: 'call', child: Text('Call')),
                        if (c.linkedUsername != null)
                          PopupMenuItem(
                            value: 'message',
                            child: Text('Message'),
                          ),
                        PopupMenuItem(value: 'remove', child: Text('Remove')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _AddSukiSheet extends StatefulWidget {
  const _AddSukiSheet({required this.owner});
  final String owner;

  @override
  State<_AddSukiSheet> createState() => _AddSukiSheetState();
}

class _AddSukiSheetState extends State<_AddSukiSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _linked = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _linked.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<PostStore>().addSuki(
      owner: widget.owner,
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      linkedUsername: _linked.text,
    );
    Navigator.pop(context);
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add regular contact',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  hintText: 'Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'Phone number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(
                  hintText: 'Address / barangay (optional)',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _linked,
                decoration: const InputDecoration(
                  hintText: 'RecyConnect username (optional)',
                  helperText: 'Lets them receive in-app notifications.',
                  prefixIcon: Icon(Icons.alternate_email),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('Save contact'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
