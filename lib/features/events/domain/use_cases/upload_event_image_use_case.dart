import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/repository/event_repository.dart';

@injectable
class UploadEventImageUseCase {
  UploadEventImageUseCase(this._eventRepository);

  final EventRepository _eventRepository;

  Future<Either<DomainException, String>> call({
    required String eventId,
    required String localImagePath,
  }) =>
      _eventRepository.uploadEventImage(
        eventId: eventId,
        localImagePath: localImagePath,
      );
}
