# Product Requirements Document — Rideglory

> Version: 1.0
> Updated: 2026-05-11
> Status: Draft — edit this file, then run `/solo-plan` to generate the iteration plan.

---

## 1. Product overview

**Rideglory** is a Flutter mobile application for motorcycle riding events and community coordination. It enables riders to discover events, register for rides, manage their garage of vehicles, track live ride positions, and connect with other riders.

The app targets Android and iOS. The backend is **rideglory-api** — a NestJS microservices system at `/Users/cami/Developer/Personal/rideglory-api` — that provides REST and WebSocket APIs authenticated via Firebase ID tokens.

---

## 2. Existing system

- **Base path:** `/Users/cami/Developer/Personal/Rideglory`
- **Flutter app:** `lib/` — Clean Architecture (domain/data/presentation per feature)
- **Backend:** `/Users/cami/Developer/Personal/rideglory-api` — NestJS microservices (gateway, tracking, events, users)
- **Notes:** Brownfield. Authentication, vehicle management, event registration, event listing, user profiles, and live tracking are partially or fully implemented. See `docs/handoffs/planning/00-existing-system-scan.md` after running `/solo-plan`.

---

## 3. Personas

**Rider** — primary user. Registers for events, tracks live rides, manages their vehicle garage, views other riders' profiles.

**Event Organizer** — creates and manages events, approves/rejects registrations, monitors live ride tracking during events.

---

## 4. Core features (what the app must do)

> The planning team will break these into iterations. Replace this list with more specific functional requirements as they are clarified.

### Authentication
- Email/password sign-in and registration
- Google sign-in
- Apple sign-in (iOS)
- Firebase Auth token refreshed automatically

### Vehicle Garage
- Add vehicles with make, model, year, VIN, license plate
- Set main vehicle
- Upload vehicle photo (Firebase Storage)
- Edit and delete vehicles

### Event Discovery
- Browse upcoming events (list and detail views)
- Filter events by type, date, location
- View event organizer and attendee list

### Event Registration
- Register for events
- Organizer approval / rejection workflow
- View my registrations (pending, approved, rejected)
- Registration detail with event info

### Live Event Tracking
- Real-time GPS location sharing during active events (WebSocket)
- Map view showing all riders' positions
- Battery-aware location updates
- Auto-reconnect on disconnect

### User Profiles
- View own profile and other riders' profiles
- Profile photo (Firebase Storage)
- Vehicle showcase

### Maintenance Log
- Log maintenance records per vehicle (date, type, mileage, notes)

### SOAT & Mandatory Insurance
- Per-vehicle insurance document management (SOAT in Colombia; extensible to other mandatory docs)
- Upload insurance document as PDF (stored in Firebase Storage)
- AI extraction of expiration date from uploaded PDF (via backend AI service)
- Visual expiration status per vehicle: valid / expiring soon (≤30 days) / expired
- Push reminder at 30 days and 7 days before expiration (future — see section 10)
- Manual override of extracted date in case of AI extraction error

### AI Features
- **Event cover image generation:** Given an event title, location, and type, generate a cover image via AI. UI entry point already implemented in the create-event form (button exists, no backend wired).
- **Event recommendations:** Surface personalized upcoming events to the rider based on their vehicle type, past registrations, and location. UI section already implemented on the home dashboard (card exists, no data source wired).

### Push Notifications
Integration via Firebase Cloud Messaging (FCM). Device token registered on login and refreshed automatically.

Notification triggers:

| Event | Recipient | Payload |
|-------|-----------|---------|
| Inscription approved | Rider who registered | Event name + deep link to registration detail |
| Inscription rejected | Rider who registered | Event name + reason (if provided) |
| Inscription pending (new request) | Event organizer | Rider name + event name + deep link to manage registrations |
| Event status → in progress | All approved registrants | Event name + meeting point + deep link to live tracking |
| Event status → cancelled | All registrants (any status) | Event name + deep link to event detail |
| SOS alert | All riders currently on the live tracking map for that event | Rider name + location — displayed as an overlay on the Map Live Tracking page only (not as a system notification banner) |

**SOS behavior:**
- Any rider on the live tracking map can trigger an SOS.
- The SOS is broadcast in real-time via WebSocket to all other riders in the same event session.
- On the Map Live Tracking page it renders as a persistent red alert overlay with the rider's name and last known position.
- It does NOT generate an FCM push notification — it is an in-app real-time signal only.

---

## 5. Technical constraints

- **Platform:** Flutter (Android + iOS). Minimum SDK: Android API 21, iOS 13.
- **State management:** BLoC/Cubit + `ResultState<T>` freezed union — no boolean flags for async state.
- **Architecture:** Clean Architecture (domain / data / presentation) per feature. One widget per file.
- **Backend:** rideglory-api NestJS microservices. All endpoints require Firebase ID token.
- **Auth:** Firebase Auth (email, Google, Apple). Token injected by `FirebaseAuthInterceptor`.
- **HTTP:** Dio + Retrofit (code-generated clients). Base URL from Firebase Remote Config (prod) or `.env` (dev).
- **Localization:** All UI strings in Spanish via `lib/l10n/app_es.arb` → `context.l10n.<key>`.
- **Design system:** Dark mode, orange primary `#f98c1f`, Space Grotesk font, 8px border radius.
- **No Playwright** — QA uses `flutter test`, `dart analyze`, widget tests.

---

## 6. Quality expectations

- `dart analyze` must pass with zero violations on every iteration.
- `flutter test` must pass on every iteration.
- No hardcoded strings in UI (always via ARB).
- No raw Material widgets where a shared equivalent exists (`AppButton`, `AppTextField`, etc.).
- No layer violations (domain must not import Flutter; presentation must not call HTTP directly).

### Test coverage requirements

**Unit tests** (`test/features/<feature>/domain/` and `test/features/<feature>/data/`):
- Every use case: happy path + at least one error path.
- Every Cubit: initial state, loading, data, empty, and error transitions.
- Repository implementations: mock the service layer, verify DTO → model mapping.

**Widget tests** (`test/features/<feature>/presentation/`):
- Every page: renders correctly in loading, data, empty, and error states.
- Key interactions: form submissions, button taps, navigation triggers.
- Use `MockBloc`/`MockCubit` to drive states; never hit real HTTP in widget tests.

**Integration tests** (`integration_test/`):
- At least one end-to-end happy-path flow per feature shipped in that iteration.
- Covers: auth token injection → API call → state update → UI render.
- Run with `flutter test integration_test/` against the dev backend.

> Existing features without tests get a test stub file created (empty `group` blocks) so coverage can be filled incrementally.

---

## 7. Security requirements

- Firebase ID tokens validated on every rideglory-api protected endpoint.
- No secrets committed to source (`.env.example` with placeholders only; real values in GitHub Actions secrets).
- Firebase config files (`google-services.json`, `GoogleService-Info.plist`) injected from CI secrets, never committed.

---

## 8. Success criteria

- Riders can discover, register for, and attend events end-to-end in the mobile app.
- Live tracking shows all riders on a map in real-time during an active event.
- The app builds and passes CI (`dart analyze` + `flutter test`) on every push to `iter-N`.

---

## 9. Historias de usuario — Rediseño de la app

### HU-DESIGN-01 · Migración y mejora de pantallas en Pencil

**Como** diseñador de Rideglory,
**quiero** tener todas las pantallas de la app organizadas y editables en un archivo `.pen` de Pencil,
**para que** Pencil sea la fuente de verdad del diseño y los cambios visuales fluyan desde ahí hacia el desarrollo Flutter.

#### Contexto
Las pantallas fueron prototipadas en Stitch y exportadas como imágenes (`stitch_rideglory/`). El archivo Pencil de referencia (`pencil-new.pen`) contiene las imágenes importadas y organizadas por flujo. A partir de ahora, todo rediseño debe hacerse en Pencil antes de implementarse en Flutter.

#### Flujos a cubrir (pantallas canónicas)

| # | Flujo | Pantallas |
|---|-------|-----------|
| 01 | Onboarding | Splash, Login, Registro |
| 02 | Home | Dashboard principal |
| 03 | Eventos | Explorar, Detalle evento, Crear evento |
| 04 | Inscripciones | Formulario, Mis inscripciones, Detalle solicitud, Gestión inscritos |
| 05 | Vehículos | Mi garaje, Nuevo vehículo, Detalle vehículo |
| 06 | Mantenimiento | Historial, Detalle, Nuevo registro |
| 07 | Rastreo en vivo | Telemetría y mapa de grupo, Vista líder, Mapa en vivo |
| 08 | Perfil | Mi perfil, Editar perfil, Perfil de piloto |

#### Criterios de aceptación

- [ ] Cada flujo tiene su sección etiquetada en el canvas de Pencil.
- [ ] La pantalla canónica (versión final) de cada flujo está importada como imagen de referencia en el frame correspondiente.
- [ ] El diseñador puede reemplazar la imagen de referencia por un diseño nativo en Pencil (con componentes reales, no imágenes planas) para cada pantalla.
- [ ] Los tokens de diseño (color `#f98c1f`, fuente Space Grotesk, dark mode `#0D0D0D`, border radius 8px) están definidos como variables en el archivo `.pen`.
- [ ] Antes de implementar cualquier cambio de UI en Flutter, el diseñador actualiza la pantalla en Pencil y el developer toma las especificaciones desde ahí.

#### Notas técnicas
- Archivo de diseño: `pencil-new.pen` (abrir en Pencil app).
- Imágenes de referencia en: `/Users/cami/Downloads/stitch_rideglory/`.
- Sistema de diseño: dark mode, primario `#f98c1f`, Space Grotesk, 8px border radius.
- No hay cambios de código Flutter en esta HU — es puramente diseño.

### HU-SOAT-01 · Gestión de SOAT y documentos obligatorios

**Como** piloto registrado en Rideglory,
**quiero** subir mi SOAT y otros documentos obligatorios por vehículo y recibir alertas antes de que venzan,
**para** no quedarme con el seguro vencido y poder participar en rodadas sin inconvenientes legales.

#### Flujo
1. En el detalle del vehículo, sección "Documentos obligatorios".
2. El rider sube el PDF del SOAT desde su dispositivo.
3. El backend envía el PDF al servicio de IA para extraer la fecha de vencimiento.
4. La fecha extraída se muestra al rider para confirmación o corrección manual.
5. El vehículo muestra un indicador de estado: `Vigente` / `Por vencer (≤30 días)` / `Vencido`.

#### Criterios de aceptación
- [ ] El rider puede subir un PDF de SOAT desde el detalle del vehículo.
- [ ] La IA extrae la fecha de vencimiento y la muestra para confirmación (editable).
- [ ] El estado del documento se refleja visualmente en el listado del garaje y en el detalle del vehículo.
- [ ] Si la extracción de IA falla, el rider puede ingresar la fecha manualmente.
- [ ] El PDF se almacena en Firebase Storage asociado al vehículo del usuario.
- [ ] `dart analyze` y `flutter test` pasan sin violaciones.

#### Notas técnicas
- Backend: nuevo endpoint en `rideglory-api` para recibir el PDF y devolver la fecha extraída.
- Servicio IA: Claude API (modelo Haiku para extracción de datos de PDF — bajo costo).
- DTO: `InsuranceDocumentDto` con `vehicleId`, `storageUrl`, `expirationDate`, `docType` (`soat` | `tecno` | `other`).
- Firebase Storage path: `insurance/{userId}/{vehicleId}/{docType}.pdf`.

---

### HU-AI-01 · Generación de imagen de portada para eventos

**Como** organizador de un evento,
**quiero** que la IA genere automáticamente una imagen de portada a partir del título, tipo y lugar del evento,
**para** que mis eventos tengan una presentación visual atractiva sin necesidad de diseño manual.

#### Contexto
El botón de generación de imagen ya existe en el formulario de creación de eventos (UI implementada). Esta HU conecta ese botón con el backend de IA.

#### Criterios de aceptación
- [ ] Al tocar "Generar portada con IA" en el formulario de evento, se envía título + tipo + ubicación al backend.
- [ ] El backend genera o busca una imagen adecuada y retorna una URL de imagen.
- [ ] La imagen generada se previsualiza en el formulario antes de publicar.
- [ ] El organizador puede regenerar o subir una imagen propia en su lugar.
- [ ] La imagen se guarda en Firebase Storage y se asocia al evento al publicar.
- [ ] `dart analyze` y `flutter test` pasan sin violaciones.

#### Notas técnicas
- Backend: endpoint `POST /events/generate-cover` en `rideglory-api`.
- Servicio IA: Claude API con capacidades de visión o integración con un servicio de imágenes (definir en arquitectura).
- No bloquea el flujo de creación del evento — imagen es opcional.

---

### HU-AI-02 · Recomendaciones personalizadas de eventos

**Como** piloto,
**quiero** ver eventos recomendados para mí en el dashboard basados en mis rodadas previas, vehículo y ubicación,
**para** descubrir eventos relevantes sin tener que buscar manualmente.

#### Contexto
La sección de recomendaciones ya existe en el dashboard principal (UI implementada). Esta HU conecta esa sección con un endpoint de recomendaciones.

#### Criterios de aceptación
- [ ] El dashboard muestra hasta 5 eventos recomendados en la sección existente.
- [ ] Las recomendaciones se basan en: tipo de vehículo del rider, historial de inscripciones, y proximidad geográfica.
- [ ] Si no hay datos suficientes (rider nuevo), se muestran los eventos más próximos por fecha.
- [ ] Las recomendaciones se cachean localmente y se refrescan al abrir la app.
- [ ] `dart analyze` y `flutter test` pasan sin violaciones.

#### Notas técnicas
- Backend: endpoint `GET /events/recommendations` en `rideglory-api`, autenticado con Firebase ID token.
- Lógica de recomendación: scoring simple en el backend (no requiere modelo ML externo para v1).
- Opcional v2: usar Claude API para generar explicación de por qué se recomienda cada evento ("Rodada de aventura cerca de ti con motos similares a la tuya").

---

### HU-PUSH-01 · Notificaciones push y alerta SOS en tiempo real

**Como** piloto o organizador,
**quiero** recibir notificaciones push cuando cambia el estado de mis inscripciones o de mis eventos, y ver alertas SOS en tiempo real cuando un piloto en la misma rodada activa una emergencia,
**para** estar siempre informado sin tener que abrir la app constantemente y poder reaccionar rápido ante emergencias.

#### Triggers de notificación FCM

| Trigger | Destinatario | Acción al tocar |
|---------|-------------|-----------------|
| Inscripción aprobada | Piloto inscrito | Abrir detalle de inscripción (deep link) |
| Inscripción rechazada | Piloto inscrito | Abrir detalle de inscripción (deep link) |
| Nueva solicitud de inscripción | Organizador del evento | Abrir gestión de inscritos (deep link) |
| Evento cambia a "en curso" | Todos los inscritos aprobados | Abrir mapa de rastreo en vivo (deep link) |
| Evento cancelado | Todos los inscritos (cualquier estado) | Abrir detalle del evento (deep link) |

#### SOS en tiempo real (WebSocket — solo en-app)

- Cualquier piloto en el mapa de rastreo puede activar SOS con un botón prominente.
- El SOS se transmite por WebSocket al resto de pilotos en la misma sesión del evento.
- En la página **Map Live Tracking**, aparece como un overlay rojo persistente con nombre del piloto y su última posición conocida.
- El overlay permanece visible hasta que el piloto que lo activó lo cancele o el organizador lo desestime.
- **No genera notificación FCM** — es una señal in-app en tiempo real únicamente.

#### Criterios de aceptación
- [ ] El token FCM se registra en `rideglory-api` al iniciar sesión y se actualiza si cambia.
- [ ] El backend envía FCM al cambiar el estado de una inscripción (aprobada / rechazada).
- [ ] El backend envía FCM al organizador cuando llega una nueva solicitud de inscripción.
- [ ] El backend envía FCM a todos los inscritos aprobados cuando el evento pasa a "en curso".
- [ ] El backend envía FCM a todos los inscritos cuando el evento se cancela.
- [ ] Tocar cualquier notificación abre la pantalla correcta mediante deep link (`go_router`).
- [ ] El botón SOS está visible en la página de rastreo en vivo.
- [ ] Al activar SOS, todos los pilotos en la misma sesión ven el overlay rojo en tiempo real (< 2 s).
- [ ] El overlay SOS muestra nombre del piloto y pin en el mapa.
- [ ] El overlay se descarta al cancelar el SOS o cuando el organizador lo desestime.
- [ ] `dart analyze` y `flutter test` pasan sin violaciones.

#### Notas técnicas
- FCM: `firebase_messaging` en Flutter. Manejar foreground, background y terminated app states.
- Token storage: guardar en `rideglory-api` tabla `device_tokens` asociada al `userId`.
- Deep links: usar `go_router` con rutas nombradas; el payload FCM incluye `route` + `params`.
- SOS: nuevo tipo de mensaje WebSocket `{ type: "sos", riderId, lat, lng, eventId }` — el servidor hace broadcast a todos los clientes del mismo `eventId`.
- Backend: nuevo módulo `notifications` en `rideglory-api`; FCM enviado via Firebase Admin SDK.
- No mostrar notificación FCM para SOS — el WebSocket es suficiente para quienes ya están en el mapa.

---

### HU-TEST-01 · Cobertura de pruebas base

**Como** equipo de desarrollo,
**quiero** tener unit tests, widget tests e integration tests para todas las features implementadas,
**para** detectar regresiones rápidamente y garantizar la calidad en cada iteración.

#### Alcance
Aplica a todas las features ya implementadas: authentication, vehicles, events, event\_registration, maintenance, tracking, users, profile.

#### Criterios de aceptación
- [ ] Cada use case tiene al menos un test de happy path y uno de error path.
- [ ] Cada Cubit tiene tests para los estados: `initial`, `loading`, `data`, `empty`, `error`.
- [ ] Cada página principal tiene widget tests para los estados de UI (loading skeleton, data render, error banner, empty state).
- [ ] Al menos un integration test end-to-end por feature (happy path completo).
- [ ] `flutter test` pasa en 100% de los tests en CI.
- [ ] `dart analyze` pasa sin violaciones.
- [ ] Los test files existentes vacíos tienen al menos un `group` definido (no archivos completamente en blanco).

#### Notas técnicas
- Mocks: usar `mocktail` o `mockito` para aislar capas.
- No hacer HTTP real en unit/widget tests — solo en integration tests contra el backend de dev.
- Estructura: `test/features/<feature>/domain/`, `test/features/<feature>/data/`, `test/features/<feature>/presentation/`.
- Integration tests en `integration_test/` con device/emulator disponible en CI.

---

## 10. Out of scope

- Web version of the app
- Admin dashboard web UI
- Payment processing
- Social feed / posts

---

## How to use this PRD

1. Edit sections 4–8 with specific acceptance criteria as features are clarified.
2. Run `/solo-plan` — the PO agent will break this into iterations.
3. Review `docs/PLAN.md` and the dashboard (`python3 server.py`).
4. Run `/solo-approve` when the plan is ready.
5. Run `/iter 1` to start building.
