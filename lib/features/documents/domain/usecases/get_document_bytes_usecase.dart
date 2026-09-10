import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../models/vehicle_document.dart';
import '../repository/documents_repository.dart';

@injectable
class GetDocumentBytesUseCase {
  const GetDocumentBytesUseCase(this._repository);

  final DocumentsRepository _repository;

  Future<Either<DomainException, Uint8List>> call(
    String vehicleId,
    DocumentKind kind,
  ) {
    return _repository.getDocumentBytes(vehicleId, kind);
  }
}
