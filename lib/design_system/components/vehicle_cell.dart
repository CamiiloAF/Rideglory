import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radii.dart';
import 'app_photo_chip.dart';
import 'app_status_chip.dart';

/// Celda de moto para la galería del garaje: foto, nombre, badge principal
/// y kilometraje, con un chip de estado opcional sobre la foto.
///
/// El chip cubre dos avisos distintos del `.pen` (`YXXpJ`): mantenimiento
/// atrasado (gota, tono error) y documento por vencer (triángulo, tono
/// warning/error) — por eso [pendingIcon] y [pendingTone] son configurables
/// en vez de fijos.
///
/// Pencil: YXXpJ
class VehicleCell extends StatelessWidget {
  const VehicleCell({
    required this.name,
    required this.kilometers,
    this.imageUrl,
    this.isMain = false,
    this.pendingLabel,
    this.pendingIcon = LucideIcons.droplet,
    this.pendingTone = AppStatusTone.error,
    this.onTap,
    super.key,
  });

  final String name;
  final String kilometers;
  final String? imageUrl;
  final bool isMain;
  final String? pendingLabel;
  final IconData pendingIcon;
  final AppStatusTone pendingTone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: colors.surface),
                  if (imageUrl != null)
                    CachedNetworkImage(imageUrl: imageUrl!, fit: BoxFit.cover),
                  if (pendingLabel != null)
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: AppPhotoChip(
                          icon: pendingIcon,
                          label: pendingLabel!,
                          tone: pendingTone,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: colors.text,
                  ),
                ),
              ),
              if (isMain) ...[
                const SizedBox(width: 5),
                Icon(LucideIcons.star, size: 14, color: colors.textSecondary),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Text(
            kilometers,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: colors.text,
            ),
          ),
        ],
      ),
    );
  }
}
