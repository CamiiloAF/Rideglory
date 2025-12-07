import 'package:bloc/bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';

class MaintenanceFormCubit extends Cubit<ResultState<MaintenanceModel>> {
  MaintenanceFormCubit() : super(const ResultState.initial());

  Future<void> _addMaintenance(MaintenanceModel maintenance) async {
    emit(const ResultState.loading());

    emit(ResultState.data(data: maintenance));
  }

  Future<void> _updateMaintenance(MaintenanceModel maintenance) async {
    emit(const ResultState.loading());

    emit(ResultState.data(data: maintenance));
  }

  Future<void> saveMaintenance(MaintenanceModel maintenance) async {
    if (maintenance.id == null) {
      await _addMaintenance(maintenance);
    } else {
      await _updateMaintenance(maintenance);
    }
  }
}
