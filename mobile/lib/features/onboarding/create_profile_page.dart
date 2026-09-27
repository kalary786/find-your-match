import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/session/session_controller.dart';
import 'package:find_your_match/features/preview/mock_people.dart';
import 'package:find_your_match/features/preview/preview_store.dart';
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
      takenUsernames: MockPeople.takenUsernames(),
      onBack: () => context.go(AppRoutes.account),
      onSubmit: (person) {
        ref.read(previewControllerProvider.notifier).saveSelf(person);
        ref.read(sessionControllerProvider.notifier).completeLocalProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved on this device. Not sent to a database.'),
          ),
        );
        context.go(AppRoutes.discover);
      },
    );
  }
}
