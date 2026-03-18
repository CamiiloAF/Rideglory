import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rideglory/design_system/foundation/extensions/theme_extensions.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';

/// Reusable image picker section for event cover, vehicle photo, etc.
/// [title] and [hint] are shown in the empty state. [uploadButtonLabel] is the
/// primary action. When [showGenerateWithAI] is true, a second outline button
/// is shown and [onGenerateWithAITap] / [generateWithAILabel] are used.
class AppImagePicker extends StatelessWidget {
  const AppImagePicker({
    super.key,
    this.imageUrl,
    this.localImagePath,
    this.onPickImage,
    this.onClearTap,
    required this.title,
    this.hint,
    required this.uploadButtonLabel,
    this.showGenerateWithAI = false,
    this.onGenerateWithAITap,
    this.generateWithAILabel,
    this.labelText,
  });

  final String? imageUrl;
  final String? localImagePath;
  final VoidCallback? onPickImage;
  final VoidCallback? onClearTap;
  final String title;
  final String? hint;
  final String uploadButtonLabel;
  final bool showGenerateWithAI;
  final VoidCallback? onGenerateWithAITap;
  final String? generateWithAILabel;
  final String? labelText;

  bool get _hasImage =>
      localImagePath != null || (imageUrl != null && imageUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          onTap: onPickImage,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(8),
              border: _hasImage
                  ? Border.all(color: cs.outlineVariant)
                  : null,
            ),
            child: _hasImage
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: double.infinity,
                          child: localImagePath != null
                              ? Image.file(
                                  File(localImagePath!),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                )
                              : Image.network(
                                  imageUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                        ),
                      ),
                      if (onClearTap != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Material(
                            color: cs.onSurface.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              onTap: onClearTap,
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.close,
                                  color: cs.onSurfaceVariant,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                : SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 28,
                        horizontal: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: CustomPaint(
                                  painter: _DashedOvalPainter(
                                    color: cs.primary,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.add_a_photo,
                                size: 48,
                                color: cs.primary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: textTheme.titleLarge?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (hint != null) ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                hint!,
                                textAlign: TextAlign.center,
                                style: textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  label: uploadButtonLabel,
                                  variant: AppButtonVariant.primary,
                                  icon: Icons.upload,
                                  onPressed: onPickImage,
                                ),
                              ),
                              if (showGenerateWithAI) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _OutlinePrimaryButton(
                                    label:
                                        generateWithAILabel ?? 'Generar con IA',
                                    icon: Icons.auto_awesome,
                                    onPressed: onGenerateWithAITap,
                                    colorScheme: cs,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _OutlinePrimaryButton extends StatelessWidget {
  const _OutlinePrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.colorScheme,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.surface.withOpacity(0),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.primary, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedOvalPainter extends CustomPainter {
  _DashedOvalPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
    final path = Path()..addOval(rect);

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final length = (distance + dashWidth > metric.length)
            ? metric.length - distance
            : dashWidth;
        final extractPath = metric.extractPath(distance, distance + length);
        canvas.drawPath(extractPath, paint);
        distance += length + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
