import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/theme/app_colors.dart';
import 'package:find_your_match/core/theme/app_tokens.dart';
import 'package:find_your_match/core/widgets/centered_panel.dart';
import 'package:find_your_match/core/widgets/empty_state.dart';
import 'package:find_your_match/core/widgets/person_avatar.dart';
import 'package:find_your_match/core/widgets/verified_badge.dart';
import 'package:find_your_match/features/ads/smart_banner_ad.dart';
import 'package:find_your_match/features/preview/preview_models.dart';
import 'package:find_your_match/features/profile/account_failure.dart';
import 'package:find_your_match/features/social/social_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

int _activeFilterCount(SearchFilter filter) {
  var count = 0;
  if (filter.minAge != 18 || filter.maxAge != 45) count++;
  if (filter.gender != null) count++;
  count += filter.interests.length;
  count += filter.preferences.length;
  return count;
}

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
    final theme = Theme.of(context);
    final filterCount = _activeFilterCount(social.filter);

    return Scaffold(
      key: const Key('search-page'),
      body: SafeArea(
        child: CenteredPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.space20,
                  AppTokens.space8,
                  AppTokens.space12,
                  AppTokens.space4,
                ),
                child: Text('Search', style: theme.textTheme.headlineMedium),
              ),
              const SmartBannerAd(placement: 'search'),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.space16,
                  AppTokens.space12,
                  AppTokens.space16,
                  AppTokens.space8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: theme.colorScheme.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppTokens.pill,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search by username or city',
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: AppTokens.space12,
                            ),
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
                                    if (mounted) {
                                      setState(() => _searching = false);
                                    }
                                  }
                                },
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTokens.space8),
                    Material(
                      color: theme.colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTokens.pill,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Tooltip(
                        message: 'Filters',
                        child: InkWell(
                        onTap: () => context.push(AppRoutes.filters),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.space12,
                            vertical: AppTokens.space12,
                          ),
                          child: Badge(
                            isLabelVisible: filterCount > 0,
                            label: Text('$filterCount'),
                            child: Icon(
                              Icons.tune_rounded,
                              color: filterCount > 0
                                  ? AppColors.coral
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      ),
                    ),
                  ],
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
                    : GridView.builder(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(
                          AppTokens.space16,
                          AppTokens.space8,
                          AppTokens.space16,
                          AppTokens.space16,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppTokens.space12,
                          mainAxisSpacing: AppTokens.space12,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final person = results[index];
                          return _SearchPersonCard(person: person);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchPersonCard extends StatelessWidget {
  const _SearchPersonCard({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: AppTokens.lg,
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.person(person.id)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: [
                PersonCover(
                  person: person,
                  height: constraints.maxHeight,
                  borderRadius: BorderRadius.zero,
                  heroTag: 'person-photo-${person.id}',
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${person.displayName}, ${person.age}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (person.verified) ...[
                                const SizedBox(width: 4),
                                const VerifiedBadge(size: 14),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            person.city,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
