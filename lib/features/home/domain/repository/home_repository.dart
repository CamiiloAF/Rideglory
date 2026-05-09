import 'package:dartz/dartz.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/home/domain/models/home_data.dart';

abstract class HomeRepository {
  Future<Either<DomainException, HomeData>> getHomeData();
}
