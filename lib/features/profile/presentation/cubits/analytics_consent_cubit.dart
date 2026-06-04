import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/core/services/crash/crash_reporter.dart';
import 'package:rideglory/core/services/user_storage_service.dart';

@injectable
class AnalyticsConsentCubit extends Cubit<ResultState<bool>> {
  AnalyticsConsentCubit(this._storage, this._analytics, this._crash)
      : super(const ResultState.initial());

  final UserStorageService _storage;
  final AnalyticsService _analytics;
  final CrashReporter _crash;

  // El opt-out detiene tanto Analytics como Crashlytics; el opt-in los reanuda.
  Future<void> _applyCollection(bool enabled) async {
    await _analytics.setEnabled(enabled);
    await _crash.setEnabled(enabled);
  }

  Future<void> load() async {
    final enabled = await _storage.getAnalyticsEnabled();
    await _applyCollection(enabled);
    emit(ResultState.data(data: enabled));
  }

  Future<void> toggle(bool enabled) async {
    // Optimistic update
    emit(ResultState.data(data: enabled));
    try {
      await _storage.setAnalyticsEnabled(enabled);
      await _applyCollection(enabled);
    } catch (_) {
      // Revert to previous value and signal error
      emit(ResultState.data(data: !enabled));
      emit(
        const ResultState.error(
          error: DomainException(
            message: 'No pudimos guardar tu preferencia. Inténtalo de nuevo.',
          ),
        ),
      );
      // Re-emit the reverted data so the UI has a stable state after the error
      emit(ResultState.data(data: !enabled));
    }
  }
}
