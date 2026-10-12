import 'package:find_your_match/core/theme/app_colors.dart';
import 'package:find_your_match/features/preview/preview_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum BubbleGroupPosition { single, first, middle, last }

class MessageBubble extends StatefulWidget {
  const MessageBubble({
    required this.message,
    required this.position,
    required this.animateIn,
    super.key,
  });

  final ChatMessage message;
  final BubbleGroupPosition position;
  final bool animateIn;

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  var _visible = false;

  @override
  void initState() {
    super.initState();
    if (widget.animateIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _visible = true);
      });
    } else {
      _visible = true;
    }
  }

  BorderRadius _radius(bool mine) {
    const large = 20.0;
    const tight = 6.0;
    final pos = widget.position;
    final topOuter = pos == BubbleGroupPosition.single ||
            pos == BubbleGroupPosition.first
        ? large
        : tight;
    final bottomOuter = pos == BubbleGroupPosition.single ||
            pos == BubbleGroupPosition.last
        ? large
        : tight;

    if (mine) {
      return BorderRadius.only(
        topLeft: const Radius.circular(large),
        bottomLeft: const Radius.circular(large),
        topRight: Radius.circular(topOuter),
        bottomRight: Radius.circular(bottomOuter),
      );
    }
    return BorderRadius.only(
      topRight: const Radius.circular(large),
      bottomRight: const Radius.circular(large),
      topLeft: Radius.circular(topOuter),
      bottomLeft: Radius.circular(bottomOuter),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: widget.message.text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mine = widget.message.fromMe;
    final showTime = widget.position == BubbleGroupPosition.single ||
        widget.position == BubbleGroupPosition.last;
    final brightness = theme.brightness;
    final textColor = mine ? Colors.white : theme.colorScheme.onSurface;
    final timeColor = textColor.withValues(alpha: 0.7);

    final bubble = Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.76,
        ),
        child: GestureDetector(
          onLongPress: () => _copy(context),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: mine ? AppColors.brandGradient : null,
              color: mine
                  ? null
                  : AppColors.bubbleThemOf(brightness),
              borderRadius: _radius(mine),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.message.text,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: textColor,
                      ),
                    ),
                  ),
                  if (showTime) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.message.timeLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10.5,
                        color: timeColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return AnimatedSlide(
      offset: _visible ? Offset.zero : Offset(0, mine ? 0.12 : 0.08),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: bubble,
      ),
    );
  }
}

BubbleGroupPosition bubbleGroupPosition({
  required List<ChatMessage> messages,
  required int index,
}) {
  final current = messages[index];
  final prevSame =
      index > 0 && messages[index - 1].fromMe == current.fromMe;
  final nextSame = index < messages.length - 1 &&
      messages[index + 1].fromMe == current.fromMe;
  if (!prevSame && !nextSame) return BubbleGroupPosition.single;
  if (!prevSame && nextSame) return BubbleGroupPosition.first;
  if (prevSame && nextSame) return BubbleGroupPosition.middle;
  return BubbleGroupPosition.last;
}

double bubbleBottomSpacing({
  required List<ChatMessage> messages,
  required int index,
}) {
  if (index >= messages.length - 1) return 0;
  final same = messages[index].fromMe == messages[index + 1].fromMe;
  return same ? 3 : 10;
}
