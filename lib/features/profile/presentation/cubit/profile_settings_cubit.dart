import 'dart:developer' as developer;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/app_preferences_repository.dart';
import '../../domain/usecases/get_profile_usecase.dart';
import 'profile_settings_state.dart';

@injectable
class ProfileSettingsCubit extends Cubit<ProfileSettingsState> {
  ProfileSettingsCubit(this._getProfile, this._appPreferencesRepository)
    : super(ProfileSettingsState.initial());

  final GetProfileUseCase _getProfile;
  final AppPreferencesRepository _appPreferencesRepository;

  Future<void> load() async {
    emit(state.copyWith(profile: const ResultState.loading()));
    final notificationsEnabledResult = await _appPreferencesRepository
        .getNotificationsEnabled();
    final analyticsEnabledResult = await _appPreferencesRepository
        .getAnalyticsEnabled();
    final result = await _getProfile();
    emit(
      state.copyWith(
        profile: result.fold(
          (error) => ResultState.error(error: error),
          (profile) => ResultState.data(data: profile),
        ),
        notificationsEnabled: notificationsEnabledResult.getOrElse(
          () => state.notificationsEnabled,
        ),
        analyticsEnabled: analyticsEnabledResult.getOrElse(
          () => state.analyticsEnabled,
        ),
      ),
    );
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final result = await _appPreferencesRepository.setNotificationsEnabled(
      enabled,
    );
    result.fold(
      (error) => developer.log(
        'No se pudo guardar la preferencia de notificaciones.',
        name: 'ProfileSettingsCubit',
        error: error,
      ),
      (_) => emit(state.copyWith(notificationsEnabled: enabled)),
    );
  }

  Future<void> setAnalyticsEnabled(bool enabled) async {
    final result = await _appPreferencesRepository.setAnalyticsEnabled(
      enabled,
    );
    if (result.isLeft()) {
      developer.log(
        'No se pudo guardar la preferencia de analítica.',
        name: 'ProfileSettingsCubit',
      );
      return;
    }
    try {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
    } catch (error, stackTrace) {
      developer.log(
        'No se pudo cambiar la recolección de analítica (Firebase puede no '
        'estar configurado en este entorno).',
        name: 'ProfileSettingsCubit',
        error: error,
        stackTrace: stackTrace,
      );
    }
    emit(state.copyWith(analyticsEnabled: enabled));
  }
}
