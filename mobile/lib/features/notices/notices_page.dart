import 'package:find_your_match/features/ads/external_link.dart';
import 'package:find_your_match/core/api/match_api.dart';
import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/session/session_controller.dart';
import 'package:find_your_match/core/widgets/empty_state.dart';
import 'package:find_your_match/features/profile/account_failure.dart';
import 'package:find_your_match/features/social/social_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NoticeState {
  const NoticeState({this.notices = const [], this.loaded = false});

  final List<AppNotice> notices;
  final bool loaded;

  int get unread => notices.where((notice) => !notice.read).length;
}

class NoticeController extends Notifier<NoticeState> {
  @override
  NoticeState build() => const NoticeState();

  Future<void> refresh() async {
    if (ref.read(socialSeedProvider) != null) {
      state = const NoticeState(loaded: true);
      return;
    }
    try {
      final notices = await ref.read(matchApiProvider).notices();
      state = NoticeState(notices: notices, loaded: true);
    } on AccountFailure {
      state = NoticeState(notices: state.notices, loaded: true);
    }
  }

  Future<void> markRead(String id) async {
    final current = state.notices.where((notice) => notice.id == id && !notice.read);
    if (current.isEmpty) return;
    try {
      await ref.read(matchApiProvider).readNotice(id);
    } on AccountFailure {
      return;
    }
    state = NoticeState(
      loaded: true,
      notices: [
        for (final notice in state.notices)
          if (notice.id == id) notice.copyWith(read: true) else notice,
      ],
    );
  }
}

final noticeControllerProvider = NotifierProvider<NoticeController, NoticeState>(
  NoticeController.new,
);

class UnreadNoticeBanner extends ConsumerWidget {
  const UnreadNoticeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref
        .watch(noticeControllerProvider)
        .notices
        .where((notice) => !notice.read);
    if (unread.isEmpty) return const SizedBox.shrink();
    final latest = unread.first;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          leading: Icon(
            Icons.notifications_outlined,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          title: Text(latest.title),
          subtitle: Text(latest.body, maxLines: 2, overflow: TextOverflow.ellipsis),
          onTap: () => context.push(AppRoutes.notices),
        ),
      ),
    );
  }
}

class NoticesPage extends ConsumerStatefulWidget {
  const NoticesPage({super.key});

  @override
  ConsumerState<NoticesPage> createState() => _NoticesPageState();
}

class _NoticesPageState extends ConsumerState<NoticesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(noticeControllerProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(noticeControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: !state.loaded
          ? const Center(child: CircularProgressIndicator())
          : state.notices.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none,
              title: 'No notifications',
              message: 'Messages and links from the app show up here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: state.notices.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notice = state.notices[index];
                return _NoticeCard(
                  notice: notice,
                  onRead: () => ref
                      .read(noticeControllerProvider.notifier)
                      .markRead(notice.id),
                );
              },
            ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice, required this.onRead});

  final AppNotice notice;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canOpen = externalHttpUri(notice.linkUrl) != null;
    return Card(
      child: InkWell(
        onTap: onRead,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notice.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: notice.read ? FontWeight.w600 : FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(notice.body, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 8),
              Text(
                notice.timeLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (canOpen) ...[
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () {
                    onRead();
                    openExternalLink(notice.linkUrl);
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open link'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
