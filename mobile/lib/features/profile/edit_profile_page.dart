import 'package:find_your_match/core/session/session_controller.dart';
import 'package:find_your_match/core/widgets/error_state.dart';
import 'package:find_your_match/features/profile/account_actions.dart';
import 'package:find_your_match/features/profile/api_account_actions.dart';
import 'package:find_your_match/features/profile/profile_editor.dart';
import 'package:find_your_match/features/profile/saved_account.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EditProfilePage extends ConsumerWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedAccountProvider);
    if (saved == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit profile')),
        body: ErrorState(
          title: 'Profile not loaded',
          message:
              'The saved profile is not on this screen yet. Check your connection and try again.',
          onRetry: () {
            ref.read(sessionControllerProvider.notifier).bootstrap();
          },
        ),
      );
    }
    return ProfileEditor(
      title: 'Edit profile',
      submitLabel: 'Save changes',
      initial: saved.person,
      photoFileRequired: true,
      keepExistingPhoto: saved.person.hasPhoto || saved.person.photoUrl != null,
      choosePhoto: pickGalleryPhoto,
      takenUsernames: const {},
      onSubmit: (draft) async {
        await ref.read(accountActionsProvider).update(draft);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated.')),
        );
        context.pop();
      },
    );
  }
}
