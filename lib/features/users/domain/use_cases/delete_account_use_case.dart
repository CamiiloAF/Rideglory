import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/nothing.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../repository/user_repository.dart';

@injectable
class DeleteAccountUseCase {
  DeleteAccountUseCase(this.userRepository);

  final UserRepository userRepository;

  Future<Either<DomainException, Nothing>> call() async {
    return userRepository.deleteMyAccount();
  }
}
