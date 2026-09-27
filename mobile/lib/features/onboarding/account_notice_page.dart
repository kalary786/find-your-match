import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/features/onboarding/onboarding_frame.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AccountNoticePage extends StatefulWidget {
  const AccountNoticePage({super.key});

  @override
  State<AccountNoticePage> createState() => _AccountNoticePageState();
}

class _AccountNoticePageState extends State<AccountNoticePage> {
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OnboardingFrame(
      step: 3,
      title: 'This account stays on this phone',
      actionLabel: 'Continue',
      onAction: _acknowledged
          ? () => context.go(AppRoutes.createProfile)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find Your Match signs you in anonymously. There is no email or password.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'The session lives on this install. Uninstalling the app, clearing storage, or moving to a new phone drops it. Firebase cannot restore an anonymous user from an email address, because no email is stored.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'After your profile is saved, the app will show a recovery code once. Only a protected hash of that code is stored. You need the code to restore the account on a new install.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'If you lose both this phone and the recovery code, the account cannot be recovered.',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _acknowledged,
            onChanged: (value) {
              setState(() => _acknowledged = value ?? false);
            },
            title: const Text(
              'I understand this account cannot be restored without the recovery code.',
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }
}
