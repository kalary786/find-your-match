import 'package:find_your_match/core/theme/app_colors.dart';
import 'package:find_your_match/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  const GradientButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  bool get _enabled => onPressed != null && !loading;

  @override
  Widget build(BuildContext context) {
    final disabledFg =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45);
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppTokens.md,
          gradient: _enabled ? AppColors.brandGradient : null,
          color: _enabled
              ? null
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.18),
          boxShadow: _enabled
              ? [
                  BoxShadow(
                    color: AppColors.coral.withValues(alpha: 0.32),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: FilledButton(
          onPressed: _enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: disabledFg,
            shape: RoundedRectangleBorder(borderRadius: AppTokens.md),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: AppTokens.space8),
                    ],
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: _enabled ? Colors.white : disabledFg,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
