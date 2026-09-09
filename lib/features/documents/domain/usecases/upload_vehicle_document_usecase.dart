import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../models/vehicle_document.dart';
import '../repository/documents_repository.dart';

@injectable
class UploadVehicleDocumentUseCase {
  const UploadVehicleDocumentUseCase(this._repository);

  final DocumentsRepository _repository;

  Future<Either<DomainException, VehicleDocument>> call(
    String vehicleId,
    DocumentUploadInput input,
  ) {
    return _repository.uploadDocument(vehicleId, input);
  }
}
