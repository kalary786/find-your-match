import 'package:find_your_match/core/routing/app_routes.dart';
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
      actionLabel: 'Continue',
      onAction: () => context.go(AppRoutes.account),
      child: const Column(
        children: [
          _Step(
            icon: Icons.badge_outlined,
            title: 'Create a profile',
            body:
                'Add a username, photo, city, and what you are looking for. You must be 18 or older.',
          ),
          _Step(
            icon: Icons.favorite_outline,
            title: 'Discover and like',
            body:
                'Browse real profiles. A like is private until the other person likes you back.',
          ),
          _Step(
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
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
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
