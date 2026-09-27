import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/widgets/centered_panel.dart';
import 'package:find_your_match/core/widgets/empty_state.dart';
import 'package:find_your_match/core/widgets/interest_wrap.dart';
import 'package:find_your_match/core/widgets/person_avatar.dart';
import 'package:find_your_match/core/widgets/sample_banner.dart';
import 'package:find_your_match/features/preview/preview_models.dart';
import 'package:find_your_match/features/preview/preview_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DiscoverPage extends ConsumerWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(previewControllerProvider);
    final queue = preview.discoverQueue;
    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: CenteredPanel(
        child: Column(
          children: [
            const SampleBanner(),
            if (preview.hidden)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text('Your profile is hidden in this preview.'),
              ),
            Expanded(
              child: queue.isEmpty
                  ? EmptyState(
                      icon: Icons.explore_outlined,
                      title: 'No sample profiles left',
                      message:
                          'You have liked or passed the layout profiles. Review them again, or open Search.',
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: _DiscoverCard(person: queue.first),
                    ),
            ),
            if (queue.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(previewControllerProvider.notifier).resetDeck();
                  },
                  child: const Text('Review sample profiles again'),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ref
                              .read(previewControllerProvider.notifier)
                              .pass(queue.first.id);
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Pass'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('discover-like'),
                        onPressed: () {
                          final matched = ref
                              .read(previewControllerProvider.notifier)
                              .like(queue.first.id);
                          if (matched && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Sample match with ${queue.first.displayName}.',
                                ),
                              ),
                            );
                          }
                        },
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
