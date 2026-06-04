> Slim handoff — read this before docs/exec-runs/doble-badge-documentos-detalle/handoffs/architect.md

# Architect → QA: doble-badge-documentos-detalle

**Fecha:** 2026-06-04T20:49:36Z

---

## Comandos de verificación

```bash
# Análisis estático
dart analyze

# Tests
flutter test

# Gate A11 — debe devolver CERO matches
grep -n "features/soat\|features/tecnomecanica" \
  lib/features/vehicles/presentation/detail/vehicle_detail_page.dart \
  lib/features/vehicles/presentation/garage/widgets/vehicle_detail_view.dart

# Huérfanos eliminados — debe devolver vacío
grep -rln "VehicleSoatCard\|VehicleSoatSection" lib/

# Verificar que archivos fuera de alcance NO se tocaron
git diff --name-only | grep -E "vehicle_form_docs_section|vehicle_soat_form_slot|vehicle_form_view"
# Esperado: sin output
```

---

## Tests a crear: `test/features/vehicles/presentation/vehicle_documents_badges_test.dart`

### Grupo 1: Dos badges renderizan juntos (Criterio 3)
- Inyectar `SoatCubit` en `data` y `TecnomecanicaCubit` en `data`
- Encontrar exactamente 2 instancias de `VehicleDocumentCard` en el árbol
- Verificar orden: SOAT antes que RTM

### Grupo 2: Carga independiente — sin bloqueo cruzado (Criterio 4)
- Escenario A: `SoatCubit` → `loading`, `TecnomecanicaCubit` → `data` → verificar que el SOAT muestra skeleton y RTM muestra estado `data` simultáneamente
- Escenario B: invertir → RTM en `loading`, SOAT en `data` → idem
- Verificar que resolver uno no dispara reflow en el otro (los dos cubits son instancias separadas)

### Grupo 3: Regresión SOAT 4 estados (Criterio 5) — parametrizado por estado

| Estado SoatCubit | Label esperado | Color |
|-----------------|---------------|-------|
| `ResultState.data(SoatModel válido)` | "Vigente" (soat_status_valid) | statusGreen |
| `ResultState.data(SoatModel expiringSoon)` | "Por vencer" (soat_status_expiring_soon) | statusWarning |
| `ResultState.data(SoatModel expired)` | "vencido" (maintenance_expired_label) | statusError |
| `ResultState.empty()` | "Sin registrar · Agregar →" (vehicle_soat_tap_to_add) | textOnDarkSecondary |

### Grupo 4: RTM 4 estados (nuevo)

| Estado TecnomecanicaCubit | Label esperado |
|--------------------------|---------------|
| `ResultState.data(TecnomecanicaModel válido)` | "Vigente" (vehicle_doc_rtm_status_valid) |
| `ResultState.data(TecnomecanicaModel expiringSoon)` | "Por vencer" (vehicle_doc_rtm_status_expiring_soon) |
| `ResultState.data(TecnomecanicaModel expired)` | "Vencida" (vehicle_doc_rtm_status_expired) |
| `ResultState.empty()` | "Sin RTM registrada" (tecnomecanica_status_no_rtm) |

### Grupo 5: Tap navega al flujo correcto (Criterio 6)
- Tocar badge SOAT (estado `data`) → verifica navegación a `AppRoutes.soatStatus`
- Tocar badge SOAT (estado `empty`) → verifica que se dispara `SoatEntryFlow.start`
- Tocar badge RTM → verifica navegación a `AppRoutes.tecnomecanicaStatus`
- Usar `GoRouter` mock o `NavigatorObserver` para capturar navegación

### Grupo 6: BlocListener odómetro intacto (Criterio 7)
- Configurar árbol completo `VehicleDetailPage` con `VehicleCubit` en `data`
- Emitir lista de vehículos con `currentMileage` distinto al `_vehicle` actual
- Verificar que `_vehicle.currentMileage` se actualiza vía `setState`
- Verificar que los callbacks de mantenimiento siguen presentes y son invocables

---

## Criterios de aceptación (trazabilidad)

| Criterio PRD | Cobertura |
|-------------|-----------|
| C1 gate A11 | Grep acotado manual + CI |
| C2 hosts libres | Cubierto por C1 grep |
| C3 dos badges | Grupo 1 |
| C4 carga independiente | Grupo 2 |
| C5 regresión SOAT | Grupo 3 |
| C6 tap por kind | Grupo 5 |
| C7 listener odómetro | Grupo 6 |
| C8 huérfanos eliminados | Grep manual |
| C9 dart analyze | `dart analyze` |

---

## Red flags que bloquean cierre

- `dart analyze` reporta nuevos warnings respecto a la rama antes del cambio
- Grep A11 devuelve cualquier match en los dos hosts
- `grep -rln "VehicleSoatSection" lib/` devuelve archivos distintos del propio archivo
- Archivos del flujo form (`vehicle_form_docs_section.dart` etc.) aparecen en `git diff`

> Full detail: docs/exec-runs/doble-badge-documentos-detalle/handoffs/architect.md
