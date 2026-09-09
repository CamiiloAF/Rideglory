import 'package:flutter/widgets.dart';

import '../../../../design_system/components/app_outlined_card.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/maintenance_agenda_item.dart';
import 'maintenance_agenda_row.dart';
import 'maintenance_section_title.dart';

/// Sección "PRÓXIMOS": una tarjeta con una fila por servicio próximo o
/// vencido. No se renderiza si no hay ítems (la agenda vacía no es un
/// "estado vacío" de pantalla completa, solo una sección ausente).
class MaintenanceAgendaSection extends StatelessWidget {
  const MaintenanceAgendaSection({
    required this.items,
    required this.onItemTap,
    super.key,
  });

  final List<MaintenanceAgendaItem> items;
  final ValueChanged<MaintenanceAgendaItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        MaintenanceSectionTitle(context.l10n.maintenance_section_agenda),
        const SizedBox(height: 6),
        AppOutlinedCard(
          children: [
            for (final item in items)
              MaintenanceAgendaRow(item: item, onTap: () => onItemTap(item)),
          ],
        ),
      ],
    );
  }
}
