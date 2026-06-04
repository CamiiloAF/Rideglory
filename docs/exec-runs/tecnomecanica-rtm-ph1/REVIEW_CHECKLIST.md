# REVIEW CHECKLIST — tecnomecanica-rtm-ph1

**Generado:** 2026-06-04T16:45:04Z

Pasos manuales antes de commitear. Todos los automáticos ya pasan (dart analyze + flutter test).

---

## Verificaciones automáticas (ya pasadas — no repetir)

- [x] `dart analyze` → 0 issues (solo 2 preexistentes de `api_base_url_resolver.dart`)
- [x] `flutter test` → EXIT 0 (720 tests)
- [x] `flutter test test/features/soat/` → 60 tests PASS, 0 assertions modificados
- [x] `flutter test test/features/vehicle_documents/` → 10 tests PASS
- [x] `grep "class SoatModel" lib/` → 1 resultado exacto
- [x] `grep "getIt" vehicle_document_card.dart` → solo en BlocProvider.create
- [x] `grep "'Vigente'\|'Por vencer'\|'Vence '" vehicle_document_card.dart` → 0
- [x] `grep "_isLoading" vehicle_document_card.dart` → 0
- [x] `SoatDto extends SoatModel` en `lib/features/soat/data/dto/soat_dto.dart` intacto

---

## Verificaciones manuales en dispositivo/simulador

### MT-ph1-01 — Badge SOAT con layout idéntico al de main
1. Abrir detalle de un vehículo que tiene SOAT vigente (>30 días).
2. Verificar: card con header "SOAT", ícono verde, label "Vigente", fecha de vencimiento abajo.
3. Comparar visualmente con el estado en main (capturas si es posible).

### MT-ph1-02 — Skeleton de loading
1. Abrir detalle de vehículo en red lenta o con breakpoint en `SoatCubit.load`.
2. Verificar: `CircularProgressIndicator` visible antes de que cargue el badge.

### MT-ph1-03 — Tap sin SOAT → SoatEntryFlow
1. Con un vehículo sin SOAT registrado, abrir su detalle.
2. Tap en el badge.
3. Verificar: abre el flujo de alta de SOAT (`SoatEntryFlow`).

### MT-ph1-04 — Tap con SOAT → navega a soat_status
1. Con un vehículo con SOAT, abrir su detalle.
2. Tap en el badge.
3. Verificar: navega a `AppRoutes.soatStatus` con el vehículo como `extra`.

### MT-ph1-05 — Reload después de tap
1. Completar MT-ph1-03 (dar de alta un SOAT nuevo).
2. Al volver a la pantalla de detalle.
3. Verificar: el badge se actualiza mostrando el nuevo estado (cubit rellamó `load`).

### MT-ph1-06 — Estado "Por vencer" (30 días o menos)
1. Con un SOAT cuya fecha de vencimiento esté en los próximos 30 días.
2. Verificar: badge muestra label "Por vencer" en color naranja/warning.

### MT-ph1-07 — Estado "Vencido"
1. Con un SOAT vencido.
2. Verificar: badge muestra label "vencido" (minúsculas, via `maintenance_expired_label`) en color rojo.

---

## Revisión de deuda documentada

- [ ] Anotar en la historia de Fase 4 que `_SoatDocumentCardBody` debe extraerse a archivo propio cuando se añada `VehicleDocumentKind.rtm`.
- [ ] El cambio fuera de alcance en `vehicle_form_specs_section.dart` (localización + eliminación de TODO button) fue validado como correcto — no requiere acción adicional.
