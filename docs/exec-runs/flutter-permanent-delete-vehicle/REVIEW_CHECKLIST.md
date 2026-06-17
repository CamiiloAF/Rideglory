# REVIEW_CHECKLIST — flutter-permanent-delete-vehicle

_Generado: 2026-06-17T17:40:07Z_

Pasos manuales a completar **antes de commitear**:

---

## Verificación automatizada

- [ ] `dart analyze lib/` — debe producir 0 errores (solo los 3 infos pre-existentes son aceptables).
- [ ] `flutter test` — 548+ passed; los 2 fallos conocidos (TC-bs-1/TC-bs-2) son pre-existentes y no bloqueantes.
- [ ] `flutter test test/features/vehicles/presentation/delete/` — los 3 nuevos tests (TC-perm-A/B/C) deben pasar.
- [ ] `grep -rn 'deleteVehicle\|DeleteVehicleUseCase\|VehicleDeleteCubit\|deleteVehicleLocally' lib/ --include='*.dart' | grep -v '\.g\.dart\|\.freezed\.dart'` → debe devolver **0 hits** en código compilable (solo l10n keys obsoletas sin consumidores son aceptables).
- [ ] `grep -rn 'hard-delete' lib/ --include='*.dart'` → 0 hits.

---

## Verificación manual (requiere backend Fase 1 activo)

- [ ] **M-1:** Tap en vehículo ACTIVO → opciones. NO aparece "Eliminar permanentemente".
- [ ] **M-2:** Tap en vehículo ARCHIVADO → opciones. SÍ aparece "Eliminar permanentemente" (icono trash rojo).
- [ ] **M-3:** Confirmar eliminación → vehículo desaparece de sección Archivados; snackbar verde "Vehículo eliminado permanentemente".
- [ ] **M-4:** Cancelar el diálogo → bottom sheet sigue visible, vehículo intacto.
- [ ] **M-5:** Vehículo activo → Editar, Agregar mantenimiento, Archivar funcionan normalmente.
- [ ] **M-6:** Vehículo archivado → "Restaurar" funciona y regresa a activos.
- [ ] **M-7:** Abrir formulario de edición → sin botón "Eliminar vehículo".
- [ ] **M-8:** Forzar error de red → snackbar rojo con mensaje de error al intentar eliminar.

---

## Notas de historial de commit

Los cambios out-of-scope (useRootNavigator en 8 bottom sheets, autofill en AppTextField, fix validación de fechas SOAT/RTM, CI workflows) son benignos pero conviene valorar si van en el mismo commit o en commits separados para claridad de historial.
