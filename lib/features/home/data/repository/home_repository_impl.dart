import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/http/rest_client_functions.dart';
import 'package:rideglory/features/home/data/service/home_service.dart';
import 'package:rideglory/features/home/data/dto/home_dto.dart';
import 'package:rideglory/features/home/domain/models/home_data.dart';
import 'package:rideglory/features/home/domain/repository/home_repository.dart';

@Injectable(as: HomeRepository)
class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._homeService);

  final HomeService _homeService;

  @override
  Future<Either<DomainException, HomeData>> getHomeData() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return executeService(
      function: () async {
        final HomeDto dto = await _homeService.getHome(dateFrom: today);
        return dto.toHomeData();
      },
    );
  }
}
