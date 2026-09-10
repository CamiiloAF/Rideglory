import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../sos_alert.dart';
import '../sos_repository.dart';

@injectable
class CloseSosUseCase {
  const CloseSosUseCase(this._repository);

  final SosRepository _repository;

  Future<Either<DomainException, SosAlert>> call(String sosId) =>
      _repository.close(sosId);
}
