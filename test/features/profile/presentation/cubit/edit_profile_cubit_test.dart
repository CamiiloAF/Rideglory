import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/profile/presentation/cubits/edit_profile_cubit.dart';

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  late MockAnalyticsService mockAnalytics;
  late EditProfileCubit cubit;

  setUp(() {
    mockAnalytics = MockAnalyticsService();
    when(() => mockAnalytics.logEvent(any(), any())).thenAnswer((_) async {});
    when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});
    cubit = EditProfileCubit(mockAnalytics);
  });

  tearDown(() => cubit.close());

  group('EditProfileCubit', () {
    test(
      'notifyEditStarted() dispara el evento profile_edit_started sin PII',
      () {
        cubit.notifyEditStarted();

        verify(
          () => mockAnalytics.logEvent(AnalyticsEvents.profileEditStarted),
        ).called(1);
        verifyNever(() => mockAnalytics.logEvent(any(), any()));
      },
    );

    test(
      'notifyEditSucceeded() dispara el evento profile_edit_succeeded sin PII',
      () {
        cubit.notifyEditSucceeded();

        verify(
          () => mockAnalytics.logEvent(AnalyticsEvents.profileEditSucceeded),
        ).called(1);
        verifyNever(() => mockAnalytics.logEvent(any(), any()));
      },
    );

    test(
      'no lanza excepciones al invocar ambos métodos en secuencia '
      '(Cubit<void> puramente instrumentación de analytics, sin estado)',
      () {
        expect(() {
          cubit.notifyEditStarted();
          cubit.notifyEditSucceeded();
        }, returnsNormally);
      },
    );
  });
}
