import 'package:find_your_match/features/preview/mock_people.dart';
import 'package:find_your_match/features/preview/preview_store.dart';
import 'package:find_your_match/features/profile/profile_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EditProfilePage extends ConsumerWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(previewControllerProvider);
    final current = preview.self;
    return ProfileEditor(
      title: 'Edit profile',
      submitLabel: 'Save changes',
      initial: preview.viewer,
      takenUsernames: MockPeople.takenUsernames(except: current?.username),
      onSubmit: (person) {
        ref.read(previewControllerProvider.notifier).saveSelf(person);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Changes saved on this device. Not sent to a database.'),
          ),
        );
        context.pop();
      },
    );
  }
}
