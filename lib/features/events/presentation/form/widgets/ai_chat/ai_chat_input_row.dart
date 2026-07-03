import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class AiChatInputRow extends StatefulWidget {
  const AiChatInputRow({
    super.key,
    required this.onSend,
    this.disabled = false,
  });

  final ValueChanged<String> onSend;

  /// When true (quota exhausted), the input and send button are disabled.
  final bool disabled;

  @override
  State<AiChatInputRow> createState() => _AiChatInputRowState();
}

class _AiChatInputRowState extends State<AiChatInputRow> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.disabled) return;
    _controller.clear();
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !widget.disabled,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              style: TextStyle(
                color: widget.disabled
                    ? colorScheme.onSurface.withValues(alpha: 0.35)
                    : colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: widget.disabled
                    ? context.l10n.ai_chatDisabledHint
                    : context.l10n.ai_chatHint,
                hintStyle: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.35),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: widget.disabled
                    ? colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.45,
                      )
                    : colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          AppSpacing.hGapSm,
          IconButton(
            onPressed: (_hasText && !widget.disabled) ? _submit : null,
            icon: Icon(
              Icons.send_rounded,
              color: (_hasText && !widget.disabled)
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            tooltip: context.l10n.ai_sendButton,
          ),
        ],
      ),
    );
  }
}
