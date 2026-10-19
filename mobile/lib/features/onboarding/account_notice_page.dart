import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/session/session_controller.dart';
import 'package:find_your_match/core/theme/app_tokens.dart';
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
  var _agreed = false;
  var _busy = false;
  var _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _whyBlocked() {
    final email = _email.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      return 'Enter an email address. That email is the login.';
    }
    if (_password.text.length < 8) {
      return 'Use a password of at least 8 characters.';
    }
    if (!_login && !_agreed) {
      return 'Tick the box to agree before the login can be created.';
    }
    return null;
  }

  Future<void> _submit() async {
    final blocked = _whyBlocked();
    if (blocked != null) {
      setState(() => _error = blocked);
      return;
    }
    final router = GoRouter.of(context);
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
      router.go(
        session.hasProfile ? AppRoutes.discover : AppRoutes.createProfile,
      );
    } on AccountFailure catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'The login could not be created. Try again.',
        );
      }
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
      subtitle:
          'Your email and password live on your website. The same login opens this profile on another phone.',
      actionLabel: _busy ? 'Please wait…' : 'Continue',
      onBack: () => context.go(AppRoutes.howItWorks),
      onAction: _busy ? null : _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'An admin can block or delete the account from the website. There is no recovery if the admin deletes it.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTokens.space16),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppTokens.space12),
          TextField(
            controller: _password,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            onChanged: (_) => setState(() {}),
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
          if (!_login) ...[
            const SizedBox(height: AppTokens.space8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  key: const Key('agree-legal'),
                  value: _agreed,
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _agreed = value ?? false),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('I agree to the '),
                        _LegalLink(label: 'Terms', route: AppRoutes.terms),
                        const Text(', '),
                        _LegalLink(label: 'Privacy', route: AppRoutes.privacy),
                        const Text(', and '),
                        _LegalLink(
                          label: 'Community Guidelines',
                          route: AppRoutes.guidelines,
                        ),
                        const Text('.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppTokens.space8),
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

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.route});

  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () => context.push(route),
      child: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
