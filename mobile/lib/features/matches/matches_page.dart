import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/theme/app_tokens.dart';
import 'package:find_your_match/core/widgets/empty_state.dart';
import 'package:find_your_match/core/widgets/person_avatar.dart';
import 'package:find_your_match/core/widgets/section_header.dart';
import 'package:find_your_match/core/widgets/verified_badge.dart';
import 'package:find_your_match/features/ads/placement_ad.dart';
import 'package:find_your_match/features/preview/preview_models.dart';
import 'package:find_your_match/features/social/social_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MatchesPage extends ConsumerWidget {
  const MatchesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(socialControllerProvider).matches;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.space20,
                AppTokens.space8,
                AppTokens.space20,
                AppTokens.space4,
              ),
              child: Text('Matches', style: theme.textTheme.headlineMedium),
            ),
            const PlacementAd(placement: 'matches'),
            Expanded(
              child: matches.isEmpty
                  ? const EmptyState(
                      icon: Icons.favorite_outline,
                      title: 'No matches yet',
                      message:
                          'A match appears here when you both like each other.',
                    )
                  : CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SectionHeader('New matches'),
                              SizedBox(
                                height: 108,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTokens.space16,
                                  ),
                                  itemCount: matches.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(width: AppTokens.space12),
                                  itemBuilder: (context, index) {
                                    final person = matches[index];
                                    return _NewMatchAvatar(person: person);
                                  },
                                ),
                              ),
                              const SizedBox(height: AppTokens.space8),
                            ],
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(
                            AppTokens.space16,
                            AppTokens.space8,
                            AppTokens.space16,
                            AppTokens.space16,
                          ),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: AppTokens.space12,
                              mainAxisSpacing: AppTokens.space12,
                              childAspectRatio: 0.72,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final person = matches[index];
                                return _MatchPhotoCard(person: person);
                              },
                              childCount: matches.length,
                            ),
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

class _NewMatchAvatar extends StatelessWidget {
  const _NewMatchAvatar({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => context.push(AppRoutes.person(person.id)),
      borderRadius: AppTokens.md,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            PersonAvatar(
              person: person,
              size: 64,
              storyRing: true,
              showOnline: true,
              heroTag: 'match-avatar-${person.id}',
            ),
            const SizedBox(height: AppTokens.space4),
            Text(
              person.displayName.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchPhotoCard extends StatelessWidget {
  const _MatchPhotoCard({required this.person});

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
      child: Stack(
        fit: StackFit.expand,
        children: [
          InkWell(
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
                          child: Row(
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
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            top: AppTokens.space8,
            right: AppTokens.space8,
            child: Material(
              color: Colors.white.withValues(alpha: 0.92),
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () =>
                    context.push(AppRoutes.conversation(person.id)),
                child: const Padding(
                  padding: EdgeInsets.all(AppTokens.space8),
                  child: Icon(
                    Icons.chat_bubble_rounded,
                    size: 20,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
