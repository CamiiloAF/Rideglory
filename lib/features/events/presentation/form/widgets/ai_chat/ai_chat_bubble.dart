import 'package:flutter/material.dart';
import 'package:rideglory/features/events/domain/model/ai_chat_turn.dart';

class AiChatBubble extends StatelessWidget {
  const AiChatBubble({
    super.key,
    required this.turn,
    this.onCopy,
    this.onInsert,
  });

  final AiChatTurn turn;
  final VoidCallback? onCopy;
  final VoidCallback? onInsert;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUser = turn.role == AiChatRole.user;
    final showActions = onCopy != null || onInsert != null;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.fromLTRB(14, 10, showActions ? 4 : 14, showActions ? 4 : 10),
        decoration: BoxDecoration(
          color: isUser
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(right: showActions ? 10 : 0),
                child: Text(
                  turn.content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isUser
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                ),
              ),
            ),
            if (showActions) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onCopy != null)
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 15,
                        icon: Icon(
                          Icons.content_copy_outlined,
                          color: (isUser
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface)
                              .withValues(alpha: 0.55),
                        ),
                        tooltip: 'Copiar',
                        onPressed: onCopy,
                      ),
                    ),
                  if (onInsert != null)
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 15,
                        icon: Icon(
                          Icons.file_download_outlined,
                          color: colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                        tooltip: 'Insertar en descripción',
                        onPressed: onInsert,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
