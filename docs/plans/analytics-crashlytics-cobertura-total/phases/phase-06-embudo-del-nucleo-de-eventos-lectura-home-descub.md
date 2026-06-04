# Fase 6 — Embudo del núcleo de eventos — LECTURA (home + descubrir/ver)

- Slug del plan: `analytics-crashlytics-cobertura-total`
- ID de fase: **6** (esquema 1..11 de `05-sintesis.md`); legacy F6 (mitad de lectura).
- Fecha (UTC): 2026-06-04T01:17:25Z
- Depende de: **1, 2, 3**
- ¿UI nueva?: **No**. Estado de captura: activa en release / off en `kDebugMode` / no-op en tests (heredado de fase 1).
- Sesión: PLANEACIÓN — este archivo NO modifica código; describe el trabajo de la fase.

---

## Objetivo

El analista ve en GA4 cómo los riders **descubren y consultan rodadas**: entrada a home,
listado de eventos y apertura del detalle (incluyendo borradores abiertos en solo-lectura).
Toda la instrumentación es de **lectura** del núcleo de eventos; la escritura/aprobación es
la fase 7. Cero PII, cero ids dinámicos como valor de param, sin cambios de UI ni de
comportamiento.

---

## Alcance (entra / no entra)

### Entra
- **Home**: una señal de "entrada a home con contenido cargado" (carga exitosa del dashboard,
  con conteos agregados de secciones — número de eventos próximos, si hay vehículo principal —
  nunca ids).
- **Events — lectura del listado**: una señal `events_list_viewed` **por carga** (carga inicial
  y recarga explícita por cambio de filtros), con conteo entero de resultados y banderas
  agregadas de contexto (lista general vs "mis eventos"). **No** por keystroke de búsqueda ni
  por re-emisión local (`addEvent`/`updateEvent`/`removeEvent`).
- **Events — lectura del detalle**: una señal `event_detail_viewed` **por apertura del detalle**
  (una sola vez por apertura), con params no-PII (tipo de evento, estado, si el usuario es
  owner, si es solo-lectura). Cubre las dos rutas de detalle: `eventDetail` (push con `EventModel`
  ya cargado, incluido el caso de borrador desde `my_drafts_view.dart`) y `eventDetailById`
  (deep-link por id que primero carga vía `EventDetailCubit.loadEvent`).

### No entra
- Crear / publicar / guardar borrador, eliminar evento, gestión de asistentes / aprobación
  (todo eso es **fase 7**).
- Registro/inscripción a eventos, "mis registros" (**fase 7**).
- Tracking en vivo / SOS (**fase 8**).
- `screen_view` de las rutas de home/list/detail: ya lo emite el `NavigatorObserver` de la
  **fase 3** (riesgo de doble conteo, ver Riesgo #1). Esta fase añade **eventos de dominio**
  (`events_list_viewed`, `event_detail_viewed`, `home_viewed`), NO `screen_view`.
- Cualquier id de evento, nombre de evento, ciudad libre o texto de búsqueda como **valor** de
  un parámetro.

---

## Qué se debe hacer (pasos concretos y ordenados)

### Paso 1 — Reusar fundaciones y taxonomía (sin reabrir fases 1/2/3)
- Consumir la abstracción `AnalyticsService` ampliada de la fase 1 (Dart-puro en `core/`,
  inyectada por DI). No instanciar el SDK Firebase en ningún archivo de `features/events/` ni
  `features/home/`.
- Usar **constantes de la taxonomía** (fase 2) para nombres de evento y claves de param; cero
  literales en los call sites (regla G1: `grep "logEvent(.*'"` = 0). Si las constantes de este
  dominio aún no existen en la clase de taxonomía, **añadirlas allí** (en
  `core/services/analytics/`), no localmente en el feature.
- Respetar límites GA4 (fase 2): nombre ≤40, key ≤40, value string ≤100, params `Object`, sin
  `bool` crudo (mapear a `0/1` u otro `Object` permitido, como ya documenta el use case de soat).

### Paso 2 — Definir las constantes del dominio de lectura (en la taxonomía de fase 2)
Eventos (nombres finales sujetos a la convención de la fase 2; propuestos):
- `home_viewed` — params: `upcoming_events_count` (int), `has_main_vehicle` (0/1).
- `events_list_viewed` — params: `result_count` (int), `list_scope` (`'all'` | `'mine'`).
- `event_detail_viewed` — params: `event_type` (string corto/enum), `event_state` (string/enum),
  `is_owner` (0/1), `is_read_only` (0/1), `source` (`'list'` | `'deep_link'` | `'draft'`).
  **Sin** `event_id`, `event_name`, `city`, `owner_id`.

### Paso 3 — Instrumentar home (`home_viewed`)
- Punto de emisión: dentro de `HomeCubit.loadHomeData()`, en el `fold` de **éxito** (rama
  `HomeLoaded`), **una sola vez por carga**. No emitir en `loading`/`error`.
- Params: `upcoming_events_count = data.upcomingEvents.length`,
  `has_main_vehicle = data.mainVehicle != null ? 1 : 0`. Inyectar `AnalyticsService` en el
  constructor de `HomeCubit` (`@injectable`, ya lo es).

### Paso 4 — Instrumentar el listado (`events_list_viewed`) — punto de emisión correcto
**Problema a evitar:** `_applyFiltersAndEmit()` (L158) emite un `ResultState` en **cada** cambio
de búsqueda (`updateSearchQuery` L107 → cada keystroke) y en cada mutación local
(`addEvent` L123, `updateEvent` L129, `removeEvent` L138). Emitir `events_list_viewed` dentro de
`_applyFiltersAndEmit()` dispararía el evento en cada tecla y cada mutación → ruido y conteo
inflado.

**Solución:** emitir `events_list_viewed` **exclusivamente dentro de `fetchEvents()`** (L91),
en el `fold` de **datos** (justo después de `_allEvents = events; _applyFiltersAndEmit();`),
**no** dentro de `_applyFiltersAndEmit()`. Así:
- Carga inicial (`..fetchEvents()` en `EventsPage` L37 / `MyDraftsPage`) → 1 evento.
- Cambio de filtros (`updateFilters` L112 / `clearFilters` L117 llaman `fetchEvents()`) → 1
  evento por recarga (recarga real contra backend; aceptable como "vista de lista con filtro
  aplicado").
- Búsqueda por texto (`updateSearchQuery` → solo `_applyFiltersAndEmit`) → **0 eventos**.
- `addEvent`/`updateEvent`/`removeEvent` (solo `_applyFiltersAndEmit`) → **0 eventos**.

Params: `result_count` = longitud de la lista filtrada **resultante** (el entero que se acaba
de emitir como `ResultState.data`); `list_scope` = `'mine'` si el cubit se creó con el
constructor `EventsCubit.myEvents`, si no `'all'`. Para conocer el scope sin acoplarse al use
case, añadir un flag privado `final bool _isMyEvents` fijado en cada constructor (named vs
default) y usarlo en el param. Inyectar `AnalyticsService` por **ambos** constructores de
`EventsCubit`.

### Paso 5 — Instrumentar el detalle (`event_detail_viewed`) — una sola emisión por apertura, sin doble conteo
Hay **dos rutas** que terminan mostrando `EventDetailView`, y el `EventDetailCubit` se crea en
**dos sitios distintos**. La regla maestra es: **`event_detail_viewed` se emite exactamente una
vez por apertura, y SOLO en uno de los dos caminos**, nunca en ambos.

#### 5a — Camino deep-link (`eventDetailById` → `EventDetailByIdPage`)
- Aquí el `EventDetailCubit` se crea en el `create:` del `BlocProvider` (L53-64 de
  `event_detail_by_id_page.dart`) y llama `..loadEvent(widget.eventId)`.
- **Emitir `event_detail_viewed` dentro de `EventDetailCubit.loadEvent`** (L129), en el `fold`
  de **datos** (L135-136), donde ya hay un `EventModel` real con `eventType`, `state`, `ownerId`.
  Esta es la fuente canónica del evento para el camino by-id, y es testeable con mock del cubit.
- **Determinación de `source`/`is_read_only` en esta página (sin ambigüedad):**
  `EventDetailByIdPage` solo recibe `widget.eventId` y **no** sabe si el id proviene de un
  borrador. La ruta `eventDetailById` es **siempre apertura directa por id** (deep-link), así que
  su `source` es fijo `'deep_link'` y `is_read_only = 0`. El caso "borrador en solo-lectura"
  **no** se maneja aquí; vive exclusivamente en el camino de `EventDetailPage` (ver 5b). Esto
  deja los dos call sites con argumentos deterministas.

#### 5b — Camino con `EventModel` precargado (`eventDetail` → `EventDetailPage`)
- Es el push directo desde el listado (`events_data_view`/`event_card`) y desde **borradores**
  (`my_drafts_view.dart` L79: `context.pushNamed(AppRoutes.eventDetail, extra: event)`).
- En este camino el `EventModel` ya está en `params.event`; el `EventDetailCubit` se crea en el
  `create:` del `BlocProvider` (L29-43) **solo si** `!params.isFromEventDetailByIdPage`.
- **Emitir `event_detail_viewed` SOLO cuando `params.isFromEventDetailByIdPage == false`.**
  Cuando `isFromEventDetailByIdPage == true`, `EventDetailPage` es renderizada **por dentro** de
  `EventDetailByIdPage` (L83-91), donde el evento **ya lo emitió** `loadEvent` (5a); volver a
  emitirlo aquí produciría un **doble `event_detail_viewed`**. Esta condición es obligatoria
  (ver Riesgo #2).
- **Mecanismo one-shot (obligatorio):** `EventDetailPage` es `StatelessWidget` y `build()` puede
  correr múltiples veces (rebuilds del `BlocListener`); por eso NO se emite en `build()`. Emitir
  el log **dentro del `create:` del `BlocProvider` que ya existe en L29** (rama
  `if (!params.isFromEventDetailByIdPage)`), que corre **una sola vez** por construcción del
  subárbol — junto con la instanciación del `EventDetailCubit`:
  ```dart
  if (!params.isFromEventDetailByIdPage)
    BlocProvider(
      create: (context) {
        context.read<AnalyticsService>().logEvent(
          AnalyticsEvents.eventDetailViewed,
          { /* params no-PII derivados de params.event */ },
        );
        return EventDetailCubit(...)
          ..loadMyRegistration(params.event.id!)
          ..loadAttendees(params.event.id!);
      },
    ),
  ```
  Alternativa equivalente si se prefiere no leer `AnalyticsService` desde `create:`: convertir
  `EventDetailPage` a `StatefulWidget` y emitir en `initState()` con el guard de
  `isFromEventDetailByIdPage`. Cualquiera de las dos cumple "una vez por apertura"; **no usar
  `build()` sin flag**, porque incumpliría el criterio.
- Params en este camino (todos desde `params.event`, que sí está completo):
  - `event_type`, `event_state` desde el modelo;
  - `is_owner` comparando `params.event.ownerId` con el uid actual (de `AuthCubit`); si no hay
    sesión, `0`. Nunca loguear el uid ni el `ownerId`, solo la bandera;
  - `source = 'draft'` si `params.event.state == EventState.draft`, si no `'list'`;
  - `is_read_only = (params.event.state == EventState.draft) ? 1 : 0`.

> Resultado neto: para una apertura by-id se emite **1** evento (en `loadEvent`); para una
> apertura desde lista o borrador se emite **1** evento (en el `create:` del provider de
> `EventDetailPage`). Nunca 2.

### Paso 6 — Verificación local (DebugView) + tests
- DebugView (debug temporalmente habilitado o staging): navegar home → lista → detalle (desde
  lista) y un deep-link by-id, y revisar que aparezcan `home_viewed`, `events_list_viewed` (una
  vez), `event_detail_viewed` (una vez por apertura) con nombres de la taxonomía y **sin** ids.
- Tests unitarios de cubits con mock de `AnalyticsService` (no-op de fase 1 / `mocktail`);
  `bloc_test` ya disponible.

### Paso 7 — Lint y no-regresión
- `dart analyze` limpio; `dart format`.
- Ningún cambio de UI ni de flujo de navegación; los call sites solo añaden una llamada
  `logEvent` en puntos de éxito.

---

## Archivos a crear/modificar (rutas reales, una línea de "qué cambia")

| Archivo | Qué cambia |
|---|---|
| `lib/core/services/analytics/<taxonomy>.dart` (clase de constantes de fase 2) | Añadir constantes `homeViewed`, `eventsListViewed`, `eventDetailViewed` y sus claves de param (no crear archivo nuevo si la clase ya existe). |
| `lib/features/home/presentation/cubit/home_cubit.dart` | Inyectar `AnalyticsService`; emitir `home_viewed` en el `fold` de éxito de `loadHomeData()` con `upcoming_events_count` + `has_main_vehicle`. |
| `lib/features/events/presentation/list/events_cubit.dart` | Inyectar `AnalyticsService` por **ambos** constructores; emitir `events_list_viewed` **dentro de `fetchEvents()`** (fold de datos), con `result_count` + `list_scope`; añadir flag `_isMyEvents`. **No** emitir en `_applyFiltersAndEmit()`. |
| `lib/features/events/presentation/list/events_page.dart` | Sin cambio de UI; pasar `getIt<AnalyticsService>()` a los constructores de `EventsCubit` (ambas ramas). |
| `lib/features/events/presentation/drafts/my_drafts_page.dart` | Si construye el `EventsCubit` aquí, pasar `AnalyticsService`; el push a `eventDetail` ya pasa `EventModel` → el detalle resuelve `source='draft'`/`is_read_only=1` por `state`. (Sin cambio si el cubit se inyecta arriba.) |
| `lib/features/events/presentation/detail/cubit/event_detail_cubit.dart` | Inyectar `AnalyticsService`; emitir `event_detail_viewed` en el `fold` de datos de `loadEvent` con `source='deep_link'`, `is_read_only=0` (canónico para el camino by-id). |
| `lib/features/events/presentation/detail/event_detail_page.dart` | Emitir `event_detail_viewed` **una sola vez** y **solo si `params.isFromEventDetailByIdPage == false`**, dentro del `create:` del `BlocProvider` existente (L29) — no en `build()`; calcular `source` (`'draft'`/`'list'`), `is_read_only`, `is_owner`, `event_type`, `event_state` desde `params.event`. |
| `lib/features/events/presentation/detail/event_detail_by_id_page.dart` | Pasar `getIt<AnalyticsService>()` al `EventDetailCubit` en el `create:` (L53). No emite directamente: el evento lo emite `loadEvent`. |
| `test/features/events/presentation/detail/event_detail_cubit_test.dart` | Test: `loadEvent` exitoso dispara 1 `event_detail_viewed` (mock), sin ids en params. |
| `test/features/events/presentation/list/events_cubit_test.dart` | Test: `fetchEvents` dispara 1 `events_list_viewed`; `updateSearchQuery`/`addEvent`/`updateEvent`/`removeEvent` disparan **0**. |
| `test/features/home/presentation/home_cubit_test.dart` | Test: `loadHomeData` exitoso dispara 1 `home_viewed` con conteos correctos; error no dispara nada. |

> Nota: el `EventDetailCubit` se instancia con `new` en ambas páginas de detalle (no por
> `getIt`), así que `AnalyticsService` se le pasa como argumento adicional desde los `create:`
> usando `getIt<AnalyticsService>()`, igual que se hace hoy con los use cases.

---

## Contratos / API rideglory-api (o "ninguno")

**Ninguno.** Toda la instrumentación es client-side. No se tocan endpoints de events
(`GET /events`, `GET /events/my`, `GET /events/:id`, `GET /home`), ni DTOs, ni contratos
WebSocket. `rideglory-api` no cambia.

---

## Cambios de datos / migraciones (o "ninguno")

**Ninguno.** Sin migraciones de BD, sin nuevas claves de persistencia local. (El opt-out y su
clave en `UserStorageService` son de la fase 11.)

---

## Criterios de aceptación (numerados, observables, testeables)

1. **Listado — count entero, una sola vez por carga.** En DebugView, abrir la lista emite **un**
   `events_list_viewed` con `result_count` (entero) y `list_scope` (`'all'`|`'mine'`). Escribir
   en el buscador (cada keystroke) y mutar la lista localmente (`addEvent`/`updateEvent`/
   `removeEvent`) **no** emiten `events_list_viewed`; un cambio de filtros que recarga emite a lo
   sumo **uno** por recarga. El evento se emite desde `fetchEvents()`, no desde
   `_applyFiltersAndEmit()`. *(Test: `fetchEvents`→1; `updateSearchQuery`/mutaciones→0.)*

2. **Detalle — una sola vez por apertura, sin doble conteo.** Abrir el detalle emite
   **exactamente un** `event_detail_viewed` por apertura.
   - 2a. Apertura por deep-link (`eventDetailById`) → el evento lo emite `EventDetailCubit.loadEvent`
     (`source='deep_link'`, `is_read_only=0`).
   - 2b. Apertura desde lista/borrador (`eventDetail`) → el evento lo emite el `create:` del
     `BlocProvider` de `EventDetailPage` **solo** cuando `params.isFromEventDetailByIdPage == false`.
   - 2c. **Cero doble conteo:** abrir por deep-link produce **1** evento total, no 2 — la
     `EventDetailPage` interna con `isFromEventDetailByIdPage == true` **no** vuelve a emitir.
     *(Test: `loadEvent`→1; pump de `EventDetailPage` con `isFromEventDetailByIdPage:true`→0.)*

3. **Home.** Entrar a home con datos cargados emite **un** `home_viewed` con
   `upcoming_events_count` (entero) y `has_main_vehicle` (0/1). Estados de error/carga no emiten.
   *(Test con mock.)*

4. **Sin PII / sin alta cardinalidad.** Ningún param de `home_viewed`/`events_list_viewed`/
   `event_detail_viewed` contiene `event_id`, `event_name`, ciudad libre, texto de búsqueda ni
   `owner_id`; solo enums/banderas/conteos. *(Grep + revisión del mapa de params.)*

5. **Nombres desde la taxonomía (G1).** Los tres eventos usan constantes de la clase de
   taxonomía de la fase 2; `grep` de `logEvent(` con literal directo en `features/events/` y
   `features/home/` = **0**.

6. **Capa respetada.** Cero imports de `package:firebase_analytics`/`firebase_crashlytics` en
   `features/events/` y `features/home/`; los cubits dependen solo de la abstracción
   `AnalyticsService` de `core/`.

7. **Sin UI / sin regresión.** No hay cambios visuales ni de navegación; `dart analyze` limpio;
   `flutter test` verde con la no-op impl (sin envíos reales en tests).

---

## Pruebas (unitarias/widget/integración)

### Unitarias (obligatorias)
- **`EventsCubit`** (`events_cubit_test.dart`): con mock de `AnalyticsService` y use case falso
  que devuelve `Right(<events>)`:
  - `fetchEvents()` → verifica `logEvent(eventsListViewed, {result_count, list_scope})` llamado
    **una vez**; `list_scope` = `'mine'` con `EventsCubit.myEvents`, `'all'` con el default.
  - `updateSearchQuery('x')` → `verifyNever` de `eventsListViewed`.
  - `addEvent`/`updateEvent`/`removeEvent` → `verifyNever` de `eventsListViewed`.
- **`EventDetailCubit`** (`event_detail_cubit_test.dart`): con use case falso que devuelve un
  `EventModel` conocido:
  - `loadEvent(id)` → `logEvent(eventDetailViewed, {...})` llamado **una vez**, con
    `source='deep_link'`, `is_read_only=0`, sin `event_id` en params.
- **`HomeCubit`** (`home_cubit_test.dart`):
  - `loadHomeData()` éxito → `home_viewed` una vez con conteos correctos.
  - `loadHomeData()` error → `verifyNever`.

### Widget (recomendada, cubre 2c)
- Pump de `EventDetailPage` con `isFromEventDetailByIdPage: true` y un `AnalyticsService` mock →
  `verifyNever(eventDetailViewed)` desde la página (confirma que el camino by-id no re-emite).
  Con `isFromEventDetailByIdPage: false` → exactamente una emisión.

### Manual / DebugView (cierre de fase)
- Recorrer home → lista → detalle (desde lista) → back → deep-link by-id, observando en
  DebugView un único evento por interacción y sin ids/PII.

---

## Riesgos y mitigaciones

1. **Doble conteo con `screen_view` (fase 3).** El `NavigatorObserver` ya emite `screen_view`
   para `home`, `events` y `event_detail`. Los eventos de dominio de esta fase
   (`home_viewed`/`events_list_viewed`/`event_detail_viewed`) son **adicionales** y con nombre
   distinto; no reemplazan ni duplican `screen_view`. *Mitigación:* nombres de dominio separados
   del mapa de rutas; documentar en la taxonomía que coexisten por diseño.

2. **Doble `event_detail_viewed` en el camino by-id.** `EventDetailByIdPage` renderiza
   `EventDetailPage` con `isFromEventDetailByIdPage == true`; si `EventDetailPage` emitiera el
   evento sin condicionar, una apertura by-id contaría **2** (uno en `loadEvent`, otro en la
   página). *Mitigación (obligatoria):* `EventDetailPage` emite **solo** cuando
   `params.isFromEventDetailByIdPage == false`; el camino by-id emite exclusivamente en
   `EventDetailCubit.loadEvent`. Cubierto por el criterio 2c y el test de widget. (Riesgo
   distinto del #1: este es doble conteo del **mismo evento de dominio** entre dos call sites; el
   #1 es la coexistencia con `screen_view`.)

3. **Emisión repetida por rebuilds de `EventDetailPage` (StatelessWidget).** `build()` corre
   varias veces (rebuilds del `BlocListener`); emitir en `build()` inflaría el conteo.
   *Mitigación:* emitir en el `create:` del `BlocProvider` (corre una vez) o convertir a
   `StatefulWidget` y emitir en `initState()`. Nunca en `build()` sin flag one-shot.

4. **`events_list_viewed` en cada keystroke / mutación.** `_applyFiltersAndEmit()` se llama en
   `updateSearchQuery` y en `addEvent`/`updateEvent`/`removeEvent`. *Mitigación:* emitir solo en
   `fetchEvents()` (fold de datos), nunca dentro de `_applyFiltersAndEmit()`. Cubierto por el
   criterio 1 y el test de `verifyNever`.

5. **Ambigüedad de `source`/`is_read_only` en `EventDetailByIdPage`.** La página by-id solo
   conoce `widget.eventId` y no sabe si viene de un borrador. *Mitigación:* fijar `source`
   determinista `'deep_link'` y `is_read_only=0` en el camino by-id; el caso `'draft'`/solo-lectura
   se calcula únicamente en `EventDetailPage` desde `params.event.state`, que sí trae el
   `EventModel` completo. Ambos call sites quedan con args deterministas.

6. **PII por id/nombre/ciudad/búsqueda.** Tentación de loguear `event_id` o el texto buscado.
   *Mitigación:* taxonomía sin esos campos; solo enums/banderas/conteos; revisión en la
   auditoría transversal (fase 10). Regla "id canónico de pantalla, nunca el valor dinámico".

7. **`is_owner` requiere uid de sesión.** Calcularlo necesita el uid actual (de `AuthCubit`).
   *Mitigación:* derivarlo del estado de sesión ya disponible; si no hay sesión, `is_owner=0`.
   Nunca loguear el uid ni el `owner_id`, solo la bandera 0/1.

8. **Acoplamiento del scope en `EventsCubit`.** Distinguir `'all'` vs `'mine'` sin filtrar por
   tipo de use case. *Mitigación:* flag `final bool _isMyEvents` fijado en cada constructor
   (named vs default); el flag alimenta `list_scope`, sin inspeccionar el use case.

---

## Dependencias (fases prerequisito y por qué)

- **Fase 1 — Fundaciones + gating + regla de capa.** Provee la abstracción `AnalyticsService`
  ampliada (Dart-puro en `core/`), su impl Firebase, la no-op para tests y el gating
  (`setEnabled(false)` / no-report en `kDebugMode`). Sin ella no hay dónde emitir ni cómo testear
  sin enviar eventos reales.
- **Fase 2 — Taxonomía + límites GA4.** Provee las constantes de nombres/params y la convención
  (≤40/≤40/≤100, params `Object`, sin bool crudo). Esta fase **reusa y extiende** esa clase de
  taxonomía; no inventa literales (G1).
- **Fase 3 — screen_view automático.** Ya cubre el recorrido de pantallas (home/list/detail) por
  el `NavigatorObserver`. Esta fase añade **eventos de dominio** complementarios; depender de la
  fase 3 delimita el alcance (Riesgo #1: no duplicar `screen_view`).
