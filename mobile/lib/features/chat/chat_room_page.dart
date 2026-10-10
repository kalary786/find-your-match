import 'dart:async';

import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/features/ads/network_ad_controller.dart';
import 'package:find_your_match/features/ads/network_banner.dart';
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
    final bannerAtTop = ref
        .watch(networkAdControllerProvider)
        .settings
        .bannerAtTop;
    const chatBanner = NetworkBanner(inChat: true);
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
          if (bannerAtTop) chatBanner,
          Expanded(
            child: ListView.builder(
              controller: _scroll,
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
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                    ),
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
          if (!bannerAtTop) chatBanner,
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
                      maxLength: 1000,
                      buildCounter:
                          (
                            context, {
                            required int currentLength,
                            required bool isFocused,
                            int? maxLength,
                          }) => null,
                      decoration: const InputDecoration(
                        hintText: 'Write a message · 100 a day',
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Send',
                    onPressed: _sending ? null : _send,
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
