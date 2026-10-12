import 'package:find_your_match/core/theme/app_colors.dart';
import 'package:find_your_match/core/theme/app_tokens.dart';
import 'package:find_your_match/core/widgets/verified_badge.dart';
import 'package:find_your_match/features/preview/preview_models.dart';
import 'package:flutter/material.dart';

class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    required this.person,
    this.size = 48,
    this.showOnline = false,
    this.storyRing = false,
    this.heroTag,
    super.key,
  });

  final Person person;
  final double size;
  final bool showOnline;
  final bool storyRing;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final color = HSLColor.fromAHSL(1, person.hue, 0.48, 0.42).toColor();
    final photo = person.photoUrl;
    final cacheWidth = (size * MediaQuery.devicePixelRatioOf(context)).round();
    Widget avatar = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: photo == null || photo.isEmpty
            ? ColoredBox(
                color: color,
                child: Center(
                  child: Text(
                    person.initials,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: size * 0.32,
                    ),
                  ),
                ),
              )
            : Image.network(
                photo,
                width: size,
                height: size,
                fit: BoxFit.cover,
                cacheWidth: cacheWidth,
                errorBuilder: (context, error, stackTrace) {
                  return ColoredBox(
                    color: color,
                    child: Center(
                      child: Text(
                        person.initials,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: size * 0.32,
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );

    if (heroTag != null) {
      avatar = Hero(tag: heroTag!, child: avatar);
    }

    if (storyRing) {
      avatar = Container(
        padding: const EdgeInsets.all(2.5),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.storyGradient,
        ),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.surface,
          ),
          child: avatar,
        ),
      );
    }

    if (!showOnline || !person.online) return avatar;

    final surface = Theme.of(context).colorScheme.surface;
    final box = storyRing ? size + 9 : size;
    return SizedBox(
      width: box,
      height: box,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: storyRing ? 2 : 0,
            bottom: storyRing ? 2 : 0,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: AppColors.online,
                shape: BoxShape.circle,
                border: Border.all(color: surface, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PersonCover extends StatefulWidget {
  const PersonCover({
    required this.person,
    this.height = 280,
    this.borderRadius,
    this.heroTag,
    super.key,
  });

  final Person person;
  final double height;
  final BorderRadius? borderRadius;
  final Object? heroTag;

  @override
  State<PersonCover> createState() => _PersonCoverState();
}

class _PersonCoverState extends State<PersonCover>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    // Avoid infinite animations in widget tests (pumpAndSettle).
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
    final theme = Theme.of(context);
    final base = HSLColor.fromAHSL(1, widget.person.hue, 0.52, 0.38).toColor();
    final photo = widget.person.photoUrl;
    final radius = widget.borderRadius ?? AppTokens.xl;
    final child = ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: base),
            if (photo == null || photo.isEmpty)
              _Initials(person: widget.person, theme: theme)
            else
              Image.network(
                photo,
                fit: BoxFit.cover,
                width: double.infinity,
                height: widget.height,
                cacheWidth: (MediaQuery.sizeOf(context).width *
                        MediaQuery.devicePixelRatioOf(context))
                    .round()
                    .clamp(320, 1200),
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  final ready = wasSynchronouslyLoaded || frame != null;
                  if (ready && !_loaded) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _loaded = true);
                    });
                  }
                  return AnimatedOpacity(
                    opacity: ready ? 1 : 0,
                    duration: AppTokens.durationNormal,
                    child: child,
                  );
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) {
                      return ColoredBox(
                        color: Color.lerp(
                          base,
                          Colors.white,
                          0.08 + _pulse.value * 0.08,
                        )!,
                        child: Center(
                          child: Text(
                            widget.person.initials,
                            style: theme.textTheme.displayMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return _Initials(person: widget.person, theme: theme);
                },
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Color(0x99000000),
                    Color(0xCC000000),
                  ],
                  stops: [0, 0.45, 0.78, 1],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (widget.heroTag == null) return child;
    return Hero(tag: widget.heroTag!, child: child);
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
    this.showOnline = false,
    super.key,
  });

  final Person person;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showOnline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: AppTokens.lg,
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: AppTokens.lg),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space12,
          vertical: AppTokens.space4,
        ),
        leading: PersonAvatar(person: person, showOnline: showOnline),
        title: Row(
          children: [
            Flexible(
              child: Text(
                person.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (person.verified) ...[
              const SizedBox(width: 4),
              const VerifiedBadge(size: 16),
            ],
          ],
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
