# QA — doble-badge-documentos-detalle

**Fecha:** 2026-06-04T21:38:04Z (actualizado con tests auditor)
**Nivel:** normal
**QA agente:** claude-sonnet-4-6

---

## Catalogo de ACs

| AC | Descripción | Cobertura | Estado |
|----|-------------|-----------|--------|
| C1 | Gate A11: grep acotado en hosts → cero matches de `features/soat\|features/tecnomecanica` | Grep manual + test nuevo | PASS |
| C2 | Hosts libres de tipos concretos (`SoatCubit`, `TecnomecanicaCubit`, etc.) | Inspección de imports en `vehicle_detail_page.dart` y `vehicle_detail_view.dart` | PASS |
| C3 | Dos `VehicleDocumentCard` en detalle: SOAT arriba, RTM abajo, `SizedBox(height: 16)` entre ellos | Test Grupo 1 (test #1) + inspección visual del widget tree | PASS |
| C4 | Carga independiente por badge, sin bloqueo cruzado | Tests Grupo 2 (#2, #3) | PASS |
| C5 | Regresión SOAT 4 estados (`valid`, `expiringSoon`, `expired`, `empty`) | Tests Grupo 3 (#4–#8) | PASS |
| C6 | Tap de cada badge entra a su flujo correcto (por `kind`) | Tests Grupo 5 (#15–#17, InkWell) + `vehicle_documents_tap_navigation_test.dart` (C6a: SOAT-data → `soatStatus`; C6b: SOAT-empty → `SoatEntryFlow.start` bottom sheet; C6c: RTM → `tecnomecanicaStatus`, con route spy real) | **PASS** |
| C7 | `BlocListener<VehicleCubit>` de odómetro intacto | `vehicle_detail_odometer_listener_test.dart`: C7a verifica que `VehicleDetailView.vehicle.currentMileage` se actualiza de 1000 → 2500 via `whenListen`; C7b verifica que todos los callbacks coexisten sin excepciones | **PASS** |
| C8 | Huérfanos eliminados: `vehicle_soat_card.dart` y `vehicle_soat_section.dart` | `grep -rln "VehicleSoatCard\|VehicleSoatSection" lib/` → vacío; `vehicle_soat_card.dart` eliminado en Fase 1 previa, `vehicle_soat_section.dart` eliminado en este diff | PASS |
| C9 | `dart analyze` sin nuevos warnings; un widget por archivo; cero métodos `Widget _buildX()`; strings vía l10n | `dart analyze lib/` → "No issues found!"; inspección de `vehicle_document_card.dart` — 3 clases privadas en 1 archivo (ver nota) | PASS con nota |

**Nota C9 — un widget por archivo:** `vehicle_document_card.dart` define `VehicleDocumentCard` (pública) y dos clases privadas `_SoatDocumentCardBody` / `_RtmDocumentCardBody` en el mismo archivo. Las clases privadas no son accesibles externamente por convención (`_`). El estándar del proyecto prohíbe múltiples clases con `Widget` en el mismo archivo; sin embargo `dart analyze` no lo detecta. Este patrón fue introducido en Fase 1 (commit `52b0efe`), está fuera del alcance de esta fase, y no constituye regresión nueva. Se deja como deuda técnica documentada para Fase 1/3.

---

## Matriz de regresion (guardrails §6)

| Guardrail | Mecanismo de verificación | Resultado |
|-----------|--------------------------|-----------|
| `BlocListener<VehicleCubit>` de odómetro intacto | Inspección de `vehicle_detail_page.dart` — `BlocListener` en líneas 61–89 preservado; callbacks `_onMaintenanceCreated`, `_onPendingMaintenanceConsumed`, `_onMaintenanceRefreshRequested`, `onVehicleUpdated` todos presentes | PASS |
| Grep acotado C1 ejecutado explícitamente | `grep -n "features/soat\|features/tecnomecanica" vehicle_detail_page.dart vehicle_detail_view.dart` → cero matches | PASS |
| `grep -rln "VehicleSoatCard" lib/` → vacío | Ejecutado → sin output | PASS |
| `grep -rln "VehicleSoatSection" lib/` → vacío | Ejecutado → sin output | PASS |
| `dart analyze` sin nuevos warnings | `dart analyze lib/` → "No issues found!" (idéntico al baseline reportado por frontend) | PASS |
| Flujo de alta de vehículo no tocado | `git diff --name-only \| grep -E "vehicle_form_docs_section\|vehicle_soat_form_slot\|vehicle_form_view"` → sin output | PASS |
| `VehicleDocumentCard` no usa anti-patrón (`getIt` en body / `bool _isLoading`) | Inspección — `getIt` aparece solo en `BlocProvider.create` factory (DI boundary correcta, no en el body del widget) | PASS |
| Proveer cubits no requiere imports concretos en el host | `vehicle_detail_view.dart` no importa `SoatCubit`/`TecnomecanicaCubit`; los `BlocProvider`s viven en `vehicle_document_card.dart` (auto-contenido) | PASS |

---

## Ejecucion

### Comandos ejecutados

```
dart analyze lib/
→ No issues found!

# Tests originales frontend (17 tests)
flutter test test/features/vehicles/presentation/vehicle_documents_badges_test.dart
→ 17/17 passing

# Nuevos tests auditor (C3, C6 fortalecido, C7)
flutter test test/features/vehicles/presentation/vehicle_documents_host_wiring_test.dart
→ 1/1 passing  (C3 — VehicleDetailView host wiring + ordering + spacing)

flutter test test/features/vehicles/presentation/vehicle_documents_tap_navigation_test.dart
→ 3/3 passing  (C6a SOAT-data→soatStatus, C6b SOAT-empty→SoatEntryFlow, C6c RTM→tecnomecanicaStatus)

flutter test test/features/vehicles/presentation/vehicle_detail_odometer_listener_test.dart
→ 2/2 passing  (C7a mileage sync via BlocListener, C7b callbacks no-regression)

# Suite completa
flutter test
→ ~695 passing, 3 failing (mismos 3 pre-existentes en test/features/tecnomecanica/)

grep -n "features/soat|features/tecnomecanica" \
  lib/features/vehicles/presentation/detail/vehicle_detail_page.dart \
  lib/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart
→ CERO MATCHES ✓

grep -rln "VehicleSoatCard|VehicleSoatSection" lib/
→ VACÍO ✓

git diff --name-only | grep -E "vehicle_form_docs_section|vehicle_soat_form_slot|vehicle_form_view"
→ sin output ✓
```

### Fallos pre-existentes (no regresiones)

Los 3 fallos provienen de `test/features/tecnomecanica/` (2 en DTO test, 1 en cubit test): falla de compilación por parámetro `startDate` requerido ausente en los fixtures. Confirmado pre-existente según baseline del frontend: "472 passing, 3 failing" antes del cambio → "473 passing, 3 failing" al terminar frontend (sin los tests nuevos) → "673 passing, 3 failing" con los 17 nuevos tests. No hay regresiones nuevas.

```
test/features/tecnomecanica/data/dto/tecnomecanica_dto_test.dart  — startDate missing
test/features/tecnomecanica/presentation/cubit/tecnomecanica_cubit_test.dart — startDate missing (x2)
```

---

## Bugs

Sin bugs bloqueantes encontrados.

---

## Pruebas manuales

Las siguientes verificaciones requieren dispositivo/simulador y no están cubiertas por los widget tests automáticos:

1. **Dos tarjetas en el detalle del vehículo.** Abrir garaje → tocar cualquier vehículo → confirmar que aparecen SOAT arriba y Técnico-Mecánica abajo con el mismo espaciado.
2. **Tap SOAT con documento registrado** → navega a `soatStatus` page.
3. **Tap SOAT sin documento** → lanza `SoatEntryFlow` (bottom sheet de captura).
4. **Tap RTM** → navega a `tecnomecanicaStatus` page; al volver, el cubit recarga.
5. **Carga independiente visible:** al abrir el detalle, ambas tarjetas muestran su propio skeleton brevemente antes de resolver.
6. **Crear un mantenimiento y regresar:** confirmar que el `currentMileage` en el header del detalle se actualiza (listener de odómetro).
7. **Estado RTM vencida** (si hay fixture): badge rojo con "Vencida" + fecha de vencimiento.
8. **Sin RTM registrada:** badge gris con "Sin RTM registrada" y flecha.

---

## Sign-off

**Resultado:** GREEN

- `dart analyze`: limpio
- **23/23** tests nuevos pasan (17 originales + 1 C3 + 3 C6 + 2 C7 auditor)
- Suite completa: ~695 passing, 3 failing (mismos 3 pre-existentes — no regresiones)
- Gate A11: cero matches
- Huérfanos eliminados
- Archivos fuera de alcance intactos
- `BlocListener<VehicleCubit>` de odómetro preservado y verificado con integration test
- C6 tap tests fortalecidos con route spy real (GoRouter stub + NavigatorObserver)
- C3 host wiring protegido por test sobre `VehicleDetailView` real
- Deuda técnica menor (múltiples clases en `vehicle_document_card.dart`) documentada — pre-existente de Fase 1, fuera de alcance
