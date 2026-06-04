import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/vehicle_documents/domain/vehicle_document_model.dart';

/// Abstract cubit base for features that load a single vehicle document.
///
/// Concrete subclasses (e.g. [SoatCubit]) override [load] and may add extra
/// methods (save, delete). The generic state is [ResultState<T>] so that
/// generic UI scaffolds can be typed against this cubit.
abstract class VehicleDocumentCubit<T extends VehicleDocumentModel>
    extends Cubit<ResultState<T>> {
  VehicleDocumentCubit() : super(const ResultState.initial());

  Future<void> load(String vehicleId);
}
