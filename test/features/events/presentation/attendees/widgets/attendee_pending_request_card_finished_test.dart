import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/attendees/attendees_cubit.dart';
import 'package:rideglory/features/events/presentation/attendees/widgets/attendee_pending_request_card.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/widgets/registration_actions/registration_approve_button.dart';
import 'package:rideglory/shared/widgets/registration_actions/registration_reject_button.dart';

class MockAttendeesCubit extends Mock implements AttendeesCubit {}

final _pending = EventRegistrationModel(
  id: 'reg-1',
  eventId: 'event-1',
  eventName: 'Test Event',
  userId: 'user-1',
  status: RegistrationStatus.pending,
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

Widget _host(MockAttendeesCubit cubit, {required bool canManage}) {
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
      value: cubit,
      child: Scaffold(
        body: AttendeePendingRequestCard(
          registration: _pending,
          canManage: canManage,
        ),
      ),
    ),
  );
}

void main() {
  late MockAttendeesCubit cubit;

  setUp(() {
    cubit = MockAttendeesCubit();
    when(() => cubit.state).thenReturn(
      ResultState<List<EventRegistrationModel>>.data(data: [_pending]),
    );
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
  });

  testWidgets('enables approve/reject when the event is active', (tester) async {
    await tester.pumpWidget(_host(cubit, canManage: true));
    await tester.pump();

    final approve = tester.widget<RegistrationApproveButton>(
      find.byType(RegistrationApproveButton),
    );
    final reject = tester.widget<RegistrationRejectButton>(
      find.byType(RegistrationRejectButton),
    );

    expect(approve.enabled, isTrue);
    expect(reject.enabled, isTrue);
  });

  testWidgets(
    'disables approve/reject and shows a hint when the event has ended',
    (tester) async {
      await tester.pumpWidget(_host(cubit, canManage: false));
      await tester.pump();

      final approve = tester.widget<RegistrationApproveButton>(
        find.byType(RegistrationApproveButton),
      );
      final reject = tester.widget<RegistrationRejectButton>(
        find.byType(RegistrationRejectButton),
      );

      expect(approve.enabled, isFalse);
      expect(reject.enabled, isFalse);
      expect(find.textContaining('El evento finalizó'), findsOneWidget);
    },
  );
}
