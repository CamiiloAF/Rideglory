import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/ai_domain_exceptions.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/events/domain/model/ai_chat_turn.dart';
import 'package:rideglory/features/events/domain/model/ai_description_request.dart';
import 'package:rideglory/features/events/domain/model/ai_description_result.dart';
import 'package:rideglory/features/events/domain/use_cases/generate_event_description_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/get_description_quota_use_case.dart';

part 'ai_description_chat_cubit.freezed.dart';

@freezed
abstract class AiDescriptionChatState with _$AiDescriptionChatState {
  const factory AiDescriptionChatState({
    @Default([]) List<AiChatTurn> history,
    @Default(ResultState<AiDescriptionResult>.initial())
    ResultState<AiDescriptionResult> sendResult,
    int? remainingQuota,
    @Default(false) bool isQuotaInitialized,
  }) = _AiDescriptionChatState;
}

@injectable
class AiDescriptionChatCubit extends Cubit<AiDescriptionChatState> {
  AiDescriptionChatCubit(
    this._generateDescriptionUseCase,
    this._getDescriptionQuotaUseCase,
    this._analyticsService,
  ) : super(const AiDescriptionChatState());

  final GenerateEventDescriptionUseCase _generateDescriptionUseCase;
  final GetDescriptionQuotaUseCase _getDescriptionQuotaUseCase;
  final AnalyticsService _analyticsService;

  Future<void> initQuota() async {
    final result = await _getDescriptionQuotaUseCase();
    result.fold(
      (_) => emit(state.copyWith(isQuotaInitialized: true)),
      (remaining) => emit(
        state.copyWith(
          remainingQuota: remaining,
          isQuotaInitialized: true,
        ),
      ),
    );
  }

  Future<void> sendMessage({
    required String userMessage,
    required String title,
    required String eventType,
    String? difficulty,
    String? startDate,
  }) async {
    if (userMessage.trim().isEmpty) return;

    final userTurn = AiChatTurn(role: AiChatRole.user, content: userMessage);
    final updatedHistory = [...state.history, userTurn];

    emit(
      state.copyWith(
        history: updatedHistory,
        sendResult: const ResultState.loading(),
      ),
    );

    final request = AiDescriptionRequest(
      title: title,
      eventType: eventType,
      difficulty: difficulty,
      startDate: startDate,
      history: updatedHistory,
      userMessage: userMessage,
    );

    final result = await _generateDescriptionUseCase(request);

    result.fold(
      (exception) {
        if (exception is AiQuotaExceededUserException ||
            exception is AiQuotaExceededProjectException) {
          _analyticsService.logEvent(
            AnalyticsEvents.aiQuotaExceeded,
            {
              AnalyticsParams.aiGenerationType:
                  AnalyticsParams.aiGenerationTypeDescription,
              AnalyticsParams.aiErrorCode: exception.runtimeType.toString(),
            },
          );
        } else {
          _analyticsService.logEvent(
            AnalyticsEvents.aiGenerationFailed,
            {
              AnalyticsParams.aiGenerationType:
                  AnalyticsParams.aiGenerationTypeDescription,
              AnalyticsParams.aiErrorCode: exception.runtimeType.toString(),
            },
          );
        }
        emit(state.copyWith(sendResult: ResultState.error(error: exception)));
      },
      (descriptionResult) {
        final modelTurn = AiChatTurn(
          role: AiChatRole.model,
          content: descriptionResult.markdown,
          isDescription: descriptionResult.isDescription,
        );
        final newHistory = [...updatedHistory, modelTurn];
        _analyticsService.logEvent(
          AnalyticsEvents.aiDescriptionGenerated,
          {AnalyticsParams.aiTurnIndex: newHistory.length},
        );
        emit(
          state.copyWith(
            history: newHistory,
            sendResult: ResultState.data(data: descriptionResult),
            remainingQuota: descriptionResult.remainingGenerations,
          ),
        );
      },
    );
  }

  Future<void> retryLastMessage({
    required String title,
    required String eventType,
    String? difficulty,
    String? startDate,
  }) async {
    final lastUserTurn = state.history.lastWhere(
      (turn) => turn.role == AiChatRole.user,
      orElse: () => state.history.first,
    );

    emit(state.copyWith(sendResult: const ResultState.loading()));

    final request = AiDescriptionRequest(
      title: title,
      eventType: eventType,
      difficulty: difficulty,
      startDate: startDate,
      history: state.history,
      userMessage: lastUserTurn.content,
    );

    final result = await _generateDescriptionUseCase(request);

    result.fold(
      (exception) {
        if (exception is AiQuotaExceededUserException ||
            exception is AiQuotaExceededProjectException) {
          _analyticsService.logEvent(
            AnalyticsEvents.aiQuotaExceeded,
            {
              AnalyticsParams.aiGenerationType:
                  AnalyticsParams.aiGenerationTypeDescription,
              AnalyticsParams.aiErrorCode: exception.runtimeType.toString(),
            },
          );
        } else {
          _analyticsService.logEvent(
            AnalyticsEvents.aiGenerationFailed,
            {
              AnalyticsParams.aiGenerationType:
                  AnalyticsParams.aiGenerationTypeDescription,
              AnalyticsParams.aiErrorCode: exception.runtimeType.toString(),
            },
          );
        }
        emit(state.copyWith(sendResult: ResultState.error(error: exception)));
      },
      (descriptionResult) {
        final modelTurn = AiChatTurn(
          role: AiChatRole.model,
          content: descriptionResult.markdown,
          isDescription: descriptionResult.isDescription,
        );
        final newHistory = [...state.history, modelTurn];
        _analyticsService.logEvent(
          AnalyticsEvents.aiDescriptionGenerated,
          {AnalyticsParams.aiTurnIndex: newHistory.length},
        );
        emit(
          state.copyWith(
            history: newHistory,
            sendResult: ResultState.data(data: descriptionResult),
            remainingQuota: descriptionResult.remainingGenerations,
          ),
        );
      },
    );
  }

  void reset() => emit(const AiDescriptionChatState());

  bool get isQuotaExhausted {
    return state.sendResult.whenOrNull(
          error: (error) => error is AiQuotaExceededUserException,
        ) ??
        (state.remainingQuota != null && state.remainingQuota! <= 0);
  }

  /// Returns the last AI markdown response if available.
  String? get lastMarkdown {
    return state.sendResult.whenOrNull(
      data: (result) => result.markdown,
    );
  }
}
