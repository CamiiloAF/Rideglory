import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/http/rest_client_functions.dart';
import 'package:rideglory/features/events/data/service/event_cover_service.dart';
import 'package:rideglory/features/events/domain/repository/event_cover_repository.dart';

@Injectable(as: EventCoverRepository)
class EventCoverRepositoryImpl implements EventCoverRepository {
  EventCoverRepositoryImpl(this._eventCoverService);

  final EventCoverService _eventCoverService;

  @override
  Future<Either<DomainException, String>> generateCover({
    required String title,
    required String eventType,
    required String city,
  }) async {
    final result = await executeService(
      function: () async {
        final dto = await _eventCoverService.generateCover({
          'title': title,
          'eventType': eventType,
          'city': city,
        });
        return dto.imageUrl;
      },
    );

    return result.fold(
      (error) => Left(
        DomainException(
          message: error.message.isNotEmpty
              ? error.message
              : 'No pudimos generar la portada. Sube tu propia imagen.',
        ),
      ),
      Right.new,
    );
  }
}
