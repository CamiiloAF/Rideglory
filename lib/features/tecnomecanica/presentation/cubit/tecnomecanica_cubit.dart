import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/tecnomecanica/domain/models/tecnomecanica_model.dart';
import 'package:rideglory/features/tecnomecanica/domain/usecases/delete_tecnomecanica_usecase.dart';
import 'package:rideglory/features/tecnomecanica/domain/usecases/get_tecnomecanica_usecase.dart';
import 'package:rideglory/features/tecnomecanica/domain/usecases/save_tecnomecanica_usecase.dart';
import 'package:rideglory/features/vehicle_documents/presentation/cubit/vehicle_document_cubit.dart';

@injectable
class TecnomecanicaCubit extends VehicleDocumentCubit<TecnomecanicaModel> {
  TecnomecanicaCubit(
    this._getTecnomecanicaUseCase,
    this._saveTecnomecanicaUseCase,
    this._deleteTecnomecanicaUseCase,
    this._analytics,
  );

  final GetTecnomecanicaUseCase _getTecnomecanicaUseCase;
  final SaveTecnomecanicaUseCase _saveTecnomecanicaUseCase;
  final DeleteTecnomecanicaUseCase _deleteTecnomecanicaUseCase;
  final AnalyticsService _analytics;

  @override
  Future<void> load(String vehicleId) async {
    emit(const ResultState.loading());
    final result = await _getTecnomecanicaUseCase(vehicleId);
    result.fold((error) => emit(ResultState.error(error: error)), (rtm) {
      if (rtm == null) {
        emit(const ResultState.empty());
      } else {
        _analytics.logEvent(AnalyticsEvents.tecnomecanicaStatusViewed, {
          AnalyticsParams.rtmStatus: rtm.documentStatus.name,
        }).ignore();
        emit(ResultState.data(data: rtm));
      }
    });
  }

  Future<bool> save({
    required String vehicleId,
    required TecnomecanicaModel tecnomecanica,
  }) async {
    emit(const ResultState.loading());
    final result = await _saveTecnomecanicaUseCase(
      vehicleId: vehicleId,
      tecnomecanica: tecnomecanica,
    );
    return result.fold(
      (error) {
        emit(ResultState.error(error: error));
        return false;
      },
      (saved) {
        final isUpdate = tecnomecanica.id.isNotEmpty;
        _analytics
            .logEvent(
              isUpdate
                  ? AnalyticsEvents.tecnomecanicaUpdated
                  : AnalyticsEvents.tecnomecanicaManualSaved,
            )
            .ignore();
        emit(ResultState.data(data: saved));
        return true;
      },
    );
  }

  Future<bool> delete(String vehicleId) async {
    emit(const ResultState.loading());
    final result = await _deleteTecnomecanicaUseCase(vehicleId);
    return result.fold(
      (error) {
        emit(ResultState.error(error: error));
        return false;
      },
      (_) {
        _analytics.logEvent(AnalyticsEvents.tecnomecanicaDeleted).ignore();
        emit(const ResultState.empty());
        return true;
      },
    );
  }
}
