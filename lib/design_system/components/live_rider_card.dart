import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radii.dart';

/// Tarjeta de un rider en la hoja/lista de la rodada en vivo (LV1, LV1b,
/// LV6): avatar con iniciales, nombre, distancia y frescura de la señal,
/// y un botón de llamar opcional (solo lo usa LV6, el organizador).
///
/// [isLeader] pinta el avatar en acento con texto oscuro (nunca blanco
/// sobre amarillo). [staleColor] permite que quien arma la pantalla pinte
/// "Sin señal hace X min" en advertencia sin que este componente conozca
/// reglas de negocio de frescura.
///
/// Pencil: eq7IG
class LiveRiderCard extends StatelessWidget {
  const LiveRiderCard({
    required this.initials,
    required this.name,
    required this.metaText,
    super.key,
    this.isLeader = false,
    this.metaColor,
    this.onCall,
  });

  final String initials;
  final String name;
  final String metaText;
  final bool isLeader;
  final Color? metaColor;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.borderStrong),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isLeader ? colors.accent : colors.block,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isLeader ? colors.onAccent : colors.onBlock,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      LucideIcons.mapPin,
                      size: 12,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        metaText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: metaColor ?? colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onCall != null) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 48,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: IconButton(
                  onPressed: onCall,
                  icon: Icon(LucideIcons.phone, size: 18, color: colors.text),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
