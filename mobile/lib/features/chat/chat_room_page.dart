import 'dart:async';

import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/features/preview/preview_models.dart';
import 'package:find_your_match/features/profile/account_failure.dart';
import 'package:find_your_match/features/social/social_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ChatRoomPage extends ConsumerStatefulWidget {
  const ChatRoomPage({required this.userId, super.key});

  final String userId;

  @override
  ConsumerState<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends ConsumerState<ChatRoomPage> {
  final _text = TextEditingController();
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final social = ref.read(socialControllerProvider.notifier);
      social.openChat(widget.userId);
      if (ref.read(socialSeedProvider) != null) return;
      _refresh = Timer.periodic(const Duration(seconds: 4), (_) {
        social.refreshMessages(widget.userId);
      });
    });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _text.text;
    _text.clear();
    try {
      await ref
          .read(socialControllerProvider.notifier)
          .sendMessage(widget.userId, text);
    } on AccountFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final social = ref.watch(socialControllerProvider);
    final person = social.personById(widget.userId);
    final theme = Theme.of(context);
    final blocked = social.blocked.any((item) => item.id == widget.userId);
    if (person == null || blocked || !social.isMatched(widget.userId)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Chat is available after a match, and closes when someone is blocked.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    final messages = social.messages[person.id] ?? const <ChatMessage>[];
    return Scaffold(
      appBar: AppBar(
        title: Text(person.displayName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'profile') {
                context.push(AppRoutes.person(person.id));
              } else if (value == 'report') {
                context.push(AppRoutes.report(person.id));
              } else if (value == 'block') {
                try {
                  await ref
                      .read(socialControllerProvider.notifier)
                      .block(person.id);
                  if (context.mounted) context.pop();
                } on AccountFailure catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error.message)),
                  );
                }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'profile', child: Text('View profile')),
              PopupMenuItem(value: 'report', child: Text('Report')),
              PopupMenuItem(value: 'block', child: Text('Block')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[messages.length - 1 - index];
                final mine = message.fromMe;
                return Align(
                  alignment: mine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    constraints: const BoxConstraints(maxWidth: 320),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: mine
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: mine
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message.timeLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: mine
                                ? theme.colorScheme.onPrimary.withValues(
                                    alpha: 0.8,
                                  )
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('chat-input'),
                      controller: _text,
                      textInputAction: TextInputAction.send,
                      decoration: const InputDecoration(
                        hintText: 'Write a message',
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Send',
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
