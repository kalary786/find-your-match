import 'dart:async';

import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/theme/app_colors.dart';
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
  String _query = '';

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
    final theme = Theme.of(context);
    final chats = ref.watch(socialControllerProvider).chats;
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? chats
        : chats
            .where(
              (chat) =>
                  chat.person.displayName.toLowerCase().contains(query),
            )
            .toList();
    final newMatches = filtered
        .where((chat) => chat.lastMessage.isEmpty)
        .toList();
    final muted = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      key: const Key('chats-page'),
      body: SafeArea(
        child: chats.isEmpty
            ? const EmptyState(
                icon: Icons.chat_bubble_outline,
                title: 'No conversations yet',
                message:
                    'Text chat opens after a mutual match. This screen does not show ads.',
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                    child: Text(
                      'Chats',
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                    child: TextField(
                      onChanged: (value) => setState(() => _query = value),
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: 'Search',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                    ),
                  ),
                  if (newMatches.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                      child: Text(
                        'New matches',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: muted,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 92,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        itemCount: newMatches.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final chat = newMatches[index];
                          final firstName =
                              chat.person.displayName.split(' ').first;
                          return InkWell(
                            onTap: () => context.push(
                              AppRoutes.conversation(chat.person.id),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 68,
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2.5),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: AppColors.brandGradient,
                                    ),
                                    child: PersonAvatar(
                                      person: chat.person,
                                      size: 60,
                                      showOnline: true,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    firstName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
                    child: Text(
                      'MESSAGES',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: muted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              'No chats match your search',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: muted,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final chat = filtered[index];
                              final last = chat.lastMessage.isEmpty
                                  ? 'Say hello 👋'
                                  : chat.lastMessage;
                              return InkWell(
                                onTap: () => context.push(
                                  AppRoutes.conversation(chat.person.id),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      PersonAvatar(
                                        person: chat.person,
                                        size: 52,
                                        showOnline: true,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    chat.person.displayName,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: theme
                                                        .textTheme
                                                        .titleMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                  ),
                                                ),
                                                if (chat.person.verified) ...[
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    Icons.verified,
                                                    size: 16,
                                                    color: theme
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              last,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(color: muted),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
