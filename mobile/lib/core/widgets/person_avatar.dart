import 'package:find_your_match/features/preview/preview_models.dart';
import 'package:flutter/material.dart';

class PersonAvatar extends StatelessWidget {
  const PersonAvatar({required this.person, this.size = 48, super.key});

  final Person person;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = HSLColor.fromAHSL(1, person.hue, 0.48, 0.42).toColor();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color,
      child: Text(
        person.initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.32,
        ),
      ),
    );
  }
}

class PersonCover extends StatelessWidget {
  const PersonCover({required this.person, this.height = 280, super.key});

  final Person person;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = HSLColor.fromAHSL(1, person.hue, 0.52, 0.38).toColor();
    final lift = HSLColor.fromAHSL(1, person.hue, 0.42, 0.58).toColor();
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [lift, base],
          ),
        ),
        child: Stack(
          children: [
            if (person.photoUrl != null)
              Positioned.fill(
                child: Image.network(
                  person.photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            if (person.photoUrl == null)
              Center(
                child: Text(
                  person.initials,
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
