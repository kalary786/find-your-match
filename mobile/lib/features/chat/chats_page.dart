import 'dart:async';

import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/widgets/empty_state.dart';
import 'package:find_your_match/core/widgets/person_avatar.dart';
import 'package:find_your_match/features/social/social_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ChatsPage extends ConsumerStatefulWidget {
  const ChatsPage({super.key});

  @override
  ConsumerState<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends ConsumerState<ChatsPage>
    with WidgetsBindingObserver {
  Timer? _refresh;
  var _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final social = ref.read(socialControllerProvider.notifier);
      social.refreshInbox();
      if (ref.read(socialSeedProvider) != null) return;
      _refresh = Timer.periodic(const Duration(seconds: 8), (_) => _poll());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (_foreground == foreground) return;
    _foreground = foreground;
    if (foreground) _poll();
  }

  void _poll() {
    if (!mounted || !_foreground) return;
    ref.read(socialControllerProvider.notifier).refreshInbox();
  }

  @override
  void dispose() {
    _refresh?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                return PersonTile(
                  person: chat.person,
                  subtitle: last,
                  onTap: () =>
                      context.push(AppRoutes.conversation(chat.person.id)),
                );
              },
            ),
    );
  }
}
