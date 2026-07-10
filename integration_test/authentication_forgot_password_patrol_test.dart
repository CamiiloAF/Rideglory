// Patrol e2e test: recuperación de contraseña ("olvidé mi contraseña").
//
// Flujo cubierto:
//   Login → "¿Olvidaste tu contraseña?" → ForgotPasswordView (form) →
//   ingresar email → "Enviar enlace" → pantalla de confirmación
//   ("Correo enviado" + email mostrado) → "No recibí el correo — reenviar".
//
// PRECONDICIONES DE DATOS:
//   1. El email usado es el de la cuenta de prueba `qa1@gmail.com` (existe en
//      Firebase Auth). `sendPasswordResetEmail` de Firebase NO revela si el
//      correo existe o no (por diseño, antienumeración) y SIEMPRE transiciona
//      a la pantalla de "Correo enviado" con `AuthState.passwordResetEmailSent`
//      si la llamada a Firebase no lanza error de red/formato — por eso este
//      test también sería válido con un email sintético inexistente, pero se
//      usa `qa1@gmail.com` para que, si alguna vez se decide verificar la
//      bandeja de entrada real, ya hay una cuenta de la que se puede leer.
//   2. Este test NO verifica que el correo de Firebase realmente llegue a la
//      bandeja (fuera del alcance de un e2e de UI) — solo que la UI reacciona
//      al estado `passwordResetEmailSent` mostrando la confirmación con el
//      email correcto.
//   3. Si el dispositivo ya tiene sesión Firebase persistida, el test
//      necesita llegar a Login para poder navegar a "¿Olvidaste tu
//      contraseña?"; si detecta Home en su lugar, cierra sesión primero desde
//      el tab Perfil (igual que `authentication_signup_patrol_test.dart`).
//
// Cómo correr:
//   patrol test -t integration_test/authentication_forgot_password_patrol_test.dart \
//     --device-id emulator-5554

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:rideglory/main.dart' as app;

// Literales de UI reales (de lib/l10n/app_es.arb). Se centralizan aquí para
// que el test rompa de forma evidente si cambian las claves.
const _tabEventos = 'EVENTOS'; // bottom nav, único de Home
const _forgotPasswordLink =
    '¿Olvidaste tu contraseña?'; // auth_forgot_password (LoginForm) /
// auth_recovery_heading (ForgotPasswordHeading) — mismo texto en ambos
// lugares; se desambigua por pantalla (uno es link, el otro es heading).
const _sendLinkButton = 'Enviar enlace'; // auth_recovery_send
const _emailSentTitle = 'Correo enviado'; // auth_recovery_sent_title
const _resendLink = 'No recibí el correo — reenviar'; // auth_recovery_resend
const _logoutMenuItem = 'Cerrar sesión'; // auth_logout (ProfileActionsList)
const _logoutConfirmMessage =
    '¿Estás seguro de que deseas cerrar sesión?'; // auth_logoutConfirmMessage

const _testEmail = 'qa1@gmail.com';

Future<void> _grantPendingLocationPermission(PatrolIntegrationTester $) async {
  if (await $.platformAutomator.mobile.isPermissionDialogVisible()) {
    await $.platformAutomator.mobile.grantPermissionWhenInUse();
    await $.pumpAndSettle();
  }
}

/// Deja el device en la pantalla de Login, cerrando sesión primero si el
/// Firebase Account Manager persistió una sesión de una corrida anterior.
Future<void> _ensureOnLoginScreen(PatrolIntegrationTester $) async {
  app.main();
  await $.pumpAndSettle();

  var onLogin = false;
  var onHome = false;
  for (var i = 0; i < 24 && !onLogin && !onHome; i++) {
    await Future<void>.delayed(const Duration(seconds: 5));
    await _grantPendingLocationPermission($);
    onLogin = $(TextField).exists;
    onHome = $(_tabEventos).exists;
  }

  if (onLogin) return;

  if (!onHome) {
    await $(_tabEventos).waitUntilVisible(timeout: const Duration(seconds: 30));
  }

  await $(Icons.person_outline).tap();
  await $.pumpAndSettle(timeout: const Duration(seconds: 20));
  await _grantPendingLocationPermission($);

  await $(
    _logoutMenuItem,
  ).waitUntilVisible(timeout: const Duration(seconds: 20));
  await $(_logoutMenuItem).tap();
  await $.pumpAndSettle();

  await $(
    _logoutConfirmMessage,
  ).waitUntilVisible(timeout: const Duration(seconds: 10));
  // El diálogo repite "Cerrar sesión" en el botón de confirmar (título + CTA
  // comparten `auth_logout`); el CTA de confirmación es el último match.
  await $(_logoutMenuItem).at($(_logoutMenuItem).evaluate().length - 1).tap();
  await $.pumpAndSettle(timeout: const Duration(seconds: 15));

  await $(TextField).waitUntilVisible(timeout: const Duration(seconds: 20));
}

void main() {
  patrolTest(
    'forgot password: enviar enlace de recuperación y ver confirmación',
    timeout: const Timeout(Duration(minutes: 6)),
    _runForgotPasswordFlow,
  );
}

Future<void> _runForgotPasswordFlow(PatrolIntegrationTester $) async {
  // 1. Garantizar que arrancamos en Login.
  await _ensureOnLoginScreen($);

  // 2. Abrir "¿Olvidaste tu contraseña?" desde el form de Login.
  await $(_forgotPasswordLink).tap();
  await $.pumpAndSettle();

  // 3. Confirmar que llegamos al form de recuperación (mismo texto que el
  // link de Login, pero ahora como heading + hay un TextField de email solo).
  await $(
    _forgotPasswordLink,
  ).waitUntilVisible(timeout: const Duration(seconds: 15));
  await $(TextField).waitUntilVisible(timeout: const Duration(seconds: 15));

  // 4. Ingresar el email y enviar.
  await $(TextField).at(0).enterText(_testEmail);
  await $.pumpAndSettle();
  await $(_sendLinkButton).tap();

  // 5. Esperar la pantalla de confirmación. No basta `pumpAndSettle` — el
  // estado depende de la respuesta (real) de Firebase Auth.
  await $(
    _emailSentTitle,
  ).waitUntilVisible(timeout: const Duration(seconds: 20));

  // 6. El email mostrado en la confirmación es el que se envió.
  await $(_testEmail).waitUntilVisible(timeout: const Duration(seconds: 5));

  // 7. El link de reenvío está disponible (no se ejecuta un segundo envío
  // real para no generar ruido de emails de Firebase innecesarios; basta con
  // verificar que el CTA existe y es tocable).
  await $(_resendLink).waitUntilVisible(timeout: const Duration(seconds: 5));
}
