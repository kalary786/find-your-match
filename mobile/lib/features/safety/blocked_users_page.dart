import 'package:find_your_match/core/widgets/empty_state.dart';
import 'package:find_your_match/core/widgets/person_avatar.dart';
import 'package:find_your_match/features/preview/preview_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BlockedUsersPage extends ConsumerWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(previewControllerProvider).blockedPeople;
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked users')),
      body: people.isEmpty
          ? const EmptyState(
              icon: Icons.block,
              title: 'No blocked people',
              message:
                  'When you block a sample profile, they show up here until you unblock them.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: people.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final person = people[index];
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tileColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerLowest,
                  leading: PersonAvatar(person: person),
                  title: Text(person.displayName),
                  subtitle: Text(person.username),
                  trailing: TextButton(
                    onPressed: () {
                      ref
                          .read(previewControllerProvider.notifier)
                          .unblock(person.id);
                    },
                    child: const Text('Unblock'),
                  ),
                );
              },
            ),
    );
  }
}
