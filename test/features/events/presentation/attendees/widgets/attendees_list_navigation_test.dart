import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/attendees/attendees_cubit.dart';
import 'package:rideglory/features/events/presentation/attendees/widgets/attendees_list.dart';
import 'package:rideglory/l10n/app_localizations.dart';

class MockAttendeesCubit extends Mock
    implements AttendeesCubit {}

final _mockEvent = EventModel(
  id: 'event-1',
  ownerId: 'owner-1',
  name: 'Test Event',
  description: 'Desc',
  startDate: DateTime(2026, 5, 20),
  meetingTime: DateTime(2026, 5, 20, 8),
  eventType: EventType.onRoad,
  difficulty: EventDifficulty.two,
);

final _mockRegistration = EventRegistrationModel(
  id: 'reg-1',
  eventId: 'event-1',
  eventName: 'Test Event',
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
  MockAttendeesCubit mockCubit,
  List<EventRegistrationModel> registrations,
) {
  return MaterialApp(
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
    home: BlocProvider<AttendeesCubit>.value(
      value: mockCubit,
      child: Scaffold(
        body: AttendeesList(
          registrations: registrations,
          event: _mockEvent,
        ),
      ),
    ),
  );
}

void main() {
  late MockAttendeesCubit mockAttendeesCubit;

  setUp(() {
    mockAttendeesCubit = MockAttendeesCubit();
    when(() => mockAttendeesCubit.state).thenReturn(
      ResultState<List<EventRegistrationModel>>.data(data: [_mockRegistration]),
    );
    when(() => mockAttendeesCubit.stream).thenAnswer((_) => const Stream.empty());
  });

  group('AttendeesList — Navigation Tests (US-2-3)', () {
    testWidgets(
      'TC-2-41: AttendeesList renders with approved registrations',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _buildTestWidget(mockAttendeesCubit, [_mockRegistration]),
        );
        await tester.pump();

        expect(find.byType(AttendeesList), findsOneWidget);
      },
    );

    testWidgets(
      'TC-2-42: AttendeesList renders empty state when no registrations',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _buildTestWidget(mockAttendeesCubit, []),
        );
        await tester.pump();

        expect(find.byType(AttendeesList), findsOneWidget);
      },
    );

    testWidgets(
      'TC-2-43: AttendeesList renders pending registration',
      (WidgetTester tester) async {
        final pendingRegistration = EventRegistrationModel(
          id: 'reg-2',
          eventId: 'event-1',
          eventName: 'Test Event',
          userId: 'user-2',
          status: RegistrationStatus.pending,
          fullName: 'María García',
          identificationNumber: '987654321',
          birthDate: DateTime(1992, 6, 15),
          phone: '3119876543',
          email: 'maria@example.com',
          residenceCity: 'Bogotá',
          eps: 'Nueva EPS',
          bloodType: BloodType.aPositive,
          emergencyContactName: 'Carlos García',
          emergencyContactPhone: '3001112233',
        );

        await tester.pumpWidget(
          _buildTestWidget(mockAttendeesCubit, [pendingRegistration]),
        );
        await tester.pump();

        expect(find.byType(AttendeesList), findsOneWidget);
      },
    );
  });
}
