import 'package:flutter/material.dart';

class InterestWrap extends StatelessWidget {
  const InterestWrap({required this.labels, super.key});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final label in labels)
          Chip(
            label: Text(label),
            visualDensity: VisualDensity.compact,
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
      ],
    );
  }
}
