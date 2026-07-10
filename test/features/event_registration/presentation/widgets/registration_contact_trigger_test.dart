import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_contact_trigger.dart';
import 'package:rideglory/l10n/app_localizations.dart';

EventRegistrationModel _registration({
  bool allowOrganizerContact = true,
  String? phone = '+57 310 456 7890',
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

Widget _host({
  bool isOrganizerView = true,
  bool allowOrganizerContact = true,
  String? phone = '+57 310 456 7890',
}) => MaterialApp(
  theme: AppTheme.darkTheme,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: const [Locale('es')],
  home: Scaffold(
    body: Center(
      child: RegistrationContactTrigger(
        registration: _registration(
          allowOrganizerContact: allowOrganizerContact,
          phone: phone,
        ),
        isOrganizerView: isOrganizerView,
      ),
    ),
  ),
);

/// Mock del canal de `url_launcher`. [canLaunchFor] simula qué URLs pueden
/// abrirse; [launched] registra los URLs efectivamente lanzados.
void _mockUrlLauncher({
  required List<String> launched,
  required bool Function(String url) canLaunchFor,
}) {
  const channel = MethodChannel('plugins.flutter.io/url_launcher');
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
        final url = (call.arguments as Map?)?['url'] as String?;
        if (call.method == 'canLaunch') return url != null && canLaunchFor(url);
        if (call.method == 'launch' || call.method == 'launchUrl') {
          if (url != null) launched.add(url);
          return true;
        }
        return null;
      });
}

void main() {
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          null,
        );
  });

  testWidgets('vista piloto (isOrganizerView false) no muestra el disparador', (
    tester,
  ) async {
    await tester.pumpWidget(_host(isOrganizerView: false));
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets(
    'organizador sin allowOrganizerContact no muestra el disparador',
    (tester) async {
      await tester.pumpWidget(_host(allowOrganizerContact: false));
      expect(find.byType(InkWell), findsNothing);
    },
  );

  testWidgets('tocar el disparador abre el sheet con las 2 opciones', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();

    expect(find.text('Contactar a Carlos Herrera'), findsOneWidget);
    expect(find.text('Llamar'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
  });

  testWidgets('elegir Llamar abre tel: (AC7)', (tester) async {
    final launched = <String>[];
    _mockUrlLauncher(launched: launched, canLaunchFor: (_) => true);

    await tester.pumpWidget(_host());
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Llamar'));
    await tester.pumpAndSettle();

    expect(launched, hasLength(1));
    expect(launched.single, startsWith('tel:'));
  });

  testWidgets('elegir WhatsApp intenta primero el esquema whatsapp://', (
    tester,
  ) async {
    final launched = <String>[];
    _mockUrlLauncher(launched: launched, canLaunchFor: (_) => true);

    await tester.pumpWidget(_host());
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    await tester.tap(find.text('WhatsApp'));
    await tester.pumpAndSettle();

    expect(launched, hasLength(1));
    expect(launched.single, 'whatsapp://send?phone=+573104567890');
  });

  testWidgets('WhatsApp cae a wa.me si el esquema directo no está disponible', (
    tester,
  ) async {
    final launched = <String>[];
    _mockUrlLauncher(
      launched: launched,
      canLaunchFor: (url) => url.startsWith('https://wa.me/'),
    );

    await tester.pumpWidget(_host());
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    await tester.tap(find.text('WhatsApp'));
    await tester.pumpAndSettle();

    expect(launched, contains('https://wa.me/+573104567890'));
  });

  testWidgets(
    'phone=null (cuenta anonimizada) con Llamar no lanza excepción ni URL (eliminacion-cuenta-phase-03)',
    (tester) async {
      final launched = <String>[];
      _mockUrlLauncher(launched: launched, canLaunchFor: (_) => true);

      await tester.pumpWidget(_host(phone: null));
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Llamar'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(launched, isEmpty);
    },
  );

  testWidgets('sin app que abra el enlace muestra un SnackBar, no falla mudo', (
    tester,
  ) async {
    final launched = <String>[];
    _mockUrlLauncher(launched: launched, canLaunchFor: (_) => false);

    await tester.pumpWidget(_host());
    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();
    await tester.tap(find.text('WhatsApp'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(launched, isEmpty);
    expect(
      find.text('No se pudo abrir WhatsApp. Verifica que esté instalado.'),
      findsOneWidget,
    );
  });
}
