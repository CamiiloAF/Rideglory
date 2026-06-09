import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/domain/model/ai_description_request.dart';
import 'package:rideglory/features/events/domain/model/ai_description_result.dart';
import 'package:rideglory/features/events/domain/repository/ai_description_repository.dart';

@injectable
class GenerateEventDescriptionUseCase {
  const GenerateEventDescriptionUseCase(this._repository);

  final AiDescriptionRepository _repository;

  static const int _maxHistoryTurns = 10;

  Future<Either<DomainException, AiDescriptionResult>> call(
    AiDescriptionRequest request,
  ) {
    final trimmedHistory = request.history.length > _maxHistoryTurns
        ? request.history.sublist(request.history.length - _maxHistoryTurns)
        : request.history;

    final trimmedRequest = AiDescriptionRequest(
      title: request.title,
      eventType: request.eventType,
      city: request.city,
      difficulty: request.difficulty,
      startDate: request.startDate,
      history: trimmedHistory,
      userMessage: request.userMessage,
    );

    return _repository.generateDescription(trimmedRequest);
  }
}
