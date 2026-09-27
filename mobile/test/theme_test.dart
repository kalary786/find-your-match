import 'package:find_your_match/core/theme/app_colors.dart';
import 'package:find_your_match/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('light theme uses coral on a warm canvas', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: SizedBox()),
      ),
    );

    final context = tester.element(find.byType(Scaffold));
    final theme = Theme.of(context);
    expect(theme.brightness, Brightness.light);
    expect(theme.colorScheme.primary, AppColors.coral);
    expect(theme.colorScheme.surface, AppColors.canvas);
    expect(theme.useMaterial3, isTrue);
  });

  testWidgets('dark theme uses a bright coral on ink', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const Scaffold(body: SizedBox()),
      ),
    );

    final context = tester.element(find.byType(Scaffold));
    final theme = Theme.of(context);
    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.primary, AppColors.coralBright);
    expect(theme.colorScheme.surface, AppColors.canvasDark);
    expect(theme.useMaterial3, isTrue);
  });
}
