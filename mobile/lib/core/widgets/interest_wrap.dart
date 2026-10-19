import 'package:find_your_match/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class InterestWrap extends StatelessWidget {
  const InterestWrap({required this.labels, super.key});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Wrap(
      spacing: AppTokens.space8,
      runSpacing: AppTokens.space8,
      children: [
        for (final label in labels)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space12,
              vertical: AppTokens.space8,
            ),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: AppTokens.pill,
            ),
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
