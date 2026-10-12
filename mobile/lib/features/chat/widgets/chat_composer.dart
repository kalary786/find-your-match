import 'package:find_your_match/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ChatComposer extends StatefulWidget {
  const ChatComposer({
    required this.controller,
    required this.sending,
    required this.onSend,
    super.key,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant ChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSend =
        !widget.sending && widget.controller.text.trim().isNotEmpty;
    final muted = theme.colorScheme.onSurfaceVariant;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '100 messages a day',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: muted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('chat-input'),
                    controller: widget.controller,
                    textInputAction: TextInputAction.send,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 1,
                    maxLines: 5,
                    maxLength: 1000,
                    buildCounter:
                        (
                          context, {
                          required int currentLength,
                          required bool isFocused,
                          int? maxLength,
                        }) => null,
                    decoration: const InputDecoration(
                      hintText: 'Message…',
                    ),
                    onSubmitted: (_) {
                      if (canSend) widget.onSend();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Tooltip(
                  message: 'Send',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      // Keep tappable whenever not sending so tests/send work
                      // immediately after typing; [_send] no-ops on empty text.
                      onTap: widget.sending ? null : widget.onSend,
                      customBorder: const CircleBorder(),
                      child: Ink(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: canSend ? AppColors.brandGradient : null,
                          color: canSend
                              ? null
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.18),
                          boxShadow: canSend
                              ? [
                                  BoxShadow(
                                    color: AppColors.coral
                                        .withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(
                                opacity: widget.sending ? 0 : 1,
                                child: Icon(
                                  Icons.send,
                                  size: 20,
                                  color: canSend
                                      ? Colors.white
                                      : theme.colorScheme.onSurface
                                          .withValues(alpha: 0.45),
                                ),
                              ),
                              if (widget.sending)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
