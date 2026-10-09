import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/widgets/interest_wrap.dart';
import 'package:find_your_match/core/widgets/person_avatar.dart';
import 'package:find_your_match/core/widgets/primary_button.dart';
import 'package:find_your_match/features/profile/account_failure.dart';
import 'package:find_your_match/features/social/social_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class UserDetailsPage extends ConsumerWidget {
  const UserDetailsPage({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final social = ref.watch(socialControllerProvider);
    final person = social.personById(userId);
    if (person == null || social.blocked.any((item) => item.id == userId)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('This profile is not available.')),
      );
    }
    final theme = Theme.of(context);
    final matched = social.isMatched(person.id);
    return Scaffold(
      appBar: AppBar(title: Text(person.displayName)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
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
          if (person.online || person.lastActive.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              person.online ? 'Online' : person.lastActive,
              style: theme.textTheme.bodyMedium,
            ),
          ],
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
          if (matched) ...[
            PrimaryButton(
              label: 'Open chat',
              onPressed: () => context.push(AppRoutes.conversation(person.id)),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const Key('unmatch-user'),
              onPressed: () =>
                  _confirmUnmatch(context, ref, person.displayName, person.id),
              child: const Text('Unmatch'),
            ),
          ] else
            _LikeButton(personId: person.id),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('block-user'),
                  onPressed: () => _confirmBlock(
                    context,
                    ref,
                    person.displayName,
                    person.id,
                  ),
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

  Future<void> _confirmUnmatch(
    BuildContext context,
    WidgetRef ref,
    String name,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Unmatch $name?'),
          content: const Text(
            'The match and its chat are removed for both of you. You can see this profile in Discover again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Unmatch'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(socialControllerProvider.notifier).unmatch(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Match removed.')));
      context.pop();
    } on AccountFailure catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
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
            'They leave Discover, Search, Matches, and Chat. You can unblock them from Settings.',
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
    try {
      await ref.read(socialControllerProvider.notifier).block(id);
      if (context.mounted) context.pop();
    } on AccountFailure catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _LikeButton extends ConsumerStatefulWidget {
  const _LikeButton({required this.personId});

  final String personId;

  @override
  ConsumerState<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends ConsumerState<_LikeButton> {
  var _busy = false;

  Future<void> _like() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final created = await ref
          .read(socialControllerProvider.notifier)
          .like(widget.personId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(created ? 'It is a match.' : 'Like sent.')),
      );
    } on AccountFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      label: _busy ? 'Sending…' : 'Like',
      onPressed: _busy ? null : _like,
    );
  }
}
