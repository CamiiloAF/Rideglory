import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/exceptions/domain_exception.dart';
import '../../domain/live_ride_contacts.dart';
import '../../domain/live_ride_error_code.dart';
import '../../domain/live_ride_repository.dart';
import '../../domain/live_rider.dart';
import '../../domain/rider_position.dart';
import '../datasources/live_ride_datasource.dart';

/// El `message` de [DomainException] es un código de [LiveRideErrorCode] o
/// un identificador corto para logs/Sentry — nunca el texto crudo del SDK.
@Injectable(as: LiveRideRepository)
class LiveRideRepositoryImpl implements LiveRideRepository {
  const LiveRideRepositoryImpl(this._datasource);

  final LiveRideDatasource _datasource;

  @override
  Stream<Either<DomainException, List<LiveRider>>> watchRiders(
    String eventId,
  ) async* {
    try {
      await for (final dtos in _datasource.watchRiders(eventId)) {
        yield Right(dtos.map((dto) => dto.toDomain()).toList());
      }
    } on PostgrestException catch (error) {
      yield Left(_mapPostgrestError(error));
    } catch (error) {
      yield Left(_mapUnknownError(error));
    }
  }

  @override
  Future<Either<DomainException, Unit>> upsertPosition(
    String eventId,
    RiderPosition position,
  ) {
    return _guard(() async {
      await _datasource.upsertPosition(eventId, position);
      return unit;
    });
  }

  @override
  Future<Either<DomainException, Unit>> endRide(String eventId) {
    return _guard(() async {
      await _datasource.endRide(eventId);
      return unit;
    });
  }

  @override
  Future<Either<DomainException, LiveRideContacts>> getContacts(
    String eventId,
  ) {
    return _guard(() async {
      final dto = await _datasource.getContacts(eventId);
      return dto.toDomain();
    });
  }

  @override
  Stream<bool> watchEventFinished(String eventId) {
    return _datasource.watchEventFinished(eventId).handleError((Object _) {});
  }

  Future<Either<DomainException, T>> _guard<T>(
    Future<T> Function() action,
  ) async {
    try {
      return Right(await action());
    } on PostgrestException catch (error) {
      return Left(_mapPostgrestError(error));
    } catch (error) {
      return Left(_mapUnknownError(error));
    }
  }

  DomainException _mapPostgrestError(PostgrestException error) {
    final message = error.message.toLowerCase();
    if (message.contains('not_a_participant')) {
      return const DomainException(message: LiveRideErrorCode.notAParticipant);
    }
    if (message.contains('event_not_started')) {
      return const DomainException(message: LiveRideErrorCode.eventNotStarted);
    }
    return DomainException(message: 'postgrest_error: ${error.code}');
  }

  DomainException _mapUnknownError(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('clientexception')) {
      return const DomainException(message: LiveRideErrorCode.offline);
    }
    return DomainException(message: 'unknown_error: $error');
  }
}
