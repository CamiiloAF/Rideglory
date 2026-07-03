import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';
import 'package:rideglory/features/users/domain/use_cases/get_user_by_id_use_case.dart';

@injectable
class RiderProfileCubit extends Cubit<ResultState<UserModel>> {
  RiderProfileCubit(this._getUserByIdUseCase, this._analytics)
    : super(const ResultState.initial());

  final GetUserByIdUseCase _getUserByIdUseCase;
  final AnalyticsService _analytics;

  Future<void> fetchRiderProfile(String userId) async {
    emit(const ResultState.loading());
    final result = await _getUserByIdUseCase(userId);
    result.fold((error) => emit(ResultState.error(error: error)), (user) {
      // Never log userId as param value — G2 compliance.
      _analytics.logEvent(AnalyticsEvents.riderProfileViewed).ignore();
      emit(ResultState.data(data: user));
    });
  }
}
