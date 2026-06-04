# Tech Lead handoff — doble-badge-documentos-detalle

**Fecha:** 2026-06-04T21:42:05Z
**Revisor:** claude-sonnet-4-6 (Tech Lead)
**Nivel:** normal

---

## Veredicto

**READY — sin blockers.** La implementación cumple todos los criterios de aceptación del PRD. Sin regresiones. Los cambios son precisos, acotados y coherentes con el contrato de Fase 1/3. Listo para commit humano después de verificación manual.

---

## Hallazgos

### Dentro del alcance — correctos

1. **Gate A11 cumplido.** `vehicle_detail_view.dart` y `vehicle_detail_page.dart` no importan `features/soat/` ni `features/tecnomecanica/`. El grep acotado devuelve cero matches.
2. **Dos badges montados.** `VehicleDocumentCard(kind: soat)` arriba, `VehicleDocumentCard(kind: rtm)` abajo, con `SizedBox(height: 16)` entre ellos. Orden y spacing correctos.
3. **`_RtmDocumentCardBody` completado.** `BlocBuilder<TecnomecanicaCubit, ResultState<TecnomecanicaModel>>` con skeleton de carga, 4 estados dinámicos, color/label/fecha derivados de `VehicleDocumentStatus`, `InkWell` con reload post-navegación. Simétrico con `_SoatDocumentCardBody`.
4. **Huérfano `vehicle_soat_section.dart` eliminado.** Confirmado sin referencias remanentes en `lib/` ni `test/`.
5. **Localización correcta.** 3 claves `vehicle_doc_rtm_status_*` añadidas con prefijo de feature correcto, generadas en `app_localizations.dart` y `app_localizations_es.dart`.
6. **`dart analyze`: limpio.** Sin warnings nuevos.
7. **23 tests nuevos: 23/23 passing.** Cubren AC3, AC4, AC5, AC6, AC7. Los 3 fallos pre-existentes en `test/features/tecnomecanica/` son deuda anterior (fixtures con `startDate` ausente), confirmada en baseline del frontend.
8. **`getIt` en `BlocProvider.create` únicamente.** No hay `getIt` en el body de ningún widget (sólo en el factory del `BlocProvider`). Patrón aprobado por Architect en D-2.
9. **Archivos fuera de alcance intactos.** `vehicle_form_docs_section.dart`, `vehicle_soat_form_slot.dart`, `vehicle_form_view.dart` no aparecen en el diff. `vehicle_detail_page.dart` tampoco.

### Deuda técnica pre-existente (no regresión de esta fase)

- **Múltiples widgets en `vehicle_document_card.dart`**: `VehicleDocumentCard`, `_SoatDocumentCardBody`, `_RtmDocumentCardBody` en un solo archivo. El estándar prohíbe esto. Introducido en Fase 1 (commit `52b0efe`), fuera del alcance de Fase 4. Documentado. Debe resolverse en Fase 1/3.
- **Tres fallos pre-existentes** en `test/features/tecnomecanica/` (parámetro `startDate` ausente en fixtures). No introducidos por esta fase.

---

## Seguridad

Sin hallazgos. La fase es 100% Flutter de presentación, sin cambios de API, sin manejo de secretos, sin PII en logs, sin cambios de CORS/auth.

---

## Arquitectura

- **Clean Architecture respetada.** `vehicles/presentation/` solo importa `vehicle_documents/` (contrato genérico) y tipos propios. Dependencias fluyen hacia adentro.
- **BLoC pattern correcto.** Cubits proveídos vía `BlocProvider` en el árbol; `getIt` solo en el factory (boundary de DI permitido). No se usan booleans de carga — se usa `ResultState`.
- **Un widget por archivo:** `vehicle_detail_view.dart` y los archivos nuevos cumplen la regla. La violación en `vehicle_document_card.dart` es pre-existente de Fase 1.
- **Strings via `context.l10n`:** cero literales hardcodeados en UI.

---

## Tests

| AC | Test | Resultado |
|----|------|-----------|
| C1 — Gate A11 | grep acotado ejecutado | PASS |
| C2 — hosts libres de tipos concretos | inspección de imports | PASS |
| C3 — dos badges + orden + spacing | `vehicle_documents_host_wiring_test.dart` | PASS |
| C4 — carga independiente | `vehicle_documents_badges_test.dart` #2, #3 | PASS |
| C5 — regresión SOAT 4 estados | `vehicle_documents_badges_test.dart` #4–#8 | PASS |
| C6 — tap por kind → flujo correcto | `vehicle_documents_tap_navigation_test.dart` | PASS |
| C7 — BlocListener odómetro intacto | `vehicle_detail_odometer_listener_test.dart` | PASS |
| C8 — huérfanos eliminados | grep lib/ → vacío | PASS |
| C9 — dart analyze / un widget por archivo / l10n | dart analyze + inspección | PASS (con nota deuda) |

---

## Pruebas manuales pendientes

Ver `REVIEW_CHECKLIST.md`. Los 12 pasos cubren los estados RTM visibles, la independencia de carga, la navegación por kind, y la integridad del listener de odómetro.
