import 'dart:math' as math;

import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/theme/app_colors.dart';
import 'package:find_your_match/core/theme/app_tokens.dart';
import 'package:find_your_match/core/widgets/centered_panel.dart';
import 'package:find_your_match/core/widgets/empty_state.dart';
import 'package:find_your_match/core/widgets/error_state.dart';
import 'package:find_your_match/core/widgets/gradient_button.dart';
import 'package:find_your_match/core/widgets/interest_wrap.dart';
import 'package:find_your_match/core/widgets/loading_state.dart';
import 'package:find_your_match/core/widgets/person_avatar.dart';
import 'package:find_your_match/core/widgets/verified_badge.dart';
import 'package:find_your_match/features/ads/placement_ad.dart';
import 'package:find_your_match/features/notices/notices_page.dart';
import 'package:find_your_match/features/preview/preview_models.dart';
import 'package:find_your_match/features/profile/account_failure.dart';
import 'package:find_your_match/features/profile/saved_account.dart';
import 'package:find_your_match/features/social/social_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage> {
  var _acting = false;
  var _profilesSeen = 0;
  var _dragDx = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(socialControllerProvider.notifier).ensureLoaded();
      ref.read(noticeControllerProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final social = ref.watch(socialControllerProvider);
    final hidden = ref.watch(savedAccountProvider)?.hidden ?? false;
    final queue = social.discover;
    final unread = ref.watch(noticeControllerProvider).unread;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: CenteredPanel(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Discover', style: theme.textTheme.headlineMedium),
                    ),
                    IconButton(
                      tooltip: 'Notifications',
                      onPressed: () => context.push(AppRoutes.notices),
                      icon: Badge(
                        isLabelVisible: unread > 0,
                        smallSize: 8,
                        child: const Icon(Icons.notifications_none_rounded),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Filters',
                      onPressed: () => context.push(AppRoutes.filters),
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ],
                ),
              ),
              const PlacementAd(placement: 'discover'),
              const UnreadNoticeBanner(),
              if (hidden)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Material(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: AppTokens.md,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Your profile is hidden. Other people cannot find you until you show it again.',
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: social.loading && queue.isEmpty
                    ? const LoadingState(message: 'Finding people')
                    : queue.isEmpty
                    ? social.error == null
                        ? const EmptyState(
                            icon: Icons.explore_outlined,
                            title: 'No profiles left',
                            message:
                                'New people will show up here when they join. You can also open Search.',
                          )
                        : ErrorState(
                            title: 'Could not load profiles',
                            message: social.error!,
                            onRetry: () {
                              ref
                                  .read(socialControllerProvider.notifier)
                                  .ensureLoaded();
                            },
                          )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Stack(
                          children: [
                            if (queue.length > 1)
                              Transform.scale(
                                scale: 0.95,
                                child: _DiscoverCard(
                                  person: queue[1],
                                  interactive: false,
                                ),
                              ),
                            GestureDetector(
                              onPanUpdate: _acting
                                  ? null
                                  : (details) {
                                      setState(() => _dragDx += details.delta.dx);
                                    },
                              onPanEnd: _acting
                                  ? null
                                  : (_) {
                                      final dx = _dragDx;
                                      setState(() => _dragDx = 0);
                                      if (dx > 110) {
                                        _like(queue.first);
                                      } else if (dx < -110) {
                                        _pass(queue.first.id);
                                      }
                                    },
                              child: Transform.translate(
                                offset: Offset(_dragDx, 0),
                                child: Transform.rotate(
                                  angle: (_dragDx / 480) * (math.pi / 18),
                                  child: Stack(
                                    children: [
                                      _DiscoverCard(
                                        person: queue.first,
                                        interactive: true,
                                      ),
                                      if (_dragDx.abs() > 28)
                                        Positioned(
                                          top: 28,
                                          left: _dragDx > 0 ? 24 : null,
                                          right: _dragDx < 0 ? 24 : null,
                                          child: Transform.rotate(
                                            angle: _dragDx > 0 ? -0.3 : 0.3,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: _dragDx > 0
                                                      ? AppColors.online
                                                      : AppColors.pass,
                                                  width: 3,
                                                ),
                                                borderRadius: AppTokens.sm,
                                              ),
                                              child: Text(
                                                _dragDx > 0 ? 'LIKE' : 'NOPE',
                                                style: theme.textTheme.titleLarge
                                                    ?.copyWith(
                                                      color: _dragDx > 0
                                                          ? AppColors.online
                                                          : AppColors.pass,
                                                      fontWeight: FontWeight.w900,
                                                      letterSpacing: 1.2,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              if (queue.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _RoundAction(
                        size: 60,
                        color: theme.colorScheme.surfaceContainerLowest,
                        icon: Icons.close_rounded,
                        iconColor: AppColors.pass,
                        tooltip: 'Pass',
                        onPressed: _acting ? null : () => _pass(queue.first.id),
                      ),
                      const SizedBox(width: 28),
                      _RoundAction(
                        key: const Key('discover-like'),
                        size: 72,
                        gradient: true,
                        icon: Icons.favorite_rounded,
                        iconColor: Colors.white,
                        tooltip: 'Like',
                        onPressed: _acting ? null : () => _like(queue.first),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pass(String id) async {
    if (_acting) return;
    HapticFeedback.lightImpact();
    setState(() => _acting = true);
    try {
      await ref.read(socialControllerProvider.notifier).pass(id);
      _show('Passed.');
      await _onProfileViewed();
    } on AccountFailure catch (error) {
      _show(error.message);
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _like(Person person) async {
    if (_acting) return;
    HapticFeedback.lightImpact();
    setState(() => _acting = true);
    try {
      final matched = await ref
          .read(socialControllerProvider.notifier)
          .like(person.id);
      if (!mounted) return;
      if (matched) {
        HapticFeedback.mediumImpact();
        await _showMatchDialog(person);
      } else {
        _show('Like sent.');
      }
      await _onProfileViewed();
    } on AccountFailure catch (error) {
      _show(error.message);
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _showMatchDialog(Person person) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final me = ref.read(savedAccountProvider)?.person;
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "It's a Match!",
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.coral,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You and ${person.displayName} liked each other.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 88,
                  width: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 0,
                        child: PersonAvatar(
                          person: me ?? person,
                          size: 72,
                          storyRing: true,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: PersonAvatar(
                          person: person,
                          size: 72,
                          storyRing: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GradientButton(
                  label: 'Send a message',
                  onPressed: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.conversation(person.id));
                  },
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Keep swiping'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onProfileViewed() async {
    _profilesSeen += 1;
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.size,
    required this.icon,
    required this.iconColor,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.gradient = false,
    super.key,
  });

  final double size;
  final IconData icon;
  final Color iconColor;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: gradient ? null : color,
              gradient: gradient ? AppColors.brandGradient : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: size * 0.42),
          ),
        ),
      ),
    );
  }
}

class _DiscoverCard extends StatelessWidget {
  const _DiscoverCard({required this.person, required this.interactive});

  final Person person;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: AppTokens.xl,
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: interactive ? 0 : 0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              PersonCover(
                person: person,
                height: constraints.maxHeight,
                borderRadius: BorderRadius.zero,
                heroTag: interactive ? 'person-photo-${person.id}' : null,
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: GestureDetector(
                  key: interactive ? const Key('discover-card') : null,
                  onTap: interactive
                      ? () => context.push(AppRoutes.person(person.id))
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          if (person.online) ...[
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.online,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              '${person.displayName}, ${person.age}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (person.verified) ...[
                            const SizedBox(width: 6),
                            const VerifiedBadge(size: 18),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              person.city,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (person.bio.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          person.bio,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                      if (person.interests.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        InterestWrap(
                          labels: person.interests.take(4).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
