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
import 'package:rideglory/features/event_registration/presentation/widgets/registration_detail_data_row.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_detail_rider_summary.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_detail_status_banner.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';
import 'package:rideglory/l10n/app_localizations.dart';

class MockAuthCubit extends Mock implements AuthCubit {}

EventRegistrationModel _buildRegistration({
  BloodType? bloodType,
  String? bloodTypeRaw,
  String phone = '3001234567',
}) => EventRegistrationModel(
  id: 'reg-1',
  eventId: 'event-1',
  eventName: 'Rodada Test',
  userId: 'user-1',
  fullName: 'Rider Test',
  identificationNumber: '123456',
  birthDate: DateTime(2000, 1, 1),
  phone: phone,
  email: 'rider@test.com',
  residenceCity: 'Bogotá',
  eps: 'Sura',
  bloodType: bloodType,
  bloodTypeRaw: bloodTypeRaw,
  emergencyContactName: 'Contact Test',
  emergencyContactPhone: '3007654321',
);

Widget _buildTestWidget(
  MockAuthCubit authCubit,
  EventRegistrationModel registration, {
  bool isOrganizerView = false,
}) {
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
        params: RegistrationDetailExtra(
          registration: registration,
          isOrganizerView: isOrganizerView,
        ),
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

      // Case 1.3 (AC10): bloodType=null but bloodTypeRaw carries a raw
      // backend string (e.g. a privacy sentinel) — it must render as-is.
      testWidgets(
        '1.3: registration with bloodType=null and bloodTypeRaw set renders the raw string',
        (tester) async {
          final registration = _buildRegistration(
            bloodType: null,
            bloodTypeRaw: '••••',
          );

          await tester.pumpWidget(
            _buildTestWidget(mockAuthCubit, registration),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Tipo de sangre'), findsOneWidget);
          expect(find.text('••••'), findsOneWidget);
        },
      );

      // Case 1.4 (AC10): bloodType=null and bloodTypeRaw=null renders the
      // localized "N/A" fallback.
      testWidgets(
        '1.4: registration with bloodType=null and bloodTypeRaw=null renders "N/A"',
        (tester) async {
          final registration = _buildRegistration(
            bloodType: null,
            bloodTypeRaw: null,
          );

          await tester.pumpWidget(
            _buildTestWidget(mockAuthCubit, registration),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Tipo de sangre'), findsOneWidget);
          expect(
            find.byWidgetPredicate(
              (widget) =>
                  widget is RegistrationDetailDataRow &&
                  widget.label == 'Tipo de sangre' &&
                  widget.value == 'N/A',
            ),
            findsOneWidget,
          );
        },
      );
    },
  );

  group(
    'RegistrationDetailPage — isOrganizerView switch (legal-privacidad-edad fase 7, AC1/AC4)',
    () {
      // AC1/AC4: organizer view — even when registration.userId equals the
      // authenticated user's id (organizer-participant edge case), the
      // isOrganizerView flag (not the userId comparison) must drive the
      // rendered chrome.
      testWidgets(
        'isOrganizerView=true (including registration.userId == authenticated user id) shows organizer title, rider summary, and no status banner',
        (tester) async {
          final registration = _buildRegistration(
            bloodType: BloodType.aPositive,
          ).copyWith(userId: 'user-1');

          await tester.pumpWidget(
            _buildTestWidget(
              mockAuthCubit,
              registration,
              isOrganizerView: true,
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Detalle de solicitud'), findsOneWidget);
          expect(
            find.byType(RegistrationDetailRiderSummary),
            findsOneWidget,
          );
          expect(
            find.byType(RegistrationDetailStatusBanner),
            findsNothing,
          );
        },
      );

      // Mirror case: isOrganizerView=false shows the rider's own-view chrome.
      testWidgets(
        'isOrganizerView=false shows rider title, status banner, and no rider summary',
        (tester) async {
          final registration = _buildRegistration(
            bloodType: BloodType.aPositive,
          );

          await tester.pumpWidget(
            _buildTestWidget(
              mockAuthCubit,
              registration,
              isOrganizerView: false,
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Mi registro'), findsOneWidget);
          expect(
            find.byType(RegistrationDetailStatusBanner),
            findsOneWidget,
          );
          expect(
            find.byType(RegistrationDetailRiderSummary),
            findsNothing,
          );
        },
      );
    },
  );

  group(
    'RegistrationDetailPage — obfuscated phone passthrough (legal-privacidad-edad fase 7, AC9)',
    () {
      // AC9: when the backend returns the obfuscation sentinel for phone,
      // the page must render it literally, with no exception and no crash —
      // locks the obfuscated-passthrough contract the AC names explicitly.
      testWidgets(
        "registration with phone='••••' renders '••••' literally with no exception",
        (tester) async {
          final registration = _buildRegistration(
            bloodType: BloodType.aPositive,
            phone: '••••',
          );

          await tester.pumpWidget(
            _buildTestWidget(mockAuthCubit, registration),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('••••'), findsOneWidget);
        },
      );
    },
  );

  group(
    'RegistrationDetailPage — anonymized (deleted-account) registration (eliminacion-cuenta-phase-03, AC10)',
    () {
      // AC10: when the registrant's account has been deleted, the backend
      // anonymizes 8 PII fields to null (fullName stays 'Usuario eliminado';
      // bloodType/bloodTypeRaw are untouched). Every nulled field must fall
      // back to the dedicated placeholder, never crash, and never reuse
      // context.l10n.notAvailable.
      testWidgets(
        'muestra el placeholder dedicado en los 7 campos de texto + fecha de nacimiento',
        (tester) async {
          const registration = EventRegistrationModel(
            id: 'reg-1',
            eventId: 'event-1',
            eventName: 'Rodada Test',
            userId: 'user-1',
            fullName: 'Usuario eliminado',
            bloodType: BloodType.aPositive,
          );

          await tester.pumpWidget(
            _buildTestWidget(mockAuthCubit, registration),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Usuario eliminado'), findsWidgets);
          // identificationNumber, birthDate, phone, email, residenceCity,
          // eps, emergencyContactName, emergencyContactPhone == 8 rows.
          expect(find.text('Cuenta eliminada'), findsNWidgets(8));
        },
      );
    },
  );

  group(
    'RegistrationDetailPage — masking regression (eliminacion-cuenta-phase-03, masking != anonymization)',
    () {
      // Regression guardrail: a registration where the rider opted out of
      // sharing medical info (shareMedicalInfo=false, backend masks the
      // medical/emergency fields as the literal privacy sentinel "••••") is
      // NOT the same thing as an anonymized (deleted-account) registration.
      // The page must render the masking sentinel literally and must never
      // show the anonymization placeholder ("Cuenta eliminada") for a
      // non-anonymized, merely-masked registration.
      testWidgets(
        'shareMedicalInfo=false con campos enmascarados ("••••") no muestra el placeholder de cuenta eliminada',
        (tester) async {
          final registration = EventRegistrationModel(
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
            eps: '••••',
            bloodType: null,
            bloodTypeRaw: '••••',
            emergencyContactName: '••••',
            emergencyContactPhone: '••••',
            shareMedicalInfo: false,
          );

          await tester.pumpWidget(
            _buildTestWidget(mockAuthCubit, registration),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Rider Test'), findsWidgets);
          // eps, bloodTypeRaw, emergencyContactName, emergencyContactPhone.
          expect(find.text('••••'), findsNWidgets(4));
          expect(find.text('Cuenta eliminada'), findsNothing);
          expect(find.text('Usuario eliminado'), findsNothing);
        },
      );
    },
  );
}
