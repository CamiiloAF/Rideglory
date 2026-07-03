import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/profile/domain/use_cases/get_my_profile_use_case.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';

@injectable
class ProfileCubit extends Cubit<ResultState<UserModel>> {
  ProfileCubit(this._getMyProfile, this._analytics)
    : super(const ResultState.initial());

  final GetMyProfileUseCase _getMyProfile;
  final AnalyticsService _analytics;

  Future<void> fetchProfile() async {
    emit(const ResultState.loading());
    final result = await _getMyProfile();
    result.fold((error) => emit(ResultState.error(error: error)), (user) {
      _analytics.logEvent(AnalyticsEvents.profileViewed).ignore();
      emit(ResultState.data(data: user));
    });
  }

  void reset() => emit(const ResultState.initial());
}
