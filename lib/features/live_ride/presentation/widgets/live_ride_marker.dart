import 'package:flutter/material.dart';

import '../../../../design_system/tokens/app_colors.dart';

/// Marcador circular con iniciales para un rider en [LiveRideMap]. El
/// líder de la rodada (organizador) se pinta en acento con texto oscuro
/// (nunca blanco sobre amarillo); el resto en bloque.
class LiveRideMarker extends StatelessWidget {
  const LiveRideMarker({
    required this.initials,
    required this.isLeader,
    super.key,
    this.isStale = false,
  });

  final String initials;
  final bool isLeader;
  final bool isStale;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final size = isLeader ? 36.0 : 32.0;
    final background = isStale
        ? colors.warning
        : (isLeader ? colors.accent : colors.block);
    final foreground = isLeader ? colors.onAccent : colors.onBlock;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(color: colors.bg, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: isLeader ? 12 : 11,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}
