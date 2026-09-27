import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/widgets/sample_banner.dart';
import 'package:find_your_match/features/preview/preview_models.dart';
import 'package:find_your_match/features/preview/preview_store.dart';
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

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send() {
    ref.read(previewControllerProvider.notifier).sendMessage(
      widget.userId,
      _text.text,
    );
    _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    final preview = ref.watch(previewControllerProvider);
    final person = preview.personById(widget.userId);
    final theme = Theme.of(context);
    if (person == null ||
        preview.blockedIds.contains(widget.userId) ||
        !preview.isMatched(widget.userId)) {
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
    final messages = preview.messages[person.id] ?? const <PreviewMessage>[];
    return Scaffold(
      appBar: AppBar(
        title: Text(person.displayName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                context.push(AppRoutes.person(person.id));
              } else if (value == 'report') {
                context.push(AppRoutes.report(person.id));
              } else if (value == 'block') {
                ref.read(previewControllerProvider.notifier).block(person.id);
                context.pop();
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
          const SampleBanner(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final mine = message.fromMe;
                return Align(
                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
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
                                ? theme.colorScheme.onPrimary.withValues(alpha: 0.8)
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
