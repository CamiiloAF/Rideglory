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
    final notificationsEnabled = await _appPreferencesRepository
        .getNotificationsEnabled();
    final analyticsEnabled = await _appPreferencesRepository
        .getAnalyticsEnabled();
    final result = await _getProfile();
    emit(
      state.copyWith(
        profile: result.fold(
          (error) => ResultState.error(error: error),
          (profile) => ResultState.data(data: profile),
        ),
        notificationsEnabled: notificationsEnabled,
        analyticsEnabled: analyticsEnabled,
      ),
    );
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _appPreferencesRepository.setNotificationsEnabled(enabled);
    emit(state.copyWith(notificationsEnabled: enabled));
  }

  Future<void> setAnalyticsEnabled(bool enabled) async {
    await _appPreferencesRepository.setAnalyticsEnabled(enabled);
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
