part of 'splash_cubit.dart';

@freezed
abstract class SplashState with _$SplashState {
  const factory SplashState.initial() = SplashInitial;
  const factory SplashState.loading() = SplashLoading;
  const factory SplashState.navigateToLogin() = SplashNavigateToLogin;
  const factory SplashState.fetchSelectedVehicle(List<VehicleModel> vehicles) = SplashFetchSelectedVehicle;
  const factory SplashState.fetchSelectedVehicleSuccess(
    VehicleModel selectedVehicle,
  ) = SplashFetchSelectedVehicleSuccess;
  const factory SplashState.navigateToOnboarding() = SplashNavigateToOnboarding;
  const factory SplashState.navigateToHome() = SplashNavigateToHome;
  const factory SplashState.error(String message) = SplashError;
}
