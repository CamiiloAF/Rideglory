# Fase 4 — Captura de errores y no-fatales de red

- Slug del plan: `analytics-crashlytics-cobertura-total`
- ID de fase: **4** | Título: Captura de errores y no-fatales de red
- dependsOn: **[1, 2]**
- Estado de captura: **Activa en release (solo categorías accionables) · Off en `kDebugMode` · No-op (mock) en tests**
- ¿UI nueva?: **No · sin UI / sin regresión de comportamiento**
- Fecha (UTC): 2026-06-04T01:06:55Z

---

## Objetivo

El equipo ve en Crashlytics los fallos **reales** (5xx, timeouts, `PlatformException`
inesperadas y errores genéricos no controlados) **categorizados**, con `stackTrace`, sin
ruido (no se reportan errores de negocio esperados ni credenciales) y **sin doble-conteo**
(la verdad de los errores de red vive en un único sitio; los cubits no re-reportan).

---

## Alcance (entra / no entra)

### Entra
- Enganchar el reporte de **no-fatales** (`CrashReporter.recordError`, `fatal: false`) en
  **`handlerExceptionHttp`** (`lib/core/http/rest_client_functions.dart`, L15-70), que es el
  **único** punto por el que pasan todas las llamadas HTTP de los 11 repositorios (vía
  `executeService`). El enganche se hace **por rama de `catch`**, no en `executeService`.
- **Política de severidad** (qué se reporta como no-fatal y qué NO), aplicada rama por rama.
- **Sanitización** de mensaje/URL/categoría antes de `recordError`: sin ids, sin body de
  respuesta, sin query params, sin PII; solo `host` + `path` con segmentos dinámicos
  enmascarados, código de estado y tipo de error.
- **Custom keys** no-PII por reporte (`error_category`, `http_status`, `dio_type`,
  `endpoint`), siempre dentro de los límites GA4/Crashlytics de la fase 2.
- **Matriz "categoría de error → único punto que reporta" (G5)** documentada en este archivo
  y respetada en código: la capa HTTP reporta; los cubits **no** re-reportan errores de red.
- Tests unitarios **por rama de `catch`** con **mock de `CrashReporter`** (verifican
  reporta / no-reporta según la matriz, y que el payload va sanitizado).

### No entra
- Reportar **crashes fatales / handlers globales** (`FlutterError.onError`,
  `PlatformDispatcher.onError`, `runZonedGuarded`) → eso es de la **fase 1**.
- La abstracción `CrashReporter`, su impl Crashlytics y su **no-op para tests** → se crean en
  la **fase 1**; aquí solo se consumen e inyectan.
- Las **constantes de taxonomía / convención de límites GA4 / sanitización canónica** →
  definidas en la **fase 2**; aquí se reutilizan (no se redefinen nombres mágicos).
- Cambios en `executeService` (solo mapea `ApiResult`→`Either`, no se toca).
- Eventos GA4 de error de negocio (4xx) — quedan fuera; a lo sumo se decidirán como
  embudo en las fases por dominio (5-9). Esta fase **no** emite eventos GA4, solo no-fatales.
- Cualquier cambio en `rideglory-api`.
- Reporte de errores propios de cubits **no** provenientes de HTTP (lógica local) → queda
  como nice-to-have para las fases por dominio; esta fase fija explícitamente que los cubits
  **no** reportan errores de red.

---

## Que se debe hacer (pasos concretos y ordenados)

1. **Confirmar prerequisitos de fase 1 y 2.** Verificar que existen e inyectables:
   `CrashReporter` (abstracción `core/` Dart-puro con `recordError({error, stackTrace, reason, fatal, information})` y `setCustomKey(key, value)`), su impl Crashlytics y la **no-op impl** para tests. Verificar que la fase 2 expone las constantes de categoría/keys y el helper de sanitización de endpoint (mapa ruta→nombre estable / enmascarado de segmentos dinámicos). Si la sanitización de URL no existe aún como helper reutilizable, crearla en `core/` como utilidad pura (sin Flutter).

2. **Inyectar `CrashReporter` en la capa HTTP.** `handlerExceptionHttp` es hoy una función top-level. Para no romper su firma usada por todos los repositorios, **obtener `CrashReporter` desde el contenedor DI** dentro de la función (lookup puntual de `getIt<CrashReporter>()`), o introducir un parámetro opcional inyectable con default desde DI. Decisión recomendada: **lookup desde DI dentro de la función** (cero cambios en los ~13 call sites de `executeService`). Documentar la decisión en el handoff de arquitectura.

3. **Gating.** Reportar **solo** cuando `!kDebugMode` (en debug, los `log()` existentes se mantienen; no se reporta a Crashlytics). En tests, la no-op impl + `setEnabled(false)` de la fase 1 garantizan que no se envía nada; el mock de los tests verifica las llamadas sin tocar la red.

4. **Implementar el reporte por rama, según la matriz (G5):**
   - **`on DioException` (L21):** decidir por `dioException.type` y `response?.statusCode`:
     - **Reporta no-fatal:** `connectionTimeout`, `sendTimeout`, `receiveTimeout`,
       `connectionError`, `badCertificate`, `badResponse` con `statusCode >= 500`, y
       `DioExceptionType.unknown`.
     - **NO reporta:** `badResponse` con `statusCode` 400/401/403/404/409 (negocio
       esperado), ni `DioExceptionType.cancel`.
     - Custom keys: `error_category=network`, `dio_type=<type>`, `http_status=<code|null>`,
       `endpoint=<host+path sanitizado>`. `reason` = string estable corto (p.ej.
       `network_timeout`, `network_5xx`, `network_connection`), **nunca** el mensaje ES de
       usuario ni el body.
   - **`on FirebaseAuthException` (L33):** **NO reporta** errores de credenciales/negocio
     (`wrong-password`, `user-not-found`, `invalid-credential`, `invalid-email`,
     `email-already-in-use`, `weak-password`, `too-many-requests`, `user-disabled`,
     `operation-not-allowed`, `credential-already-in-use`, `requires-recent-login`). Estos
     son esperados. **Sí** podría reportarse `network-request-failed` como no-fatal de red
     (categoría `network`); el resto, no. Documentar la lista exacta en código como conjunto
     constante.
   - **`on PlatformException` (L45):** **NO reporta** los códigos esperados de sign-in
     (`sign_in_cancelled`, `sign_in_failed`, `network_error`). **Sí reporta** no-fatal
     cualquier `PlatformException` **inesperada** (código fuera de la lista conocida),
     `error_category=platform_unexpected`.
   - **`on DomainException` (L57):** **NO reporta**. Ya viene categorizada y, si nació de una
     rama anterior, ya fue evaluada allí. Reportarla aquí sería **doble-conteo**.
   - **`catch` genérico (L59):** **Reporta no-fatal siempre** con el `stackTrace` real (si
     `error is Error`, usar `error.stackTrace`; si no, `StackTrace.current`).
     `error_category=unexpected`. Estos son los bugs reales no anticipados.

5. **Sanitizar todo payload antes de `recordError`:**
   - `endpoint`: solo `host + path`, con segmentos dinámicos (`:id`, UUIDs, números)
     enmascarados a `:id`; **sin** query string, **sin** fragment.
   - **Nunca** incluir `response.data` / body, headers, tokens, email, placa, VIN ni ids
     dinámicos.
   - `reason` y custom keys: strings cortos estables de un catálogo constante (fase 2),
     respetando límites (key ≤40, value string ≤100).

6. **Garantizar no doble-conteo en cubits (auditoría G5).** Grep de `recordError`/uso de
   `CrashReporter` en `lib/features/**`: confirmar que **ningún** cubit reporta errores que
   provienen de un `ResultState.error(DomainException)` originado en HTTP. Si se encuentra
   alguno, eliminarlo (la verdad vive en la capa HTTP). Dejar constancia en el handoff.

7. **Tests por rama** con mock de `CrashReporter` (ver sección Pruebas).

8. **`dart analyze` limpio** y, si la inyección requiere regenerar DI, correr
   `dart run build_runner build --delete-conflicting-outputs`.

---

## Archivos a crear/modificar (rutas reales, una línea de "que cambia")

| Ruta | Qué cambia |
|---|---|
| `lib/core/http/rest_client_functions.dart` | Engancha `CrashReporter.recordError(fatal:false)` por rama de `catch` en `handlerExceptionHttp` (L21/L33/L45/L57/L59) según la matriz de severidad; añade gating `!kDebugMode`; obtiene `CrashReporter` por lookup DI. **No** se toca `executeService`. |
| `lib/core/http/network_error_classifier.dart` *(nuevo, opcional)* | Función pura que clasifica `(DioException/FirebaseAuthException/PlatformException)` → `{shouldReport, category, reason, httpStatus}` para mantener `handlerExceptionHttp` legible y test-eable sin DI; sin Flutter, sin SDK. |
| `lib/core/services/analytics/` (helper sanitización de endpoint) | Si no fue creado en fase 2, añadir utilidad pura `sanitizeEndpoint(uri)` que devuelve `host+path` con segmentos dinámicos enmascarados; reutilizable por la fase 3. |
| `test/core/http/rest_client_functions_test.dart` *(nuevo o ampliado)* | Test por rama de `catch` con mock de `CrashReporter`: verifica reporta/no-reporta y payload sanitizado. |
| `test/core/http/network_error_classifier_test.dart` *(nuevo, si se extrae el clasificador)* | Tests unitarios puros de la matriz de severidad (sin mocks de red). |

> Nota: la abstracción `CrashReporter`, su impl Crashlytics, la no-op de tests y las
> constantes de taxonomía/sanitización canónica se crean en **fases 1 y 2**; esta fase las
> consume. Si el helper de sanitización de URL no existe aún, esta fase lo crea como utilidad
> pura en `core/`.

---

## Contratos / API rideglory-api

**Ninguno.** El reporte de no-fatales es 100% client-side. No se añade, cambia ni consume
ningún endpoint de `rideglory-api`. No hay DTOs nuevos (la analítica/crash no serializa
modelos de API).

---

## Cambios de datos / migraciones

**Ninguno.** No hay persistencia local nueva ni migraciones de BD. (La clave de opt-out en
`UserStorageService` es de la fase 11, no de esta.)

---

## Matriz de severidad (G5) — categoría → reporta / no reporta

| Rama `catch` (línea) | Sub-caso | ¿No-fatal? | `error_category` | Notas |
|---|---|---|---|---|
| `DioException` (L21) | timeout (connection/send/receive) | **Sí** | `network` | `reason=network_timeout` |
| `DioException` (L21) | `connectionError` / `badCertificate` | **Sí** | `network` | `reason=network_connection` |
| `DioException` (L21) | `badResponse` 5xx | **Sí** | `network` | `reason=network_5xx`, `http_status` |
| `DioException` (L21) | `badResponse` 400/401/403/404/409 | **No** | — | negocio esperado |
| `DioException` (L21) | `cancel` | **No** | — | esperado |
| `DioException` (L21) | `unknown` | **Sí** | `network` | bug potencial |
| `FirebaseAuthException` (L33) | credenciales/negocio (lista) | **No** | — | esperado |
| `FirebaseAuthException` (L33) | `network-request-failed` | **Sí** | `network` | fallo de red real |
| `PlatformException` (L45) | sign-in conocido (cancel/failed/network) | **No** | — | esperado |
| `PlatformException` (L45) | código **inesperado** | **Sí** | `platform_unexpected` | bug potencial |
| `DomainException` (L57) | cualquiera | **No** | — | **anti doble-conteo**: ya capturada/categorizada |
| genérico (L59) | cualquiera | **Sí** | `unexpected` | bug real, con `stackTrace` |
| **Cubits / presentación** | error de red propagado | **No** | — | la verdad vive en la capa HTTP; no re-reportar |

---

## Criterios de aceptación (numerados, observables, testeables)

1. Provocar un **timeout** o un **5xx** en una llamada real genera **un** no-fatal en la
   consola de Crashlytics con `stackTrace`, `error_category=network` y custom keys
   `http_status`/`dio_type`/`endpoint` presentes.
2. Un **400/401/403/404/409** y una `FirebaseAuthException` de **credenciales**
   (`wrong-password`, `invalid-credential`, etc.) **NO** generan no-fatal (verificable: cero
   nuevos no-fatales en Crashlytics tras provocarlos).
3. Una `DomainException` ya capturada en L57 **NO** se reporta (no hay doble-conteo entre la
   rama de origen y la rama `DomainException`).
4. El `catch` genérico (L59) genera **siempre** un no-fatal con `error_category=unexpected`.
5. Una `PlatformException` con **código inesperado** genera no-fatal
   (`platform_unexpected`); las de sign-in conocidas, no.
6. Los **mensajes/URLs reportados están sanitizados**: `endpoint` es `host+path` con
   segmentos dinámicos enmascarados (`:id`), **sin** query string, **sin** body de respuesta,
   **sin** ids/PII; `reason`/custom keys son strings cortos de catálogo, dentro de límites
   (key ≤40, value ≤100).
7. En **`kDebugMode`** no se envía ningún no-fatal (los `log()` existentes siguen
   funcionando); verificable en log y en mock.
8. **No doble-conteo en cubits:** grep confirma que ningún cubit de `lib/features/**`
   reporta a `CrashReporter` un error de red proveniente de un `DomainException`/HTTP.
9. **Test por rama de `catch`** con mock de `CrashReporter` pasa: cada rama verifica
   reporta/no-reporta según la matriz y que el payload va sanitizado.
10. `dart analyze` limpio y `flutter test` verde; `executeService` no fue modificado.

---

## Pruebas (unitarias/widget/integración)

**Unitarias (obligatorias) — `test/core/http/rest_client_functions_test.dart`:**
- Helper que ejecuta `handlerExceptionHttp` con un `function` que lanza, inyectando un
  **mock de `CrashReporter`** (vía DI override o el parámetro inyectable).
- **DioException — reporta:** timeout, `connectionError`, `badResponse` 500/503, `unknown` →
  `verify(recordError(fatal: false)).called(1)` con `error_category=network`.
- **DioException — NO reporta:** `badResponse` 400/401/403/404/409, `cancel` →
  `verifyNever(recordError(...))`.
- **FirebaseAuthException:** `wrong-password`/`invalid-credential` → `verifyNever`;
  `network-request-failed` → `called(1)` categoría `network`.
- **PlatformException:** `sign_in_cancelled`/`sign_in_failed`/`network_error` → `verifyNever`;
  código inesperado (p.ej. `unknown_xyz`) → `called(1)` categoría `platform_unexpected`.
- **DomainException:** lanzar un `DomainException` directo → `verifyNever` (anti
  doble-conteo).
- **Genérico:** lanzar un `Exception`/`Error` arbitrario → `called(1)` categoría `unexpected`
  con `stackTrace` no nulo.
- **Sanitización:** capturar los args del mock y asertar que `endpoint` no contiene query ni
  ids dinámicos, y que no se incluyó `response.data`.
- **Gating:** con la no-op impl + `setEnabled(false)` (fase 1) no se intenta enviar nada.

**Unitarias (si se extrae el clasificador) — `network_error_classifier_test.dart`:**
- Tabla de casos (type/status/code) → `{shouldReport, category}` esperado, sin mocks ni DI.

**Widget / integración:** **no aplica** (fase sin UI). La verificación e2e en
DebugView/Crashlytics consola se documenta como pasos manuales en el doc de QA de la fase 10.

---

## Riesgos y mitigaciones

1. **Enganche en el sitio equivocado.** Si va en `executeService` (que solo mapea
   `ApiResult`→`Either`) se pierden categoría y `stackTrace`. *Mitigación:* el enganche es
   **exclusivamente** en `handlerExceptionHttp`, por rama de `catch`; `executeService` no se
   toca (criterio 10).
2. **Doble-conteo.** Reportar en la rama `DomainException` o también en cubits duplica
   eventos. *Mitigación:* matriz G5 (rama `DomainException` no reporta; cubits no re-reportan)
   + auditoría grep (criterios 3 y 8).
3. **Ruido de 4xx/credenciales.** Inundar Crashlytics con errores de negocio esperados.
   *Mitigación:* política de severidad explícita; listas constantes de códigos esperados
   (criterios 2 y 5).
4. **PII / alta cardinalidad en el reporte.** URL con ids, body con datos del usuario.
   *Mitigación:* sanitización obligatoria de endpoint y prohibición de body/headers/PII
   (criterio 6); custom keys de catálogo con límites GA4 (fase 2).
5. **Inyección en función top-level.** `handlerExceptionHttp` no tiene `BuildContext` ni
   instancia; un mal acceso a DI rompería la capa HTTP. *Mitigación:* lookup puntual de
   `getIt<CrashReporter>()` con la no-op registrada para tests; degradación silenciosa si el
   reporter no está disponible (try/catch interno alrededor del `recordError`, nunca propaga).
6. **Gating insuficiente en debug/tests.** Enviar no-fatales en CI o desarrollo.
   *Mitigación:* `!kDebugMode` + no-op impl + `setEnabled(false)` reutilizados de la fase 1
   (criterio 7).
7. **Regresión de comportamiento.** Cambiar el flujo de `ApiResult.failure`/mensajes ES.
   *Mitigación:* el reporte es un **efecto lateral** antes del `return` existente; los
   `return ApiResult.failure(...)` y los mensajes de usuario no cambian (fase sin regresión).

---

## Dependencias (fases prerequisito y por qué)

- **Fase 1 — Fundaciones, captura de crashes y regla de capa.** Provee la abstracción
  `CrashReporter` (Dart-puro en `core/`), su impl Crashlytics, la **no-op impl** para tests,
  el registro por DI, el gating (`setEnabled(false)` + handlers no-report en `kDebugMode`) y
  la **regla de capa (G0)**. Sin ella no existe el destino del `recordError` ni el gating.
- **Fase 2 — Taxonomía, mapa de rutas y límites GA4.** Provee las **constantes** de
  categorías/keys/reasons (sin strings mágicos → cumple G1), la **convención de límites**
  (key ≤40, value ≤100, sin bool→0/1) y la base de **sanitización de endpoint** (mapa
  ruta→nombre estable / enmascarado de segmentos dinámicos) que esta fase reutiliza para no
  filtrar ids.

Esta fase **no** depende de la 3 (screen_view): comparten el helper de sanitización de
rutas, pero su producción puede coordinarse en la fase 2.
