import 'package:find_your_match/core/theme/app_tokens.dart';
import 'package:find_your_match/core/widgets/empty_state.dart';
import 'package:find_your_match/core/widgets/person_avatar.dart';
import 'package:find_your_match/features/profile/account_failure.dart';
import 'package:find_your_match/features/social/social_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BlockedUsersPage extends ConsumerWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(socialControllerProvider).blocked;
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked users')),
      body: people.isEmpty
          ? const EmptyState(
              icon: Icons.block,
              title: 'No blocked people',
              message: 'People you block show up here until you unblock them.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppTokens.space16),
              itemCount: people.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppTokens.space8),
              itemBuilder: (context, index) {
                final person = people[index];
                return PersonTile(
                  person: person,
                  subtitle: person.username,
                  trailing: TextButton(
                    onPressed: () async {
                      try {
                        await ref
                            .read(socialControllerProvider.notifier)
                            .unblock(person.id);
                      } on AccountFailure catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.message)),
                        );
                      }
                    },
                    child: const Text('Unblock'),
                  ),
                );
              },
            ),
    );
  }
}
