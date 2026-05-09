import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/home/domain/models/home_data.dart';
import 'package:rideglory/features/home/domain/repository/home_repository.dart';

@injectable
class GetHomeDataUseCase {
  GetHomeDataUseCase(this._repository);

  final HomeRepository _repository;

  Future<Either<DomainException, HomeData>> call() {
    return _repository.getHomeData();
  }
}
