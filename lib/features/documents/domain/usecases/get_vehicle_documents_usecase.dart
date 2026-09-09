import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../models/vehicle_documents_summary.dart';
import '../repository/documents_repository.dart';

@injectable
class GetVehicleDocumentsUseCase {
  const GetVehicleDocumentsUseCase(this._repository);

  final DocumentsRepository _repository;

  Future<Either<DomainException, VehicleDocumentsSummary>> call(String vehicleId) {
    return _repository.getDocuments(vehicleId);
  }
}
