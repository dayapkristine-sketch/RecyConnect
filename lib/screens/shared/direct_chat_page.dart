import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../providers/post_store.dart';

class DirectChatPage extends StatefulWidget {
  const DirectChatPage({
    super.key,
    required this.otherUsername,
    required this.otherName,
  });

  final String otherUsername;
  final String otherName;

  @override
  State<DirectChatPage> createState() => _DirectChatPageState();
}

class _DirectChatPageState extends State<DirectChatPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final user = context.read<AppProvider>().currentUser;
    if (user == null) return;
    final error = context.read<PostStore>().sendDirectMessage(
      fromUsername: user.username,
      fromName: user.fullName,
      toUsername: widget.otherUsername,
      text: _controller.text,
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
    final me = user?.username ?? '';
    final messages = context.watch<PostStore>().directMessagesFor(
      me,
      widget.otherUsername,
    );
    return Scaffold(
      appBar: AppBar(title: Text(widget.otherName)),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text('Start a private conversation.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final message = messages[i];
                      final mine = message.fromUsername == me;
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
                            child: Text(message.text),
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
