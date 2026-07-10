# Checklist de QA — Home

**Feature:** Dashboard principal (vehículo destacado, próximos eventos, saludo, campana) (`lib/features/home/`)
**Referencia:** `docs/features/home.md` (actualizada 2026-07-04)
**Estado:** Pendiente de ejecución

---

## Pre-condiciones

- [ ] Cuenta de prueba `qa1@gmail.com` (`Test123.`) con al menos un vehículo, uno marcado como principal (`isMainVehicle`).
- [ ] Cuenta de prueba `qa2@gmail.com` (`Test123.`) usada como cuenta secundaria/organizadora (para el escenario "Mi Evento", si aplica a algún caso de navegación).
- [ ] Cuenta de prueba adicional o la misma `qa1@gmail.com` con **cero vehículos activos** (o todos archivados) para el estado vacío de garage. Puede requerir una cuenta separada o archivar temporalmente los vehículos existentes y restaurarlos después.
- [ ] Al menos 2-3 eventos próximos visibles para el usuario de prueba en distintos estados/dificultades (para el carrusel).
- [ ] Un escenario sin eventos próximos (usuario nuevo o filtrando fecha futura lejana) para el estado vacío de eventos.
- [ ] Un vehículo con SOAT vigente, uno próximo a vencer y uno vencido (o sin SOAT) para revisar los 4 colores del badge.
- [ ] Dispositivo/emulador con fecha y zona horaria configurables (para probar el filtro `dateFrom` por fecha local).
- [ ] Conexión a internet controlable (para simular error de red al cargar `/home`).

---

## 1. Ver dashboard con vehículo principal

> Entra a Home con una cuenta que tiene al menos un vehículo activo marcado como principal.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 1.1 | Abre el tab Home | Se ve el saludo con el nombre del usuario y la campana de notificaciones en `HomeHeader` | 👤 Manual (no existe widget test de `HomeHeader`; verificación visual del saludo + campana) | |
| 1.2 | Revisa la sección de garage | Se muestra `HomeGarageCard` con el vehículo marcado como `isMainVehicle` (foto, nombre, badge SOAT) | 🤖✅ Auto-PASS (`test/features/home/presentation/widgets/home_garage_section_test.dart`) | |
| 1.3 | Con varios vehículos activos pero ninguno marcado como principal | Se muestra el primero de la lista de activos (`active.first`) como fallback | 🤖✅ Auto-PASS (`test/features/home/presentation/widgets/home_garage_section_test.dart` — cubre la lógica de selección de `HomeGarageSection`) | |
| 1.4 | Revisa el badge SOAT del vehículo destacado | El color coincide con el estado: verde (`valid`), amarillo (`expiringSoon`), rojo (`expired`) o azul info (`noSoat`/`null`) | 👤 Manual (no hay widget test de `HomeGarageSoatBadge` que verifique los 4 colores; verificación visual) | |
| 1.5 | Archiva el vehículo principal desde el Garaje y vuelve a Home sin recargar Home | La sección de garage se actualiza sola (reactiva a `VehicleCubit`), mostrando otro vehículo activo o el estado vacío, sin necesidad de pull-to-refresh de Home | 🤖✅ Auto-PASS (`test/features/home/presentation/widgets/home_garage_section_test.dart` prueba la reactividad ante cambios de `VehicleCubit`) | |
| 1.6 | Cambia el vehículo principal desde el Garaje y vuelve a Home | `HomeGarageCard` muestra el nuevo vehículo principal sin re-fetch de `/home` | 🤖✅ Auto-PASS (mismo mecanismo cubierto en `home_garage_section_test.dart`) | |

---

## 2. Ver próximos eventos

> Entra a Home con eventos próximos visibles para el usuario.

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 2.1 | Revisa la sección de eventos | Se ve un carrusel horizontal (`HomeEventsSection`) con tarjetas de ≈240px de ancho, portada, badge de estado, nombre, fecha y dificultad | 👤 Manual (no existe widget test de `HomeEventsSection`/`HomeEventCard`; verificación visual del carrusel — ver "Fixes requeridos") | |
| 2.2 | Verifica que `HomeCubit.loadHomeData()` puebla `upcomingEvents` con los eventos del backend | El estado `HomeLoaded.upcomingEvents` contiene la lista esperada | 🤖✅ Auto-PASS (`test/features/home/presentation/cubit/home_cubit_test.dart`, TC-home-2) | |
| 2.3 | Toca "Ver detalle" en una tarjeta de evento | Navega al detalle del evento (`pushNamed(AppRoutes.eventDetail, extra: event)`) | 👤 Manual (no hay widget test de la navegación de `HomeEventCard`; requiere interacción de tap — ver "Fixes requeridos") | |
| 2.4 | Vuelve del detalle de evento habiendo editado el evento (retorna `EventModel`) | La tarjeta en Home se actualiza con los nuevos datos sin recargar todo Home (`updateEvent`) | 👤 Manual (lógica de `updateEvent` en el cubit no tiene test dedicado — solo se prueban `loadHomeData` success/error; ver "Fixes requeridos") | |
| 2.5 | Vuelve del detalle habiendo eliminado el evento (retorna `true`) | La tarjeta desaparece del carrusel en Home (`removeEvent`) | 👤 Manual (mismo motivo que 2.4 — sin test de `removeEvent`, ver "Fixes requeridos") | |
| 2.6 | Toca el botón "VIEW CATALOG" / "Ver todos" de eventos | Navega a `/events` (catálogo completo) | 👤 Manual (no hay widget test de `HomeViewAllEventsButton`) | |

---

## 3. Estado vacío (sin vehículo / sin eventos)

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 3.1 | Entra a Home con una cuenta sin vehículos activos (ninguno o todos archivados) | Se muestra `HomeEmptyGarageCard` con CTA para crear vehículo | 🤖✅ Auto-PASS (`test/features/home/presentation/widgets/home_garage_section_test.dart` cubre el caso `vehicles.isEmpty`/todos archivados → `HomeEmptyGarageCard`) | |
| 3.2 | Toca el CTA de garage vacío | Navega a `createVehicle` | 👤 Manual (no hay widget test de tap sobre `HomeEmptyGarageCard`) | |
| 3.3 | Entra a Home con una cuenta sin eventos próximos | Se muestra `HomeEmptyEventsCard` con CTA para crear evento, en vez del carrusel | Estado del cubit: 🤖✅ Auto-PASS (`test/features/home/presentation/cubit/home_cubit_test.dart`, TC-home-a3 confirma `upcomingEvents` vacío en `HomeLoaded`). Render del widget: 🤖✅ Auto-PASS (`test/features/home/presentation/widgets/home_events_section_test.dart`, TC-events-section-1 monta `HomeEventsSection` con `events: []` y verifica que renderiza `HomeEmptyEventsCard` sin carrusel) | |
| 3.4 | Toca el CTA de eventos vacío | Navega a `createEvent` | 👤 Manual (no hay widget test de tap sobre `HomeEmptyEventsCard`) | |
| 3.5 | `VehicleCubit` en estado `error` (fallo al cargar vehículos) | `HomeGarageSection` cae al mismo `HomeEmptyGarageCard` (no muestra un mensaje de error separado) | 🤖✅ Auto-PASS (`test/features/home/presentation/widgets/home_garage_section_test.dart`, TC-garage-section-5c emite `ResultState.error()` desde `VehicleCubit` y confirma que se renderiza `HomeEmptyGarageCard`, nunca `HomeGarageCard`, según el mapeo de `home_garage_section.dart:44`) | |
| 3.6 | `HomeCubit` en estado `HomeError` (fallo al cargar `/home`) | Se muestra `PageErrorStateWidget` con el mensaje de error y botón de reintento | 🤖✅ Auto-PASS (`test/features/home/presentation/cubit/home_cubit_test.dart`, TC-home-3) | |
| 3.7 | Con `VehicleCubit` en `initial`/`loading` (aún no ha llamado a `fetchMyVehicles`) | Se muestra el placeholder de 200px (`_GaragePlaceholder`), no el estado vacío ni error | 🤖✅ Auto-PASS (`test/features/home/presentation/widgets/home_garage_section_test.dart`, TC-garage-section-1 y TC-garage-section-2) | |

---

## 4. Pull-to-refresh

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 4.1 | Con Home cargado, desliza hacia abajo para refrescar | Se dispara `loadHomeData()` de nuevo; se ve el estado de carga y luego los datos actualizados | 👤 Manual (requiere gesto de `RefreshIndicator`; no hay widget test específico de la interacción de pull-to-refresh, aunque `loadHomeData()` sí está cubierto por separado) | |
| 4.2 | Durante el refresh, revisa si hay parpadeo/flicker | `HomeLoading` reemplaza momentáneamente los datos anteriores (comportamiento documentado, sin caché); es aceptado pero debe confirmarse que no rompe la UX | 👤 Manual (percepción visual, comportamiento conocido y documentado como limitación) | |
| 4.3 | Verifica que el pull-to-refresh de Home NO dispare `VehicleCubit.fetchMyVehicles()` | Solo se recarga `HomeCubit`; la sección de garage no vuelve a pedir vehículos al backend en el refresh de Home | 🤖✅ Auto-PASS (`test/features/home/presentation/cubit/home_cubit_test.dart`, TC-home-4 mockea `VehicleCubit` y verifica con `verifyNever(() => mockVehicleCubit.fetchMyVehicles())` que `HomeCubit.loadHomeData()` nunca invoca ese método; complementa TC-garage-section-6 en `home_garage_section_test.dart`, que prueba la dirección inversa) | |
| 4.4 | Provoca un error de red durante el pull-to-refresh | Se reemplaza el contenido por `PageErrorStateWidget` con botón de reintento (no hay rollback al estado anterior) | 🤖✅ Auto-PASS (`test/features/home/presentation/cubit/home_cubit_test.dart`, TC-home-3, mismo camino de error que la carga inicial) | |

---

## 5. Filtro por fecha local del dispositivo

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 5.1 | Cambia la zona horaria del dispositivo a una muy adelantada respecto al servidor (ej. UTC+12) y entra a Home | Se envía `dateFrom` con la fecha local del dispositivo (`yyyy-MM-dd`), no la del servidor; los eventos "de hoy" para ese usuario aparecen correctamente | 👤 Manual (requiere cambiar la zona horaria del dispositivo real/emulador y comparar contra backend; el cálculo en sí es determinístico en código pero no hay test que mockee `DateTime.now()` con distintas zonas) | |
| 5.2 | Revisa la query real enviada a `GET /home` | Incluye `?dateFrom=yyyy-MM-dd` con la fecha local | 👤 Manual (requiere inspección de logs de red/Dio interceptor; no hay unit test de `HomeRepositoryImpl` para este feature en `test/features/home/` — ver "Fixes requeridos") | |
| 5.3 | Un evento programado "para hoy" en la zona horaria del usuario pero "para mañana" en UTC del servidor | El evento SÍ aparece en "próximos eventos" (el filtro usa el reloj del dispositivo, no UTC del servidor) | 👤 Manual (requiere coordinar datos de backend con la hora del dispositivo; caso de regresión histórico documentado) | |

---

## 6. Ocultar controles al finalizar rodada

> Nota: el flujo de "ocultar controles al finalizar rodada" pertenece principalmente a Live Tracking/Events; en Home el efecto observable es que el evento finalizado deja de aparecer como "próximo".

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 6.1 | Finaliza una rodada activa (evento en curso) desde su pantalla de tracking | Al volver a Home, el evento finalizado ya no aparece en la sección de "próximos eventos" (tras recargar/pull-to-refresh) | 👤 Manual (requiere flujo completo de tracking en vivo + backend; fuera del alcance unitario de Home) | |
| 6.2 | Verifica que Home no muestra ningún control de tracking (SOS, controles en vivo) fuera de la pantalla de evento activo | Home no monta ningún widget de tracking; esos controles viven exclusivamente en la pantalla de detalle/tracking del evento | 👤 Manual (verificación de que Home no tiene acoplamiento con tracking; revisión de código/UI) | |

---

## 7. Navegación desde tarjetas

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 7.1 | Toca "Ver todos" en la sección de garage | Navega a `/garage` (`context.go(AppRoutes.garage)`) | 👤 Manual (no hay widget test de `HomeSectionHeader`/botón "Ver todos") | |
| 7.2 | Toca la campana de notificaciones | Navega a `/notifications` | 👤 Manual (no hay widget test de `NotificationBellButton` dentro de `HomeHeader`; ver también checklist de notifications) | |
| 7.3 | Toca atrás (back físico) estando en Home | Aparece el diálogo "¿Salir de la app?"; al confirmar, se cierra la app (`SystemNavigator.pop()`) | 👤 Manual (requiere interacción con back físico + diálogo nativo; `PopScope(canPop: false)` no tiene widget test dedicado — ver "Fixes requeridos") | |
| 7.4 | Cancela el diálogo "¿Salir de la app?" | La app permanece en Home sin cerrarse | 👤 Manual (mismo motivo que 7.3) | |

---

## 8. Analytics

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 8.1 | Carga Home exitosamente con vehículo principal y eventos | Se dispara el evento `home_viewed` (u homólogo) de Analytics con los parámetros correctos | 🤖✅ Auto-PASS (`test/features/home/presentation/cubit/home_cubit_test.dart`, grupo `HomeCubit — analytics (Fase 6)`, primer test) | |
| 8.2 | Carga Home exitosamente sin vehículo principal | El evento de Analytics refleja la ausencia de vehículo principal sin crashear | 🤖✅ Auto-PASS (`test/features/home/presentation/cubit/home_cubit_test.dart`, TC-home-a2) | |
| 8.3 | Carga Home exitosamente con lista de eventos vacía | El evento de Analytics refleja 0 eventos próximos | 🤖✅ Auto-PASS (`test/features/home/presentation/cubit/home_cubit_test.dart`, TC-home-a3) | |
| 8.4 | Carga Home con error | El evento `home_viewed` NO se dispara | 🤖✅ Auto-PASS (`test/features/home/presentation/cubit/home_cubit_test.dart`, TC-home-a4) | |

---

## 9. Casos de borde

### 9A. `EventDto` casteado directo a `EventModel`

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 9A.1 | Recibe un `HomeDto` con `upcomingEvents` en la respuesta | La conversión `List<EventModel>.from(upcomingEvents)` no falla (depende de que `EventDto extends EventModel` siga vigente) | 👤 Manual (no hay test dedicado de `HomeDto.toHomeData()` en `test/features/home/` — ver "Fixes requeridos") | |

### 9B. E2E completo (Patrol)

| # | Accion | Resultado esperado | Estado auto | ✅/❌ |
|---|--------|--------------------|-------------|-------|
| 9B.1 | Corre `integration_test/home_patrol_test.dart` con credenciales de prueba reales | El flujo login → home navega y espera correctamente hasta ver el bottom nav y el contenido cargado del `HomeHeader` | ⏳ PENDIENTE de corrida real en emulador — el test existe en `integration_test/home_patrol_test.dart` pero aún no hay una ejecución verde registrada; no debe leerse como "ya pasó" | |

---

## 10. Verificaciones técnicas (equipo de desarrollo)

> Estas verificaciones requieren acceso al código, logs o consola de desarrollo.

| # | Verificación | Resultado esperado | ✅/❌ |
|---|-------------|--------------------|-------|
| 10.1 | Correr `flutter test test/features/home/` | Todos los tests del feature pasan en verde | |
| 10.2 | Correr `dart analyze` sobre `lib/features/home/` | Sin issues nuevos | |
| 10.3 | Correr `integration_test/home_patrol_test.dart` en un emulador Android disponible | El test pasa de principio a fin | |
| 10.4 | Revisar que `MainShell` dispare `VehicleCubit.fetchMyVehicles()` solo si `state is Initial` en el primer frame del shell | Confirmado; evita refetch innecesario al navegar entre tabs | |
| 10.5 | Revisar si existen widget tests para `HomeHeader`, `HomeEventsSection`, `HomeEventCard`, `HomeScaffold` (PopScope), `HomeEmptyGarageCard`/`HomeEmptyEventsCard` (taps) | Actualmente no existen (solo hay tests de `HomeCubit` y `HomeGarageSection`) — confirmar gap de cobertura en el resto de la capa de presentación | |
| 10.6 | Revisar si existe test unitario/widget de `HomeDto.toHomeData()` y `HomeRepositoryImpl.getHomeData()` (incluyendo el cálculo de `dateFrom`) | Actualmente no existen tests en `test/features/home/data/` — confirmar gap en la capa de datos | |

---

## Fixes requeridos

> `HomeCubit` (domain/state) y `HomeGarageSection` tienen buena cobertura; el resto de la capa de presentación y toda la capa de datos del feature carecen de tests automatizados.

1. **Alta prioridad** — No existen tests para la capa de datos (`HomeDto.toHomeData()`, `HomeRepositoryImpl.getHomeData()`, cálculo de `dateFrom`). Es el único endpoint consolidado del feature; un cambio en el shape del backend o en el cálculo de fecha podría romper Home sin que ningún test lo detecte.
2. **Alta prioridad** — Existe cobertura de render (`test/features/home/presentation/widgets/home_events_section_test.dart`, TC-events-section-1/2: `HomeEmptyEventsCard` vs. carrusel con `HomeEventCard`), pero sigue sin haber widget test de `HomeEventsSection`/`HomeEventCard` que confirme la navegación a `eventDetail` ni el manejo del pop result (`updateEvent`/`removeEvent`). Es lógica de negocio visible con alto tráfico de usuario.
3. **Media prioridad** — No hay widget test de `HomeHeader` (saludo con nombre del usuario, fallback `'Rider'` hardcodeado, integración con `NotificationBellButton`).
4. **Media prioridad** — No hay widget test de `HomeScaffold` (`PopScope(canPop: false)`, diálogo "¿Salir de la app?", `RefreshIndicator`).
5. **Baja prioridad** — No hay widget test de los CTAs de estado vacío (`HomeEmptyGarageCard` → `createVehicle`, `HomeEmptyEventsCard` → `createEvent`) ni de `HomeViewAllEventsButton`/`HomeSectionHeader` ("Ver todos" → `/garage`, "VIEW CATALOG" → `/events`).
6. **Baja prioridad** — `home_notification_button.dart` y `home_vehicle_info_row.dart` no se montan en el árbol actual (código potencialmente muerto); evaluar eliminarlos o documentar por qué se conservan, para no confundir cobertura futura.

---

## Resultado final

| Estado | Criterio |
|--------|----------|
| ✅ Aprobado | Todos los casos de las secciones 1–7 marcados como ✅ |
| ⚠️ Aprobado con observaciones | Máximo 2 casos fallidos de baja severidad (secciones 8, 9 o 10), con ticket creado |
| ❌ Rechazado | Cualquier caso de las secciones 1, 2, 3 o 7 marcado como ❌ |

**Revisado por:** ___________________
**Fecha:** ___________________
**Resultado:** ___________________
**Observaciones:** ___________________
