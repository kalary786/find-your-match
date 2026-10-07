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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          for (final section in document.sections) ...[
            Text(
              section.heading,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(section.body, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 20),
          ],
          if (publicUrl != null)
            Text(
              'The same page is public at $publicUrl',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
