import 'package:find_your_match/core/session/session_controller.dart';
import 'package:find_your_match/core/theme/app_colors.dart';
import 'package:find_your_match/core/theme/app_tokens.dart';
import 'package:find_your_match/core/widgets/gradient_button.dart';
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
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: AppTokens.lg,
                gradient: AppColors.brandGradient,
              ),
              child: const Icon(Icons.link_rounded, color: Colors.white, size: 34),
            ),
            const SizedBox(height: AppTokens.space20),
            Text(
              'Add your website address',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: AppTokens.space12),
            Text(
              'Profiles, chats, and ads come from the PHP site you host. The app stays on this screen until that address is set.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTokens.space20),
            const _SetupStep(
              number: '1',
              text:
                  'Create a MySQL database, copy server/config.example.php to server/config.php, and open server/install.php once.',
            ),
            const _SetupStep(
              number: '2',
              text:
                  'Upload the server folder to your hosting. Delete install.php after the admin account exists.',
            ),
            const _SetupStep(
              number: '3',
              text:
                  'Set ApiConfig.baseUrl to that public folder, for example https://example.com/server, then restart the app.',
            ),
            const SizedBox(height: AppTokens.space8),
            Text(
              'The admin password stays on the website. It is never stored in this app.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTokens.space24),
            GradientButton(
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
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.brandGradient,
                ),
                child: Text(
                  number,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.space12),
              Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
            ],
          ),
        ),
      ),
    );
  }
}
