# Tech Lead handoff — remove-city-field

**Fecha:** 2026-06-11T22:45:53Z  
**Agente:** Tech Lead  
**Nivel:** normal

---

## Veredicto

**READY** — sin blockers. Dos items menores documentados (no bloquean funcionalidad ni CI). Ejecutar `flutter gen-l10n` antes de commitear.

---

## Hallazgos

| ID | Severidad | Area | Descripcion |
|----|-----------|------|-------------|
| F1 | Baja | frontend | `lib/l10n/app_localizations.dart` y `app_localizations_es.dart` aún declaran las 4 keys de ciudad (`event_cityRequired`, `event_eventCity`, `event_eventCityHint`, `event_filterByCity`) porque `flutter gen-l10n` no fue ejecutado tras limpiar `app_es.arb`. No falla `dart analyze` (no hay referencias activas) pero el contrato L10n queda desincronizado. Fix: `flutter gen-l10n` antes del commit. |
| F2 | Muy baja | frontend | Comentario stale en `lib/features/events/presentation/list/widgets/event_card.dart` línea 17: `/// - locRow: map-pin icon + city text (13 secondary)` — debería decir `meetingPoint text`. Cosmético. |
| F3 | Muy baja | frontend | Trailing whitespace en `test/features/events/presentation/form/cubit/ai_description_chat_cubit_test.dart` en 6 call-sites donde se eliminó `city:` — quedan líneas vacías dentro de named-arg lists. No causa error de compilación ni lint. Cosmético. |

Ninguno de los 3 hallazgos es un blocker.

---

## Seguridad

- Sin cambios en autenticación, CORS ni middleware.
- Sin SQL concatenado: la eliminación en `events.service.ts` es limpia (quitar campo de destructuring y de objetos de filtro Prisma tipados).
- Sin PII en logs: el campo `city` no era PII sensible y su eliminación reduce datos en tránsito.
- Sin secretos hardcodeados introducidos.
- Sin cambios en URLs de API ni variables de entorno.
- **Gemini:** el campo `city` ya no se envía al prompt de IA — reduce el contexto enviado a un proveedor externo.

---

## Arquitectura

- **Clean Architecture respetada:** el campo fue eliminado correctamente en todos los layers siguiendo el orden domain → data → presentation. `EventModel` (domain) es la fuente de verdad; `EventDto` sigue extendiendo `EventModel` (DTO Pattern B); no hay referencias circulares.
- **DTO Pattern B mantenido:** `EventDto extends EventModel`; `AiEventContextDto` no extiende ningún modelo de dominio y es un DTO de escritura, conforme a las excepciones documentadas.
- **No hay DTOs expuestos en Presentation:** la presentation layer sigue usando `EventModel`, no `EventDto`.
- **`meetingPoint` como proxy geográfico:** decisión D2 del architect es correcta; `event.meetingPoint` reemplaza `event.city` en las cards. Campo ya existente, no introducido.
- **Eliminación de `EventCardDateAndCity`:** confirmado como dead code por grep en el architect handoff — eliminación correcta y limpia.
- **`AppCityAutocomplete` preservado** en `lib/shared/widgets/form/` y en su único call-site activo (`registration_personal_step.dart` en el wizard de event_registration). Correcto per decisión del architect.
- **Filtro local eliminado correctamente:** el bloque `if (_filters.city != null)` en `_applyFiltersAndEmit()` y la rama de `_searchQuery` que incluía `e.city` se eliminaron; la búsqueda local ahora opera solo sobre `name`. Intencional per decisión D5.
- **Contracts rebuild:** ejecutado — `npm run build` en rideglory-contracts + `pnpm install` en events-ms y api-gateway.

---

## Tests

| Suite | Antes | Despues |
|-------|-------|---------|
| `flutter test` | — | 897/897 PASS |
| `dart analyze lib/` | — | No issues found |
| `events-ms` npm test | 5 fail / 26 (pre-existing) | 24/24 PASS |
| `api-gateway` npm test | 98/98 | 110/110 PASS |
| `tsc --noEmit` | — | Sin errores en events-ms y api-gateway |

Cobertura de ACs:

| AC | Test | Estado |
|----|------|--------|
| AC1: no `.city` en lib/features/ | TC-1/TC-2 (grep) | PASS |
| AC2: no city en schema Prisma | TC-3 (grep) | PASS |
| AC3: no city en contratos | TC-4 (grep) | PASS |
| AC4: backend compila (tsc) | TC-5 | PASS |
| AC5: dart analyze limpio | TC-6 | PASS |
| AC6: flutter test verde | TC-7 | PASS |
| AC7: sin AppCityAutocomplete en events form | TC-8 (grep) | PASS |
| AC8: sin EventFormFields.city | TC-9 (grep) | PASS |
| AC9: formulario sin errores runtime | TC pendiente | Manual — ver REVIEW_CHECKLIST.md |
| AC10: gemini.service limpio | TC-10 (grep) | PASS |
| AC11: EventCardDateAndCity eliminado | TC-11 | PASS |

---

## Pruebas manuales

Ver `REVIEW_CHECKLIST.md` para la lista completa. Items clave:

1. Ejecutar `flutter gen-l10n` y confirmar que los archivos generados no contienen las 4 keys de ciudad.
2. Abrir el formulario de creación/edición de evento en simulador y confirmar que no aparece campo de ciudad.
3. Abrir lista de eventos y confirmar que las cards muestran `meetingPoint`.
4. Abrir filtros de eventos y confirmar que no hay sección de ciudad.
5. Verificar `psql events -c '\d "Event"'` — columna `city` ausente.
6. `POST /events` sin `city` → 201.
7. `POST /ai/description` sin `city` en `eventContext` → descripción generada sin "Ciudad:".
