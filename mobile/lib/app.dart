import 'dart:async';

import 'package:find_your_match/core/routing/app_router.dart';
import 'package:find_your_match/core/session/session_controller.dart';
import 'package:find_your_match/core/theme/app_theme.dart';
import 'package:find_your_match/core/theme/theme_mode_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FindYourMatchApp extends ConsumerStatefulWidget {
  const FindYourMatchApp({this.bootstrapOnStart = true, super.key});

  /// Widget tests that seed a session skip the server bootstrap.
  final bool bootstrapOnStart;

  @override
  ConsumerState<FindYourMatchApp> createState() => _FindYourMatchAppState();
}

class _FindYourMatchAppState extends ConsumerState<FindYourMatchApp> {
  @override
  void initState() {
    super.initState();
    if (!widget.bootstrapOnStart) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(sessionControllerProvider.notifier).bootstrap());
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Find Your Match',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
