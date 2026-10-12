import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/theme/app_tokens.dart';
import 'package:find_your_match/core/widgets/gradient_button.dart';
import 'package:find_your_match/core/widgets/interest_wrap.dart';
import 'package:find_your_match/core/widgets/person_avatar.dart';
import 'package:find_your_match/core/widgets/section_header.dart';
import 'package:find_your_match/core/widgets/verified_badge.dart';
import 'package:find_your_match/features/profile/account_failure.dart';
import 'package:find_your_match/features/preview/preview_models.dart';
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
    final matched = social.isMatched(person.id);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 420,
            pinned: true,
            stretch: true,
            actions: [
              IconButton(
                tooltip: 'More',
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showActionsSheet(
                  context,
                  ref,
                  person,
                  matched: matched,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PersonCover(
                    person: person,
                    height: 420,
                    borderRadius: BorderRadius.zero,
                    heroTag: 'person-photo-${person.id}',
                  ),
                  Positioned(
                    left: AppTokens.space20,
                    right: AppTokens.space20,
                    bottom: AppTokens.space20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${person.displayName}, ${person.age}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      shadows: const [
                                        Shadow(
                                          blurRadius: 12,
                                          color: Color(0x99000000),
                                        ),
                                      ],
                                    ),
                              ),
                            ),
                            if (person.verified) ...[
                              const SizedBox(width: 6),
                              const VerifiedBadge(size: 22),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${person.username} · ${person.city}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                                shadows: const [
                                  Shadow(
                                    blurRadius: 8,
                                    color: Color(0x99000000),
                                  ),
                                ],
                              ),
                        ),
                        if (person.online || person.lastActive.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            person.online ? 'Online' : person.lastActive,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space20,
              AppTokens.space8,
              AppTokens.space20,
              100,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _DetailCard(
                  title: 'About',
                  child: Text(
                    person.bio.isEmpty ? 'No bio yet.' : person.bio,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.space12),
                _DetailCard(
                  title: 'Interests',
                  child: person.interests.isEmpty
                      ? Text(
                          'No interests listed.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        )
                      : InterestWrap(labels: person.interests),
                ),
                const SizedBox(height: AppTokens.space12),
                _DetailCard(
                  title: 'Looking for',
                  child: person.preferences.isEmpty
                      ? Text(
                          'No preferences listed.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        )
                      : InterestWrap(labels: person.preferences),
                ),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppTokens.space20,
          AppTokens.space8,
          AppTokens.space20,
          AppTokens.space16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            matched
                ? GradientButton(
                    label: 'Message',
                    icon: Icons.chat_bubble_outline,
                    onPressed: () =>
                        context.push(AppRoutes.conversation(person.id)),
                  )
                : _LikeButton(personId: person.id),
            const SizedBox(height: AppTokens.space8),
            if (matched) ...[
              OutlinedButton(
                key: const Key('unmatch-user'),
                onPressed: () => _confirmUnmatch(
                  context,
                  ref,
                  person.displayName,
                  person.id,
                ),
                child: const Text('Unmatch'),
              ),
              const SizedBox(height: AppTokens.space8),
            ],
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
                const SizedBox(width: AppTokens.space12),
                Expanded(
                  child: OutlinedButton(
                    key: const Key('report-user'),
                    onPressed: () =>
                        context.push(AppRoutes.report(person.id)),
                    child: const Text('Report'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showActionsSheet(
    BuildContext context,
    WidgetRef ref,
    Person person, {
    required bool matched,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: AppTokens.xl),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (matched)
                ListTile(
                  key: const Key('unmatch-user'),
                  leading: const Icon(Icons.heart_broken_outlined),
                  title: const Text('Unmatch'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _confirmUnmatch(
                      context,
                      ref,
                      person.displayName,
                      person.id,
                    );
                  },
                ),
              ListTile(
                key: const Key('block-user'),
                leading: const Icon(Icons.block_outlined),
                title: const Text('Block'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmBlock(context, ref, person.displayName, person.id);
                },
              ),
              ListTile(
                key: const Key('report-user'),
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Report'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push(AppRoutes.report(person.id));
                },
              ),
              const SizedBox(height: AppTokens.space8),
            ],
          ),
        );
      },
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

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: AppTokens.lg,
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title),
            child,
          ],
        ),
      ),
    );
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
    return GradientButton(
      label: _busy ? 'Sending…' : 'Like',
      icon: Icons.favorite_outline,
      loading: _busy,
      onPressed: _busy ? null : _like,
    );
  }
}
