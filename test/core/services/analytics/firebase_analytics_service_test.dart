import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/services/analytics/firebase_analytics_service.dart';

class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

void main() {
  late MockFirebaseAnalytics mockAnalytics;
  late FirebaseAnalyticsService service;

  setUp(() {
    mockAnalytics = MockFirebaseAnalytics();
    service = FirebaseAnalyticsService(mockAnalytics);
  });

  group('FirebaseAnalyticsService — nuevas firmas de fase 1', () {
    test(
      'TC-analytics-1: logScreenView delega al SDK con screenName correcto',
      () async {
        when(
          () => mockAnalytics.logScreenView(screenName: any(named: 'screenName')),
        ).thenAnswer((_) async {});

        await service.logScreenView('home');

        verify(
          () => mockAnalytics.logScreenView(screenName: 'home'),
        ).called(1);
      },
    );

    test(
      'TC-analytics-2: setUserId delega al SDK con id correcto',
      () async {
        when(
          () => mockAnalytics.setUserId(id: any(named: 'id')),
        ).thenAnswer((_) async {});

        await service.setUserId('hashed-user-id');

        verify(
          () => mockAnalytics.setUserId(id: 'hashed-user-id'),
        ).called(1);
      },
    );

    test(
      'TC-analytics-3: setUserProperty delega al SDK con name y value correctos',
      () async {
        when(
          () => mockAnalytics.setUserProperty(
            name: any(named: 'name'),
            value: any(named: 'value'),
          ),
        ).thenAnswer((_) async {});

        await service.setUserProperty('plan', 'free');

        verify(
          () => mockAnalytics.setUserProperty(name: 'plan', value: 'free'),
        ).called(1);
      },
    );

    test(
      'TC-analytics-4: setEnabled delega al SDK con valor correcto',
      () async {
        when(
          () => mockAnalytics.setAnalyticsCollectionEnabled(any()),
        ).thenAnswer((_) async {});

        await service.setEnabled(false);

        verify(
          () => mockAnalytics.setAnalyticsCollectionEnabled(false),
        ).called(1);
      },
    );

    test(
      'TC-analytics-5: setEnabled(true) delega al SDK con true',
      () async {
        when(
          () => mockAnalytics.setAnalyticsCollectionEnabled(any()),
        ).thenAnswer((_) async {});

        await service.setEnabled(true);

        verify(
          () => mockAnalytics.setAnalyticsCollectionEnabled(true),
        ).called(1);
      },
    );
  });
}
