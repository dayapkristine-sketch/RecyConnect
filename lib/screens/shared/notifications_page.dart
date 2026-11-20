import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/recyclable_post.dart';
import '../../providers/app_provider.dart';
import '../../providers/post_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/header_background.dart';
import 'communication_page.dart';
import 'post_chat_page.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PostStore>();
    final username = context.read<AppProvider>().currentUser?.username ?? '';
    final list = store.notificationsFor(username);

    return Scaffold(
      appBar: HeaderAppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: list.isEmpty ? null : () => store.markAllRead(username),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: list.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 56,
                    color: AppTheme.brand(context),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'No notifications yet',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final n = list[i];
                return ListTile(
                  leading: Icon(
                    n.read
                        ? Icons.notifications_none_rounded
                        : Icons.notifications_active_rounded,
                    color: AppTheme.brand(context),
                  ),
                  title: Text(
                    n.message,
                    style: TextStyle(
                      fontWeight: n.read ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    fmtDateTime(n.sentAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.muted(context),
                    ),
                  ),
                  onTap: () {
                    store.markRead(n);
                    final post = n.postId == null
                        ? null
                        : store.postById(n.postId!);
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => post == null
                            ? const CommunicationPage()
                            : PostChatPage(post: post),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
