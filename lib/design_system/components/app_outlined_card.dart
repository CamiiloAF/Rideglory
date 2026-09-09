import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radii.dart';

/// Tarjeta con borde y separadores de 1dp entre sus hijos: el contenedor
/// que envuelve listas de [RecordRow]/[SettingsRow] en toda la app
/// (agenda, historial, datos del detalle, anteriores).
///
/// Pencil: patrón repetido en `Card PRÓXIMOS`, `Card datos`, `Card
/// anteriores`.
class AppOutlinedCard extends StatelessWidget {
  const AppOutlinedCard({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.borderStrong),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Container(height: 1, color: colors.border),
          ],
        ],
      ),
    );
  }
}
