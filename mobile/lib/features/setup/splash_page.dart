import 'package:find_your_match/core/theme/app_colors.dart';
import 'package:find_your_match/core/widgets/app_wordmark.dart';
import 'package:find_your_match/core/widgets/loading_state.dart';
import 'package:flutter/material.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [AppColors.canvasDark, Color(0xFF2A1614)]
                : const [AppColors.canvas, Color(0xFFFFE4DC)],
          ),
        ),
        child: const SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite, size: 48),
                  SizedBox(height: 20),
                  AppWordmark(centered: true),
                  SizedBox(height: 28),
                  LoadingState(message: 'Getting things ready'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
