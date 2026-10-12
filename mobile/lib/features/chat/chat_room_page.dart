import 'dart:async';

import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/theme/app_colors.dart';
import 'package:find_your_match/core/widgets/person_avatar.dart';
import 'package:find_your_match/features/ads/network_ad_controller.dart';
import 'package:find_your_match/features/ads/network_banner.dart';
import 'package:find_your_match/features/chat/widgets/chat_composer.dart';
import 'package:find_your_match/features/chat/widgets/message_bubble.dart';
import 'package:find_your_match/features/preview/preview_models.dart';
import 'package:find_your_match/features/profile/account_failure.dart';
import 'package:find_your_match/features/social/social_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

bool shouldPollChat({
  required bool foreground,
  required bool routeCurrent,
  required bool matched,
  required bool blocked,
}) {
  return foreground && routeCurrent && matched && !blocked;
}

class ChatRoomPage extends ConsumerStatefulWidget {
  const ChatRoomPage({required this.userId, super.key});

  final String userId;

  @override
  ConsumerState<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends ConsumerState<ChatRoomPage>
    with WidgetsBindingObserver {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  Timer? _refresh;
  var _sending = false;
  var _foreground = true;
  final _seenIds = <String>{};
  var _seededSeen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scroll.addListener(_loadOlderIfNeeded);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final social = ref.read(socialControllerProvider.notifier);
      social.openChat(widget.userId);
      if (ref.read(socialSeedProvider) != null) return;
      _refresh = Timer.periodic(const Duration(seconds: 4), (_) => _poll());
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
    if (!mounted) return;
    final social = ref.read(socialControllerProvider);
    final routeCurrent = ModalRoute.of(context)?.isCurrent ?? true;
    if (!shouldPollChat(
      foreground: _foreground,
      routeCurrent: routeCurrent,
      matched: social.isMatched(widget.userId),
      blocked: social.blocked.any((item) => item.id == widget.userId),
    )) {
      return;
    }
    ref.read(socialControllerProvider.notifier).refreshMessages(widget.userId);
  }

  void _loadOlderIfNeeded() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.maxScrollExtent <= 0) return;
    if (position.pixels < position.maxScrollExtent - 80) return;
    ref.read(socialControllerProvider.notifier).loadOlderMessages(widget.userId);
  }

  @override
  void dispose() {
    _refresh?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _scroll.removeListener(_loadOlderIfNeeded);
    _scroll.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _text.clear();
    try {
      await ref
          .read(socialControllerProvider.notifier)
          .sendMessage(widget.userId, text);
      ref.read(networkAdControllerProvider.notifier).onMessageSent();
    } on AccountFailure catch (error) {
      if (!mounted) return;
      _text.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _seedHello(Person person) {
    final firstName = person.displayName.split(' ').first;
    _text.text = 'Hi $firstName! 👋';
    _text.selection = TextSelection.collapsed(offset: _text.text.length);
  }

  void _rememberMessages(List<ChatMessage> messages) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final hasNew = messages.any((m) => !_seenIds.contains(m.id));
      if (!_seededSeen || hasNew) {
        _seenIds.addAll(messages.map((m) => m.id));
        _seededSeen = true;
      }
    });
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
    _rememberMessages(messages);
    final bannerAtTop = ref
        .watch(networkAdControllerProvider)
        .settings
        .bannerAtTop;
    const chatBanner = NetworkBanner(inChat: true);
    final muted = theme.colorScheme.onSurfaceVariant;
    final line = AppColors.lineOf(theme.brightness);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: () => context.push(AppRoutes.person(person.id)),
          child: Row(
            children: [
              PersonAvatar(person: person, size: 40, showOnline: true),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            person.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (person.verified) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      person.online ? 'Online' : person.lastActive,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: person.online ? AppColors.online : muted,
                        fontWeight:
                            person.online ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: ColoredBox(
            color: line,
            child: const SizedBox(height: 1, width: double.infinity),
          ),
        ),
      ),
      body: Column(
        children: [
          if (bannerAtTop) chatBanner,
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PersonAvatar(person: person, size: 72),
                          const SizedBox(height: 16),
                          Text(
                            'You matched with ${person.displayName}',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => _seedHello(person),
                            child: Text(
                              'Say hello 👋',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final chronologicalIndex = messages.length - 1 - index;
                      final message = messages[chronologicalIndex];
                      final isNew =
                          _seededSeen && !_seenIds.contains(message.id);
                      final position = bubbleGroupPosition(
                        messages: messages,
                        index: chronologicalIndex,
                      );
                      final spacing = bubbleBottomSpacing(
                        messages: messages,
                        index: chronologicalIndex,
                      );
                      return Padding(
                        padding: EdgeInsets.only(bottom: spacing),
                        child: MessageBubble(
                          message: message,
                          position: position,
                          animateIn: isNew,
                        ),
                      );
                    },
                  ),
          ),
          if (!bannerAtTop) chatBanner,
          ChatComposer(
            controller: _text,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}
