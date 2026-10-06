import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/features/profile/account_actions.dart';
import 'package:find_your_match/features/profile/api_account_actions.dart';
import 'package:find_your_match/features/profile/profile_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreateProfilePage extends ConsumerWidget {
  const CreateProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProfileEditor(
      title: 'Create profile',
      stepLabel: 'Step 4 of 4',
      submitLabel: 'Save profile',
      photoFileRequired: true,
      choosePhoto: pickGalleryPhoto,
      takenUsernames: const {},
      onBack: () => context.go(AppRoutes.account),
      onSubmit: (draft) async {
        final outcome = await ref.read(accountActionsProvider).create(draft);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              outcome.alreadyExisted
                  ? 'This account already has a profile. Opening the saved one.'
                  : 'Profile saved.',
            ),
          ),
        );
        context.go(AppRoutes.discover);
      },
    );
  }
}
