part of 'splash_cubit.dart';

@freezed
abstract class SplashState with _$SplashState {
  const factory SplashState.initial() = SplashInitial;
  const factory SplashState.loading() = SplashLoading;
  const factory SplashState.authenticated() = SplashAuthenticated;
  const factory SplashState.unauthenticated() = SplashUnauthenticated;
  const factory SplashState.error(String message) = SplashError;
}
