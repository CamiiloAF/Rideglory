import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../models/vehicle_document.dart';
import '../repository/documents_repository.dart';

@injectable
class ToggleDocumentReminderUseCase {
  const ToggleDocumentReminderUseCase(this._repository);

  final DocumentsRepository _repository;

  Future<Either<DomainException, Unit>> call(
    String vehicleId,
    DocumentKind kind,
    bool enabled,
  ) {
    return _repository.setReminderEnabled(vehicleId, kind, enabled);
  }
}
