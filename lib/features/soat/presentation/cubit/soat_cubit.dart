import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/soat/domain/models/soat_model.dart';
import 'package:rideglory/features/soat/domain/usecases/get_soat_usecase.dart';
import 'package:rideglory/features/soat/domain/usecases/save_soat_usecase.dart';

@injectable
class SoatCubit extends Cubit<ResultState<SoatModel>> {
  SoatCubit(
    this._getSoatUseCase,
    this._saveSoatUseCase,
  ) : super(const ResultState.initial());

  final GetSoatUseCase _getSoatUseCase;
  final SaveSoatUseCase _saveSoatUseCase;

  Future<void> load(String vehicleId) async {
    emit(const ResultState.loading());
    final result = await _getSoatUseCase(vehicleId);
    result.fold(
      (error) => emit(ResultState.error(error: error)),
      (soat) {
        if (soat == null) {
          emit(const ResultState.empty());
        } else {
          emit(ResultState.data(data: soat));
        }
      },
    );
  }

  Future<bool> save({
    required String vehicleId,
    required SoatModel soat,
  }) async {
    emit(const ResultState.loading());
    final result = await _saveSoatUseCase(vehicleId: vehicleId, soat: soat);
    return result.fold(
      (error) {
        emit(ResultState.error(error: error));
        return false;
      },
      (saved) {
        emit(ResultState.data(data: saved));
        return true;
      },
    );
  }
}
