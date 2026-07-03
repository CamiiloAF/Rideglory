import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/presentation/registration_detail_extra.dart';
import 'package:rideglory/features/event_registration/presentation/registration_detail_page.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';
import 'package:rideglory/l10n/app_localizations.dart';

class MockAuthCubit extends Mock implements AuthCubit {}

EventRegistrationModel _buildRegistration({BloodType? bloodType}) =>
    EventRegistrationModel(
      id: 'reg-1',
      eventId: 'event-1',
      eventName: 'Rodada Test',
      userId: 'user-1',
      fullName: 'Rider Test',
      identificationNumber: '123456',
      birthDate: DateTime(2000, 1, 1),
      phone: '3001234567',
      email: 'rider@test.com',
      residenceCity: 'Bogotá',
      eps: 'Sura',
      bloodType: bloodType,
      emergencyContactName: 'Contact Test',
      emergencyContactPhone: '3007654321',
    );

Widget _buildTestWidget(
  MockAuthCubit authCubit,
  EventRegistrationModel registration,
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
    home: BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: RegistrationDetailPage(
        params: RegistrationDetailExtra(registration: registration),
      ),
    ),
  );
}

void main() {
  late MockAuthCubit mockAuthCubit;

  setUp(() {
    mockAuthCubit = MockAuthCubit();
    when(() => mockAuthCubit.stream).thenAnswer((_) => const Stream.empty());
    // The viewer is the registrant itself (userId == currentUser.id) so the
    // rider-summary banner (organizer view) is skipped and we exercise the
    // simplest render path for the medical info card.
    when(() => mockAuthCubit.state).thenReturn(
      const AuthState.authenticated(
        UserModel(
          id: 'user-1',
          fullName: 'Rider Test',
          email: 'rider@test.com',
        ),
      ),
    );
  });

  group(
    'RegistrationDetailPage — bloodType row (legal-privacidad-edad fase 3)',
    () {
      // Case 1.1: bloodType present renders its label without crashing.
      testWidgets(
        '1.1: registration with bloodType=A+ renders "A+" in the blood type row',
        (tester) async {
          final registration = _buildRegistration(
            bloodType: BloodType.aPositive,
          );

          await tester.pumpWidget(
            _buildTestWidget(mockAuthCubit, registration),
          );
          await tester.pumpAndSettle();

          expect(find.text('Tipo de sangre'), findsOneWidget);
          expect(find.text('A+'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      // Case 1.2: bloodType absent (null) does not crash and never shows the
      // literal string 'null'.
      testWidgets(
        '1.2: registration with bloodType=null renders blank value, no "null" text, no crash',
        (tester) async {
          final registration = _buildRegistration(bloodType: null);

          await tester.pumpWidget(
            _buildTestWidget(mockAuthCubit, registration),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Tipo de sangre'), findsOneWidget);
          expect(find.text('null'), findsNothing);
        },
      );
    },
  );
}
