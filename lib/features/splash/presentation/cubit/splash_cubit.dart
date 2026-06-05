import 'package:bloc/bloc.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rideglory/core/config/api_remote_config.dart';
import 'package:rideglory/core/permissions/location_permission_handler.dart';
import 'package:rideglory/features/splash/domain/use_cases/load_current_user_use_case.dart';

part 'splash_state.dart';
part 'splash_cubit.freezed.dart';

@injectable
class SplashCubit extends Cubit<SplashState> {
  SplashCubit(this._loadCurrentUserUseCase, this._remoteConfig)
      : super(const SplashInitial());

  final LoadCurrentUserUseCase _loadCurrentUserUseCase;
  final FirebaseRemoteConfig _remoteConfig;

  Future<void> initialize() async {
    emit(const SplashLoading());

    try {
      await LocationPermissionHandler.requestOnceOnFirstSplashOpen();
      await Future.delayed(const Duration(milliseconds: 1500));

      if (await _isForceUpdateRequired()) {
        emit(const SplashForceUpdate());
        return;
      }

      final currentUserResult = await _loadCurrentUserUseCase();
      currentUserResult.fold(
        (failure) => emit(SplashError(failure.message)),
        (user) => emit(
          user == null
              ? const SplashUnauthenticated()
              : const SplashAuthenticated(),
        ),
      );
    } catch (e) {
      emit(SplashError('Failed to initialize: ${e.toString()}'));
    }
  }

  Future<bool> _isForceUpdateRequired() async {
    final minVersion = _remoteConfig
        .getString(ApiRemoteConfig.minRequiredVersionKey)
        .trim();
    if (minVersion.isEmpty) return false;

    final info = await PackageInfo.fromPlatform();
    return _isVersionBelow(info.version, minVersion);
  }

  /// Returns true if [current] is strictly older than [minimum].
  /// Compares semver parts numerically: "0.0.3" vs "1.0.0".
  bool _isVersionBelow(String current, String minimum) {
    final c = current.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final m = minimum.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    for (var i = 0; i < m.length; i++) {
      final cv = i < c.length ? c[i] : 0;
      if (cv < m[i]) return true;
      if (cv > m[i]) return false;
    }
    return false;
  }
}
