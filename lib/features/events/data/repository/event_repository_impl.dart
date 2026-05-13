import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/http/rest_client_functions.dart';
import 'package:rideglory/features/events/data/dto/event_dto.dart';
import 'package:rideglory/features/events/data/service/event_service.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/model/upload_event_image_request.dart';
import 'package:rideglory/features/events/domain/repository/event_repository.dart';

@Injectable(as: EventRepository)
class EventRepositoryImpl implements EventRepository {
  EventRepositoryImpl(this._eventService, this._storage);

  final EventService _eventService;
  final FirebaseStorage _storage;

  @override
  Future<Either<DomainException, List<EventModel>>> getEvents({
    String? type,
    String? dateFrom,
    String? dateTo,
    String? city,
  }) {
    return executeService(
      function: () async {
        return _eventService.getEvents(
          type: type,
          dateFrom: dateFrom,
          dateTo: dateTo,
          city: city,
        );
      },
    );
  }

  @override
  Future<Either<DomainException, List<EventModel>>> getMyEvents() {
    return executeService(
      function: () async {
        return _eventService.getMyEvents();
      },
    );
  }

  @override
  Future<Either<DomainException, EventModel>> getEventById(String id) {
    return executeService(
      function: () async {
        return _eventService.getEventById(id);
      },
    );
  }

  @override
  Future<Either<DomainException, EventModel>> createEvent(EventModel event) {
    return executeService(
      function: () async {
        return _eventService.createEvent(event.toJson());
      },
    );
  }

  @override
  Future<Either<DomainException, EventModel>> updateEvent(EventModel event) {
    if (event.id == null) {
      return Future.value(
        const Left(
          DomainException(message: 'Event ID is required for update.'),
        ),
      );
    }

    return executeService(
      function: () async {
        return _eventService.updateEvent(event.id!, event.toJson());
      },
    );
  }

  @override
  Future<Either<DomainException, Nothing>> deleteEvent(String id) {
    return executeService(
      function: () async {
        await _eventService.deleteEvent(id);
        return const Nothing();
      },
    );
  }

  @override
  Future<Either<DomainException, String>> uploadEventImage(
    UploadEventImageRequest request,
  ) {
    return executeService(
      function: () async {
        final folder =
            request.eventId ??
            '${request.ownerId ?? 'anonymous'}-${DateTime.now().microsecondsSinceEpoch}';
        final file = File(request.localImagePath);
        final ref = _storage.ref().child('events/$folder/cover.jpg');
        final uploadTask = await ref.putFile(file);
        return uploadTask.ref.getDownloadURL();
      },
    );
  }
}
