import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/widgets/app_wordmark.dart';
import 'package:find_your_match/features/onboarding/onboarding_frame.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OnboardingFrame(
      step: 1,
      title: 'Welcome',
      actionLabel: 'Continue',
      onAction: () => context.go(AppRoutes.howItWorks),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppWordmark(),
          const SizedBox(height: 24),
          Text(
            'A place for adults 18 and older to discover people, match, and talk.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Dating features are only for people who are 18 or older. If a date of birth is under 18, no profile is created.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
