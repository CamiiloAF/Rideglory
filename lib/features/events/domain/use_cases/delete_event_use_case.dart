import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/repository/event_repository.dart';

@injectable
class DeleteEventUseCase {
  DeleteEventUseCase(this._eventRepository);

  final EventRepository _eventRepository;

  Future<Either<DomainException, Nothing>> call(String id) =>
      _eventRepository.deleteEvent(id);
}
