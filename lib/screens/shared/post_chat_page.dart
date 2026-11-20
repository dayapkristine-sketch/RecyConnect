import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/recyclable_post.dart';
import '../../providers/app_provider.dart';
import '../../providers/post_store.dart';
import '../../widgets/header_background.dart';

class PostChatPage extends StatefulWidget {
  const PostChatPage({super.key, required this.post, this.recipientUsername});

  final RecyclablePost post;
  final String? recipientUsername;

  @override
  State<PostChatPage> createState() => _PostChatPageState();
}

class _PostChatPageState extends State<PostChatPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final user = context.read<AppProvider>().currentUser;
    if (user == null) return;
    final existing = context.read<PostStore>().messagesFor(
      widget.post.id,
      user.username,
    );
    final fallbackRecipient = existing.reversed
        .map((m) => m.fromUsername)
        .firstWhere((username) => username != user.username, orElse: () => '');
    final error = context.read<PostStore>().sendMessage(
      post: widget.post,
      fromUsername: user.username,
      fromName: user.fullName,
      text: _controller.text,
      recipientUsername:
          widget.recipientUsername ??
          (fallbackRecipient.isEmpty ? null : fallbackRecipient),
    );
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppProvider>().currentUser;
    final username = user?.username ?? '';
    final messages = context.watch<PostStore>().messagesFor(
      widget.post.id,
      username,
    );

    return Scaffold(
      appBar: HeaderAppBar(title: Text('Chat • ${widget.post.material}')),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Text('No messages yet. Start the conversation.'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final message = messages[i];
                      final mine = message.fromUsername == username;
                      return Align(
                        alignment: mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Card(
                          color: mine
                              ? Theme.of(context).colorScheme.primaryContainer
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: mine
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.fromName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(message.text),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Write a message...',
                      ),
                    ),
                  ),
                  IconButton(onPressed: _send, icon: const Icon(Icons.send)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
