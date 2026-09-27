import 'package:flutter/material.dart';

class AppWordmark extends StatelessWidget {
  const AppWordmark({this.centered = false, super.key});

  final bool centered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = Text(
      'Find Your Match',
      style: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
    );
    final tagline = Text(
      'Meet. Match. Connect.',
      style: theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
    );

    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        title,
        const SizedBox(height: 4),
        tagline,
      ],
    );
  }
}
