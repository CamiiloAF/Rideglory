# Fase 5 — Embudos de adquisición: autenticación y onboarding

> Plan: `analytics-crashlytics-cobertura-total` · ID de fase: **5** · dependsOn: **[1, 2]**
> Fecha (UTC): 2026-06-04T01:06:49Z
> Sesión: PLANEACIÓN — no se modifica código de la app. Este archivo es el detalle ejecutable de la fase.
> Insumos: `05-sintesis.md` (filas/criterios de la fase 5), `03-architect-review.md` (F5), `01-scan.md`.

---

## Objetivo

El analista mide **cuántos riders inician sesión/registro, por qué método y dónde abandonan**,
identificando cada paso del embudo de adquisición `splash → login/signup → home`, con un
**identificador de usuario anónimo** (uid de Firebase hasheado SHA-256 en cliente). Cero PII
(nunca email, nombre, ni uid en claro), cero cambios de backend, cero UI nueva.

---

## Alcance (entra / no entra)

### Entra
- Instrumentación de los flujos de autenticación: **inicio del flujo**, **método elegido**
  (email login, email signup, Google, Apple, forgot-password), **resultado**
  (éxito / fallo / abandono) y **primera entrada a home** tras autenticarse.
- `setUserId` con el **uid de Firebase hasheado SHA-256 en cliente**, disparado dentro de
  `AuthCubit` al confirmar sesión (excepción singleton/router ya existente).
- **User properties no-PII**: método de login (`login_method`) y `has_vehicle` (booleano
  agregado, sin identificar). Nunca email/nombre.
- Señal de **abandono**: el rider entra a una vista de auth, no completa el flujo y sale (o
  vuelve a splash/otra vista) sin éxito.
- Reutilización de la **taxonomía centralizada** (constantes de la fase 2) y la convención de
  límites GA4 (nombre ≤40, key ≤40, value string ≤100, params `Object`, sin `bool` → `0/1`).
- **Test unitario con mock** de `AnalyticsService` para el camino feliz de login.

### No entra
- Cualquier **cambio de UI / comportamiento** (es una fase cero-UI, sin regresión).
- Tocar **`GET /me`** o cualquier contrato de `rideglory-api` (todo es client-side).
- El **opt-out de privacidad** (fase 11) ni la **auditoría no-PII transversal** (fase 10).
- `screen_view` automático de las vistas de auth: lo cubre la fase 3 (NavigatorObserver); aquí
  solo se emiten **eventos de embudo de dominio**, no `screen_view`.
- Instrumentar el `splash` más allá de marcarlo como **inicio del recorrido de adquisición**
  (no se añade lógica de auth al splash).
- Las **constantes de taxonomía** las define la fase 2; aquí solo se **consumen** (si falta
  alguna constante de auth, se añade a la clase de taxonomía de la fase 2, nunca literales
  inline en el call site).

---

## Que se debe hacer (pasos concretos y ordenados)

1. **Confirmar prerequisitos (fases 1 y 2):**
   - La interfaz `AnalyticsService` (`lib/core/services/analytics/analytics_service.dart`) ya
     expone `setUserId` y `setUserProperty` (ampliada en fase 1; hoy solo tiene `logEvent`).
   - Existe la **no-op impl** de `AnalyticsService` para tests (fase 1) y el gating
     (`setEnabled(false)` + no-report en `kDebugMode`).
   - Existen las **constantes de taxonomía** de auth en `core/services/analytics/` (fase 2):
     nombres de evento (`auth_flow_started`, `auth_method_selected`, `auth_succeeded`,
     `auth_failed`, `auth_abandoned`, `auth_first_home_entry` — nombres finales los fija la
     taxonomía de la fase 2) y las **claves de params** (`auth_method`, `auth_step`,
     `auth_error_category`) y **user properties** (`login_method`, `has_vehicle`).

2. **Definir el contrato de eventos del embudo (en la taxonomía de la fase 2):**
   - `auth_flow_started` — param `auth_method` (`login` | `signup` | `forgot_password`); se emite
     al entrar a la vista correspondiente.
   - `auth_method_selected` — param `auth_method` (`email` | `google` | `apple`); se emite al
     pulsar el botón/submit del método concreto.
   - `auth_succeeded` — param `auth_method`; se emite cuando `AuthCubit` confirma sesión
     (`AuthState.authenticated`).
   - `auth_failed` — params `auth_method`, `auth_error_category` (categoría no-PII:
     `invalid_credentials` | `network` | `cancelled` | `unknown`); se emite en
     `AuthState.error`. **Nunca** el mensaje crudo ni el email.
   - `auth_abandoned` — param `auth_method`; se emite si el usuario sale de la vista de auth sin
     éxito (dispose/back sin `authenticated`).
   - `auth_first_home_entry` — sin params PII; primera entrada a home tras autenticar (marca el
     cierre del embudo de adquisición).

3. **Instrumentar `AuthCubit`** (`lib/features/authentication/application/auth_cubit.dart`):
   - Inyectar `AnalyticsService` por constructor (el cubit es `@singleton`; añadir el
     parámetro al constructor y regenerar DI con `build_runner`).
   - En cada método (`signInWithEmail`, `signUpWithEmail`, `signInWithGoogle`,
     `signInWithApple`, `sendPasswordResetEmail`): al confirmar éxito emitir `auth_succeeded`
     con su `auth_method`; en la rama de fallo emitir `auth_failed` con `auth_method` +
     `auth_error_category` derivada (mapear `failure.message`/tipo a categoría, **sin** pasar el
     texto crudo).
   - Al confirmar sesión (todas las ramas que emiten `AuthState.authenticated`): llamar
     `setUserId(<hash>)` con el **SHA-256 del uid de Firebase** calculado en cliente, y
     `setUserProperty('login_method', <metodo>)`. **Nunca** uid en claro ni email.
   - Calcular el hash con `crypto` (`sha256.convert(utf8.encode(uid)).toString()`) en un helper
     privado del cubit (o un helper puro en `core/`); el `crypto` package ya es transitivo de
     Firebase, confirmar disponibilidad en `pubspec.lock` y añadir a `pubspec.yaml` si hace falta.
   - `setUserProperty('has_vehicle', ...)`: si el dato no está disponible en el momento de auth
     sin tocar el backend, **diferir** esta property a un call site que ya tenga la lista de
     vehículos (p.ej. `VehicleCubit` tras `fetchMyVehicles`) — documentarlo, no inventar una
     llamada a `GET /me`/vehículos extra solo para esto.

4. **Instrumentar las vistas de auth (inicio de flujo + método + abandono):**
   - `LoginView` (`lib/features/authentication/login/presentation/login_view.dart`): `initState`
     → `auth_flow_started(login)`; al pulsar login email / Google / Apple →
     `auth_method_selected(<metodo>)`; en `dispose` sin éxito → `auth_abandoned(login)`.
   - `SignupView` (`lib/features/authentication/signup/presentation/signup_view.dart`):
     `auth_flow_started(signup)`, `auth_method_selected(...)`, `auth_abandoned(signup)`.
   - `ForgotPasswordView`
     (`lib/features/authentication/login/presentation/forgot_password_view.dart`):
     `auth_flow_started(forgot_password)`, `auth_method_selected(email)`,
     `auth_abandoned(forgot_password)`.
   - El acceso a `AnalyticsService` en las vistas es vía `getIt`/`context.read` según convención
     (las vistas no son cubits); **no** introducir literales de evento: usar las constantes de
     taxonomía. El cálculo de "salió sin éxito" se hace observando el `AuthState` (escuchar el
     `AuthCubit` para no marcar abandono cuando el flujo terminó en `authenticated`).

5. **Marcar la primera entrada a home (cierre del embudo):**
   - En el punto donde la app entra a home tras autenticar (router redirect a home / shell home),
     emitir `auth_first_home_entry` una sola vez por sesión de adquisición. Preferir hacerlo
     desde `AuthCubit` (transición a `authenticated`) o desde el entry point de home, evitando
     duplicar con el `screen_view` de la fase 3.

6. **Gating y no-regresión:**
   - Toda llamada pasa por la impl con gating (no-op en tests, `setEnabled(false)` y no-report en
     `kDebugMode` ya provistos por fase 1). Confirmar que ningún `emit`/flujo cambia de orden o
     semántica: la instrumentación es aditiva (no altera estados ni navegación).

7. **Tests:**
   - Test unitario de `AuthCubit` con **mock de `AnalyticsService`**: `signInWithEmail` exitoso
     dispara `setUserId(<hash esperado>)` **+** `auth_succeeded(email)` **+**
     `setUserProperty('login_method', 'email')`; verificar que el argumento de `setUserId` es el
     SHA-256 de un uid de prueba conocido y **nunca** el uid en claro ni el email.
   - Test de rama de fallo: `auth_failed` con `auth_error_category` correcta y sin texto crudo.

8. **Cierre técnico:** `dart run build_runner build --delete-conflicting-outputs` (por el cambio
   de constructor `@singleton`), `dart analyze` limpio, `flutter test` verde, verificación manual
   en **GA4 DebugView** del embudo completo.

---

## Archivos a crear/modificar (rutas reales, una línea de "que cambia")

| Ruta | Qué cambia |
|---|---|
| `lib/features/authentication/application/auth_cubit.dart` | Inyecta `AnalyticsService`; emite `auth_succeeded`/`auth_failed`; llama `setUserId(SHA-256 uid)` y `setUserProperty('login_method', …)` al autenticar; helper de hash. |
| `lib/features/authentication/login/presentation/login_view.dart` | `auth_flow_started(login)` en init, `auth_method_selected(email/google/apple)` al pulsar, `auth_abandoned(login)` al salir sin éxito. |
| `lib/features/authentication/signup/presentation/signup_view.dart` | `auth_flow_started(signup)`, `auth_method_selected(...)`, `auth_abandoned(signup)`. |
| `lib/features/authentication/login/presentation/forgot_password_view.dart` | `auth_flow_started(forgot_password)`, `auth_method_selected(email)`, `auth_abandoned(forgot_password)`. |
| `lib/features/splash/presentation/splash_screen.dart` | (Opcional/mínimo) marca el inicio del recorrido de adquisición; sin lógica de auth nueva. |
| `lib/core/services/analytics/<taxonomía auth>.dart` (fase 2) | Se **consumen/añaden** las constantes de eventos/params/user-properties de auth (definidas en fase 2; aquí solo se referencian, sin literales inline). |
| `lib/features/authentication/application/auth_cubit.dart` (DI generada) | Re-run de `build_runner` por el nuevo parámetro de constructor del `@singleton`. |
| `pubspec.yaml` | Añadir `crypto` a dependencias si no está como directo (para SHA-256). |
| `test/features/authentication/auth_cubit_test.dart` (nuevo) | Test con mock: login exitoso → `setUserId(hash)` + `auth_succeeded` + property; fallo → `auth_failed` categorizado. |

> Nota: el punto exacto de "primera entrada a home" (paso 5) puede resolverse dentro de
> `AuthCubit` (transición a `authenticated`) sin tocar el router; si se decide el entry point de
> home, será `lib/features/home/...` — fijarlo en implementación para no duplicar con fase 3.

---

## Contratos / API rideglory-api (o "ninguno")

**Ninguno.** Toda la analítica es **100% client-side**. El identificador anónimo se obtiene
**hasheando el uid de Firebase en cliente (SHA-256)**; **no** se modifica `GET /me` ni ningún
endpoint, ni se añaden DTOs (la analítica no serializa modelos de API).

---

## Cambios de datos / migraciones (o "ninguno")

**Ninguno.** Sin migraciones de BD ni persistencia local nueva en esta fase (el opt-out y su clave
en `UserStorageService` pertenecen a la fase 11). El `userId` de analítica lo gestiona el SDK de
Firebase Analytics en memoria/disco propio; no es estado de la app.

---

## Criterios de aceptación (numerados, observables, testeables)

1. **DebugView — embudo completo:** en GA4 DebugView, recorrer `splash → login → home` y
   `splash → signup → home` produce, en orden, los eventos de **inicio del flujo**
   (`auth_flow_started`), **método elegido** (`auth_method_selected`), **éxito**
   (`auth_succeeded`) y **primera entrada a home** (`auth_first_home_entry`), cada uno con su
   `auth_method`.
2. **DebugView — fallo y abandono:** un intento con credenciales inválidas emite `auth_failed`
   con `auth_error_category` (no el mensaje crudo); salir de una vista de auth sin completar emite
   `auth_abandoned` con su `auth_method`.
3. **setUserId hasheado:** al autenticar, `setUserId` recibe el **SHA-256 del uid** (cadena hex de
   64 chars); **nunca** se envía el uid en claro ni el email en ningún evento/property/userId.
4. **User properties no-PII:** se fija `login_method` (y `has_vehicle` cuando hay dato disponible
   sin tocar backend); **ningún** evento ni property contiene email, nombre, ni uid en claro.
5. **Sin cambios en `GET /me`** ni en ningún contrato de `rideglory-api` (revisión de diff:
   cero cambios de red/DTO; el id anónimo se calcula en cliente).
6. **Sin UI / sin regresión:** el diff no añade ni cambia pantallas, navegación ni estados de
   `AuthCubit`; la instrumentación es aditiva (los flujos de login/signup/forgot funcionan
   idénticos a antes).
7. **Taxonomía sin literales:** grep de los call sites de esta fase muestra **0** strings de
   evento inline; todos referencian constantes de la taxonomía (fase 2).
8. **Test unitario (mock):** `flutter test` verifica que `signInWithEmail` exitoso dispara
   `setUserId(<sha256(uid)>)` + `auth_succeeded(email)` + `setUserProperty('login_method','email')`,
   y que la rama de fallo dispara `auth_failed` categorizado; con la no-op impl + `setEnabled(false)`
   no se envía telemetría real. `dart analyze` limpio.

---

## Pruebas (unitarias/widget/integración)

- **Unitarias (obligatorias):**
  - `AuthCubit` con `MockAnalyticsService`: camino feliz de `signInWithEmail` →
    `setUserId(hash)` + `auth_succeeded` + `setUserProperty('login_method','email')`; asegurar
    que el hash coincide con `sha256(uidDePrueba)` y que **no** se pasa el uid/email en claro.
  - Rama de fallo de `signInWithEmail`/`signInWithGoogle`: `auth_failed` con
    `auth_error_category` esperada y sin texto crudo.
  - Verificar con `verifyNever`/equivalente que **no** se llama `setUserId` antes de `authenticated`.
- **Widget (recomendada, no bloqueante):**
  - `LoginView`: montar con `AuthCubit` mockeado y `MockAnalyticsService`; `initState` dispara
    `auth_flow_started(login)`; pulsar el botón de Google dispara `auth_method_selected(google)`;
    al desmontar sin éxito dispara `auth_abandoned(login)`.
- **Gating:** confirmar que la suite usa la **no-op impl** (fase 1) y que ningún test envía
  telemetría real (sin red, sin Firebase).
- **Manual / DebugView:** recorrer los 3 flujos (login email, Google, signup) y forgot-password en
  build debug con DebugView habilitado y confirmar el embudo y la ausencia de PII.

---

## Riesgos y mitigaciones

1. **uid en claro o email filtrados por error.** *Mitigación:* hash SHA-256 en cliente con helper
   único; test que asegura que `setUserId` recibe el hash (64 hex) y nunca el uid/email; auditoría
   transversal en fase 10.
2. **Mensaje de error con PII en `auth_failed`.** *Mitigación:* mapear `failure.message`/tipo a una
   **categoría enumerada** (`invalid_credentials`/`network`/`cancelled`/`unknown`); prohibido pasar
   el texto crudo; test de la rama de fallo.
3. **`AuthCubit` es `@singleton`: cambiar el constructor rompe DI.** *Mitigación:* añadir el
   parámetro `AnalyticsService` y correr `build_runner`; verificar que el grafo DI resuelve (la
   impl ya está registrada desde fase 1). Es la excepción singleton/router aceptada por las reglas.
4. **Doble conteo de "entrada a home"** entre `auth_first_home_entry` (esta fase) y el `screen_view`
   de home (fase 3). *Mitigación:* `auth_first_home_entry` es un evento de dominio distinto y se
   emite una sola vez por sesión de adquisición; no sustituye ni duplica el `screen_view`.
5. **Falsos "abandono"** si la vista se reconstruye o el flujo terminó en `authenticated`.
   *Mitigación:* marcar abandono solo en `dispose`/back cuando el último `AuthState` no es
   `authenticated`/`passwordResetEmailSent`; escuchar el cubit para distinguir éxito de salida.
6. **`has_vehicle` exigiría una llamada extra al backend.** *Mitigación:* diferir la property a un
   call site que ya tenga la lista de vehículos (no tocar `GET /me`/endpoints solo para esto);
   documentar la decisión.
7. **`crypto` no declarado como dependencia directa.** *Mitigación:* añadir a `pubspec.yaml`
   (es transitivo de Firebase pero no debe usarse implícito) y `flutter pub get`.

---

## Dependencias (fases prerequisito y por qué)

- **Fase 1 — Fundaciones, captura de crashes y regla de capa.** Provee la interfaz
  `AnalyticsService` ampliada con `setUserId`/`setUserProperty`/`setEnabled`, la **no-op impl** para
  tests, el gating (`setEnabled(false)` + no-report en `kDebugMode`) y la **regla de capa** (la
  abstracción es `core` Dart-puro, consumible por presentation/`AuthCubit`). Sin ella no hay API de
  identidad anónima ni gating.
- **Fase 2 — Taxonomía centralizada y límites GA4.** Provee las **constantes** de eventos/params y
  user-properties de auth y la convención de límites (≤40/≤40/≤100, `Object`, sin `bool`→`0/1`) que
  esta fase consume; sin ella se caería en literales inline (violación G1).

Esta fase **no** depende de la 3 (screen_view) ni de la 4 (no-fatales): emite eventos de embudo de
dominio propios; el `screen_view` de las vistas de auth lo cubre la fase 3 por separado.
