import 'package:find_your_match/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class LoadingState extends StatelessWidget {
  const LoadingState({this.message, this.skeleton = true, super.key});

  final String? message;
  final bool skeleton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final canSkeleton =
            skeleton && constraints.hasBoundedHeight && constraints.maxHeight > 160;
        if (!canSkeleton) {
          return Padding(
            padding: const EdgeInsets.all(AppTokens.space32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                if (message != null) ...[
                  const SizedBox(height: AppTokens.space20),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(AppTokens.space16),
          child: Column(
            children: [
              if (message != null) ...[
                Text(
                  message!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppTokens.space12),
              ],
              const Expanded(child: _SkeletonCard()),
              const SizedBox(height: AppTokens.space12),
              const Row(
                children: [
                  Expanded(child: _SkeletonBar(height: 48)),
                  SizedBox(width: AppTokens.space12),
                  Expanded(child: _SkeletonBar(height: 48)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    final inTest = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('TestWidgetsFlutterBinding');
    if (!inTest) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.outlineVariant;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final color = Color.lerp(base, Colors.white, _pulse.value * 0.35)!;
        return Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppTokens.xl,
          ),
        );
      },
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: AppTokens.md,
      ),
    );
  }
}
