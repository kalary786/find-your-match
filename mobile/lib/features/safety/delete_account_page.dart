import 'package:find_your_match/core/api/api_config.dart';
import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/theme/app_tokens.dart';
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
  final _password = TextEditingController();
  var _confirmed = false;
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(accountActionsProvider).deleteAccount(password: _password.text);
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
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space20,
          AppTokens.space8,
          AppTokens.space20,
          AppTokens.space24,
        ),
        children: [
          Material(
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.45),
            shape: RoundedRectangleBorder(
              borderRadius: AppTokens.lg,
              side: BorderSide(
                color: theme.colorScheme.error.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: AppTokens.space8),
                      Text(
                        'Delete this account',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space12),
                  Text(
                    'This deletes the profile, photo, likes, matches, and chats from your website. It does not create a replacement profile.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space12),
                  Text(
                    'Hiding a profile is not deletion. After deletion the email can be used to register again, as a new account. The same deletion is available in a browser at ${ApiConfig.baseUrl}/delete-account.php if you still know the email and password.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space20),
          Material(
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
                  TextField(
                    key: const Key('delete-password'),
                    controller: _password,
                    obscureText: true,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: InputBorder.none,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  Divider(height: 1, color: theme.colorScheme.outlineVariant),
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
                ],
              ),
            ),
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
          const SizedBox(height: AppTokens.space16),
          PrimaryButton(
            key: const Key('confirm-delete'),
            label: _busy ? 'Deleting…' : 'Delete account',
            loading: _busy,
            onPressed: _confirmed && !_busy && _password.text.isNotEmpty
                ? _delete
                : null,
          ),
        ],
      ),
    );
  }
}
