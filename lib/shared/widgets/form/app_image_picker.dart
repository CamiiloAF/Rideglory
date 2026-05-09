import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:shimmer/shimmer.dart';

const double _kFormImagePreviewAspectRatio = 16 / 9;

/// Reusable image picker section for event cover, vehicle photo, etc.
/// [title] and [hint] are shown in the empty state. [uploadButtonLabel] is the
/// primary action. When [showGenerateWithAI] is true, a second outline button
/// is shown and [onGenerateWithAITap] / [generateWithAILabel] are used.
///
/// Remote previews use a fixed aspect ratio so layout does not jump; loading
/// states show a shimmer placeholder.
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
    this.guardPhotoPermission = true,
    this.permissionDialogTitle,
    this.permissionDeniedMessage,
    this.permissionPermanentlyDeniedMessage,
    this.openSettingsLabel,
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
  final bool guardPhotoPermission;
  final String? permissionDialogTitle;
  final String? permissionDeniedMessage;
  final String? permissionPermanentlyDeniedMessage;
  final String? openSettingsLabel;

  bool get _hasImage =>
      localImagePath != null || (imageUrl != null && imageUrl!.isNotEmpty);

  Permission get _galleryPermission {
    if (Platform.isIOS) return Permission.photos;
    // On modern Android this maps to READ_MEDIA_IMAGES; on older versions it
    // falls back to legacy storage permission.
    return Permission.photos;
  }

  Future<bool> _requestPhotoPermission() async {
    final status = await _galleryPermission.request();
    return status.isGranted || status.isLimited;
  }

  Future<bool> _isPhotoPermissionPermanentlyDenied() async {
    final status = await _galleryPermission.status;
    return status.isPermanentlyDenied;
  }

  Future<void> _showPermissionDeniedDialog(
    BuildContext context, {
    required bool isPermanentlyDenied,
  }) async {
    final title = permissionDialogTitle ?? context.l10n.photoPermissionTitle;
    final message = isPermanentlyDenied
        ? (permissionPermanentlyDeniedMessage ??
              context.l10n.photoPermissionPermanentlyDenied)
        : (permissionDeniedMessage ?? context.l10n.photoPermissionDenied);

    if (!isPermanentlyDenied) {
      await InfoDialog.show(
        context: context,
        title: title,
        content: message,
        type: DialogType.warning,
      );
      return;
    }

    final openSettings = await ConfirmationDialog.show(
      context: context,
      title: title,
      content: message,
      cancelLabel: context.l10n.accept,
      confirmLabel: openSettingsLabel ?? context.l10n.openSettings,
      confirmType: DialogActionType.primary,
      dialogType: DialogType.warning,
      isDismissible: true,
    );

    if (openSettings == true) {
      await openAppSettings();
    }
  }

  Future<void> _handlePickImageTap(BuildContext context) async {
    if (onPickImage == null) return;
    if (!guardPhotoPermission) {
      onPickImage?.call();
      return;
    }

    final granted = await _requestPhotoPermission();
    if (!context.mounted) return;
    if (granted) {
      onPickImage?.call();
      return;
    }

    final permanentlyDenied = await _isPhotoPermissionPermanentlyDenied();
    if (!context.mounted) return;
    await _showPermissionDeniedDialog(
      context,
      isPermanentlyDenied: permanentlyDenied,
    );
  }

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
          AppSpacing.gapSm,
        ],
        GestureDetector(
          onTap: () => _handlePickImageTap(context),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(8),
              border: _hasImage ? Border.all(color: cs.outlineVariant) : null,
            ),
            child: _hasImage
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AspectRatio(
                          aspectRatio: _kFormImagePreviewAspectRatio,
                          child: localImagePath != null
                              ? Image.file(
                                  File(localImagePath!),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                )
                              : CachedNetworkImage(
                                  imageUrl: imageUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fadeInDuration: const Duration(
                                    milliseconds: 200,
                                  ),
                                  placeholder: (context, url) =>
                                      Shimmer.fromColors(
                                        baseColor: cs.surfaceContainerHighest,
                                        highlightColor: cs.primary.withValues(
                                          alpha: 0.14,
                                        ),
                                        period: const Duration(
                                          milliseconds: 1200,
                                        ),
                                        child: ColoredBox(
                                          color: cs.surfaceContainerHighest,
                                          child: const SizedBox.expand(),
                                        ),
                                      ),
                                  errorWidget: (context, url, error) =>
                                      ColoredBox(
                                        color: cs.surfaceContainerHighest,
                                        child: Center(
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                            size: 48,
                                            color: cs.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
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
                          AppSpacing.gapXl,
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: textTheme.titleLarge?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (hint != null) ...[
                            AppSpacing.gapSm,
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
                          AppSpacing.gapXxl,
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  label: uploadButtonLabel,
                                  variant: AppButtonVariant.primary,
                                  icon: Icons.upload,
                                  onPressed: () => _handlePickImageTap(context),
                                ),
                              ),
                              if (showGenerateWithAI) ...[
                                AppSpacing.hGapMd,
                                Expanded(
                                  child: _OutlinePrimaryButton(
                                    label:
                                        generateWithAILabel ??
                                        context.l10n.generateWithAI,
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
              AppSpacing.hGapSm,
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
