import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/components/app_photo_chip.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../domain/event_difficulty.dart';
import '../event_labels.dart';

/// Hero del detalle: foto, botón volver y chip de dificultad.
class EventDetailHero extends StatelessWidget {
  const EventDetailHero({required this.difficulty, this.imageUrl, super.key});

  final EventDifficulty difficulty;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: colors.block,
            child: imageUrl == null
                ? null
                : CachedNetworkImage(imageUrl: imageUrl!, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.plate,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      LucideIcons.arrowLeft,
                      size: 20,
                      color: colors.plateText,
                    ),
                  ),
                ),
                AppPhotoChip(
                  icon: LucideIcons.gauge,
                  label: eventDifficultyLabel(context, difficulty),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
