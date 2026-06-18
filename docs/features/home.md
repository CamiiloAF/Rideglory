# Documentación del Feature: Home

> Última actualización: 2026-06-17  
> Alcance: `lib/features/home/`

---

## Tabla de contenido

1. [Visión general](#1-visión-general)
2. [Modelo de dominio](#2-modelo-de-dominio)
3. [Arquitectura por capas](#3-arquitectura-por-capas)
   - 3.1 [Domain](#31-domain)
   - 3.2 [Data](#32-data)
   - 3.3 [Presentation](#33-presentation)
4. [Cubit y estados](#4-cubit-y-estados)
5. [Secciones de la pantalla](#5-secciones-de-la-pantalla)
6. [Flujo de carga](#6-flujo-de-carga)
7. [Rutas de navegación](#7-rutas-de-navegación)
8. [API endpoints](#8-api-endpoints)
9. [Conexiones con otros features](#9-conexiones-con-otros-features)
10. [Patrones y trampas conocidas](#10-patrones-y-trampas-conocidas)
11. [Archivos clave de referencia rápida](#11-archivos-clave-de-referencia-rápida)

---

## 1. Visión general

El feature **Home** es el dashboard de bienvenida. Es el primer tab del bottom navigation. Su responsabilidad:

1. **Saludar al usuario** con su nombre.
2. **Destacar el vehículo principal** (foto, nombre, badge SOAT).
3. **Listar próximos eventos** (carrusel horizontal con badge de estado).
4. **Botón "Ver catálogo"** para ir a la lista completa de eventos.
5. **Atajos a notificaciones** (campana con badge de no-leídas).

Una sola request consolida los datos: `GET /home` retorna `mainVehicle` + `upcomingEvents`. El feature **no tiene catálogos propios** — todos los datos vienen del backend en un endpoint dedicado.

---

## 2. Modelo de dominio

### `HomeData`
> `lib/features/home/domain/models/home_data.dart`

```
HomeData
  mainVehicle: VehicleModel?            — null si el usuario no tiene vehículos
  upcomingEvents: List<EventModel>      — vacío si no hay eventos
```

Modelo simple sin freezed. Reutiliza `VehicleModel` (feature `vehicles`) y `EventModel` (feature `events`).

---

## 3. Arquitectura por capas

### 3.1 Domain
```
lib/features/home/domain/
├── models/
│   └── home_data.dart
├── repository/
│   └── home_repository.dart
└── use_cases/
    └── get_home_data_use_case.dart
```

**`HomeRepository`** (interface):
```dart
Future<Either<DomainException, HomeData>> getHomeData();
```

**`GetHomeDataUseCase`** (`@injectable`):
```dart
call() → Future<Either<DomainException, HomeData>>
```
Delegación directa al repository.

---

### 3.2 Data
```
lib/features/home/data/
├── dto/
│   ├── home_dto.dart
│   └── home_dto.g.dart
├── repository/
│   └── home_repository_impl.dart
└── service/
    ├── home_service.dart
    └── home_service.g.dart
```

**`HomeDto`** (`@JsonSerializable(explicitToJson: true)`):
```dart
mainVehicle: VehicleDto?
upcomingEvents: List<EventDto>

HomeData toHomeData() => HomeData(
  mainVehicle: mainVehicle?.toModel(),
  upcomingEvents: List<EventModel>.from(upcomingEvents),   // EventDto extends EventModel
);
```

**Nota técnica:** la conversión `List<EventModel>.from(upcomingEvents)` funciona porque `EventDto extends EventModel`. Si en el futuro se separa DTO de modelo en `events`, esto se rompe.

**`HomeService` (Retrofit)**:
```dart
@singleton
@RestApi()
abstract class HomeService {
  factory HomeService(Dio dio) = _HomeService;

  @GET(ApiRoutes.home)
  Future<HomeDto> getHome();
}
```

**`HomeRepositoryImpl`** (`@Injectable(as: HomeRepository)`):
```dart
Future<Either<DomainException, HomeData>> getHomeData() {
  return executeService(function: () async {
    final dto = await _homeService.getHome();
    return dto.toHomeData();
  });
}
```
Sin caché local; cada `loadHomeData()` produce un request HTTP.

---

### 3.3 Presentation
```
lib/features/home/presentation/
├── cubit/
│   ├── home_cubit.dart
│   └── home_state.dart                     (part of home_cubit.dart)
├── home_page.dart
└── widgets/
    ├── home_scaffold.dart
    ├── home_header.dart                   (saludo + campana de notif)
    ├── home_section_header.dart           (label "GARAGE" + "Ver todos")
    ├── home_garage_section.dart           (sección vehículo principal)
    ├── home_garage_card.dart
    ├── home_garage_hero_image.dart
    ├── home_garage_vehicle_info.dart
    ├── home_garage_soat_badge.dart        (valid/expiring/expired/none → colores)
    ├── home_garage_placeholder_image.dart
    ├── home_empty_garage_card.dart        (CTA crear vehículo)
    ├── home_events_section.dart           (carrusel horizontal)
    ├── home_event_card.dart               (width 240, height 340)
    ├── home_event_card_image.dart
    ├── home_event_card_image_placeholder.dart
    ├── home_event_card_content.dart
    ├── home_event_default_background.dart
    ├── home_event_gradient_overlay.dart
    ├── home_event_difficulty_badge.dart
    ├── home_event_view_details_button.dart
    ├── home_empty_events_card.dart
    ├── home_view_all_events_button.dart    (botón "VIEW CATALOG")
    ├── home_notification_button.dart       (no usado actualmente; la campana viene de notifications)
    ├── home_vehicle_info_row.dart          (con FutureBuilder a maintenance)
    ├── home_vehicle_placeholder_image.dart
    └── home_submenu_option.dart
```

---

## 4. Cubit y estados

| Cubit | Archivo | DI | Estado base |
|---|---|---|---|
| `HomeCubit` | `presentation/cubit/home_cubit.dart` | `@injectable` | `HomeState` (sealed class manual) |

**`HomeState`** — 4 casos (sealed class, **no** freezed, **no** `ResultState<T>`):

```dart
sealed class HomeState { const HomeState(); }
final class HomeInitial extends HomeState { const HomeInitial(); }
final class HomeLoading extends HomeState { const HomeLoading(); }
final class HomeLoaded extends HomeState {
  const HomeLoaded({required this.upcomingEvents});
  final List<EventModel> upcomingEvents;
}
final class HomeError extends HomeState {
  const HomeError(this.message);
  final String message;
}
```

> **`mainVehicle` fue eliminado de `HomeLoaded`** (Phase 5). `HomeGarageSection` lee exclusivamente de `VehicleCubit`. `HomeData.mainVehicle` (del API home) sigue usándose internamente en `HomeCubit.loadHomeData()` para Analytics únicamente.

**Métodos públicos:**
| Método | Efecto |
|---|---|
| `loadHomeData()` | Emite `HomeLoading` → llama use case → emite `HomeLoaded(data)` o `HomeError(message)` |
| `updateEvent(EventModel)` | Si el estado es `HomeLoaded`, reemplaza el evento con mismo `id`. Útil cuando el usuario edita un evento desde el detalle y vuelve a home |
| `removeEvent(String eventId)` | Si el estado es `HomeLoaded`, filtra el evento (cuando se elimina desde el detalle) |

> A diferencia de cubits más complejos, `HomeCubit` no expone `addEvent`. Si se crea un evento desde otra pantalla, no se refleja en home hasta el próximo `loadHomeData()` (pull-to-refresh).

---

## 5. Secciones de la pantalla

### `HomePage` (`home_page.dart`)

```dart
class HomePage extends StatelessWidget {
  Widget build(context) {
    return BlocProvider(
      create: (_) => getIt<HomeCubit>()..loadHomeData(),
      child: const HomeScaffold(),
    );
  }
}
```

Solo crea el `HomeCubit` y llama `loadHomeData()`. Toda la UI vive en `HomeScaffold`.

### `HomeScaffold` (`widgets/home_scaffold.dart`)

- `PopScope(canPop: false)` con `_showExitConfirmation`: al pulsar back físico, muestra diálogo "¿Salir de la app?" → `SystemNavigator.pop()`. Es la última pantalla pre-cierre.
- `SafeArea(bottom: false)` — el bottom nav del shell maneja el inset inferior.
- `RefreshIndicator(onRefresh: () => context.read<HomeCubit>().loadHomeData())`.
- `BlocBuilder<HomeCubit, HomeState>` con un `CustomScrollView` de slivers:
  - `HomeHeader` (siempre visible).
  - `HomeLoading` → `SliverFillRemaining(AppLoadingIndicator)`.
  - `HomeLoaded` → `HomeGarageSection` + `HomeEventsSection` + `HomeViewAllEventsButton`.
  - `HomeError` → texto centrado con `state.message`.
  - Padding final `AppSpacing.gap100` (100px).

### `HomeHeader` (`widgets/home_header.dart`)

- Saludo `context.l10n.home_greeting` + nombre del usuario.
- Nombre se resuelve desde `AuthCubit.state.currentUser?.fullName ?? email.split('@').first ?? 'Rider'` — lee con `context.watch<AuthCubit>()`.
- `NotificationBellButton` a la derecha (importado de `features/notifications/presentation/widgets/`).

### `HomeGarageSection` (`widgets/home_garage_section.dart`)

Lee **exclusivamente** de `VehicleCubit` mediante `BlocBuilder`:

```dart
BlocBuilder<VehicleCubit, ResultState<List<VehicleModel>>>(
  builder: (context, vehicleState) {
    return vehicleState.when(
      initial: () => _GaragePlaceholder(),
      loading: () => _GaragePlaceholder(),
      data: (vehicles) {
        final active = vehicles.where((v) => !v.isArchived).toList();
        if (active.isEmpty) return const HomeEmptyGarageCard();
        final mainVehicle =
            active.where((v) => v.isMainVehicle).firstOrNull ?? active.first;
        return HomeGarageCard(vehicle: mainVehicle);
      },
      empty: () => const HomeEmptyGarageCard(),
      error: (_) => const HomeEmptyGarageCard(),
    );
  },
)
```

Puntos clave:
- **Filtra activos antes de elegir principal**: solo vehículos con `isArchived: false` se consideran. Si todos están archivados, muestra `HomeEmptyGarageCard`.
- **Sin prop `vehicle`**: elimina la dependencia de `HomeLoaded.mainVehicle`.
- **`_GaragePlaceholder`**: contenedor de 200 px mientras `VehicleCubit` carga (estados `initial`/`loading`).
- Reacciona en tiempo real a cambios del cubit: archivar, restaurar o cambiar vehículo principal se reflejan sin re-fetch HTTP de `HomeCubit`.

### `HomeGarageCard` + `HomeGarageSoatBadge`

`HomeGarageSoatBadge` mapea `SoatStatus` a colores:
| Status | Fondo | Texto |
|---|---|---|
| `valid` | `AppColors.successSubtle` | success |
| `expiringSoon` | `AppColors.warningSubtle` | warning |
| `expired` | `AppColors.errorSubtle` | error |
| `noSoat` / `null` | `AppColors.infoSubtle` | info |

### `HomeEventsSection`

- Carrusel horizontal con `ListView.separated`, altura ≈340px.
- Cada `HomeEventCard` (width 240) muestra portada + estado (`AppEventBadge`) + nombre + fecha + dificultad + botón "Ver detalle".
- Al tocar el card:
  ```dart
  final result = await context.pushNamed<dynamic>(AppRoutes.eventDetail, extra: event);
  if (!context.mounted) return;
  if (result is EventModel)         context.read<HomeCubit>().updateEvent(result);
  else if (result == true && event.id != null) context.read<HomeCubit>().removeEvent(event.id!);
  ```
- Si no hay eventos: `HomeEmptyEventsCard` con CTA a `createEvent`.

### `HomeViewAllEventsButton`

Botón outlined al fondo que navega a `/events`.

---

## 6. Flujo de carga

```
MainShell montado (usuario autenticado, primer frame del shell)
  └─ WidgetsBinding.addPostFrameCallback:
       si VehicleCubit.state is Initial → VehicleCubit.fetchMyVehicles()
           → API GET /vehicles/my → puebla la lista de vehículos
           → HomeGarageSection reacciona vía BlocBuilder

HomePage construido (BlocProvider crea HomeCubit y dispara loadHomeData())
  │
  ▼
HomeCubit.loadHomeData()
  ├─ emit(HomeLoading)
  ├─ GetHomeDataUseCase()
  │  └─ HomeRepositoryImpl.getHomeData()
  │     └─ HomeService.getHome()  → GET /home
  │        Response: { mainVehicle: VehicleDto?, upcomingEvents: EventDto[] }
  │     └─ dto.toHomeData()  (VehicleDto → VehicleModel, EventDto cast a EventModel)
  │
  ├─ Si error → emit(HomeError(message))
  └─ Si data  → emit(HomeLoaded(upcomingEvents))   ← mainVehicle ya no va al estado

HomeScaffold renderiza secciones según HomeState.
HomeGarageSection reacciona a VehicleCubit (independiente de HomeState).

Pull-to-refresh → loadHomeData() de nuevo (emite Loading, borra datos anteriores).
                  VehicleCubit no se re-fetcha en pull-to-refresh de Home.
Detail event return → cubit.updateEvent / removeEvent (sin re-fetch).
```

---

## 7. Rutas de navegación

| Ruta | Constante | Página | Tab del shell |
|---|---|---|---|
| `/home` | `AppRoutes.home` | `HomePage` | Índice 0 (primera rama) |

`HomePage` vive dentro del primer `StatefulShellBranch` del `StatefulShellRoute.indexedStack` (en `app_router.dart`).

**Navegaciones salientes:**
- "Ver todos" en garage → `context.go(AppRoutes.garage)`.
- "Ver detalle" en evento → `context.pushNamed(AppRoutes.eventDetail, extra: event)` (espera `EventModel` o `true` o `null` como pop result).
- "VIEW CATALOG" → `context.go(AppRoutes.events)`.
- Empty garage CTA → `context.pushNamed(AppRoutes.createVehicle)`.
- Empty events CTA → `context.pushNamed(AppRoutes.createEvent)`.
- Campana de notificación → `context.pushNamed(AppRoutes.notifications)`.

---

## 8. API endpoints

| Método | Endpoint | Descripción |
|---|---|---|
| `GET` | `/home` | Retorna `{mainVehicle?, upcomingEvents}` consolidado |

Definido en `ApiRoutes.home`.

**Response shape esperada:**
```json
{
  "mainVehicle": { ...VehicleDto },
  "upcomingEvents": [ { ...EventDto }, ... ]
}
```

---

## 9. Conexiones con otros features

| Feature | Conexión |
|---|---|
| `vehicles` | `HomeGarageSection` lee **exclusivamente** de `VehicleCubit.state`. `MainShell` dispara `fetchMyVehicles()` al montar el shell para que Home tenga datos sin necesidad de navegar al Garaje primero |
| `events` | Reutiliza `EventModel` y `EventDto`. `HomeEventsSection` empuja a `eventDetail` y reacciona al pop result con `updateEvent` / `removeEvent` |
| `authentication` | `HomeHeader` lee `AuthCubit.state.currentUser` para mostrar el nombre |
| `notifications` | Importa `NotificationBellButton` (lee `NotificationsCubit.state.unreadCount` para badge) |
| `soat` | El badge SOAT del vehículo lee `vehicle.soatStatus` (campo persistido en `VehicleModel`) |

---

## 10. Patrones y trampas conocidas

### `HomeState` es sealed class manual (no `ResultState<T>`)
A diferencia de la mayoría del codebase, home no usa el patrón `ResultState`. La razón es que `HomeLoaded` necesita dos datos (vehículo + eventos) y un solo `ResultState<HomeData>` produciría reconstrucciones más amplias. Mantener el patrón si se agregan estados (p. ej. `HomeRefreshing`).

### Carga sin caché
`HomeRepositoryImpl.getHomeData()` no tiene caché local. Cada `loadHomeData()` produce HTTP. Si el usuario hace pull-to-refresh rápidamente, hay flicker porque `HomeLoading` borra el `HomeLoaded` anterior.

### `VehicleCubit` es la única fuente de verdad para el vehículo en Home
`HomeGarageSection` reacciona directamente a `VehicleCubit`. `HomeData.mainVehicle` (del API home) se conserva en `HomeCubit` solo para Analytics. Archivar, restaurar o cambiar el vehículo principal se refleja en Home sin re-fetch de `HomeCubit`.

`MainShell` dispara `VehicleCubit.fetchMyVehicles()` en el primer frame post-montaje (guard `is Initial`) para que Home tenga datos desde el arranque, sin depender de que el usuario visite el tab Garaje.

### Vehículos archivados en Home
`HomeGarageSection` filtra `!isArchived` antes de elegir el principal. Si todos los vehículos están archivados, muestra `HomeEmptyGarageCard`. Nunca cae al fallback `vehicles.first` con un vehículo archivado.

### `EventDto` se castea directo a `EventModel`
`HomeDto.toHomeData()` hace `List<EventModel>.from(upcomingEvents)` sin invocar `.toModel()`. Funciona porque `EventDto extends EventModel`. Si en el futuro se separa DTO de modelo, agregar conversión explícita.

### `home_notification_button.dart` no se usa en home actual
La campana real viene de `lib/features/notifications/presentation/widgets/notification_bell_button.dart`. El widget local de home parece un remanente o pieza alternativa. Verificar antes de editar.

### `home_vehicle_info_row.dart` hace `FutureBuilder` a maintenance
Tiene un cálculo de "alerta de mantenimiento" usando `GetMaintenancesByVehicleIdUseCase`. **No se monta en el árbol actual de home**, pero sí está disponible. Si se reactiva, evaluar que un `FutureBuilder` no dispare requests excesivos al rebuild.

### `PopScope` cierra la app
Back físico en home → diálogo + `SystemNavigator.pop()`. Si el `StatefulShellRoute` mueve a home pero el usuario esperaba volver a otro tab, no funcionará — el comportamiento es el correcto para "última pantalla autenticada".

### Hardcoded `'Rider'` como fallback
`HomeHeader` cae a literal `'Rider'` si no hay `fullName` ni email. No usa `context.l10n`. Considerar localizar.

### Pop result protocol con el detalle de evento
- `null` → no cambia nada.
- `EventModel` → actualiza el evento en la lista.
- `true` → elimina el evento de la lista.

Cualquier otra cosa se ignora. Si el detalle empieza a retornar otros tipos (un objeto compuesto, por ejemplo), home no reaccionará.

### `HomeCubit` es `@injectable`, no singleton
Cada vez que `HomePage` se construye, se crea un nuevo cubit y se dispara `loadHomeData()`. En `StatefulShellRoute.indexedStack` el shell mantiene viva la rama al cambiar de tab, así que el cubit persiste mientras estés en la app; pero si la rama se destruye (no es el caso por defecto), se haría reload.

---

## 11. Archivos clave de referencia rápida

| Qué buscar | Archivo |
|---|---|
| Modelo del home | `lib/features/home/domain/models/home_data.dart` |
| Interface del repository | `lib/features/home/domain/repository/home_repository.dart` |
| Use case | `lib/features/home/domain/use_cases/get_home_data_use_case.dart` |
| DTO + conversor | `lib/features/home/data/dto/home_dto.dart` |
| Service Retrofit | `lib/features/home/data/service/home_service.dart` |
| Repository impl | `lib/features/home/data/repository/home_repository_impl.dart` |
| Cubit + estados | `lib/features/home/presentation/cubit/home_cubit.dart` |
| Página | `lib/features/home/presentation/home_page.dart` |
| Scaffold + slivers | `lib/features/home/presentation/widgets/home_scaffold.dart` |
| Sección garage | `lib/features/home/presentation/widgets/home_garage_section.dart` |
| Sección eventos | `lib/features/home/presentation/widgets/home_events_section.dart` |
| Header con saludo | `lib/features/home/presentation/widgets/home_header.dart` |
| Campana de notif | `lib/features/notifications/presentation/widgets/notification_bell_button.dart` |
| Endpoint | `lib/core/http/api_routes.dart` (`home = '/home'`) |
