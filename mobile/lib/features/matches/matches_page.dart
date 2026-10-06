import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/widgets/empty_state.dart';
import 'package:find_your_match/core/widgets/person_avatar.dart';
import 'package:find_your_match/features/ads/placement_ad.dart';
import 'package:find_your_match/features/social/social_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MatchesPage extends ConsumerWidget {
  const MatchesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(socialControllerProvider).matches;
    return Scaffold(
      appBar: AppBar(title: const Text('Matches')),
      body: Column(
        children: [
          const PlacementAd(placement: 'matches'),
          Expanded(
            child: matches.isEmpty
                ? const EmptyState(
                    icon: Icons.favorite_outline,
                    title: 'No matches yet',
                    message:
                        'A match appears here when you both like each other.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: matches.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final person = matches[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        tileColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLowest,
                        leading: PersonAvatar(person: person),
                        title: Text(person.displayName),
                        subtitle: Text('${person.age} · ${person.city}'),
                        trailing: IconButton(
                          tooltip: 'Chat',
                          onPressed: () =>
                              context.push(AppRoutes.conversation(person.id)),
                          icon: const Icon(Icons.chat_bubble_outline),
                        ),
                        onTap: () => context.push(AppRoutes.person(person.id)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
