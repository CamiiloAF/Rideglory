import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../delete_account_summary.dart';
import '../profile_repository.dart';

@injectable
class GetDeleteAccountSummaryUseCase {
  GetDeleteAccountSummaryUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Either<DomainException, DeleteAccountSummary>> call() {
    return _repository.getDeleteAccountSummary();
  }
}
