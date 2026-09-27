import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/widgets/interest_wrap.dart';
import 'package:find_your_match/core/widgets/person_avatar.dart';
import 'package:find_your_match/core/widgets/primary_button.dart';
import 'package:find_your_match/core/widgets/sample_banner.dart';
import 'package:find_your_match/features/preview/preview_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class UserDetailsPage extends ConsumerWidget {
  const UserDetailsPage({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(previewControllerProvider);
    final person = preview.personById(userId);
    if (person == null || preview.blockedIds.contains(userId)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('This sample profile is not available.')),
      );
    }
    final theme = Theme.of(context);
    final matched = preview.isMatched(person.id);
    final liked = preview.likedIds.contains(person.id);
    return Scaffold(
      appBar: AppBar(title: Text(person.displayName)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const SampleBanner(),
          const SizedBox(height: 12),
          PersonCover(person: person, height: 320),
          const SizedBox(height: 16),
          Text(
            '${person.displayName}, ${person.age}',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${person.username} · ${person.city} · ${person.gender}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            person.online ? 'Sample status: online' : 'Sample status: ${person.lastActive}',
            style: theme.textTheme.bodyMedium,
          ),
          if (person.verified)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Layout badge only. This is not an identity check.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(person.bio, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          Text('Interests', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          InterestWrap(labels: person.interests),
          const SizedBox(height: 16),
          Text('Looking for', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          InterestWrap(labels: person.preferences),
          const SizedBox(height: 24),
          if (matched)
            PrimaryButton(
              label: 'Open chat',
              onPressed: () => context.push(AppRoutes.conversation(person.id)),
            )
          else if (!liked)
            PrimaryButton(
              label: 'Like',
              onPressed: () {
                final created = ref
                    .read(previewControllerProvider.notifier)
                    .like(person.id);
                if (created && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sample match created.')),
                  );
                }
              },
            )
          else
            const PrimaryButton(label: 'Liked', onPressed: null),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('block-user'),
                  onPressed: () => _confirmBlock(context, ref, person.displayName, person.id),
                  child: const Text('Block'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  key: const Key('report-user'),
                  onPressed: () => context.push(AppRoutes.report(person.id)),
                  child: const Text('Report'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmBlock(
    BuildContext context,
    WidgetRef ref,
    String name,
    String id,
  ) async {
    final blocked = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Block $name?'),
          content: const Text(
            'They leave Discover, Search, Matches, and Chat in this preview. You can unblock them from Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Block'),
            ),
          ],
        );
      },
    );
    if (blocked != true || !context.mounted) return;
    ref.read(previewControllerProvider.notifier).block(id);
    context.pop();
  }
}
