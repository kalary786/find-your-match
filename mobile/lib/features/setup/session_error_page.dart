import 'package:find_your_match/core/session/session_controller.dart';
import 'package:find_your_match/core/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionErrorPage extends ConsumerWidget {
  const SessionErrorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: ErrorState(
          title: 'Could not start the session',
          message: session.errorMessage ??
              'Something went wrong before your account was ready.',
          onRetry: () {
            ref.read(sessionControllerProvider.notifier).bootstrap();
          },
        ),
      ),
    );
  }
}
