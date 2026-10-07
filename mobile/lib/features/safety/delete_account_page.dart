import 'package:find_your_match/core/api/api_config.dart';
import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/widgets/primary_button.dart';
import 'package:find_your_match/features/profile/account_failure.dart';
import 'package:find_your_match/features/profile/api_account_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  var _confirmed = false;
  var _busy = false;
  String? _error;

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(accountActionsProvider).deleteAccount();
      if (!mounted) return;
      context.go(AppRoutes.onboarding);
    } on AccountFailure catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Delete account')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            'Delete this account',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This deletes the profile, photo, likes, matches, and chats from your website. It does not create a replacement profile.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Hiding a profile is not deletion. After deletion the email can be used to register again, as a new account. The same deletion is available in a browser at ${ApiConfig.baseUrl}/delete-account.php if you still know the email and password.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _confirmed,
            onChanged: _busy
                ? null
                : (value) => setState(() => _confirmed = value ?? false),
            title: const Text(
              'I understand this permanently deletes the account.',
            ),
            controlAffinity: ListTileControlAffinity.leading,
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
          const SizedBox(height: 12),
          PrimaryButton(
            key: const Key('confirm-delete'),
            label: _busy ? 'Deleting…' : 'Delete account',
            onPressed: _confirmed && !_busy ? _delete : null,
          ),
        ],
      ),
    );
  }
}
