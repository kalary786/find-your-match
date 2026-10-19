import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/session/session_controller.dart';
import 'package:find_your_match/core/theme/app_colors.dart';
import 'package:find_your_match/core/theme/app_tokens.dart';
import 'package:find_your_match/core/widgets/error_state.dart';
import 'package:find_your_match/core/widgets/gradient_button.dart';
import 'package:find_your_match/core/widgets/interest_wrap.dart';
import 'package:find_your_match/core/widgets/person_avatar.dart';
import 'package:find_your_match/core/widgets/section_header.dart';
import 'package:find_your_match/core/widgets/settings_group.dart';
import 'package:find_your_match/features/notices/notices_page.dart';
import 'package:find_your_match/features/preview/preview_models.dart';
import 'package:find_your_match/features/profile/account_failure.dart';
import 'package:find_your_match/features/profile/api_account_actions.dart';
import 'package:find_your_match/features/profile/saved_account.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedAccountProvider);
    if (saved == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          actions: const [_SettingsButton()],
        ),
        body: ErrorState(
          title: 'Profile not loaded',
          message:
              'You appear to be offline, or the saved profile could not be read. Nothing new was created.',
          onRetry: () {
            ref.read(sessionControllerProvider.notifier).bootstrap();
          },
        ),
      );
    }
    return _ProfileScaffold(person: saved.person, hidden: saved.hidden);
  }
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('settings-button'),
      tooltip: 'Settings',
      onPressed: () => context.push(AppRoutes.settings),
      icon: const Icon(Icons.settings_outlined),
    );
  }
}

double _profileCompletion(Person person) {
  var filled = 0;
  if (person.hasPhoto) filled++;
  if (person.bio.trim().isNotEmpty) filled++;
  if (person.interests.isNotEmpty) filled++;
  if (person.city.trim().isNotEmpty) filled++;
  return filled / 4;
}

class _ProfileScaffold extends ConsumerStatefulWidget {
  const _ProfileScaffold({required this.person, required this.hidden});

  final Person person;
  final bool hidden;

  @override
  ConsumerState<_ProfileScaffold> createState() => _ProfileScaffoldState();
}

class _ProfileScaffoldState extends ConsumerState<_ProfileScaffold> {
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(noticeControllerProvider.notifier).refresh();
    });
  }

  Future<void> _setHidden(bool value) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(accountActionsProvider).setHidden(value);
    } on AccountFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hidden = ref.watch(savedAccountProvider)?.hidden ?? widget.hidden;
    final unread = ref.watch(noticeControllerProvider).unread;
    final completion = _profileCompletion(widget.person);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: const [_SettingsButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space20,
          AppTokens.space8,
          AppTokens.space20,
          AppTokens.space24,
        ),
        children: [
          Material(
            color: theme.colorScheme.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: AppTokens.lg,
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.space20),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      PersonAvatar(
                        person: widget.person,
                        size: 104,
                        storyRing: true,
                        heroTag: 'person-photo-${widget.person.id}',
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Material(
                          color: theme.colorScheme.primary,
                          shape: const CircleBorder(),
                          elevation: 2,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => context.push(AppRoutes.editProfile),
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space16),
                  Text(
                    widget.person.displayName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space4),
                  Text(
                    '@${widget.person.username}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space4),
                  Text(
                    '${widget.person.age} · ${widget.person.city}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (completion < 1) ...[
                    const SizedBox(height: AppTokens.space16),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: AppTokens.pill,
                            child: LinearProgressIndicator(
                              value: completion,
                              minHeight: 6,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation(
                                AppColors.coral,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTokens.space12),
                        Text(
                          '${(completion * 100).round()}%',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.space4),
                    Text(
                      'Complete your profile to stand out in Discover.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space16),
          if (widget.person.bio.isNotEmpty) ...[
            Text(
              widget.person.bio,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
            const SizedBox(height: AppTokens.space16),
          ],
          if (widget.person.interests.isNotEmpty) ...[
            const SectionHeader('Interests'),
            InterestWrap(labels: widget.person.interests),
            const SizedBox(height: AppTokens.space12),
          ],
          if (widget.person.preferences.isNotEmpty) ...[
            const SectionHeader('Looking for'),
            InterestWrap(labels: widget.person.preferences),
            const SizedBox(height: AppTokens.space16),
          ],
          GradientButton(
            label: 'Edit profile',
            icon: Icons.edit_outlined,
            onPressed: () => context.push(AppRoutes.editProfile),
          ),
          const SizedBox(height: AppTokens.space20),
          SettingsGroup(
            title: 'Preferences',
            children: [
              SettingsTile(
                leadingIcon: Icons.visibility_off_outlined,
                title: 'Hide profile',
                subtitle: _busy
                    ? 'Saving…'
                    : 'Hidden profiles stay out of Discover. Hiding is not deletion.',
                trailing: Switch.adaptive(
                  value: hidden,
                  onChanged: _busy ? null : (value) => _setHidden(value),
                ),
              ),
              SettingsTile(
                leadingIcon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: unread == 0
                    ? 'Messages and links from the app'
                    : '$unread unread',
                trailing: unread == 0
                    ? null
                    : Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.coral,
                          shape: BoxShape.circle,
                        ),
                      ),
                onTap: () => context.push(AppRoutes.notices),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: AppTokens.space12),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: AppTokens.space12),
          Text(
            'Saved on your website. Sign in with the same email on another phone to open this profile.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
