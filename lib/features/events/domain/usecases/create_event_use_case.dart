import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/exceptions/domain_exception.dart';
import '../create_event_params.dart';
import '../events_repository.dart';

/// Crea la rodada en `draft`, sube la foto si hay una, y publica —
/// `draft -> published` es la única transición que EV3 dispara.
@injectable
class CreateEventUseCase {
  const CreateEventUseCase(this._repository);

  final EventsRepository _repository;

  Future<Either<DomainException, Unit>> call(CreateEventParams params) async {
    final createResult = await _repository.createEvent(params);
    if (createResult.isLeft()) {
      return createResult.fold(
        Left.new,
        (_) => throw StateError('unreachable'),
      );
    }
    final eventId = createResult.getOrElse(
      () => throw StateError('unreachable'),
    );

    if (params.localImagePath != null) {
      // Best-effort: si la foto falla, la rodada igual se publica sin
      // portada. No es un requisito bloqueante (D del plan: "foto opcional").
      await _repository.uploadEventImage(eventId, params.localImagePath!);
    }

    return _repository.publishEvent(eventId);
  }
}
