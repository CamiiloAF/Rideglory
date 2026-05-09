/// Aggregated service dates/mileage for a vehicle’s maintenance list (computed server-side).
class MaintenanceListSummary {
  const MaintenanceListSummary({
    this.lastServiceDate,
    this.lastServiceMileage,
    this.nextServiceDate,
  });

  final DateTime? lastServiceDate;
  final int? lastServiceMileage;
  final DateTime? nextServiceDate;
}
