import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../profile_repository.dart';
import '../rider_vehicle_preview.dart';

@injectable
class GetRiderVehiclePreviewsUseCase {
  GetRiderVehiclePreviewsUseCase(this._repository);

  final ProfileRepository _repository;

  Future<Either<DomainException, List<RiderVehiclePreview>>> call() {
    return _repository.getRiderVehiclePreviews();
  }
}
