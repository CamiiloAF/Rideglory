import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/profile.dart';

part 'profile_settings_state.freezed.dart';

/// Estado de P1 (lista de ajustes): el perfil (async, puede fallar) y las
/// dos preferencias de dispositivo (síncronas, siempre disponibles).
@freezed
abstract class ProfileSettingsState with _$ProfileSettingsState {
  const factory ProfileSettingsState({
    required ResultState<Profile> profile,
    required bool notificationsEnabled,
    required bool analyticsEnabled,
  }) = _ProfileSettingsState;

  factory ProfileSettingsState.initial() => const ProfileSettingsState(
    profile: ResultState.initial(),
    notificationsEnabled: true,
    analyticsEnabled: true,
  );
}
