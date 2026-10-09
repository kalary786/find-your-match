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
    final photo = person.photoUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ColoredBox(
          color: base,
          child: photo == null || photo.isEmpty
              ? _Initials(person: person, theme: theme)
              : Image.network(
                  photo,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: height,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return _Initials(person: person, theme: theme);
                  },
                ),
        ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.person, required this.theme});

  final Person person;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        person.initials,
        style: theme.textTheme.displayLarge?.copyWith(
          color: Colors.white.withValues(alpha: 0.92),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class PersonTile extends StatelessWidget {
  const PersonTile({
    required this.person,
    required this.subtitle,
    this.onTap,
    this.trailing,
    super.key,
  });

  final Person person;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: PersonAvatar(person: person),
        title: Text(
          person.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
