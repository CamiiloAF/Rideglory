import 'package:rideglory/features/maintenance/domain/model/maintenance_list_summary.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';

/// All maintenances for the current user plus per-vehicle list summaries from the API.
class MaintenanceUserListAggregate {
  const MaintenanceUserListAggregate({
    required this.items,
    required this.summariesByVehicleId,
  });

  final List<MaintenanceModel> items;
  final Map<String, MaintenanceListSummary> summariesByVehicleId;
}
