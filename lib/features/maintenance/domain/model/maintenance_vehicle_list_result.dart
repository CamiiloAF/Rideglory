import 'package:rideglory/features/maintenance/domain/model/maintenance_list_summary.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';

class MaintenanceVehicleListResult {
  const MaintenanceVehicleListResult({
    required this.items,
    required this.summary,
  });

  final List<MaintenanceModel> items;
  final MaintenanceListSummary summary;
}
