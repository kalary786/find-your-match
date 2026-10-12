import 'package:find_your_match/core/theme/app_tokens.dart';
import 'package:find_your_match/core/widgets/error_state.dart';
import 'package:find_your_match/features/legal/legal_copy.dart';
import 'package:flutter/material.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({required this.document, super.key});

  final LegalDocument? document;

  @override
  Widget build(BuildContext context) {
    final document = this.document;
    if (document == null) {
      return const Scaffold(
        body: ErrorState(
          title: 'Page not available',
          message: 'That page is not part of this build.',
        ),
      );
    }
    final theme = Theme.of(context);
    final publicUrl = document.publicUrl;
    return Scaffold(
      appBar: AppBar(title: Text(document.title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space20,
              AppTokens.space8,
              AppTokens.space20,
              AppTokens.space24,
            ),
            children: [
              for (final section in document.sections) ...[
                Text(
                  section.heading,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTokens.space12),
                Text(
                  section.body,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
                ),
                const SizedBox(height: AppTokens.space24),
              ],
              if (publicUrl != null)
                Text(
                  'The same page is public at $publicUrl',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
