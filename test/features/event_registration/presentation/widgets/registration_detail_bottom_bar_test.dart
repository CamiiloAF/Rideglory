import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/presentation/registration_detail_extra.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_detail_bottom_bar.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';
import 'package:rideglory/shared/widgets/registration_actions/registration_approve_button.dart';

EventRegistrationModel _registration({
  RegistrationStatus status = RegistrationStatus.approved,
  bool allowOrganizerContact = true,
}) => EventRegistrationModel(
  id: 'reg-1',
  eventId: 'event-1',
  eventName: 'Rodada de prueba',
  userId: 'user-1',
  status: status,
  fullName: 'Carlos Herrera',
  identificationNumber: '123456789',
  birthDate: DateTime(1990, 1, 1),
  phone: '+57 310 456 7890',
  email: 'carlos@test.com',
  residenceCity: 'Bogotá',
  eps: 'Sura',
  bloodType: null,
  emergencyContactName: 'Ana',
  emergencyContactPhone: '3007654321',
  allowOrganizerContact: allowOrganizerContact,
);

Widget _host(RegistrationDetailExtra params) => MaterialApp(
  theme: AppTheme.darkTheme,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [Locale('es')],
  home: Scaffold(
    bottomNavigationBar: RegistrationDetailBottomBar(params: params),
  ),
);

void main() {
  testWidgets('aprobada + allowOrganizerContact + organizador → barra vacía '
      '(el contacto ya no vive en la barra sino en el encabezado)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        RegistrationDetailExtra(
          registration: _registration(),
          isOrganizerView: true,
        ),
      ),
    );
    expect(find.text('Llamar'), findsNothing);
    expect(find.text('WhatsApp'), findsNothing);
    expect(find.byType(AppButton), findsNothing);
    expect(find.byType(RegistrationApproveButton), findsNothing);
  });

  testWidgets(
    'aprobada sin allowOrganizerContact ni acciones → barra vacía (shrink)',
    (tester) async {
      await tester.pumpWidget(
        _host(
          RegistrationDetailExtra(
            registration: _registration(allowOrganizerContact: false),
            isOrganizerView: true,
          ),
        ),
      );
      expect(find.byType(RegistrationApproveButton), findsNothing);
      expect(find.byType(AppButton), findsNothing);
    },
  );

  testWidgets('pending + organizador con callbacks → aprobar/rechazar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        RegistrationDetailExtra(
          registration: _registration(
            status: RegistrationStatus.pending,
            allowOrganizerContact: false,
          ),
          isOrganizerView: true,
          onApprove: (_) {},
          onReject: (_) {},
        ),
      ),
    );
    expect(find.byType(RegistrationApproveButton), findsOneWidget);
  });

  testWidgets('vista piloto → editar + cancelar', (tester) async {
    await tester.pumpWidget(
      _host(
        RegistrationDetailExtra(
          registration: _registration(allowOrganizerContact: false),
          onEditRegistration: (_) {},
          onCancelRegistration: () async => true,
        ),
      ),
    );
    expect(find.byType(AppButton), findsNWidgets(2));
  });
}
