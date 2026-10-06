import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/widgets/empty_state.dart';
import 'package:find_your_match/core/widgets/person_avatar.dart';
import 'package:find_your_match/features/social/social_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ChatsPage extends ConsumerWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(socialControllerProvider).chats;
    return Scaffold(
      key: const Key('chats-page'),
      appBar: AppBar(title: const Text('Chats')),
      body: chats.isEmpty
          ? const EmptyState(
              icon: Icons.chat_bubble_outline,
              title: 'No conversations yet',
              message:
                  'Text chat opens after a mutual match. This screen does not show ads.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: chats.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final chat = chats[index];
                final last = chat.lastMessage.isEmpty
                    ? 'Say hello'
                    : chat.lastMessage;
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tileColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerLowest,
                  leading: PersonAvatar(person: chat.person),
                  title: Text(chat.person.displayName),
                  subtitle: Text(
                    last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () =>
                      context.push(AppRoutes.conversation(chat.person.id)),
                );
              },
            ),
    );
  }
}
