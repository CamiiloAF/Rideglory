import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/models/vehicle_documents_summary.dart';
import '../../domain/usecases/get_vehicle_documents_usecase.dart';

/// SOAT y RTM de una moto, para la fila ancha de documentos en editar
/// moto y para la alerta de la galería del garaje.
@injectable
class VehicleDocumentsCubit extends Cubit<ResultState<VehicleDocumentsSummary>> {
  VehicleDocumentsCubit(this._getVehicleDocuments) : super(const ResultState.initial());

  final GetVehicleDocumentsUseCase _getVehicleDocuments;

  Future<void> load(String vehicleId) async {
    emit(const ResultState.loading());
    final result = await _getVehicleDocuments(vehicleId);
    result.fold(
      (error) => emit(ResultState.error(error: error)),
      (summary) => emit(ResultState.data(data: summary)),
    );
  }
}
