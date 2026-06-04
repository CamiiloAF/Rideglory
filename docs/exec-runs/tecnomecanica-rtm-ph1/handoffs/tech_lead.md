# Tech Lead handoff — tecnomecanica-rtm-ph1

**Fecha:** 2026-06-04T16:45:04Z
**Agente:** Tech Lead
**Nivel:** normal

---

## Veredicto

**READY** — La fase está lista para commit humano tras las pruebas manuales en dispositivo (AC#12).

---

## Hallazgos

### OBS-TL-01 — `_SoatDocumentCardBody` privada en mismo archivo que `VehicleDocumentCard` (LOW)

El archivo `lib/features/vehicles/presentation/garage/widgets/vehicle_document_card.dart` contiene 2 widgets: `VehicleDocumentCard` (pública) y `_SoatDocumentCardBody` (privada). El coding standard dice "un widget por archivo". El frontend lo documentó explícitamente como excepción aceptada por ser clase auxiliar privada del widget compuesto. No genera lint, no rompe compilación, no es regresión. Acción: extraer `_SoatDocumentCardBody` a `soat_document_card_body.dart` en Fase 4 cuando se añada `VehicleDocumentKind.rtm`.

### OBS-TL-02 — `vehicle_form_specs_section.dart` modificado fuera de alcance (LOW)

El diff incluye cambios en `lib/features/vehicles/presentation/form/widgets/vehicle_form_specs_section.dart` (localización del literal `'Opcional'` y eliminación del botón TODO de IA search). Estos cambios estaban fuera del alcance declarado en §3 del PRD pero son correctos y mejoran el código. No generan regresión. No requieren acción.

### OBS-TL-03 — `VehicleSoatFormDataDto` no extiende `VehicleSoatFormData` (INFO — excepción documentada)

El `soat_dto.dart` en la feature `vehicles/data/dto/` no sigue Pattern B (DTO extends Model) porque los campos de fecha son `String` en el DTO y `DateTime` en el model — shape-mismatch. El código documenta la excepción explícitamente con un comentario completo y provee `extension VehicleSoatFormDataModelExtension.toJson()` para los write payloads y `extension VehicleSoatFormDataDtoExtension.toFormData()` para los read payloads. La excepción está contemplada en el coding-standard para DTOs con tipos incompatibles. Sin acción requerida.

---

## Seguridad

- Sin secretos, credenciales ni PII en ningún archivo del diff.
- Sin SQL concatenado ni XSS.
- Sin cambios en auth/CORS (el diff no toca backend).
- `getIt<SoatCubit>()` solo en el factory de `BlocProvider.create` — no en el body del widget. Patrón correcto para cubits locales.
- Dominio (`vehicle_documents/domain/`) sin imports de Flutter — constraint cumplido.

---

## Arquitectura

**Clean Architecture — OK:**
- Dominio nuevo (`vehicle_documents/domain/`) sin imports de Flutter ni HTTP.
- Data (`vehicles/data/dto/`) sin widgets ni `BuildContext`.
- Presentación (`vehicle_document_card.dart`) no hace HTTP directo, no expone DTOs, depende de cubit.

**Pattern B — OK con excepción documentada:**
- `SoatDto extends SoatModel` en `soat/data/dto/soat_dto.dart` → intacto.
- `VehicleSoatFormDataDto` no extiende `VehicleSoatFormData` por shape-mismatch (fechas String vs DateTime). Excepción documentada en código. Permitida por los coding-standards.

**Contrato ADR cumplido:**
- `SoatModel with VehicleDocumentExpiry implements VehicleDocumentModel` — verifica.
- `SoatCubit extends VehicleDocumentCubit<SoatModel>` — verifica.
- `VehicleDocumentCard` parametrizado por `VehicleDocumentKind` — extensible para Fase 3 (RTM).
- `home_garage_soat_badge.dart` no tocado — verifica.

**Colisión de nombre eliminada:**
- `grep "class SoatModel" lib/` → 1 resultado exacto en `soat/domain/models/soat_model.dart`.
- El nombre `SoatDto` aparece en `soat/data/service/soat_service.dart` e importa de `soat/data/dto/soat_dto.dart` — es el DTO del feature SOAT (extiende `SoatModel` de soat). Distinto del `VehicleSoatFormDataDto` de vehicles. Sin colisión.

**Cubits — OK:**
- `SoatCubit` sigue siendo `@injectable` (no singleton).
- `VehicleDocumentCubit` es abstract, sin DI annotation — correcto.
- `VehicleDocumentCard` usa `BlocProvider` local con `getIt<SoatCubit>()` en factory — patrón aceptado.

**Un widget por archivo:**
- Todos los archivos de `vehicle_documents/presentation/widgets/` tienen exactamente 1 widget público.
- Excepción: `vehicle_document_card.dart` tiene `_SoatDocumentCardBody` privada (OBS-TL-01).

**Strings localizados:**
- 3 literales del card eliminados; `vehicle_doc_expires_on` añadida en `app_es.arb`.
- Sin hardcoded en el nuevo card ni en los widgets genéricos.

---

## Tests

| Suite | Resultado |
|-------|-----------|
| `dart analyze` | 0 issues (2 preexistentes permitidos en api_base_url_resolver) |
| `flutter test` completa | EXIT 0 |
| `flutter test test/features/soat/` | 60 tests PASS — 0 assertions modificados |
| `flutter test test/features/vehicle_documents/` | 10 tests PASS |
| `vehicle_form_cubit_soat_test` | 5 tests PASS |

Todos los ACs verificables automáticamente (AC1–AC11) pasan. AC#12 (cero cambio visible) queda deferred a dispositivo.

---

## Pruebas manuales

Ver `REVIEW_CHECKLIST.md` para los 7 pasos detallados. Los críticos:

1. Badge SOAT en detalle de vehículo — layout idéntico al de main (4 estados + skeleton).
2. Tap sin SOAT → `SoatEntryFlow`.
3. Tap con SOAT → navega a `soat_status`.
4. Reload del badge al volver de tap.

---

## Change log

- 2026-06-04T16:45:04Z: Tech Lead review — tecnomecanica-rtm-ph1, nivel normal. Veredicto: READY.
