import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/theme/app_colors.dart';
import 'package:find_your_match/core/theme/app_tokens.dart';
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
      subtitle: 'A warm place to meet people who are actually looking.',
      actionLabel: 'Continue',
      onAction: () => context.go(AppRoutes.howItWorks),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 24,
                  top: 18,
                  child: _Bubble(color: AppColors.coral.withValues(alpha: 0.2), size: 48),
                ),
                Positioned(
                  right: 32,
                  top: 8,
                  child: _Bubble(color: AppColors.peach.withValues(alpha: 0.35), size: 36),
                ),
                Positioned(
                  right: 18,
                  bottom: 20,
                  child: _Bubble(color: AppColors.coralLight.withValues(alpha: 0.28), size: 44),
                ),
                Positioned(
                  left: 40,
                  bottom: 12,
                  child: _Bubble(color: AppColors.superlike.withValues(alpha: 0.18), size: 32),
                ),
                const AppWordmark(centered: true, showTagline: false),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space24),
          Text(
            'A place for adults 18 and older to discover people, match, and talk.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppTokens.space12),
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

class _Bubble extends StatelessWidget {
  const _Bubble({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(
        Icons.person_rounded,
        size: size * 0.45,
        color: AppColors.coral.withValues(alpha: 0.7),
      ),
    );
  }
}
