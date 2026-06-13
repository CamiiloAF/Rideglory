# Verificación manual — Observability / Sentry (Fases 1-4)

> **Objetivo:** confirmar, con la app y el backend corriendo en **dev** bajo la
> ventana temporal de verificación (`SENTRY_DEV_VERIFY=true` / `kSentryDevVerify`),
> que las 4 fases funcionan end-to-end antes de retirar Crashlytics, restaurar la
> regla prod-only y abrir los PRs.
>
> **Recordatorio:** esta ventana **rompe a propósito** la regla de oro `dev → consola`.
> Es solo para verificar. Al terminar se revierte (ver §8).

---

## 0. Pre-requisitos (ya configurados)

- [ ] `config/dev.json` tiene `SENTRY_DSN` **y** `"SENTRY_DEV_VERIFY": true`.
- [ ] Los 6 `.env` del backend tienen `SENTRY_DSN`, `SENTRY_DEV_VERIFY=true`,
      `SENTRY_TRACES_SAMPLE_RATE=1.0` (api-gateway en `.env.dev`; el resto en `.env`).
- [ ] `pnpm install` corrido en los 6 MS (deps `@sentry/node` + common-lib presentes).
- [ ] **Dos proyectos Sentry** (misma organización): **`rideglory-flutter`** (app)
      y **`rideglory-backend`** (los 6 MS, distinguidos entre sí por el tag
      `service`: `api-gateway`, `users-ms`, …). Los errores de la app van al primero
      y los del backend al segundo; el trazado distribuido los correlaciona igual.

---

## 1. Arranque

### Backend (cada MS en su propia terminal, desde `rideglory-api/`)

```bash
# 1. Bases de datos (postgres de los MS con DB)
npm run docker:up

# 2. Microservicios (una terminal por MS)
cd api-gateway     && pnpm start:dev:local   # usa .env.dev
cd users-ms        && pnpm start:dev
cd events-ms       && pnpm start:dev
cd vehicles-ms     && pnpm start:dev
cd maintenances-ms && pnpm start:dev
cd notifications-ms && pnpm start:dev
```

- [ ] Los 6 arrancan sin error (ningún `MODULE_NOT_FOUND` de `@sentry/node` ni
      `@rideglory/common-lib`).
- [ ] Cada uno imprime logs con **pino-pretty** (coloreados, legibles), no JSON
      crudo (eso confirma `NODE_ENV` ≠ production).

### App Flutter

```bash
flutter run --flavor dev --dart-define-from-file=config/dev.json
```

- [ ] La app levanta normal en el flavor dev (`rideglory-dev`).

---

## 2. Fase 1 — traceId distribuido + logs estructurados sin PII

Hacé desde la app cualquier acción que pegue al backend (ej. abrir la lista de
eventos, abrir tu garaje, ver tu perfil).

**En la consola del api-gateway:**
- [ ] Cada request loguea una línea con un campo **`traceId`** (mixin de pino).
- [ ] El mismo `traceId` aparece en el **MS downstream** (ej. abrir eventos →
      `traceId` igual en gateway y en `events-ms`). → confirma la propagación
      del traceId por TCP (serializer/deserializer + CLS).

**Redacción de PII (crítico):** hacé un login o una acción con datos sensibles
(email, teléfono, placa, token). En **ninguna** consola debe aparecer el valor
real; debe verse `[REDACTED]`. Campos cubiertos por la denylist:
`authorization`, `password`, `email`, `phone`/`phoneNumber`, `soatNumber`,
`licensePlate`, `vin`, `idToken`, `token`, `firebaseToken`, `fcmToken`.

- [ ] Ningún email/teléfono/placa/token en texto plano en los logs.
- [ ] Donde debería ir un dato sensible aparece `[REDACTED]`.

---

## 3. Fase 2 — errores 5xx en Sentry, 4xx como logs (NO eventos de error)

### 3a. Forzar un 5xx
La forma más limpia sin tocar código: **detené un MS downstream** (ej. cerrá la
terminal de `events-ms`) y desde la app hacé una acción que dependa de él
(abrir/crear evento). El gateway no podrá completar la llamada TCP → responde 5xx.

- [ ] En consola del gateway: log de nivel `error` con el `traceId`.
- [ ] En **Sentry → Issues**: aparece un **evento de error** nuevo, con:
  - tag `service` = `api-gateway` (o el MS que lanzó).
  - el `traceId` visible (en tags o contexto) para correlacionar con los logs.
- [ ] Volvé a levantar `events-ms` para seguir.

### 3b. Forzar un 4xx (no debe consumir la cuota de errores)
Desde la app provocá un 4xx de negocio (ej. enviar un formulario inválido, o una
acción no autorizada → 400/401/403).

- [ ] En consola: queda logueado (pino) con su `traceId`.
- [ ] En **Sentry → Issues**: **NO** aparece como evento de error.
- [ ] En **Sentry → Logs** (structured logs, `enableLogs`): aparece como
      `warn` con contexto. → confirma que los 4xx dan contexto sin gastar la
      cuota de 5k errores/mes.

---

## 4. Fase 3 — Flutter: Sentry (reemplazo de Crashlytics) enlazado al backend

### 4a. Captura de fallo HTTP (sentry_dio)
Con la app logueada, provocá una respuesta de error del backend (reusá el 5xx de
§3a: MS caído + acción en la app).

- [ ] En **Sentry**: aparece un evento originado en la **app Flutter** por el
      request fallido (`captureFailedRequests`).
- [ ] **Traza distribuida:** ese evento de la app comparte `trace`/`traceId` con
      el evento/registro del backend del mismo request (headers `sentry-trace` /
      `baggage` propagados solo a la API de Rideglory). → se puede seguir un
      request app → gateway → MS en una sola traza.

### 4b. Captura de excepción no controlada (opcional, requiere editar 1 línea)
Agregá temporalmente en un `onPressed` cualquiera:
```dart
throw StateError('sentry dev-verify test');
```
- [ ] El crash aparece en **Sentry** como evento de la app (vía
      `runZonedGuarded` / hooks de `SentryFlutter`).
- [ ] **Quitá la línea** después de probar.

### 4c. PII scrub en la app
- [ ] En los eventos de Sentry de la app, ningún tag/breadcrumb expone PII
      (las keys de `kPiiDenylist` salen redactadas por `beforeSend`/`beforeBreadcrumb`).

### 4d. Gating dev-verify (negativo, recomendado)
- [ ] Poné `"SENTRY_DEV_VERIFY": false` en `config/dev.json`, reiniciá la app,
      repetí §4a → **NO** debe llegar nada nuevo a Sentry (en debug, `beforeSend`
      devuelve `null`). Volvé a `true` para seguir.

---

## 5. Trazado distribuido end-to-end (resumen del "happy path")

Una sola acción de la app que pegue al backend debe poder seguirse así:

- [ ] App Flutter (sentry_dio inicia la traza) →
- [ ] api-gateway (mismo `traceId` en logs, propagado por TCP) →
- [ ] MS downstream (mismo `traceId` en logs) →
- [ ] de vuelta, todo correlacionado en Sentry por la traza distribuida.

---

## 6. Fase 4 — Insights de producto (Firebase Analytics / GA4)

> Los eventos de GA4 se ven en **Firebase Console → Analytics → DebugView**.
> Activá debug primero:
> - **Android:** `adb shell setprop debug.firebase.analytics.app com.camiloagudelo.rideglory.dev`
> - **iOS:** correr con argumento de lanzamiento `-FIRDebugEnabled`.

### 6a. Drop-off por step del wizard de creación de evento
Abrí *crear evento* y navegá entre pasos.

- [ ] Al avanzar: `events_step_advanced` con `step_index` (1→3) y `step_name`
      (`config`/`route`/`review`).
- [ ] Al retroceder: `events_step_back` con `step_index` y `step_name`.
- [ ] Estando en el último paso, "siguiente" no dispara `events_step_advanced`
      (no hay step 4).

### 6b. Abandono e intención
- [ ] Cerrar el wizard **sin** publicar ni guardar borrador → `events_create_abandoned`
      con `form_mode` y `abandoned_at_step` (= el paso donde estabas). Una sola vez.
- [ ] Publicar con éxito y luego cerrar → `events_create_abandoned` **NO** se dispara.
- [ ] Al pulsar publicar → `events_publish_attempted` (antes del resultado
      `events_published`/`events_publish_failed`).
- [ ] En el wizard de **registro**: al enviar → `registration_submit_attempted`;
      cerrar sin enviar → `registration_abandoned` (una sola vez).

### 6c. Tap de navegación pura
- [ ] En el home vacío, tap en "Ver eventos" → `home_empty_events_cta`.

### 6d. screen_view + SentryNavigatorObserver
- [ ] Navegando entre pantallas, GA4 registra `screen_view` por transición (sin
      duplicados).
- [ ] En **Sentry**, los eventos de la app traen breadcrumbs de navegación
      (`SentryNavigatorObserver`, activo por estar en la ventana dev-verify).

### 6e. Sin PII / baja cardinalidad
- [ ] Ningún evento GA4 lleva email/placa/VIN/coordenadas/ids dinámicos; solo
      `form_mode`, `step_index`, `step_name`, `abandoned_at_step`.

---

## 7. Checklist final de éxito

- [ ] §2 traceId propagado app→gateway→MS y PII redactada en consola.
- [ ] §3 5xx → evento de error en Sentry; 4xx → log `warn`, NO evento de error.
- [ ] §4 crash + fallo HTTP de la app llegan a Sentry, sin PII, con gating correcto.
- [ ] §5 traza distribuida completa por `traceId`.
- [ ] §6 eventos de insights del wizard en GA4 DebugView, sin PII.

Si todo esto pasa → **Sentry está validado** y se puede proceder al cierre.

---

## 8. Cierre (DESPUÉS de validar — no ahora)

Recordatorio de lo pendiente una vez aprobada la validación (ver `PLAN.md` §Cierre):

1. Retirar Firebase Crashlytics de la app (`pubspec.yaml` + provider DI).
2. Restaurar **prod-only**:
   - Backend: quitar `SENTRY_DEV_VERIFY` de los 6 `.env`; gate queda
     `NODE_ENV === 'production' && !!dsn`.
   - Flutter: quitar `SENTRY_DEV_VERIFY` de `config/dev.json`; `beforeSend → null`
     en debug, init solo prod.
3. Verificar que en dev ya **no** se envía nada a Sentry (solo consola).
4. Crear PRs (1 por repo: 7 submódulos backend + Flutter).
