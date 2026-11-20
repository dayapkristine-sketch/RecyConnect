import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../providers/post_store.dart';
import '../../widgets/header_background.dart';
import 'direct_chat_page.dart';
import 'post_chat_page.dart';

class CommunicationPage extends StatelessWidget {
  const CommunicationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser;
    final store = context.watch<PostStore>();
    final username = user?.username ?? '';
    final posts = store
        .postsForUser(username)
        .where((p) => store.messagesFor(p.id, username).isNotEmpty)
        .toList();
    final contacts = store.directContactsFor(username).toList();

    return Scaffold(
      appBar: const HeaderAppBar(title: Text('Communication')),
      body: posts.isEmpty && contacts.isEmpty
          ? const Center(
              child: Text('Your messages and conversations will appear here.'),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (posts.isNotEmpty) ...[
                  const Text(
                    'Post conversations',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...posts.map(
                    (post) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.forum_outlined),
                        title: Text('${post.material} • ${post.quantityLabel}'),
                        subtitle: Text(
                          '${store.messagesFor(post.id, username).length} messages',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PostChatPage(post: post),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (contacts.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Direct conversations',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...contacts.map((contact) {
                    final other = context.read<AppProvider>().userByUsername(
                      contact,
                    );
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(other?.fullName ?? contact),
                        subtitle: const Text('Private conversation'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DirectChatPage(
                              otherUsername: contact,
                              otherName: other?.fullName ?? contact,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
    );
  }
}
