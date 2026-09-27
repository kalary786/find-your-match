import 'package:find_your_match/core/session/session_controller.dart';
import 'package:find_your_match/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SetupPage extends ConsumerWidget {
  const SetupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          children: [
            Text(
              'Connect Firebase to continue',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Anonymous sign-in is built, and it stays off until this install has a Firebase project. No sample people are included.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            const _SetupStep(
              number: '1',
              text:
                  'Create a Firebase project, register the Android app, and enable Anonymous Authentication and Cloud Firestore.',
            ),
            const _SetupStep(
              number: '2',
              text:
                  'Download google-services.json into mobile/android/app. Do not commit it.',
            ),
            const _SetupStep(
              number: '3',
              text:
                  'Set FirebaseAppConfig.isConfigured to true, then restart the app.',
            ),
            const SizedBox(height: 8),
            Text(
              'Admin passwords and service accounts never belong in this app.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Try again',
              onPressed: () {
                ref.read(sessionControllerProvider.notifier).bootstrap();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            child: Text(
              number,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
