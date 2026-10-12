import 'package:find_your_match/core/theme/app_colors.dart';
import 'package:find_your_match/core/theme/app_tokens.dart';
import 'package:find_your_match/core/widgets/gradient_button.dart';
import 'package:flutter/material.dart';

class OnboardingFrame extends StatelessWidget {
  const OnboardingFrame({
    required this.step,
    required this.title,
    required this.child,
    required this.actionLabel,
    required this.onAction,
    this.subtitle,
    this.onBack,
    super.key,
  });

  final int step;
  final String title;
  final String? subtitle;
  final Widget child;
  final String actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onBack;

  static const stepCount = 4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (step > 1)
                    IconButton(
                      tooltip: 'Back',
                      onPressed: onBack ?? () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Row(
                      children: [
                        for (var i = 1; i <= stepCount; i++) ...[
                          Expanded(
                            child: AnimatedContainer(
                              duration: AppTokens.durationFast,
                              height: 4,
                              decoration: BoxDecoration(
                                borderRadius: AppTokens.pill,
                                gradient: i <= step
                                    ? AppColors.brandGradient
                                    : null,
                                color: i <= step
                                    ? null
                                    : theme.colorScheme.outlineVariant,
                              ),
                            ),
                          ),
                          if (i < stepCount)
                            const SizedBox(width: AppTokens.space4),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: AppTokens.space12),
              Text(
                'Step $step of $stepCount',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTokens.space12),
              Text(title, style: theme.textTheme.headlineMedium),
              if (subtitle != null) ...[
                const SizedBox(height: AppTokens.space8),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppTokens.space16),
              Expanded(child: SingleChildScrollView(child: child)),
              const SizedBox(height: AppTokens.space16),
              SafeArea(
                top: false,
                child: GradientButton(label: actionLabel, onPressed: onAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
