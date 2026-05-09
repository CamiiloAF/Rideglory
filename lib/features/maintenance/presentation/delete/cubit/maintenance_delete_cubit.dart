import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/delete_maintenance_use_case.dart';

part 'maintenance_delete_cubit.freezed.dart';
part 'maintenance_delete_state.dart';

@injectable
class MaintenanceDeleteCubit extends Cubit<MaintenanceDeleteState> {
  MaintenanceDeleteCubit(this._deleteMaintenanceUseCase)
    : super(const MaintenanceDeleteState.initial());

  final DeleteMaintenanceUseCase _deleteMaintenanceUseCase;

  Future<void> deleteMaintenance(MaintenanceModel maintenance) async {
    final maintenanceId = maintenance.id;
    if (maintenanceId == null) {
      emit(const MaintenanceDeleteState.error(message: 'Missing maintenance id'));
      return;
    }

    emit(const MaintenanceDeleteState.loading());

    final result = await _deleteMaintenanceUseCase(maintenance);

    result.fold(
      (error) => emit(MaintenanceDeleteState.error(message: error.message)),
      (_) => emit(MaintenanceDeleteState.success(deletedId: maintenanceId)),
    );
  }

  void reset() {
    emit(const MaintenanceDeleteState.initial());
  }
}
