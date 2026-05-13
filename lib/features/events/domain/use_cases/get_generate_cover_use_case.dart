import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/repository/event_cover_repository.dart';

@injectable
class GetGenerateCoverUseCase {
  GetGenerateCoverUseCase(this._eventCoverRepository);

  final EventCoverRepository _eventCoverRepository;

  Future<Either<DomainException, String>> call({
    required String title,
    required String eventType,
    required String city,
  }) =>
      _eventCoverRepository.generateCover(
        title: title,
        eventType: eventType,
        city: city,
      );
}
