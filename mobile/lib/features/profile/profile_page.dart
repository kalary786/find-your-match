import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/widgets/interest_wrap.dart';
import 'package:find_your_match/core/widgets/person_avatar.dart';
import 'package:find_your_match/features/preview/preview_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(previewControllerProvider);
    final person = preview.viewer;
    final theme = Theme.of(context);
    final savedHere = preview.self != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            key: const Key('settings-button'),
            tooltip: 'Settings',
            onPressed: () => context.push(AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          PersonCover(person: person, height: 220),
          const SizedBox(height: 16),
          Text(
            person.displayName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${person.username} · ${person.age} · ${person.city}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            savedHere
                ? 'Saved on this device only. Not written to a database.'
                : 'Sample stand-in until you save a profile on this device.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(person.bio),
          const SizedBox(height: 12),
          InterestWrap(labels: person.interests),
          const SizedBox(height: 8),
          InterestWrap(labels: person.preferences),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Hide profile'),
            subtitle: const Text(
              'Hidden profiles stay out of a future Discover feed. This switch is local.',
            ),
            value: preview.hidden,
            onChanged: (value) {
              ref.read(previewControllerProvider.notifier).setHidden(value);
            },
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => context.push(AppRoutes.editProfile),
            child: const Text('Edit profile'),
          ),
        ],
      ),
    );
  }
}
