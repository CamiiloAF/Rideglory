import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/model/upload_event_image_request.dart';
import 'package:rideglory/features/events/domain/repository/event_repository.dart';

@injectable
class UploadEventImageUseCase {
  UploadEventImageUseCase(this._eventRepository);

  final EventRepository _eventRepository;

  Future<Either<DomainException, String>> call(
    UploadEventImageRequest request,
  ) => _eventRepository.uploadEventImage(request);
}
