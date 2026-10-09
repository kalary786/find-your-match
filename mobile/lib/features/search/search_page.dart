import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/widgets/centered_panel.dart';
import 'package:find_your_match/core/widgets/empty_state.dart';
import 'package:find_your_match/core/widgets/person_avatar.dart';
import 'package:find_your_match/features/ads/placement_ad.dart';
import 'package:find_your_match/features/profile/account_failure.dart';
import 'package:find_your_match/features/social/social_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  var _searching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(socialControllerProvider.notifier).ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final social = ref.watch(socialControllerProvider);
    final results = social.searchResults;
    return Scaffold(
      key: const Key('search-page'),
      appBar: AppBar(
        title: const Text('Search'),
        actions: [
          IconButton(
            tooltip: 'Filters',
            onPressed: () => context.push(AppRoutes.filters),
            icon: Badge(
              isLabelVisible: social.filter.isActive,
              child: const Icon(Icons.tune),
            ),
          ),
        ],
      ),
      body: CenteredPanel(
        child: Column(
          children: [
            const PlacementAd(placement: 'search'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Search by username or city',
                  prefixIcon: Icon(Icons.search),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: _searching
                    ? null
                    : (value) async {
                        setState(() => _searching = true);
                        try {
                          await ref
                              .read(socialControllerProvider.notifier)
                              .search(value);
                        } on AccountFailure catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.message)),
                          );
                        } finally {
                          if (mounted) setState(() => _searching = false);
                        }
                      },
              ),
            ),
            if (_searching) const LinearProgressIndicator(),
            Expanded(
              child: results.isEmpty
                  ? EmptyState(
                      icon: Icons.search,
                      title: _searching ? 'Searching' : 'No people yet',
                      message: _searching
                          ? 'Looking through profiles on your website.'
                          : 'Search by username or city. Results come from profiles on your website.',
                    )
                  : ListView.separated(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: results.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final person = results[index];
                        return PersonTile(
                          person: person,
                          subtitle: '${person.username} · ${person.city}',
                          onTap: () =>
                              context.push(AppRoutes.person(person.id)),
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
