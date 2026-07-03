import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/presentation/registration_detail_extra.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_contact_actions.dart';
import 'package:rideglory/l10n/app_localizations.dart';

EventRegistrationModel _registration({
  bool allowOrganizerContact = true,
  String phone = '+57 310 456 7890',
}) => EventRegistrationModel(
  id: 'reg-1',
  eventId: 'event-1',
  eventName: 'Rodada de prueba',
  userId: 'user-1',
  status: RegistrationStatus.approved,
  fullName: 'Carlos Herrera',
  identificationNumber: '123456789',
  birthDate: DateTime(1990, 1, 1),
  phone: phone,
  email: 'carlos@test.com',
  residenceCity: 'Bogotá',
  eps: 'Sura',
  bloodType: null,
  emergencyContactName: 'Ana',
  emergencyContactPhone: '3007654321',
  allowOrganizerContact: allowOrganizerContact,
);

Widget _host(RegistrationDetailExtra extra) => MaterialApp(
  theme: AppTheme.darkTheme,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [Locale('es')],
  home: Scaffold(body: RegistrationContactActions(extra: extra)),
);

void main() {
  testWidgets('vista piloto (isOrganizerView false) no muestra botones', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(RegistrationDetailExtra(registration: _registration())),
    );
    expect(find.text('Llamar'), findsNothing);
    expect(find.text('WhatsApp'), findsNothing);
  });

  testWidgets('organizador sin allowOrganizerContact no muestra botones', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        RegistrationDetailExtra(
          registration: _registration(allowOrganizerContact: false),
          isOrganizerView: true,
        ),
      ),
    );
    expect(find.text('Llamar'), findsNothing);
    expect(find.text('WhatsApp'), findsNothing);
  });

  testWidgets('organizador con allowOrganizerContact muestra ambos botones', (
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
    expect(find.text('Llamar'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
  });

  group('taps lanzan las URLs correctas', () {
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    final launched = <String>[];

    setUp(() {
      launched.clear();
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'canLaunch') return true;
            if (call.method == 'launch' || call.method == 'launchUrl') {
              final url = (call.arguments as Map)['url'] as String?;
              if (url != null) launched.add(url);
              return true;
            }
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    testWidgets('tap en Llamar abre tel:', (tester) async {
      await tester.pumpWidget(
        _host(
          RegistrationDetailExtra(
            registration: _registration(),
            isOrganizerView: true,
          ),
        ),
      );
      await tester.tap(find.text('Llamar'));
      await tester.pumpAndSettle();
      // El teléfono con espacios se percent-encodea al construir la Uri; lo que
      // importa es que se lanzó un enlace tel: (AC7).
      expect(launched, hasLength(1));
      expect(launched.single, startsWith('tel:'));
    });

    testWidgets('tap en WhatsApp abre wa.me con el teléfono saneado', (
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
      await tester.tap(find.text('WhatsApp'));
      await tester.pumpAndSettle();
      expect(launched, contains('https://wa.me/+573104567890'));
    });
  });
}
