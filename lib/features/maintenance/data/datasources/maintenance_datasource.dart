import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../dto/maintenance_dto.dart';
import '../dto/vehicle_option_dto.dart';

/// Acceso directo a Supabase para mantenimiento. Sin `Either` ni
/// `DomainException` aquí: eso lo traduce el repositorio.
@injectable
class MaintenanceDatasource {
  const MaintenanceDatasource(this._client);

  final SupabaseClient _client;

  Future<List<VehicleOptionDto>> getVehicles() async {
    final rows = await _client
        .from('vehicles')
        .select(
          'id, name, brand, model, license_plate, current_mileage, is_main',
        )
        .filter('archived_at', 'is', null)
        .order('is_main', ascending: false)
        .order('created_at');
    return rows.map(VehicleOptionDto.fromJson).toList();
  }

  Future<List<MaintenanceDto>> getMaintenances() async {
    final rows = await _client
        .from('maintenances')
        .select('*, vehicles(name, brand, model)')
        .order('service_date', ascending: false);
    return rows.map(MaintenanceDto.fromJson).toList();
  }

  /// Inserta y, si aplica, actualiza el odómetro de la moto en la misma
  /// operación (D5), vía la función de Postgres `register_maintenance`.
  Future<MaintenanceDto> registerMaintenance({
    required String vehicleId,
    required String type,
    required DateTime serviceDate,
    required int odometer,
    double? cost,
    String? workshop,
    String? notes,
    DateTime? nextDate,
    int? nextOdometer,
  }) async {
    final row = await _client.rpc<Map<String, dynamic>>(
      'register_maintenance',
      params: {
        'p_vehicle_id': vehicleId,
        'p_type': type,
        'p_service_date': _dateOnly(serviceDate),
        'p_odometer': odometer,
        'p_cost': cost,
        'p_workshop': workshop,
        'p_notes': notes,
        'p_next_date': nextDate != null ? _dateOnly(nextDate) : null,
        'p_next_odometer': nextOdometer,
      },
    );
    return MaintenanceDto.fromJson(row);
  }

  Future<MaintenanceDto> updateMaintenance({
    required String id,
    required String vehicleId,
    required String type,
    required DateTime serviceDate,
    required int odometer,
    double? cost,
    String? workshop,
    String? notes,
    DateTime? nextDate,
    int? nextOdometer,
  }) async {
    final row = await _client
        .from('maintenances')
        .update({
          'type': type,
          'service_date': _dateOnly(serviceDate),
          'odometer': odometer,
          'cost': cost,
          'workshop': workshop,
          'notes': notes,
          'next_date': nextDate != null ? _dateOnly(nextDate) : null,
          'next_odometer': nextOdometer,
        })
        .eq('id', id)
        .select('*, vehicles(name, brand, model)')
        .single();

    // Actualización del odómetro derivado (D5), best-effort: la edición no
    // es la operación atómica que exige el contrato (esa es el registro),
    // pero mantiene el odómetro consistente si el usuario corrige el km.
    await _client
        .from('vehicles')
        .update({'current_mileage': odometer})
        .eq('id', vehicleId)
        .lt('current_mileage', odometer);

    return MaintenanceDto.fromJson(row);
  }

  Future<void> deleteMaintenance(String id) async {
    await _client.from('maintenances').delete().eq('id', id);
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
