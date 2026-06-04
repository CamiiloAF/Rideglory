// Analytics tests — Fase 9: Perfil
// Verifica:
//   profile_viewed se emite al cargar perfil exitosamente.
//   profile_viewed NO se emite en error.
//   G2: sin email/nombre en params.

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/profile/domain/use_cases/get_my_profile_use_case.dart';
import 'package:rideglory/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';

class MockGetMyProfileUseCase extends Mock implements GetMyProfileUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  late MockGetMyProfileUseCase mockGetProfile;
  late MockAnalyticsService mockAnalytics;
  late ProfileCubit cubit;

  final mockUser = UserModel(
    id: 'uid-123',
    fullName: 'Camilo Rider',
    email: 'camilo@test.com',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 6, 1),
  );

  setUp(() {
    mockGetProfile = MockGetMyProfileUseCase();
    mockAnalytics = MockAnalyticsService();
    when(() => mockAnalytics.logEvent(any(), any())).thenAnswer((_) async {});
    when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});
    cubit = ProfileCubit(mockGetProfile, mockAnalytics);
  });

  tearDown(() => cubit.close());

  group('ProfileCubit — analytics Fase 9', () {
    // TC-prof-a1: profile_viewed se emite tras fetchProfile exitoso
    test(
      'TC-prof-a1: fetchProfile exitoso → profile_viewed emitido',
      () async {
        when(() => mockGetProfile()).thenAnswer((_) async => Right(mockUser));

        await cubit.fetchProfile();

        verify(
          () => mockAnalytics.logEvent(AnalyticsEvents.profileViewed),
        ).called(1);
      },
    );

    // TC-prof-a2: profile_viewed NO se emite con error
    test(
      'TC-prof-a2: fetchProfile con error → profile_viewed NO emitido',
      () async {
        when(() => mockGetProfile()).thenAnswer(
          (_) async =>
              const Left(DomainException(message: 'Error de red')),
        );

        await cubit.fetchProfile();

        verifyNever(
          () => mockAnalytics.logEvent(AnalyticsEvents.profileViewed),
        );
      },
    );

    // TC-prof-a3: G2 — profile_viewed se emite sin params (sin email/nombre)
    test(
      'TC-prof-a3: G2 — profile_viewed se emite sin params PII',
      () async {
        when(() => mockGetProfile()).thenAnswer((_) async => Right(mockUser));

        await cubit.fetchProfile();

        // Verify called with no params (single-arg overload, no Map passed)
        verify(
          () => mockAnalytics.logEvent(AnalyticsEvents.profileViewed),
        ).called(1);

        // Two-arg overload with params must NOT have been called with profile_viewed
        verifyNever(
          () => mockAnalytics.logEvent(AnalyticsEvents.profileViewed, any()),
        );
      },
    );
  });
}
