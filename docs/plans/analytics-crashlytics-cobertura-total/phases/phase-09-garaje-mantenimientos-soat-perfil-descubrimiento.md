# Fase 9 — Garaje, mantenimientos, SOAT, perfil, descubrimiento y notificaciones

> Plan: `analytics-crashlytics-cobertura-total` · Fase 9 de 11
> Fecha (UTC): 2026-06-04T01:06:49Z
> Sesión: PLANEACIÓN (no se modifica código de la app)
> dependsOn: [1, 2]
> Estado de captura: **sin UI nueva / sin regresión de comportamiento**. Activa en release; off en `kDebugMode` (handlers/gating de fase 1); no-op + `setEnabled(false)` en tests.

## Objetivo

Cerrar la cobertura de analítica de los seis features restantes (vehículos, mantenimiento, SOAT, perfil, users/descubrimiento, notificaciones) con un **alcance mínimo obligatorio verificable por feature**, de modo que la fase tenga un criterio de cierre nítido y no se convierta en una fase abierta. Toda la instrumentación es **client-side**, reutiliza la taxonomía centralizada y los límites GA4 de la fase 2, respeta la regla de capa (G0) de la fase 1, y no añade ni cambia ninguna pantalla.

## Alcance (entra / no entra)

### Entra — obligatorio (bloquea el cierre de la fase)

- **Vehículos** (`lib/features/vehicles/`): alta de vehículo, edición, borrado y *set principal*.
- **Mantenimiento** (`lib/features/maintenance/`): alta de mantenimiento y ver historial.
- **SOAT** (`lib/features/soat/`): ver estado del SOAT y captura manual (guardado). El *scan* OCR (`soat_scan_attempted/success/failed`) **ya quedó instrumentado y migrado a constantes en la fase 2** — aquí NO se reinstrumenta, solo se completan los call sites de estado/captura-manual usando las mismas constantes de taxonomía.
- **Perfil** (`lib/features/profile/presentation/`): ver perfil propio y editar perfil (inicio/éxito de la edición).
- **Users / descubrimiento** (`lib/features/users/`): ver el perfil de otro rider.
- **Notificaciones** (`lib/features/notifications/`): abrir una notificación, marcar leída (individual y todas) y registro del FCM token como señal de salud.

### Entra — nice-to-have (NO bloquea el cierre; se instrumenta si cabe sin abrir la fase)

- Archivar / desarchivar vehículo (`archive_vehicle_usecase`, `unarchive_vehicle_usecase`).
- Editar / borrar mantenimiento (`maintenance_delete_cubit`, modo edición de `maintenance_form_cubit`).
- Detalle de descubrimiento (interacciones secundarias dentro de `rider_profile_page`).
- Borrar SOAT (`SoatCubit.delete`).

### No entra

- Pantallas nuevas, cambios de copy de UI o de flujo (esta fase es cero-UI).
- Cambios en `rideglory-api`, DTOs, contratos HTTP o WebSocket.
- Definición de nuevas constantes de taxonomía fuera del catálogo: si falta un nombre, se añade al catálogo central de la fase 2 (no strings mágicos en los call sites — G1).
- `setUserId` / user properties (eso es fase 5).
- Auditoría no-PII transversal y doc de QA (fase 10); opt-out (fase 11).
- Instrumentar cada interacción/botón: solo el alcance mínimo + nice-to-have listados.

## Que se debe hacer (pasos concretos y ordenados)

1. **Añadir las constantes de eventos/params de esta fase al catálogo central de la fase 2** (`core/services/analytics/`), respetando snake_case, prefijo por feature y los límites GA4 (nombre evento ≤40, key ≤40, value string ≤100, params `Object`, sin `bool` → usar `0/1`). Nombres sugeridos por feature:
   - `vehicle_added`, `vehicle_updated`, `vehicle_deleted`, `vehicle_set_main`, `vehicle_archived` (nice-to-have).
   - `maintenance_added`, `maintenance_history_viewed`, `maintenance_updated`/`maintenance_deleted` (nice-to-have).
   - `soat_status_viewed`, `soat_manual_saved`, `soat_deleted` (nice-to-have). (El scan ya existe.)
   - `profile_viewed`, `profile_edit_started`, `profile_edit_succeeded`.
   - `rider_profile_viewed`.
   - `notification_opened`, `notification_marked_read`, `notifications_marked_all_read`, `fcm_token_registered`.
2. **Inyectar `AnalyticsService`** (abstracción core pura, regla G0) en los call sites elegidos por feature. Preferir el **use case de domain** cuando la acción ya pasa por uno (alta/edición/borrado de vehículo, alta de mantenimiento, registro FCM token, scan/save de SOAT); usar el **cubit de presentation** cuando el hito es de navegación/lectura (ver perfil, ver detalle de rider, abrir notificación). Nunca instrumentar en data/repository ni con `BuildContext`.
3. **Vehículos**: emitir `vehicle_added` tras éxito en el flujo de creación (`VehicleFormCubit._createNewVehicle` / `AddVehicleUseCase`); `vehicle_updated` tras edición (`_saveExistingVehicle` / `UpdateVehicleUseCase`); `vehicle_deleted` tras éxito en `VehicleDeleteCubit` / `DeleteVehicleUseCase`; `vehicle_set_main` en `VehicleCubit.setMainVehicle` tras éxito. Params: solo agregados no-PII (p.ej. `had_photo: 0/1`). **Nunca placa, VIN ni id de vehículo como valor.**
4. **Mantenimiento**: emitir `maintenance_added` tras guardado exitoso en `MaintenanceFormCubit.saveMaintenance`; `maintenance_history_viewed` al cargar historial en `MaintenancesCubit` (o `VehicleMaintenancesCubit`). Params: tipo de mantenimiento (enum estable) y `mode` si aplica, nunca kilometraje exacto como id ni notas libres.
5. **SOAT**: emitir `soat_status_viewed` cuando `SoatCubit.load` resuelve a `Data` con un SOAT; `soat_manual_saved` cuando `SoatCubit.save` (captura manual) confirma. Reutilizar el patrón y constantes del scan ya migrado. **Nunca aseguradora identificable, placa ni número de póliza como param**; solo agregados (`fields_count`, `had_pdf: 0/1`, etc.).
6. **Perfil**: emitir `profile_viewed` al resolver `ProfileCubit.fetchProfile`; `profile_edit_started` al abrir el flujo de edición y `profile_edit_succeeded` tras guardar (en el cubit de edición / `edit_profile_page`). Sin email, nombre ni teléfono en params.
7. **Users / descubrimiento**: emitir `rider_profile_viewed` en `RiderProfileCubit.fetchRiderProfile` tras éxito. **Nunca el `userId` del otro rider como valor de param** (G2); a lo sumo un flag agregado (p.ej. `is_self: 0/1` si aplica).
8. **Notificaciones**: emitir `notification_opened` al abrir/tap de una notificación (`NotificationItem` → `NotificationsCubit`); `notification_marked_read` en `NotificationsCubit.markRead`; `notifications_marked_all_read` en `markAllRead`; `fcm_token_registered` en `RegisterFcmTokenUseCase.call` (señal de salud). **Distinguir explícitamente recibida vs abierta**: solo se loguea *abierta/leída*, no la mera recepción/render del listado. Nunca id de notificación ni texto del mensaje como param.
9. **Respetar el gating de la fase 1**: no añadir condicionales `kDebugMode` en los call sites (el gating vive en la impl/handlers); en tests se usa la no-op impl + `setEnabled(false)`.
10. **Añadir un test unitario con mock de `AnalyticsService`** por feature (mínimo cuatro: vehículo, mantenimiento, perfil, notificaciones), verificando nombre de evento esperado y ausencia de params PII.
11. **Verificar G1** (grep de `logEvent(` con literal directo = 0 en los archivos tocados) y **G2** (grep de placa/VIN/aseguradora/`userId`/id como valor de param = 0).
12. Ejecutar `dart run build_runner build --delete-conflicting-outputs` (si cambia DI por nuevas inyecciones), `dart analyze` y `flutter test`.
13. Actualizar `docs/features/*.md` de los features tocados si el comportamiento documentado lo amerita (regla de docs de feature); la analítica suele ser transversal, así que el doc canónico de taxonomía vive en la fase 2/10.

## Archivos a crear/modificar (rutas reales, una linea de "que cambia")

- `lib/core/services/analytics/` (catálogo de constantes de fase 2) — **modificar**: añadir las constantes de eventos/params de esta fase.
- `lib/features/vehicles/presentation/cubit/vehicle_form_cubit.dart` — **modificar**: emitir `vehicle_added`/`vehicle_updated` tras éxito de creación/edición.
- `lib/features/vehicles/presentation/cubit/vehicle_cubit.dart` — **modificar**: emitir `vehicle_set_main` en `setMainVehicle` tras éxito.
- `lib/features/vehicles/presentation/delete/cubit/vehicle_delete_cubit.dart` — **modificar**: emitir `vehicle_deleted` tras éxito.
- `lib/features/vehicles/domain/usecases/archive_vehicle_usecase.dart` / `unarchive_vehicle_usecase.dart` — **modificar (nice-to-have)**: emitir `vehicle_archived`.
- `lib/features/maintenance/presentation/form/cubit/maintenance_form_cubit.dart` — **modificar**: emitir `maintenance_added` tras `saveMaintenance` exitoso.
- `lib/features/maintenance/presentation/list/maintenances/maintenances_cubit.dart` — **modificar**: emitir `maintenance_history_viewed` al cargar historial.
- `lib/features/maintenance/presentation/delete/cubit/maintenance_delete_cubit.dart` — **modificar (nice-to-have)**: emitir `maintenance_deleted`.
- `lib/features/soat/presentation/cubit/soat_cubit.dart` — **modificar**: emitir `soat_status_viewed` en `load` y `soat_manual_saved` en `save`; `soat_deleted` en `delete` (nice-to-have).
- `lib/features/profile/presentation/cubits/profile_cubit.dart` — **modificar**: emitir `profile_viewed` en `fetchProfile`.
- `lib/features/profile/presentation/edit_profile_page.dart` (o su cubit de edición) — **modificar**: emitir `profile_edit_started`/`profile_edit_succeeded`.
- `lib/features/users/presentation/cubit/rider_profile_cubit.dart` — **modificar**: emitir `rider_profile_viewed` en `fetchRiderProfile`.
- `lib/features/notifications/presentation/cubit/notifications_cubit.dart` — **modificar**: emitir `notification_opened`, `notification_marked_read` (en `markRead`), `notifications_marked_all_read` (en `markAllRead`).
- `lib/features/notifications/domain/usecases/register_fcm_token_usecase.dart` — **modificar**: emitir `fcm_token_registered` en `call`.
- `lib/core/di/injection.config.dart` — **regenerado** por build_runner si cambian las firmas de DI (no editar a mano).
- `test/features/vehicles/...`, `test/features/maintenance/...`, `test/features/profile/...`, `test/features/notifications/...` — **crear**: un test por feature con mock de `AnalyticsService`.

> Nota: confirmar la ruta exacta de los archivos de test contra la estructura `test/` existente; si no hay carpeta por feature, alinear con la convención del repo en el momento de implementar.

## Contratos / API rideglory-api (o "ninguno")

**Ninguno.** Toda la instrumentación es client-side. No se tocan endpoints, DTOs, request bodies ni el WebSocket. El registro del FCM token ya existe (`RegisterFcmTokenUseCase` → `POST` vía `notifications_service`); aquí solo se le añade una emisión de evento de salud, sin cambiar su contrato.

## Cambios de datos / migraciones (o "ninguno")

**Ninguno.** Sin migraciones de BD, sin nuevas claves de persistencia local (la clave de opt-out es de la fase 11). El re-run de `build_runner` solo regenera DI si cambian inyecciones.

## Criterios de aceptacion (numerados, observables, testeables)

1. **DebugView — obligatorios presentes**: ejecutar agregar vehículo, registrar mantenimiento, ver estado SOAT, editar perfil y abrir notificación produce, cada uno, su evento correspondiente con el nombre del catálogo de la fase 2 (nombres normalizados, snake_case).
2. **G2 — cero PII / cero alta cardinalidad**: ningún evento de esta fase lleva como valor de param placa, VIN, aseguradora identificable, número de póliza, email/nombre/teléfono, ni el id de otro rider / id de vehículo / id de notificación. Verificable por inspección de params en DebugView y por grep en los archivos tocados.
3. **Notificación recibida vs abierta**: solo se emite evento al *abrir / marcar leída*; renderizar el listado o recibir la notificación NO emite `notification_opened`. Verificable navegando al listado sin abrir nada (cero `notification_opened`) y luego abriendo una (exactamente uno).
4. **G1 — sin literales**: `grep -rn "logEvent(" ` sobre los archivos modificados muestra **0** literales de nombre directo; todos referencian constantes del catálogo.
5. **Regla de capa (G0) intacta**: ningún call site importa `package:firebase_analytics`/`firebase_crashlytics`; todos dependen de la abstracción `AnalyticsService` de `core/`. Domain inyecta solo la abstracción; sin `BuildContext` en data/domain.
6. **Test por feature con mock**: al menos un call site por feature (vehículo, mantenimiento, perfil, notificaciones) tiene un test que verifica, con un mock de `AnalyticsService`, que se emite el evento esperado con los params esperados y sin PII.
7. **Sin UI / sin regresión**: no se añaden ni modifican pantallas, copys ni flujos; el comportamiento funcional de los seis features es idéntico al previo (los tests existentes siguen verdes).
8. **Gating respetado**: con la no-op impl + `setEnabled(false)`, `flutter test` no intenta enviar eventos reales; `dart analyze` limpio; en `kDebugMode` no se reporta a la consola (heredado de fase 1).
9. **Nice-to-have no bloquea**: la fase cierra con los obligatorios aunque archivar vehículo, editar/borrar mantenimiento, borrar SOAT y detalle de descubrimiento queden sin instrumentar; si se instrumentan, también cumplen G1/G2.

## Pruebas (unitarias/widget/integracion)

- **Unitarias (obligatorias, una por feature)** con mock de `AnalyticsService` (`mocktail`/`mockito` según convención del repo):
  - Vehículos: `VehicleFormCubit` con creación exitosa → verifica `vehicle_added` (y `vehicle_updated` en edición); opcional `VehicleCubit.setMainVehicle` → `vehicle_set_main`.
  - Mantenimiento: `MaintenanceFormCubit.saveMaintenance` exitoso → `maintenance_added` con `maintenance_type` agregado, sin notas libres.
  - Perfil: `ProfileCubit.fetchProfile` resuelto → `profile_viewed`, sin email/nombre en params.
  - Notificaciones: `NotificationsCubit.markRead` → `notification_marked_read`; verificar que cargar el listado NO emite `notification_opened` (distinción recibida vs abierta).
- **Unitaria de privacidad (recomendada)**: un test parametrizado que captura los params emitidos por los call sites de la fase y asserta que ninguna clave/valor contiene patrones PII (placa/VIN/email/id) — refuerza G2 antes de la auditoría de la fase 10.
- **Widget / integración**: no se requieren (cero-UI). Reusar la suite existente de los features como red de seguridad de no-regresión.
- **Gating en CI**: confirmar que la suite corre con la no-op impl registrada (fase 1) y `setEnabled(false)`.

## Riesgos y mitigaciones

1. **Fase que no cierra por exceso de features (seis dominios).** *Mitigación*: alcance mínimo obligatorio explícito vs nice-to-have (este documento); el cierre depende solo de los obligatorios y de un test por feature.
2. **PII de alto riesgo (placa, VIN, aseguradora, póliza, id de rider).** *Mitigación*: G2 como criterio de aceptación, test de privacidad, "ids canónicos/agregados, nunca el valor dinámico"; reforzado por la auditoría de la fase 10.
3. **Confundir recibida con abierta en notificaciones** (doble conteo o métrica engañosa). *Mitigación*: solo instrumentar abrir/marcar leída; criterio 3 verifica que el listado no emite apertura.
4. **Re-instrumentar el scan de SOAT** ya migrado en la fase 2 (eventos duplicados). *Mitigación*: alcance lo excluye; aquí solo `soat_status_viewed`/`soat_manual_saved` reutilizando constantes existentes.
5. **Strings mágicos por prisa** (violación G1). *Mitigación*: paso 1 añade primero las constantes al catálogo; grep G1 en aceptación.
6. **Violación de capa al instrumentar desde data/`BuildContext`.** *Mitigación*: regla G0 de fase 1; instrumentar en use case/cubit, nunca en repository ni con context.
7. **DI desincronizada tras nuevas inyecciones.** *Mitigación*: `build_runner build --delete-conflicting-outputs` + `dart analyze` antes de cerrar.
8. **Inyectar `AnalyticsService` en `RegisterFcmTokenUseCase`** podría alterar su firma de DI. *Mitigación*: añadir como dependencia de constructor estándar `@injectable`; regenerar DI; el evento es best-effort (no debe bloquear el registro del token).

## Dependencias (fases prerequisito y por que)

- **Fase 1 — Fundaciones, captura de crashes, gating y regla de capa (G0).** Provee la abstracción `AnalyticsService` ampliada, la no-op impl para tests, el gating (`setEnabled(false)` + handlers no-report en debug) y la regla de capa que legitima inyectar la abstracción en domain/presentation. Sin ella, los call sites no tendrían dónde apoyarse ni gating verificable.
- **Fase 2 — Taxonomía centralizada, mapa de rutas y límites GA4.** Provee el catálogo único de constantes (a donde se añaden los nombres de esta fase) y la convención de límites/no-PII que esta fase reutiliza para cumplir G1 y los límites GA4. Sin ella, los call sites usarían literales (violación G1).
- **No depende de la fase 3** (screen_view): esta fase instrumenta acciones de dominio, no recorrido de pantallas; el `rider_profile_viewed`/`profile_viewed` son hitos de carga de datos, no `screen_view` automáticos.
