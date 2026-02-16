import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/get_maintenance_list_use_case.dart';

class MaintenancesCubit extends Cubit<ResultState<List<MaintenanceModel>>> {
  MaintenancesCubit(this._getMaintenancesUseCase)
    : super(const ResultState.initial());

  final GetMaintenanceListUseCase _getMaintenancesUseCase;

  Future<void> fetchMaintenances() async {
    emit(const ResultState.loading());
    final result = await _getMaintenancesUseCase.execute();

    result.fold((error) => emit(ResultState.error(error: error)), (
      maintenances,
    ) {
      if (maintenances.isEmpty) {
        emit(const ResultState.empty());
      } else {
        emit(ResultState.data(data: maintenances));
      }
    });
  }
}
