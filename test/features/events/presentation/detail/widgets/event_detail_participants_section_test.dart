import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/presentation/registration_detail_extra.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/detail/cubit/event_detail_cubit.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_participants_section.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/router/app_routes.dart';

class MockEventDetailCubit extends Mock implements EventDetailCubit {}

final _mockEvent = EventModel(
  id: 'event-1',
  ownerId: 'owner-1',
  name: 'Mi Evento',
  description: 'Desc',
  startDate: DateTime(2026, 5, 20),
  meetingTime: DateTime(2026, 5, 20, 8),
  eventType: EventType.onRoad,
  difficulty: EventDifficulty.two,
);

final _mockRegistration = EventRegistrationModel(
  id: 'reg-1',
  eventId: 'event-1',
  eventName: 'Mi Evento',
  userId: 'user-1',
  status: RegistrationStatus.approved,
  fullName: 'Juan Pérez',
  identificationNumber: '123456789',
  birthDate: DateTime(1990, 1, 1),
  phone: '3001234567',
  email: 'juan@example.com',
  residenceCity: 'Medellín',
  eps: 'Sura',
  bloodType: BloodType.oPositive,
  emergencyContactName: 'María Pérez',
  emergencyContactPhone: '3009876543',
);

Widget _buildTestWidget(
  MockEventDetailCubit mockCubit, {
  required void Function(RegistrationDetailExtra extra)
  onRegistrationDetailPushed,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: BlocProvider<EventDetailCubit>.value(
            value: mockCubit,
            child: EventDetailParticipantsSection(event: _mockEvent),
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.registrationDetail,
        name: AppRoutes.registrationDetail,
        builder: (context, state) {
          final extra = state.extra! as RegistrationDetailExtra;
          onRegistrationDetailPushed(extra);
          return const Scaffold(body: Text('registration-detail-stub'));
        },
      ),
    ],
  );

  return MaterialApp.router(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: ThemeMode.dark,
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      AppLocalizations.delegate,
    ],
    supportedLocales: const [Locale('es')],
    routerConfig: router,
  );
}

void main() {
  late MockEventDetailCubit mockEventDetailCubit;

  setUp(() {
    mockEventDetailCubit = MockEventDetailCubit();
    when(() => mockEventDetailCubit.state).thenReturn(
      EventDetailState(
        registrationResult: const ResultState.initial(),
        eventResult: ResultState.data(data: _mockEvent),
        attendeesResult: ResultState.data(data: [_mockRegistration]),
      ),
    );
    when(
      () => mockEventDetailCubit.stream,
    ).thenAnswer((_) => const Stream.empty());
  });

  group(
    'EventDetailParticipantsSection — navigation (legal-privacidad-edad fase 7, AC2)',
    () {
      // AC2: tapping a participant row from the event-detail "Inscritos"
      // preview must push registrationDetail with isOrganizerView:true. The
      // Patrol run never reached a real detail (empty seed list) so this is
      // the only deterministic coverage of this navigation branch.
      testWidgets(
        'tapping a participant row pushes RegistrationDetailExtra.isOrganizerView == true',
        (WidgetTester tester) async {
          RegistrationDetailExtra? pushedExtra;
          await tester.pumpWidget(
            _buildTestWidget(
              mockEventDetailCubit,
              onRegistrationDetailPushed: (extra) => pushedExtra = extra,
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.text('Juan Pérez'));
          await tester.pumpAndSettle();

          expect(pushedExtra, isNotNull);
          expect(pushedExtra!.isOrganizerView, isTrue);
          expect(pushedExtra!.registration.id, 'reg-1');
          expect(pushedExtra!.eventOwnerId, 'owner-1');
        },
      );
    },
  );
}
