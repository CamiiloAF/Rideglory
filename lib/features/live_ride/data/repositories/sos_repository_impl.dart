import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/exceptions/domain_exception.dart';
import '../../domain/live_ride_error_code.dart';
import '../../domain/sos_alert.dart';
import '../../domain/sos_outbox_item.dart';
import '../../domain/sos_repository.dart';
import '../datasources/sos_datasource.dart';

/// El `message` de [DomainException] es un código de [LiveRideErrorCode] o
/// un identificador corto para logs/Sentry — nunca el texto crudo del SDK.
@Injectable(as: SosRepository)
class SosRepositoryImpl implements SosRepository {
  const SosRepositoryImpl(this._datasource);

  final SosDatasource _datasource;

  @override
  Future<Either<DomainException, SosAlert>> raise(SosOutboxItem item) {
    return _guard(() async {
      final dto = await _datasource.raise(item);
      return dto.toDomain();
    });
  }

  @override
  Future<Either<DomainException, SosAlert>> close(String sosId) {
    return _guard(() async {
      final dto = await _datasource.close(sosId);
      return dto.toDomain();
    });
  }

  @override
  Stream<Either<DomainException, List<SosAlert>>> watchAlerts(
    String eventId,
  ) async* {
    try {
      await for (final dtos in _datasource.watchAlerts(eventId)) {
        yield Right(dtos.map((dto) => dto.toDomain()).toList());
      }
    } on PostgrestException catch (error) {
      yield Left(_mapPostgrestError(error));
    } catch (error) {
      yield Left(_mapUnknownError(error));
    }
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
    if (message.contains('sos_not_found')) {
      return const DomainException(message: LiveRideErrorCode.sosNotFound);
    }
    if (message.contains('not_allowed_to_close')) {
      return const DomainException(
        message: LiveRideErrorCode.notAllowedToClose,
      );
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
