import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/widgets/centered_panel.dart';
import 'package:find_your_match/core/widgets/empty_state.dart';
import 'package:find_your_match/core/widgets/person_avatar.dart';
import 'package:find_your_match/core/widgets/sample_banner.dart';
import 'package:find_your_match/features/preview/preview_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(previewControllerProvider);
    final results = preview.searchResults;
    return Scaffold(
      key: const Key('search-page'),
      appBar: AppBar(
        title: const Text('Search'),
        actions: [
          IconButton(
            tooltip: 'Filters',
            onPressed: () => context.push(AppRoutes.filters),
            icon: Badge(
              isLabelVisible: preview.filter.isActive,
              child: const Icon(Icons.tune),
            ),
          ),
        ],
      ),
      body: CenteredPanel(
        child: Column(
          children: [
            const SampleBanner(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Search by username or city',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  ref.read(previewControllerProvider.notifier).setQuery(value);
                },
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? const EmptyState(
                      icon: Icons.search_off,
                      title: 'No sample profiles match',
                      message:
                          'Try another username, city, or a wider set of filters.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: results.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final person = results[index];
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          tileColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLowest,
                          leading: PersonAvatar(person: person),
                          title: Text('${person.displayName}, ${person.age}'),
                          subtitle: Text(
                            '${person.username} · ${person.city} · Sample',
                          ),
                          onTap: () => context.push(AppRoutes.person(person.id)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
