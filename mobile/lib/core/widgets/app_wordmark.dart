import 'package:find_your_match/core/theme/app_colors.dart';
import 'package:find_your_match/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class AppWordmark extends StatelessWidget {
  const AppWordmark({
    this.centered = false,
    this.showTagline = true,
    this.compact = false,
    super.key,
  });

  final bool centered;
  final bool showTagline;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final markSize = compact ? 44.0 : 64.0;
    final mark = Container(
      width: markSize,
      height: markSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        gradient: AppColors.brandGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.coral.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        Icons.favorite_rounded,
        color: Colors.white,
        size: compact ? 22 : 30,
      ),
    );

    final title = Text(
      'Find Your Match',
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: (compact ? theme.textTheme.titleLarge : theme.textTheme.headlineMedium)
          ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.6),
    );
    final tagline = Text(
      'Meet. Match. Connect.',
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
    );

    return Column(
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        mark,
        SizedBox(height: compact ? AppTokens.space12 : AppTokens.space16),
        title,
        if (showTagline) ...[
          const SizedBox(height: AppTokens.space4),
          tagline,
        ],
      ],
    );
  }
}
