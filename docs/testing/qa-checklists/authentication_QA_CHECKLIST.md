# Checklist de QA — Authentication (login, signup, social sign-in, forgot password)

**Feature:** Authentication (`lib/features/authentication/`)
**Alcance:** Login email, Signup email, Google sign-in, Apple sign-in, forgot password, logout,
persistencia de sesión, reconciliación Firebase/backend, analytics del funnel.
**Estado:** Planificación — pendiente de correr `/qa-auto` para anotar resultados reales.

> Este checklist se planificó a mano a partir de `docs/features/authentication.md` y del código de
> test existente en `test/features/authentication/` e `integration_test/`. No viene de una corrida
> de `rg-exec`, así que no tiene auditor Opus ni resumen de automatización todavía. Cuando alguien
> corra `/qa-auto` sobre este archivo, se agregará el bloque `<!-- qa-auto:annotated -->` con el
> resumen y se rellenarán las columnas ✅/❌.
>
> **Nota sobre "Estado auto":** la marca `🤖✅ Auto-PASS` significa que el caso está **cubierto por
> un test automatizado existente** (el test citado se leyó y se confirmó que ejercita lo descrito
> en "Resultado esperado"), **no** que se haya ejecutado en verde durante esta corrida — el estado
> de este documento es de planificación, no de ejecución. `👤 Manual` significa que no existe (o no
> se encontró) cobertura automatizada para ese caso.

---

## Pre-condiciones

- [ ] Cuenta de prueba existente en Firebase Auth + backend: `qa1@gmail.com` / `Test123.` (rider).
- [ ] Cuenta de prueba existente en Firebase Auth + backend: `qa2@gmail.com` / `Test123.` (owner de "Mi Evento").
- [ ] Capacidad de generar un email sintético único (`qa.signup.<timestamp>@rideglory-test.com`) para probar signup sin colisionar con cuentas reales.
- [ ] Un email que NO exista en Firebase Auth, para probar login fallido / cuenta inexistente (ej. `qa.no-existe.<timestamp>@rideglory-test.com`).
- [ ] Dispositivo o emulador Android con Google Play Services (cuenta de Google real o de prueba configurada) para probar el flujo social de Google.
- [ ] Dispositivo iOS real o simulador con sesión de Apple ID configurada (Sandbox) para probar Apple sign-in — **en Android no aplica** (el botón puede no mostrarse o fallar por diseño de plataforma; verificar comportamiento esperado antes de reportar como bug).
- [ ] Verificar en Firebase Console → Authentication → Sign-in providers que **Apple** esté habilitado (según la doc, es un prerequisito de activación, no un stub).
- [ ] Acceso a Firebase Console / backend para confirmar que un registro de signup efectivamente creó el usuario en ambos lados (reconciliación).
- [ ] Modo avión o forma de cortar la red del dispositivo, para probar los casos de borde de red caída.
- [ ] Si el dispositivo ya tiene sesión Firebase persistida de una corrida anterior, tener a mano el flujo de logout (tab Perfil → "Cerrar sesión" → confirmar) o usar `patrol test --uninstall` para arrancar limpio.

---

## 1. Login con email/password — caso exitoso

> Desde la pantalla de Login, con una cuenta existente y válida.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 1.1 | Ingresa `qa1@gmail.com` / `Test123.` y toca "Iniciar sesión" | Se llama `signInWithEmail` con los valores trimmed | 🤖✅ Auto-PASS (`test/features/authentication/login/presentation/login_view_test.dart` TC-login-4 — verifica `signInWithEmail` invocado con valores trimmed) | |
| 1.1b | Mientras el login está en progreso | El botón muestra estado de carga (`isLoading`) | 🤖✅ Auto-PASS (`test/features/authentication/login/presentation/login_view_test.dart` TC-login-4b — usa un `StreamController<AuthState>` controlado para verificar que `AppButton.isLoading` es `true` inmediatamente al enviar el formulario (antes de que el cubit resuelva) y que vuelve a `false` al recibir un estado no-loading) | |
| 1.2 | Espera a que termine el login | La app navega a Home (`pushReplacementNamed`) y se ve el bottom nav con "EVENTOS" | 👤 Manual (navegación real y renderizado de Home no están cubiertos por el widget test de `LoginView`, que hace mock del cubit; requiere e2e o inspección visual) | |
| 1.3 | Verifica en consola de debug (`kDebugMode`) | Se logea el `idToken` de Firebase con `dart:developer log()` (solo en debug) | 👤 Manual (requiere correr en modo debug y revisar logs; no automatizable con unit/widget test) | |
| 1.4 | Revisa analytics (si hay acceso a DebugView de Firebase Analytics o mocks en QA) | Se dispara `authFirebaseOk`, luego `authSucceeded` + `authFirstHomeEntry`, con `setUserId` recibiendo un hash SHA-256 (no el uid crudo) y `login_method=email` como user property | 🤖✅ Auto-PASS (`test/features/authentication/application/auth_cubit_test.dart` TC-auth-4d — verifica hash de 64 chars, distinto al uid, y eventos de analytics) | |
| 1.5 | Desde `LoginView`, sin haber navegado desde otra pantalla, presiona el back físico/gesto de Android | Aparece el diálogo "¿Salir de la app?" (`ConfirmationDialog` con `auth_exitLoginTitle`/`auth_exitLoginMessage`); la pantalla NO hace pop (el `PopScope` tiene `canPop: false`) | 🤖✅ Auto-PASS (`test/features/authentication/login/presentation/login_view_test.dart` TC-login-7 — simula el back del sistema con `tester.binding.handlePopRoute()` y verifica que aparecen los textos de `auth_exitLoginTitle`/`auth_exitLoginMessage` y que `LoginView` sigue presente debajo del diálogo) | |
| 1.6 | En el diálogo "¿Salir de la app?", toca "Confirmar" | Se llama `SystemNavigator.pop()` (la app se cierra) | 🤖✅ Auto-PASS (`test/features/authentication/login/presentation/login_view_test.dart` TC-login-8 — intercepta el canal de plataforma `SystemChannels.platform` y verifica que el método `'SystemNavigator.pop'` se invoca al tocar "Confirmar"; no verifica el cierre real del proceso, solo que se emite la llamada de plataforma esperada) | |

---

## 2. Login con email/password — casos fallidos

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 2.1 | Deja el formulario vacío y toca "Iniciar sesión" | Aparecen errores de campo requerido en email y password, no se llama al cubit | 🤖✅ Auto-PASS (`test/features/authentication/login/presentation/login_view_test.dart` TC-login-1) | |
| 2.2 | Ingresa un email mal formado (ej. `no-es-un-email`) | Error inline de formato de email | 🤖✅ Auto-PASS (`login_view_test.dart` TC-login-2) | |
| 2.3 | Ingresa una password de menos de 6 caracteres | Error inline de longitud mínima | 🤖✅ Auto-PASS (`login_view_test.dart` TC-login-3) | |
| 2.4 | Ingresa un email inexistente + password incorrecta y toca "Iniciar sesión" | SnackBar con mensaje genérico **"Correo o contraseña incorrectos."** (antienumeración — no distingue usuario no existe de password incorrecta); el usuario permanece en Login, no navega a Home | 🤖✅ Auto-PASS (`integration_test/authentication_login_failure_patrol_test.dart`; también `login_view_test.dart` TC-login-5 a nivel de estado de error genérico) | |
| 2.5 | Revisa analytics tras el intento fallido | Se dispara `authFailed` con `authMethod=email` y una categoría de error (no el mensaje crudo) | 🤖✅ Auto-PASS (`auth_cubit_test.dart` TC-auth-4b) | |
| 2.6 | Repite el intento fallido varias veces seguidas | No hay bloqueo/captcha visible del lado de la app (Firebase puede eventualmente exigir reCAPTCHA/rate-limit); si aparece, la app no debe crashear | 👤 Manual (depende de umbrales internos de Firebase, no reproducible de forma determinística en test) | |

---

## 3. Signup con email/password — caso exitoso

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 3.1 | Desde Login, toca "Regístrate" | Navega a `SignupView` (`pushNamed`) | 👤 Manual (la navegación real desde Login no está cubierta por un widget test aislado de `SignupView`; sí lo ejerce el e2e) | |
| 3.2 | Completa nombre, email sintético único, password válida (≥8, 1 mayúscula, 1 número) y su confirmación, marca el checkbox de términos, toca "Crear cuenta" | Se crea la cuenta en Firebase Auth y en el backend; navega a Home con "EVENTOS" visible | 🤖✅ Auto-PASS (`integration_test/authentication_signup_patrol_test.dart`) | |
| 3.3 | Tras el signup, verifica en Firebase Console y en el backend | El usuario existe en ambos lados con los mismos datos (nombre, email) — reconciliación correcta | 👤 Manual (verificación cruzada en dos consolas externas, fuera del alcance de un test automatizado de la app) | |
| 3.4 | Revisa analytics tras el signup exitoso | Se dispara `authSucceeded` (método email) + `authFirstHomeEntry`, `setUserId` con hash, `login_method=email` | 🤖✅ Auto-PASS (`auth_cubit_test.dart` TC-auth-5b — cubre `signUpWithEmail` con `setUserId` (hash) + `authSucceeded(email)` + `setUserProperty(login_method, email)`) | |

---

## 4. Signup — validaciones de formulario

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 4.1 | Deja el formulario vacío y toca "Crear cuenta" | Errores de campo requerido en nombre, email, password y confirmación | 🤖✅ Auto-PASS (`test/features/authentication/signup/presentation/signup_view_test.dart` TC-signup-1) | |
| 4.2 | Ingresa una password que no cumple las reglas (ej. `abcdefgh`, sin mayúscula ni número) | Errores de: longitud mínima (si aplica), falta de mayúscula, falta de número | 🤖✅ Auto-PASS (`signup_view_test.dart` TC-signup-2) | |
| 4.3 | Ingresa una confirmación de password distinta a la password | Error de "las contraseñas no coinciden" | 🤖✅ Auto-PASS (`signup_view_test.dart` TC-signup-3) | |
| 4.4 | Completa el formulario válido pero NO marca el checkbox de términos, toca "Crear cuenta" | SnackBar de error indicando que debe aceptar términos; no se llama `signUpWithEmail` | 🤖✅ Auto-PASS (`signup_view_test.dart` TC-signup-4) | |
| 4.5 | Completa el formulario válido y SÍ marca términos, toca "Crear cuenta" | Se llama `signUpWithEmail` con los valores correctos (trimmed) | 🤖✅ Auto-PASS (`signup_view_test.dart` TC-signup-5) | |
| 4.6 | Intenta registrar un email que YA existe en Firebase | El flujo reconcilia: internamente hace sign-in con esas credenciales; si la contraseña es correcta, continúa como si fuera login (no informa "email ya registrado" para no permitir enumeración de cuentas); si la contraseña es incorrecta, muestra el mismo error genérico de credenciales inválidas | 👤 Manual (requiere una cuenta real ya existente en Firebase + backend y no está cubierto por unit test de esta rama específica de `AuthService`; validar contra `docs/features/authentication.md` sección "Reconciliación") | |
| 4.7 | Estado de error genérico de signup (ej. red caída durante el registro) | SnackBar con el mensaje de error correspondiente | 🤖✅ Auto-PASS (`signup_view_test.dart` TC-signup-6) | |

---

## 5. Google sign-in

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5.1 | Desde Login, toca el botón de Google | Se abre el picker nativo de cuentas de Google del dispositivo | 👤 Manual (requiere dispositivo/emulador real con Google Play Services; el intent nativo no es testeable con flutter_test) | |
| 5.2 | Selecciona una cuenta de Google válida | Navega a Home; si es la primera vez, se crea el usuario en el backend con nombre/email de Google | 👤 Manual (depende del picker nativo real; no cubierto por Patrol todavía) | |
| 5.3 | Cancela el picker de Google (botón atrás o "Cancelar") | No se muestra ningún error visible al usuario; el estado vuelve a `unauthenticated` silenciosamente | 🤖✅ Auto-PASS (`auth_cubit_test.dart` TC-auth-G1 — verifica que se reporta `authFailed` con categoría `cancelled` a analytics, aunque la UI no muestre snackbar de error para este código) | |
| 5.4 | Mientras el login de Google está en progreso | El botón de Apple se deshabilita (no se puede iniciar ambos flujos social a la vez) | 🤖✅ Auto-PASS (`test/features/authentication/presentation/widgets/login_social_section_test.dart` TC-social-section-2/3 — verifican la exclusión mutua real de `_loadingProvider`: al tocar Google, éste queda `isLoading: true`/`isDisabled: true` y Apple queda `isLoading: false`/`isDisabled: true` sin invocar `signInWithApple`, y viceversa; TC-social-section-4 verifica que ambos se re-habilitan cuando el cubit emite un estado no-loading. **Nota de testabilidad:** `login_social_section.dart` gatea los botones con `Platform.isAndroid`/`Platform.isIOS` de `dart:io`, que son `static final` y reflejan el SO real del host — en un `flutter test` corrido en macOS/Linux ninguno de los dos es `true`, así que ningún botón renderizaría y esta lógica sería intestable. Se agregaron dos overrides `@visibleForTesting` (`LoginSocialSection.debugIsAndroidOverride`/`debugIsIOSOverride`, `null` por defecto, sin efecto en producción) para forzar la rama deseada solo en tests) | |
| 5.5 | Falla de red durante Google sign-in (ej. modo avión activado a mitad del flujo) | Se muestra un error manejado (no crash), y se reporta `authFailed` con la categoría correspondiente | 👤 Manual (requiere provocar la falla de red real en el momento exacto del flujo nativo) | |
| 5.6 | Usuario nuevo por Google pero que YA existía en el backend sin registro completo (reconciliación) | Se llama `_registerApiUser` para crear el registro faltante antes de continuar a Home | 👤 Manual (caso de reconciliación de backend, difícil de reproducir de forma determinística en unit test sin mocks específicos; verificar si existe cobertura en `AuthService` tests fuera de `authentication/`) | |

---

## 6. Apple sign-in

> Apple sign-in está **implementado** (no es un stub) — requiere capability activo en Apple Developer
> Portal + Firebase Console + dispositivo/simulador iOS con Apple ID configurado.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 6.1 | Desde Login, en un dispositivo iOS, toca el botón de Apple | Se abre el flujo nativo de Face ID / Touch ID / password de Apple ID | 👤 Manual (requiere dispositivo/simulador iOS real con Apple ID configurado; intent nativo no testeable con flutter_test) | |
| 6.2 | Completa el sign-in con Apple (primera vez) | Apple entrega nombre y email; se crea el usuario en el backend con esos datos; navega a Home | 🤖✅ Auto-PASS a nivel de cubit (`auth_cubit_test.dart` TC-auth-A1 — happy path completo: `setUserId` con hash, `authSucceeded`, `login_method=apple`); la parte de UI/dispositivo real es manual | |
| 6.3 | Cierra sesión y vuelve a iniciar con Apple (segunda vez) | Apple NO reenvía nombre/email (campo vacío); el flujo debe leer los datos desde caché local o desde el backend para completar el `UserModel` sin perder el nombre | 👤 Manual (comportamiento documentado del SDK de Apple; requiere sesión real repetida en dispositivo, no reproducible con mocks simples) | |
| 6.4 | Cancela el flujo nativo de Apple sign-in | No se muestra error visible; el estado vuelve a `unauthenticated` silenciosamente (mensaje interno `'Inicio de sesión cancelado.'`) | 🤖✅ Auto-PASS (`auth_cubit_test.dart` TC-auth-A2 — verifica `authFailed` con categoría `cancelled` y que nunca se llama `setUserId`) | |
| 6.5 | Verifica el workaround del nonce (`OAuthProvider.credential` con `accessToken: authorizationCode`) | El login con Apple NO falla con `invalid-credential` / "Invalid OAuth response from apple.com" en iOS real | 👤 Manual (bug de SDK específico de iOS real; documentado en `docs/features/authentication.md` sección 11 — no automatizable, solo verificable en dispositivo) | |
| 6.6 | Intenta Apple sign-in en un dispositivo Android | Verificar comportamiento esperado: el botón puede no aparecer, o mostrar un error claro (no debe crashear la app) | 👤 Manual (comportamiento de plataforma; confirmar contra especificación antes de reportar como bug) | |

---

## 7. Forgot password

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 7.1 | Desde Login, toca "¿Olvidaste tu contraseña?" | Navega a `ForgotPasswordView` | 🤖✅ Auto-PASS (`test/features/authentication/login/presentation/login_view_test.dart` TC-login-6) | |
| 7.2 | Deja el campo de email vacío y toca "Enviar enlace" | Error de campo requerido | 🤖✅ Auto-PASS (`test/features/authentication/login/presentation/forgot_password_view_test.dart` TC-forgot-1) | |
| 7.3 | Ingresa un email mal formado | Error de formato de email | 🤖✅ Auto-PASS (`forgot_password_view_test.dart` TC-forgot-2) | |
| 7.4 | Ingresa un email válido (existente o no — Firebase no revela cuál) y toca "Enviar enlace" | Se llama `sendPasswordResetEmail` con el valor trimmed; la pantalla cambia a la vista de confirmación mostrando el email enviado | 🤖✅ Auto-PASS (`forgot_password_view_test.dart` TC-forgot-3, TC-forgot-5; `integration_test/authentication_forgot_password_patrol_test.dart` end-to-end con `qa1@gmail.com`) | |
| 7.5 | En la pantalla de confirmación, toca "No recibí el correo — reenviar" | Vuelve al formulario o reenvía el correo (según implementación) | 🤖✅ Auto-PASS (`forgot_password_view_test.dart` TC-forgot-5 — hace tap real del link y verifica que `sendPasswordResetEmail` se llama una segunda vez con el mismo email; el Patrol test `authentication_forgot_password_patrol_test.dart` solo verifica que el CTA es visible, no hace tap real de reenvío) | |
| 7.6 | Provoca un error (ej. red caída) al enviar el correo de recuperación | SnackBar con el mensaje de error correspondiente; la pantalla NO cambia a la vista de confirmación | 🤖✅ Auto-PASS (`forgot_password_view_test.dart` TC-forgot-4) | |
| 7.7 | Verifica que el correo de recuperación realmente llega a la bandeja de entrada | El usuario recibe el correo de Firebase con el link de reset y puede cambiar su contraseña | 👤 Manual (fuera del alcance de cualquier test de UI; requiere acceso real a la bandeja de correo) | |

---

## 8. Logout

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 8.1 | Estando autenticado, ve a Perfil → "Cerrar sesión" → confirmar | Se emite `AuthState.unauthenticated()`; navega de vuelta a Login | 🤖✅ Auto-PASS (`auth_cubit_test.dart` TC-auth-6 — verifica el estado emitido; la navegación real la ejercen los tests Patrol de forma indirecta como setup) | |
| 8.2 | Provoca un error en `signOut()` (ej. `AuthException` interna) | Se cae al mensaje `RidegloryL10n.current.auth_failedToSignOut`; no debe dejar la sesión en un estado inconsistente | 👤 Manual (requiere forzar el catch genérico de `AuthException`; verificar si hay un caso de test específico para el path de error de `signOut`, si no, es gap de cobertura) | |
| 8.3 | Tras logout, intenta volver atrás (back físico/gesto) desde Login | El guard de rutas mantiene a la app en Login (rutas públicas vs protegidas); no debe poder navegar a Home sin volver a autenticar | 👤 Manual (comportamiento de navegación de plataforma + guard de router; no cubierto por los widget tests de auth) | |

---

## 9. Persistencia de sesión

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 9.1 | Con sesión iniciada, cierra la app completamente y vuélvela a abrir | La app arranca directo en Home sin pedir login de nuevo (`checkAuthState` detecta usuario actual) | 🤖✅ Auto-PASS a nivel de cubit (`auth_cubit_test.dart` TC-auth-2 — `checkAuthState` emite `authenticated` cuando `currentUser` no es null); el arranque real de la app completa es manual/e2e | |
| 9.2 | Sin sesión (o tras logout), cierra y reabre la app | La app arranca en Login | 🤖✅ Auto-PASS a nivel de cubit (`auth_cubit_test.dart` TC-auth-3 — `checkAuthState` emite `unauthenticated` cuando `currentUser` es null) | |
| 9.3 | Con sesión iniciada por Google/Apple, reinicia el dispositivo completo | La sesión persiste igual que con email (Firebase Account Manager / Keychain) | 👤 Manual (requiere reinicio real de dispositivo; los tests Patrol documentan explícitamente este caso como una condición a manejar con `--uninstall`, pero no lo verifican de forma automática) | |

---

## 10. Casos de borde

### 10A. Red caída durante autenticación

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 10A.1 | Activa modo avión y intenta login con email/password | Error manejado (no crash), mensaje claro al usuario, se reporta `authFailed` a analytics con categoría de red | 👤 Manual (requiere control real de la conectividad del dispositivo/emulador) | |
| 10A.2 | Activa modo avión y intenta signup | Igual que 10A.1 pero para el flujo de creación de cuenta | 👤 Manual (mismo motivo) | |
| 10A.3 | Activa modo avión y intenta forgot password | Igual, mensaje de error sin crash | 👤 Manual (mismo motivo) | |

### 10B. Cancelación de social sign-in

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 10B.1 | Cancela el picker de Google a medio camino | Ya cubierto en 5.3 — sin error visible, estado `unauthenticated` | 🤖✅ Auto-PASS (`auth_cubit_test.dart` TC-auth-G1) | |
| 10B.2 | Cancela el flujo de Apple a medio camino | Ya cubierto en 6.4 — sin error visible, estado `unauthenticated` | 🤖✅ Auto-PASS (`auth_cubit_test.dart` TC-auth-A2) | |
| 10B.3 | Cambia el texto exacto de cancelación en `rest_client_functions.dart` sin actualizar el `if` de `AuthCubit` | Riesgo documentado: la comparación es un string hardcodeado; si el mensaje cambia, la cancelación silenciosa deja de funcionar y empieza a mostrarse como error real | 👤 Manual (es una trampa de mantenimiento documentada en `docs/features/authentication.md`, no un caso de test per se; revisar en code review cuando se toque ese archivo) | |

### 10C. Cuenta ya existente (signup con email duplicado)

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 10C.1 | Intenta signup con un email que ya tiene cuenta, password correcta | Reconciliación: internamente se resuelve como sign-in exitoso; navega a Home sin mostrar error de "cuenta ya existe" | 👤 Manual (requiere una cuenta real preexistente; no cubierto por los tests actuales de `AuthCubit`/`SignupView`, que mockean directamente `AuthService`) | |
| 10C.2 | Intenta signup con un email que ya tiene cuenta, password incorrecta | Mensaje genérico de credenciales inválidas (mismo que login fallido) — no debe revelar que el email ya existe | 👤 Manual (mismo motivo que 10C.1; gap de cobertura a nivel de `AuthService`, fuera del alcance de `authentication/` puro) | |

### 10D. Validación de password asimétrica entre pantallas

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 10D.1 | Compara las reglas de password en Login (min 6) vs Signup (min 8 + mayúscula + número) | La asimetría es intencional (usuarios legacy con passwords cortas pueden seguir iniciando sesión); no reportar como bug sin confirmar contra la doc | 🤖✅ Auto-PASS (cubierto indirectamente por `login_view_test.dart` TC-login-3 y `signup_view_test.dart` TC-signup-2, cada uno verificando su propia regla) | |

---

## 11. Verificaciones técnicas (equipo de desarrollo)

> Estas verificaciones requieren acceso al código, logs o consola de desarrollo. Ninguna se ha
> ejecutado todavía — quedan pendientes para cuando se corra `/qa-auto` o antes de un release.

| # | Verificación | Resultado esperado | ✅/❌ |
|---|-------------|--------------------|-------|
| 11.1 | Correr `flutter test test/features/authentication/` | Todos los tests del feature pasan en verde (incluye `auth_cubit_test.dart`, `login_view_test.dart`, `signup_view_test.dart`, `forgot_password_view_test.dart`, `login_social_button_test.dart`) | |
| 11.2 | Correr `flutter test` (suite completa) | Sin regresiones en otros features que dependen de `AuthCubit` (splash, profile, home shell) | |
| 11.3 | Correr `dart analyze` | Sin issues nuevos en `lib/features/authentication/` y `lib/core/services/auth_service.dart` | |
| 11.4 | Correr `patrol test -t integration_test/authentication_signup_patrol_test.dart --device-id <emulator>` | El signup e2e completa el flujo Login → Regístrate → Home; verificar limpieza manual periódica de cuentas `qa.signup.*@rideglory-test.com` | |
| 11.5 | Correr `patrol test -t integration_test/authentication_login_failure_patrol_test.dart --device-id <emulator> --uninstall` | El login con credenciales inválidas muestra el error genérico y no navega a Home; `--uninstall` es obligatorio para garantizar arranque limpio en Login | |
| 11.6 | Correr `patrol test -t integration_test/authentication_forgot_password_patrol_test.dart --device-id <emulator>` | El flujo completo de recuperación de contraseña llega a la pantalla de confirmación con el email correcto | |
| 11.7 | Revisar logs de consola en modo debug durante un login exitoso | Se ve el `idToken` logeado vía `dart:developer log()`; confirmar que **nunca** se logea en modo release (`kDebugMode` gate) | |
| 11.8 | Revisar Firebase Console → Authentication → Sign-in providers | Google y Apple están habilitados; para Apple, confirmar que el capability está también activo en Apple Developer Portal (`com.camiloagudelo.rideglory` y `*.dev`) | |
| 11.9 | Revisar `ios/Runner/Runner.entitlements` | Contiene `com.apple.developer.applesignin` (prerequisito de Apple sign-in en iOS) | |
| 11.10 | Si hay acceso a Firebase Analytics DebugView | Confirmar que `authFailed`, `authFirebaseOk`, `authSucceeded` y `authFirstHomeEntry` llegan con los parámetros documentados (`authMethod`, `authErrorCategory`, hash SHA-256 en `setUserId`, `login_method` como user property) | |

---

## Resultado final

| Estado | Criterio |
|--------|----------|
| ✅ Aprobado | Todos los casos de las secciones 1–3, 7 y 8 marcados como ✅ (flujos core: login exitoso/fallido, signup, forgot password, logout) |
| ⚠️ Aprobado con observaciones | Máximo 3 casos fallidos de baja severidad (secciones 4–6, 9 o 10), con ticket creado |
| ❌ Rechazado | Cualquier caso de las secciones 1, 2, 3, 7 u 8 marcado como ❌ |

**Revisado por:** ___________________
**Fecha:** ___________________
**Resultado:** ___________________
**Observaciones:** ___________________
