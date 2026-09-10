import 'package:flutter/material.dart';

import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';

/// Encabezado de EV1: solo el título, sin acción -- el frame de contenido
/// real (`EV1 — Lista`) no trae el icono de filtros que sí aparece en los
/// frames de estado (vacío/carga/error/sin conexión); sin una interacción
/// de filtro definida en el plan, se omite en vez de inventar un botón sin
/// función.
class EventsListHeader extends StatelessWidget {
  const EventsListHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Text(
        context.l10n.events_list_title,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: colors.text,
        ),
      ),
    );
  }
}
