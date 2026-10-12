import 'package:find_your_match/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({this.size = 16, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.verified,
      size: size,
      color: AppColors.superlike,
    );
  }
}
