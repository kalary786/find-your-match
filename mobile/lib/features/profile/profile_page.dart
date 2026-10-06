import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/session/session_controller.dart';
import 'package:find_your_match/core/widgets/error_state.dart';
import 'package:find_your_match/core/widgets/interest_wrap.dart';
import 'package:find_your_match/core/widgets/person_avatar.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: const [_SettingsButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          PersonCover(person: widget.person, height: 220),
          const SizedBox(height: 16),
          Text(
            widget.person.displayName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.person.username} · ${widget.person.age} · ${widget.person.city}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Saved on your website. Sign in with the same email on another phone to open this profile.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(widget.person.bio),
          const SizedBox(height: 12),
          InterestWrap(labels: widget.person.interests),
          const SizedBox(height: 8),
          InterestWrap(labels: widget.person.preferences),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Hide profile'),
            subtitle: Text(
              _busy
                  ? 'Saving…'
                  : 'Hidden profiles stay out of Discover. Hiding is not deletion.',
            ),
            value: hidden,
            onChanged: _busy ? null : (value) => _setHidden(value),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => context.push(AppRoutes.editProfile),
            child: const Text('Edit profile'),
          ),
        ],
      ),
    );
  }
}
