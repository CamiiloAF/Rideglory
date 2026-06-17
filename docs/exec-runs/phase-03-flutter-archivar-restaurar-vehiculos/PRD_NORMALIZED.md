# PRD Normalizado — Fase 3: Flutter — Archivar y restaurar vehículos

_Generado: 2026-06-16T22:39:53Z_
_Fuente: docs/plans/archive-vehicle-soft-delete/phases/phase-03-flutter-archivar-y-restaurar-vehiculos.md_

---

## 1 Objetivo

Permitir que el usuario mueva un vehículo al archivo desde el garaje activo y lo restaure desde la sección de archivados, sin re-fetch HTTP, conservando la coherencia local del vehículo principal. Todo el flujo ocurre en la misma sesión sin navegar ni recargar la página.

---

## 2 Por qué

El backend ya soporta `isArchived` y los use cases `ArchiveVehicleUseCase`/`UnarchiveVehicleUseCase` están listos (Fase 1 completada). El diseño Pencil fue aprobado por el PO (Fase 2 completada). Esta fase cierra la brecha de UI/cubit que expone la funcionalidad al usuario final. Sin ella, los vehículos archivados no son visibles ni accionables desde la app.

---

## 3 Alcance

**Entra:**
- Renombrar `VehicleDeleteCubit`/`VehicleDeleteState` → `VehicleActionCubit`/`VehicleActionState` (estado freezed unificado con variantes `archiveSuccess` y `unarchiveSuccess`; variante `success` conservada sin renombrar para no romper consumidores).
- Métodos `archiveVehicle` y `unarchiveVehicle` en `VehicleActionCubit` con invocación real de use cases vía `Either`.
- Métodos `archiveLocally(String id)` y `unarchiveLocally(String id)` en `VehicleCubit` con lógica de promoción de vehículo principal (`_promoteNewMain`).
- Bifurcación de `GarageOptionsBottomSheet` por `vehicle.isArchived`: activos muestran "Marcar como principal" (condicional), "Editar", "Agregar mantenimiento", "Archivar" (sin "Eliminar"); archivados muestran únicamente "Restaurar".
- Diálogo de confirmación de archivado (tono informativo, CTA en primario con texto oscuro).
- Nuevos widgets `GarageArchivedHeader` y `GarageArchivedSection` (cada uno en su propio archivo).
- Integración de `GarageArchivedSection` en `GarageVehiclesContent`.
- Actualización de `vehicle_unarchiveVehicle` en `app_es.arb` de "Desarchivar" a "Restaurar"; añadir 8 claves l10n nuevas.
- Eventos de analytics `vehicleArchived` y `vehicleUnarchived`.
- Widget tests para `GarageArchivedSection` (5 tests) y tests unitarios recomendados para `archiveLocally`/`_promoteNewMain`.
- `dart analyze` y `flutter test` en verde.

**No entra:**
- Eliminación permanente (Fase 4).
- Nuevos endpoints HTTP (usa `PATCH /api/vehicles/:id` existente).
- Cambios en el backend.
- Diseño Pencil (Fase 2, prerrequisito ya completado).
- Fix de `HomeLoaded.mainVehicle` stale (Fase 5, independiente).
- Renombrado de `VehicleRepository.deleteVehicle` → `permanentlyDeleteVehicle` (Fase 4).
- Modo read-only de detalle de vehículo archivado (implementación de badge "Archivado", ocultamiento de botón Editar, FAB, acciones de mantenimiento, y lógica de SOAT/RTM sin indicadores de estado).

---

## 4 Áreas afectadas

| Área | Archivos principales |
|------|---------------------|
| l10n | `lib/l10n/app_es.arb`, `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_es.dart` |
| Cubit de acción (scoped) | `lib/features/vehicles/presentation/delete/cubit/vehicle_action_cubit.dart` (ex `vehicle_delete_cubit.dart`), `vehicle_action_state.dart`, `vehicle_action_cubit.freezed.dart` |
| Cubit global de vehículos | `lib/features/vehicles/presentation/cubit/vehicle_cubit.dart` |
| Widgets de garaje | `lib/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet.dart`, `garage_vehicles_content.dart` |
| Nuevos widgets | `lib/features/vehicles/presentation/garage/widgets/garage_archived_header.dart`, `garage_archived_section.dart` |
| Formulario de vehículo | `lib/features/vehicles/presentation/form/widgets/vehicle_form_view.dart` |
| Analytics | `lib/core/services/analytics/analytics_events.dart` |
| Tests | `test/features/vehicles/presentation/garage/widgets/garage_archived_section_test.dart` |

---

## 5 Criterios de aceptación

1. Al archivar un vehículo activo, desaparece de la lista activa y aparece bajo "Archivados (N)" en la misma sesión, sin navegación ni reload de página.
2. Al restaurar un vehículo archivado, vuelve a la lista activa de inmediato, **sin re-fetch HTTP** (`fetchMyVehicles` no se invoca en el flujo de restaurar).
3. El contador "(N)" en el header de la sección archivados refleja en todo momento el número real de vehículos con `isArchived: true` en el estado local de `VehicleCubit`.
4. Si el vehículo archivado era el principal (`isMainVehicle: true`), `VehicleCubit.archiveLocally` promueve automáticamente el siguiente vehículo activo según el criterio: activos no archivados ordenados por `createdAt` desc (nulls al final), tie-break por `id` lexicográfico asc. Esto ocurre antes de emitir el nuevo estado, de modo que la UI refleja el nuevo main de inmediato.
5. El wiring de `onArchive`/`onUnarchive` se realiza en `GarageVehiclesContent`/`GarageOptionsBottomSheet`. `VehicleCard` solo recibe y ejecuta los callbacks — no llama use cases ni cubits directamente.
6. `GarageArchivedSection` y `GarageArchivedHeader` son widgets en archivos propios (un widget por archivo, sin métodos privados que retornen widgets).
7. La sección "Archivados" no se renderiza cuando no hay vehículos archivados (`archivedVehicles.isEmpty` → `SizedBox.shrink()`).
8. "Editar" y "Agregar mantenimiento" no aparecen en el menú contextual de vehículos archivados.
9. El `ListTile` de "Eliminar" no aparece en el menú contextual de vehículos activos (reemplazado por "Archivar").
10. Todos los textos de UI (labels de menú, header de sección, mensajes del diálogo, snackbars) provienen de claves `l10n` — cero strings hardcodeados.
11. `dart analyze` pasa en verde (excluido el lint conocido de `api_base_url_resolver.dart`).
12. `flutter test` pasa en verde.
13. **[Tests mínimos verificables]** Existen widget tests para `GarageArchivedSection` que cubren: (a) estado vacío — sección no renderizada, (b) estado colapsado con contador correcto, (c) estado expandido listando los vehículos archivados. Existen tests para el diálogo de confirmación de archivado: (d) flujo confirmar dispara `archiveVehicle`, (e) flujo cancelar no dispara `archiveVehicle`.

---

## 6 Guardrails de regresión

- **No re-fetch HTTP en flujo de archive/unarchive:** `fetchMyVehicles` / `loadVehicles` no deben invocarse como efecto de archivar o restaurar. El `onGarageListUpdatedLocally` en `GarageArchivedSection` se pasa como `null`.
- **Variante `success` en `VehicleActionState` intacta:** no renombrar a `deleteSuccess` ni cambiar su firma `({required String deletedId})`; los consumidores `vehicle_form_view.dart` y `garage_options_bottom_sheet.dart` dependen de ella sin modificación.
- **`VehicleActionCubit` no puede ser singleton:** instanciado con `getIt<VehicleActionCubit>()..reset()` al abrir el bottom sheet. Declarado `@injectable`, no `@singleton`.
- **No romper `deleteVehicle` en `VehicleActionCubit`:** el método permanece sin cambios porque `vehicle_form_view.dart` lo sigue invocando desde la pantalla de edición.
- **Un widget por archivo:** `GarageArchivedHeader` y `GarageArchivedSection` deben vivir en archivos separados. La excepción `State<GarageArchivedSection>` puede coexistir en el mismo archivo que `GarageArchivedSection`.
- **Cero strings hardcodeados en UI:** toda cadena visible pasa por `app_es.arb` y `context.l10n`.
- **`dart analyze` verde** al finalizar (excluyendo el lint conocido de `api_base_url_resolver.dart` documentado en MEMORY.md).
- **`flutter test` verde** al finalizar, incluyendo los nuevos widget tests.

---

## 7 Constraints heredados

- **Prerequisito bloqueante:** Fase 2 (diseño Pencil) debe tener aprobación explícita del PO antes de tocar código. Sin esa aprobación, no iniciar el Paso 1.
- **Arquitectura Clean:** `VehicleCubit` y `VehicleActionCubit` pertenecen a la capa de presentación. No pueden importar DTOs ni llamar servicios HTTP directamente.
- **BLoC/Cubit vía `BlocProvider`:** cubits van `@injectable` + `BlocProvider` en el árbol; nunca `@singleton` / `getIt.get()` para los cubits de UI.
- **Diseñar antes de implementar (regla de proyecto):** UI nueva requiere aprobación en Pencil primero (ya satisfecha por Fase 2).
- **DTO Pattern B:** no aplica directamente en esta fase (sin DTOs nuevos); los use cases existentes ya cumplen el patrón.
- **Leer Pencil antes de tocar widgets** (regla MEMORY.md): si se duda de algún detalle visual, consultar el frame correspondiente en Pencil antes de implementar.
- **Build runner con `--force-jit`** si se ejecuta en un entorno fresco o worktree (MEMORY.md `project_build_runner_force_jit`).
- **API local hack en `api_base_url_resolver.dart`:** `shouldUseLocalApi=true` no debe commitearse ni revertirse; ignorar sus 2 lints conocidos.
- **Texto oscuro sobre primario:** sobre el acento naranja (`#f98c1f`), texto/iconos/knob/badge van con `darkBgPrimary`/`onPrimary`, nunca blanco.
- **No commitear:** el árbol de trabajo queda sucio a propósito; el humano commitea tras revisar.
