import 'package:flutter/material.dart';

class CenteredPanel extends StatelessWidget {
  const CenteredPanel({required this.child, this.maxWidth = 520, super.key});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
