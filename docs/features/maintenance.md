# Maintenance

> Reescrito para v2 (F6). Reemplaza `maintenance.md` de la v1.

## Problema que resuelve

"El mejor problema del set" (P-02) según `docs/product/ALCANCE-V2.md`: historial de mantenimiento (servicio, fecha, odómetro, costo, taller, notas). Es la pestaña de entrada de la app (decisión D4 del 2026-08-19): único feature con uso real y recurrente, y el que reemplazó al Home eliminado. También resuelve **P-15 (el odómetro)**: el estado "próximo servicio" no puede depender de un número que solo se actualiza cuando ya no hace falta el aviso — de ahí la decisión D5 (odómetro derivado).

## Flujos

- **Agenda + historial en una pantalla** (`MaintenancePage`): agenda derivada arriba (qué está vencido/por vencer), historial agrupado por mes abajo, con filtro por moto y por estado.
- **Registrar en 3 pasos** (`RegisterMaintenancePage`): tipo (con sugerencias: cambio de aceite, llantas, pastillas de freno, kit de arrastre, revisión general, otro) → datos (fecha, odómetro, taller, costo, notas) → recordatorio (por kilometraje y/o por fecha). Sirve tanto para crear como para editar.
- **Odómetro derivado (D5)**: la RPC `register_maintenance` inserta el mantenimiento **y** actualiza `vehicles.current_mileage` de forma atómica, solo si el odómetro reportado es mayor al actual. Al editar, el mismo criterio se aplica pero en dos pasos no atómicos (`update` + `update ... where current_mileage < odometer`) — nunca retrocede el odómetro al editar.
- **Agenda derivada, no un campo aparte**: `MaintenanceAgendaCalculator.compute()` (puro, con unit tests) compara para cada moto+tipo el último registro con recordatorio contra el kilometraje y la fecha actuales, y clasifica en `overdue` / `dueSoon` (≤30 días) / `upcoming`. Cuando ambos umbrales (km y fecha) aplican, gana el más severo; en empate gana kilometraje, por ser verificable al instante en el odómetro.
- **Detalle con "anteriores"**: `MaintenanceDetailPage` muestra hasta 3 registros anteriores del mismo tipo y moto, con expansor "ver más".
- **Recordatorio local**: notificación local (no push) programada solo si el mantenimiento tiene `nextDate` (los recordatorios puramente por kilometraje no generan notificación local — no hay forma de "despertar" la app para verificar el odómetro sin GPS ni red). Se cancela y reprograma en cada edición, y se cancela al borrar.

## Pantallas (Pencil)

| Pantalla | Archivo | Pencil |
|---|---|---|
| Agenda + historial | `presentation/pages/maintenance_page.dart` | `V3B6C` (header `ViTPl`, chip de filtro `Id49n`) |
| Detalle de mantenimiento | `presentation/pages/maintenance_detail_page.dart` | `b8WMj1` |
| Registrar (3 pasos) | `presentation/pages/register_maintenance_page.dart` | `Yhgp2` / `x74Sa` / `g3rONd` (pasos: `oMSFa`, `ljdLM`, `B8OGu`) |

Frames adicionales referenciados en el commit de F6 pero sin página propia identificada 1:1: `W7VSyz`, `Tdnlr`, `D9ImJl`, `kDrlb`, `wuUsj`, `PPgFL`, `mgxIO`, `Z6b3T` (resumen de recordatorio), `eRpHn` (hoja de confirmación de borrado).

## Datos

- Tabla `maintenances`: `vehicle_id, type, service_date, odometer, cost, workshop, notes, next_date, next_odometer`. El datasource incrusta `vehicles(name, brand, model)` en el mismo `select` para evitar N+1.
- Tabla `vehicles`: solo lectura de `id, name, brand, model, license_plate, current_mileage, is_main` (filtra archivadas) — mantenimiento no depende del feature `garage`, lee la tabla directamente.
- **RPC `register_maintenance`** (`p_vehicle_id, p_type, p_service_date, p_odometer, p_cost, p_workshop, p_notes, p_next_date, p_next_odometer`): inserta el registro y actualiza el odómetro en una sola llamada atómica — es el mecanismo real detrás de D5. Migración: `supabase/migrations/20260909000019_register_maintenance.sql`.
- Sin Edge Functions propias.

## Estados

`MaintenanceCubit`: `MaintenanceState` con dos `ResultState` independientes (`vehicles`, `maintenances`) más filtros locales (`selectedVehicleId`, `statusFilter`) y listas derivadas (`agendaItems`, `historyGroups`) calculadas del estado, no almacenadas por separado. `MaintenanceDetailCubit`: `maintenance`, `allMaintenances: ResultState<List<Maintenance>>`, `deletion: ResultState<Unit>`. `RegisterMaintenanceCubit`: estado freezed propio con el paso del asistente y una `submission: ResultState<Maintenance>` embebida.

Obligatorios: skeleton (`SkeletonList`), vacío (`EmptyStateView`), error con reintentar (`ErrorStateView`), sin conexión (`OfflineStateView`, gateado por `ConnectivityCubit`). Sin permiso de ubicación / sin GPS no aplican: mantenimiento no depende de ubicación.

## Pendientes

- Ninguna nota `TODO`/`FIXME`/pendiente encontrada en el código de esta feature.
- La actualización de odómetro al editar un mantenimiento no es atómica con el `update` del registro (dos llamadas separadas) — a diferencia de crear, que sí lo es vía RPC. Riesgo bajo (ambas tocan la misma fila y la segunda es idempotente), pero documentado para no asumir paridad con el flujo de creación.
