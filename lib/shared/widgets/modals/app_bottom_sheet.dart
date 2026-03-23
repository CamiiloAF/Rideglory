import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class AppBottomSheet<T> extends StatelessWidget {
  final String title;
  final String? description;
  final Widget Function(BuildContext) contentBuilder;
  final VoidCallback? onCancel;
  final bool showDragHandle;
  final bool isScrollable;

  const AppBottomSheet({
    super.key,
    required this.title,
    this.description,
    required this.contentBuilder,
    this.onCancel,
    this.showDragHandle = true,
    this.isScrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDragHandle)
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (description != null) ...[
                  AppSpacing.gapXxs,
                  Text(description!, style: context.bodyMedium),
                ],
              ],
            ),
          ),
          // Content
          Flexible(
            child: isScrollable
                ? SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: contentBuilder(context),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: contentBuilder(context),
                  ),
          ),
          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? description,
    required Widget Function(BuildContext) contentBuilder,
    bool isDismissible = true,
    bool enableDrag = true,
    bool showDragHandle = true,
    bool isScrollable = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorScheme.surface.withOpacity(0),
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      builder: (context) => AppBottomSheet(
        title: title,
        description: description,
        contentBuilder: contentBuilder,
        showDragHandle: showDragHandle,
        isScrollable: isScrollable,
      ),
    );
  }
}
