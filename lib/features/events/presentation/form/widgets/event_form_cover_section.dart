import 'dart:io';

import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';

class EventFormCoverSection extends StatelessWidget {
  const EventFormCoverSection({
    super.key,
    this.imageUrl,
    this.localImagePath,
    this.onUploadTap,
    this.onClearTap,
    this.onGenerateWithAITap,
  });

  final String? imageUrl;
  final String? localImagePath;
  final VoidCallback? onUploadTap;
  final VoidCallback? onClearTap;
  final VoidCallback? onGenerateWithAITap;

  bool get _hasImage =>
      localImagePath != null || (imageUrl != null && imageUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onUploadTap,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(8),
              border: _hasImage
                  ? Border.all(color: AppColors.darkBorder)
                  : null,
            ),
            child: _hasImage
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: localImagePath != null
                            ? Image.file(
                                File(localImagePath!),
                                fit: BoxFit.cover,
                                height: 220,
                                width: double.infinity,
                              )
                            : Image.network(
                                imageUrl!,
                                fit: BoxFit.cover,
                                height: 220,
                                width: double.infinity,
                              ),
                      ),
                      if (onClearTap != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Material(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              onTap: onClearTap,
                              borderRadius: BorderRadius.circular(20),
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 28,
                      horizontal: 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: CustomPaint(
                                painter: _DashedOvalPainter(
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.add_a_photo,
                              size: 48,
                              color: colorScheme.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          EventStrings.addEventCover,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            EventStrings.addEventCoverHint,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.darkTextSecondary),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: EventStrings.uploadImage,
                                variant: AppButtonVariant.primary,
                                icon: Icons.upload,
                                onPressed: onUploadTap,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _OutlinePrimaryButton(
                                label: EventStrings.generateWithAI,
                                icon: Icons.auto_awesome,
                                onPressed: onGenerateWithAITap,
                                colorScheme: colorScheme,
                              ),
                            ),
                          ],
                        ),
                      ],
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
      color: Colors.transparent,
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
