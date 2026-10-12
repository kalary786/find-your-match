import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/theme/app_colors.dart';
import 'package:find_your_match/core/theme/app_tokens.dart';
import 'package:find_your_match/features/onboarding/onboarding_frame.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HowItWorksPage extends StatelessWidget {
  const HowItWorksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingFrame(
      step: 2,
      title: 'How it works',
      subtitle: 'Three simple steps from profile to conversation.',
      actionLabel: 'Continue',
      onBack: () => context.go(AppRoutes.onboarding),
      onAction: () => context.go(AppRoutes.account),
      child: const Column(
        children: [
          _Step(
            number: '1',
            icon: Icons.badge_outlined,
            title: 'Create a profile',
            body:
                'Add a username, photo, city, and what you are looking for. You must be 18 or older.',
          ),
          _Step(
            number: '2',
            icon: Icons.favorite_outline,
            title: 'Discover and like',
            body:
                'Browse real profiles. A like is private until the other person likes you back.',
          ),
          _Step(
            number: '3',
            icon: Icons.chat_bubble_outline,
            title: 'Match, then talk',
            body:
                'Text chat opens only after a mutual match. You can block or report someone at any time.',
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
  });

  final String number;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space12),
      child: Material(
        color: theme.colorScheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: AppTokens.lg,
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.space16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.brandGradient,
                ),
                child: Text(
                  number,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.space4),
                    Text(body, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
