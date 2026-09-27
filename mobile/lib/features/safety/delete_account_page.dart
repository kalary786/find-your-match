import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/session/session_controller.dart';
import 'package:find_your_match/core/widgets/primary_button.dart';
import 'package:find_your_match/features/preview/preview_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  ConsumerState<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  var _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Delete account')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            'Delete the preview on this phone',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This removes the profile, likes, and messages kept in memory for the layout. It does not call Firebase, because the database is not connected.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Hiding a profile is not deletion. When a real account exists, deletion will also need to remove the cloud account and its data, with a web page for people who no longer have the app.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _confirmed,
            onChanged: (value) => setState(() => _confirmed = value ?? false),
            title: const Text(
              'I understand this clears the preview on this device.',
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            key: const Key('confirm-delete'),
            label: 'Delete preview data',
            onPressed: _confirmed
                ? () {
                    ref.read(previewControllerProvider.notifier).clearSelf();
                    ref.read(sessionControllerProvider.notifier).forgetLocalProfile();
                    context.go(AppRoutes.onboarding);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
