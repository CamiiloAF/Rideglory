import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/soat/domain/models/soat_model.dart';
import 'package:rideglory/features/soat/domain/usecases/delete_soat_usecase.dart';
import 'package:rideglory/features/soat/domain/usecases/get_soat_usecase.dart';
import 'package:rideglory/features/soat/domain/usecases/save_soat_usecase.dart';
import 'package:rideglory/features/vehicle_documents/presentation/cubit/vehicle_document_cubit.dart';

@injectable
class SoatCubit extends VehicleDocumentCubit<SoatModel> {
  SoatCubit(
    this._getSoatUseCase,
    this._saveSoatUseCase,
    this._deleteSoatUseCase,
    this._analytics,
  );

  final GetSoatUseCase _getSoatUseCase;
  final SaveSoatUseCase _saveSoatUseCase;
  final DeleteSoatUseCase _deleteSoatUseCase;
  final AnalyticsService _analytics;

  @override
  Future<void> load(String vehicleId) async {
    emit(const ResultState.loading());
    final result = await _getSoatUseCase(vehicleId);
    result.fold((error) => emit(ResultState.error(error: error)), (soat) {
      if (soat == null) {
        emit(const ResultState.empty());
      } else {
        _analytics
            .logEvent(AnalyticsEvents.soatStatusViewed, {
              AnalyticsParams.soatStatus: soat.status.name,
            })
            .ignore();
        emit(ResultState.data(data: soat));
      }
    });
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
        // Un id no vacío indica edición de un SOAT existente; vacío = creación.
        final isUpdate = soat.id.isNotEmpty;
        _analytics
            .logEvent(
              isUpdate
                  ? AnalyticsEvents.soatUpdated
                  : AnalyticsEvents.soatManualSaved,
              {AnalyticsParams.hadPdf: 0},
            )
            .ignore();
        emit(ResultState.data(data: saved));
        return true;
      },
    );
  }

  Future<bool> delete(String vehicleId) async {
    emit(const ResultState.loading());
    final result = await _deleteSoatUseCase(vehicleId);
    return result.fold(
      (error) {
        emit(ResultState.error(error: error));
        return false;
      },
      (_) {
        _analytics.logEvent(AnalyticsEvents.soatDeleted).ignore();
        emit(const ResultState.empty());
        return true;
      },
    );
  }
}
