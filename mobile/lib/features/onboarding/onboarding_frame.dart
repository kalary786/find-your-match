import 'package:find_your_match/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';

class OnboardingFrame extends StatelessWidget {
  const OnboardingFrame({
    required this.step,
    required this.title,
    required this.child,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final int step;
  final String title;
  final Widget child;
  final String actionLabel;
  final VoidCallback? onAction;

  static const stepCount = 4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Step $step of $stepCount',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: step / stepCount,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(child: child),
              ),
              const SizedBox(height: 16),
              PrimaryButton(label: actionLabel, onPressed: onAction),
            ],
          ),
        ),
      ),
    );
  }
}
