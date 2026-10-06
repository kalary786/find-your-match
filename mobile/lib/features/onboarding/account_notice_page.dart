import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/session/session_controller.dart';
import 'package:find_your_match/features/onboarding/onboarding_frame.dart';
import 'package:find_your_match/features/profile/account_failure.dart';
import 'package:find_your_match/features/profile/saved_account.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AccountNoticePage extends ConsumerStatefulWidget {
  const AccountNoticePage({super.key});

  @override
  ConsumerState<AccountNoticePage> createState() => _AccountNoticePageState();
}

class _AccountNoticePageState extends ConsumerState<AccountNoticePage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _login = false;
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final email = _email.text.trim();
    return email.contains('@') &&
        email.contains('.') &&
        _password.text.length >= 8 &&
        !_busy;
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = ref.read(matchApiProvider);
      final session = _login
          ? await api.login(email: _email.text.trim(), password: _password.text)
          : await api.register(
              email: _email.text.trim(),
              password: _password.text,
            );
      ref.read(savedAccountProvider.notifier).replace(session.account);
      ref.read(sessionControllerProvider.notifier).adoptAccount(
        uid: session.userId,
        hasProfile: session.hasProfile,
      );
      if (!mounted) return;
      context.go(session.hasProfile ? AppRoutes.discover : AppRoutes.createProfile);
    } on AccountFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OnboardingFrame(
      step: 3,
      title: _login ? 'Sign in' : 'Create your login',
      actionLabel: _busy ? 'Please wait…' : 'Continue',
      onAction: _canSubmit ? _submit : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your email and password live on your website. The same login opens this profile on another phone.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'An admin can block or delete the account from the website. There is no recovery if the admin deletes it.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Email'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
            onChanged: (_) => setState(() {}),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                    _login = !_login;
                    _error = null;
                  }),
            child: Text(
              _login
                  ? 'Need an account? Create one'
                  : 'Already have an account? Sign in',
            ),
          ),
        ],
      ),
    );
  }
}
