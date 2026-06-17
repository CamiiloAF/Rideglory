# PRD Normalizado — Flutter: Eliminación Permanente desde Archivados

_Generado: 2026-06-17T17:03:21Z_
_Fuente: docs/plans/archive-vehicle-soft-delete/phases/phase-04-flutter-eliminacion-permanente-desde-archivados.md_
_Slug: flutter-permanent-delete-vehicle_

---

## 1 Objetivo

Habilitar la eliminación definitiva de vehículos archivados directamente desde el menú contextual del garaje (`GarageOptionsBottomSheet`). La acción requiere confirmación explícita con tono destructivo (mostrando el nombre del vehículo y describiendo la irreversibilidad), está protegida contra doble-tap mediante un guard en el cubit, y al completarse hace un re-fetch completo de la lista via `VehicleCubit.fetchMyVehicles()`. El formulario de edición pierde su botón de eliminar (ahora superfluo). Se renombra toda la capa `deleteVehicle` → `permanentlyDeleteVehicle` para expresar la semántica correcta.

---

## 2 Por qué

El flujo anterior permitía eliminar vehículos desde el formulario de edición sin distinguir entre activos y archivados, usando una ruta Retrofit obsoleta (`hard-delete/:id`). La arquitectura de soft-delete introducida en Fase 1 requiere que la eliminación permanente sea exclusiva para vehículos archivados y use el endpoint `DELETE /api/vehicles/my/:vehicleId`. Centralizar esta acción en el garaje (donde el estado archivado es visible) elimina ambigüedad para el usuario y simplifica el árbol de widgets del formulario.

---

## 3 Alcance

### Entra

- Renombrar `VehicleRepository.deleteVehicle` → `permanentlyDeleteVehicle` en: interfaz de dominio, implementación del repositorio, use case (archivo + clase), y `VehicleDeleteCubit` (método).
- Eliminar el parámetro `availableVehicles` de la firma del método del cubit; reemplazar `deleteVehicleLocally` por `fetchMyVehicles()` en el branch de éxito.
- Reemplazar la declaración Retrofit `deleteVehicle` (ruta `hard-delete`) por `permanentlyDeleteVehicle` con `@DELETE('${ApiRoutes.myVehicles}/{id}')`.
- Añadir guard anti doble-tap en el cubit: si ya está en `loading`, retornar inmediatamente sin emitir.
- Conectar tile "Eliminar permanentemente" en `GarageOptionsBottomSheet`, visible únicamente cuando `vehicle.isArchived == true`.
- Usar `ConfirmationDialog` con `confirmType: DialogActionType.danger` para el diálogo destructivo.
- Eliminar el punto de entrada de eliminación del formulario (cadena de 4 archivos): `VehicleFormCta`, `VehicleFormBody`, `VehicleFormView`, `VehicleFormPage`.
- Añadir 5 claves nuevas en `lib/l10n/app_es.arb` y regenerar localización.
- Crear widget tests para el diálogo destructivo, el guard anti doble-tap y el flujo de cancelar.
- Regenerar código con `build_runner` y `flutter gen-l10n` en los puntos correspondientes.

### No entra

- Eliminar vehículos activos (no archivados).
- Cambios en el backend (Fase 1).
- Diseño de nuevos frames en Pencil (Fase 2).
- Lógica de archivar / restaurar (Fase 3).
- Eliminación del alias `hard-delete/:id` en el gateway (coordinación de despliegue de Fase 1).
- Cambios en `HomeGarageSection` ni en `HomeCubit` (Fase 5).
- Deprecación formal de claves l10n sin consumidores (`vehicle_vehicleDeleted`, `vehicle_deleteVehicle`, `vehicle_form_delete_vehicle`): solo verificar con grep y documentar.
- Nuevas dependencias de `pubspec.yaml`.

---

## 4 Áreas afectadas

| Capa | Archivos principales |
|------|---------------------|
| **l10n** | `lib/l10n/app_es.arb`, `app_localizations.dart`, `app_localizations_es.dart` |
| **Dominio** | `lib/features/vehicles/domain/repository/vehicle_repository.dart`, `lib/features/vehicles/domain/usecases/delete_vehicle_usecase.dart` → renombrar a `permanently_delete_vehicle_usecase.dart` |
| **Data** | `lib/features/vehicles/data/repository/vehicle_repository_impl.dart`, `lib/features/vehicles/data/service/vehicle_service.dart`, `vehicle_service.g.dart` (auto-generado) |
| **Presentation — cubit** | `lib/features/vehicles/presentation/delete/cubit/vehicle_delete_cubit.dart`, `vehicle_delete_cubit.freezed.dart` (auto-generado) |
| **Presentation — UI garaje** | `lib/features/vehicles/presentation/garage/widgets/garage_options_bottom_sheet.dart` |
| **Presentation — UI form** | `lib/features/vehicles/presentation/form/widgets/vehicle_form_cta.dart`, `vehicle_form_body.dart`, `widgets/vehicle_form_view.dart`, `vehicle_form_page.dart` |
| **DI** | `lib/core/di/injection.config.dart` (auto-generado) |
| **Tests** | `test/features/vehicles/presentation/delete/vehicle_permanent_delete_dialog_test.dart` (nuevo) |

---

## 5 Criterios de aceptación

1. **Visibilidad contextual:** La opción "Eliminar permanentemente" aparece en `GarageOptionsBottomSheet` únicamente cuando `vehicle.isArchived == true`. Los vehículos activos no ven esta opción. El formulario de edición no tiene botón de eliminar.

2. **Diálogo destructivo:** El `ConfirmationDialog` usa `confirmType: DialogActionType.danger` (activa `AppModalVariant.destructive` — icono y CTA en `colorScheme.error`, texto `onError`). El título es `vehicle_permanentDeleteTitle`, el cuerpo contiene el nombre del vehículo via `vehicle_permanentDeleteMessage(vehicle.name)`, el CTA dice `vehicle_permanentDeleteAction`.

3. **Flujo de confirmación:** Al confirmar, se llama `deleteCubit.permanentlyDeleteVehicle(vehicle.id!)` sin pasar `availableVehicles`. Al cancelar, no se llama ningún método del cubit ni del repositorio.

4. **Anti doble-tap (guard en cubit):** Si `permanentlyDeleteVehicle` es invocado mientras el cubit ya está en `VehicleDeleteState.loading()`, el método retorna inmediatamente sin emitir ni llamar al use case. El Test B aserta este comportamiento: dos llamadas consecutivas → el use case se invoca exactamente una vez.

5. **Re-fetch tras éxito:** Tras recibir `VehicleDeleteState.success`, el cubit llama `await _vehicleCubit.fetchMyVehicles()` (re-fetch completo). El vehículo eliminado desaparece de la sección "Archivados" en la misma sesión.

6. **Snackbar de éxito:** Se muestra un `SnackBar` con el texto de `vehicle_permanentDeleteSuccess` y `backgroundColor: AppColors.success`. La clave `vehicle_vehicleDeleted` deja de tener consumidores tras esta fase.

7. **Snackbar de error:** Si el cubit emite `VehicleDeleteState.error`, se muestra un `SnackBar` con el mensaje de error y `backgroundColor: colorScheme.error`.

8. **Contrato Retrofit:** `VehicleService.permanentlyDeleteVehicle` apunta a `DELETE /vehicles/my/{id}`. No existe ninguna referencia a la ruta `hard-delete` en el código Flutter compilable tras esta fase.

9. **Renombrado completo:** El grep `grep -rn 'deleteVehicle\|DeleteVehicleUseCase' lib/ --include='*.dart' | grep -v '\.g\.dart\|\.freezed\.dart'` devuelve cero hits. `dart analyze` pasa sin errores.

10. **Tests en verde:** `flutter test` pasa sin errores, incluyendo los nuevos widget tests (Test A: nombre del vehículo visible en el diálogo; Test B: guard anti doble-tap; Test C: cancelar no dispara eliminación).

11. **Strings l10n:** Ninguna string visible del usuario está hardcodeada. Todas usan `context.l10n.<clave>`.

12. **Form limpio:** `VehicleFormPage` no registra `BlocProvider<VehicleDeleteCubit>`. `VehicleFormBody` y `VehicleFormCta` no declaran `onDelete`. El form compila sin errores.

---

## 6 Guardrails de regresión

- **Gate de entrada (Paso 0):** Verificar que el endpoint `DELETE /api/vehicles/my/:vehicleId` (Fase 1) está disponible antes de tocar código. Si el endpoint no responde, detener la fase.
- **Pre-flight grep:** Ejecutar `grep -rn 'deleteVehicle\|DeleteVehicleUseCase\|availableVehicles' lib/ --include='*.dart' | grep -v '\.g\.dart\|\.freezed\.dart'` antes de implementar y verificar que los únicos hits son los archivos listados en la tabla de archivos a modificar.
- **grep de verificación post-implementación (Paso 7):** Cero hits de `deleteVehicle` ni `DeleteVehicleUseCase` en código compilable.
- **No romper vehículos activos:** Los tiles "Editar", "Agregar mantenimiento" y "Archivar" deben seguir funcionando para vehículos activos. El menú debe ser mutuamente excluyente (`!isArchived` / `isArchived`).
- **No navegación fantasma:** Confirmar que la eliminación de `_deleteListener` (que ejecutaba `context.goAndClearStack(AppRoutes.garage)`) no introduce una regresión: la eliminación ahora ocurre desde el garaje, no desde el formulario, por lo que esa navegación ya no aplica.
- **Clean Architecture:** Dominio sin imports Flutter; data sin `BuildContext`; presentación sin DTOs ni llamadas HTTP directas.
- **Un widget por archivo:** No introducir métodos que retornen widgets en los archivos modificados.
- **`dart analyze` en cero errores** antes de cerrar la fase.
- **`flutter test` en verde** incluyendo los tres nuevos widget tests.

---

## 7 Constraints heredados

- **Strings l10n:** Cero tolerancia a strings hardcodeadas en UI. Todas las cadenas visibles en `app_es.arb` + `context.l10n.<clave>`.
- **Switches:** No relevante en esta fase (no hay switches nuevos).
- **Texto oscuro sobre acento naranja:** No relevante en esta fase (el diálogo destructivo usa `colorScheme.error`, no el acento primario).
- **`ConfirmationDialog` ya soporta `DialogActionType.danger`:** No hay trabajo nuevo en shared widgets.
- **`parentContext.mounted` guard:** Verificar `!parentContext.mounted` tras el `await ConfirmationDialog.show` antes de invocar el cubit.
- **Retrofit write payloads via DTO `.toJson()`:** En esta fase el DELETE no tiene body; no aplica.
- **`build_runner --force-jit`:** Usar `dart run build_runner build --delete-conflicting-outputs` con `--force-jit` si el entorno es un worktree fresco o falla por build hooks de `objective_c`.
- **Commit por fase:** El workflow no commitea. El humano revisa el working tree y commitea al aprobar.
- **`docs/plans/` y código son de solo lectura para el normalizador:** El implementador puede modificar `lib/` y `test/`; nunca tocar `docs/plans/`, `.claude/` ni archivos de configuración global.
- **Dependencias de fases prerequisito:** Fase 1 (endpoint backend) y Fase 3 (bifurcación de menú en `GarageOptionsBottomSheet`) deben estar completadas antes de ejecutar esta fase.
