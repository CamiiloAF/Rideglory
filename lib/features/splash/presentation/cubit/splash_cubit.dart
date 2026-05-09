import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/permissions/location_permission_handler.dart';
import 'package:rideglory/features/splash/domain/use_cases/load_current_user_use_case.dart';

part 'splash_state.dart';
part 'splash_cubit.freezed.dart';

@injectable
class SplashCubit extends Cubit<SplashState> {
  SplashCubit(this._loadCurrentUserUseCase)
      : super(const SplashInitial());

  final LoadCurrentUserUseCase _loadCurrentUserUseCase;

  Future<void> initialize() async {
    emit(const SplashLoading());

    try {
      await LocationPermissionHandler.requestOnceOnFirstSplashOpen();
      await Future.delayed(const Duration(milliseconds: 1500));

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
}
