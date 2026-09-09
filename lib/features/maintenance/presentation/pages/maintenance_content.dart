import 'package:flutter/widgets.dart';

import '../../domain/maintenance.dart';
import '../cubit/maintenance_state.dart';
import '../widgets/maintenance_agenda_section.dart';
import '../widgets/maintenance_history_section.dart';
import '../widgets/vehicle_filter_row.dart';

/// Cuerpo con datos: filtro por moto, agenda y historial.
class MaintenanceContent extends StatelessWidget {
  const MaintenanceContent({
    required this.state,
    required this.onVehicleSelected,
    required this.onAgendaItemTap,
    required this.onHistoryEntryTap,
    super.key,
  });

  final MaintenanceState state;
  final ValueChanged<String?> onVehicleSelected;
  final void Function(String maintenanceId) onAgendaItemTap;
  final ValueChanged<Maintenance> onHistoryEntryTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      children: [
        VehicleFilterRow(
          vehicles: state.vehicleList,
          selectedVehicleId: state.selectedVehicleId,
          onSelected: onVehicleSelected,
        ),
        const SizedBox(height: 14),
        MaintenanceAgendaSection(
          items: state.agendaItems,
          onItemTap: (item) => onAgendaItemTap(item.sourceMaintenanceId),
        ),
        if (state.agendaItems.isNotEmpty) const SizedBox(height: 14),
        MaintenanceHistorySection(
          groups: state.historyGroups,
          onEntryTap: onHistoryEntryTap,
        ),
      ],
    );
  }
}
