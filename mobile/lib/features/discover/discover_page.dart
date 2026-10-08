import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/widgets/centered_panel.dart';
import 'package:find_your_match/core/widgets/empty_state.dart';
import 'package:find_your_match/core/widgets/interest_wrap.dart';
import 'package:find_your_match/core/widgets/person_avatar.dart';
import 'package:find_your_match/features/ads/placement_ad.dart';
import 'package:find_your_match/features/notices/notices_page.dart';
import 'package:find_your_match/features/preview/preview_models.dart';
import 'package:find_your_match/features/profile/account_failure.dart';
import 'package:find_your_match/features/profile/saved_account.dart';
import 'package:find_your_match/features/social/social_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(socialControllerProvider.notifier).ensureLoaded();
      ref.read(noticeControllerProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final social = ref.watch(socialControllerProvider);
    final hidden = ref.watch(savedAccountProvider)?.hidden ?? false;
    final queue = social.discover;
    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: CenteredPanel(
        child: Column(
          children: [
            const PlacementAd(placement: 'discover'),
            const UnreadNoticeBanner(),
            if (hidden)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  'Your profile is hidden. Other people cannot find you until you show it again.',
                ),
              ),
            Expanded(
              child: social.loading && queue.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : queue.isEmpty
                  ? EmptyState(
                      icon: Icons.explore_outlined,
                      title: social.error == null
                          ? 'No profiles left'
                          : 'Could not load profiles',
                      message: social.error ??
                          'New people will show up here when they join. You can also open Search.',
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: _DiscoverCard(person: queue.first),
                    ),
            ),
            if (queue.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pass(queue.first.id),
                        icon: const Icon(Icons.close),
                        label: const Text('Pass'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('discover-like'),
                        onPressed: () => _like(queue.first),
                        icon: const Icon(Icons.favorite),
                        label: const Text('Like'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pass(String id) async {
    try {
      await ref.read(socialControllerProvider.notifier).pass(id);
    } on AccountFailure catch (error) {
      _show(error.message);
    }
  }

  Future<void> _like(Person person) async {
    try {
      final matched = await ref
          .read(socialControllerProvider.notifier)
          .like(person.id);
      if (matched && mounted) {
        _show('You matched with ${person.displayName}.');
      }
    } on AccountFailure catch (error) {
      _show(error.message);
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _DiscoverCard extends StatelessWidget {
  const _DiscoverCard({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final coverHeight = (constraints.maxHeight * 0.52).clamp(160, 360);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                key: const Key('discover-card'),
                onTap: () => context.push(AppRoutes.person(person.id)),
                child: PersonCover(
                  person: person,
                  height: coverHeight.toDouble(),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${person.displayName}, ${person.age}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${person.username} · ${person.city}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      InterestWrap(labels: person.interests),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
