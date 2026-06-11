# REVIEW_CHECKLIST — remove-city-field

**Fecha:** 2026-06-11T22:45:53Z

Pasos manuales a completar ANTES de commitear:

## Obligatorios

- [ ] **L10n regenerada:** ejecutar `flutter gen-l10n` (o `dart run build_runner build --delete-conflicting-outputs`) y verificar que `lib/l10n/app_localizations.dart` ya no contiene `event_cityRequired`, `event_eventCity`, `event_eventCityHint`, `event_filterByCity`.
- [ ] **Formulario de creación:** abrir el form de nuevo evento, navegar por todos los pasos (básico, ubicación, fechas, vehículo), confirmar que no aparece campo de ciudad y que no hay errores en consola.
- [ ] **Formulario de edición:** cargar un evento existente, confirmar que no hay referencias rotas a `city`.
- [ ] **Lista de eventos:** verificar que las cards muestran `meetingPoint` (punto de encuentro) en el row de ubicación (donde antes aparecía ciudad).
- [ ] **Filtros de eventos:** abrir el bottom sheet de filtros y confirmar que no hay sección de ciudad.
- [ ] **Wizard de registro:** verificar que `AppCityAutocomplete` sigue presente en el paso de información personal del wizard de registro a evento.
- [ ] **Inscription card:** abrir detalle de un evento con inscripción aprobada; confirmar que la tarjeta no muestra fila de ciudad ni error de runtime.
- [ ] **Backend — migración:** confirmar `psql events -c '\d "Event"'` muestra que la columna `city` no existe.
- [ ] **Backend — create sin city:** `POST /events` sin campo `city` → debe responder 201.
- [ ] **Backend — AI sin city:** `POST /ai/description` con `eventContext` sin `city` → descripción generada sin "Ciudad:" en el prompt (verificar logs de Gemini).

## Opcionales (cosméticos)

- [ ] Corregir comentario en `lib/features/events/presentation/list/widgets/event_card.dart` línea 17: cambiar `city text (13 secondary)` → `meetingPoint text (13 secondary)`.
- [ ] Limpiar trailing whitespace (líneas vacías) en `test/features/events/presentation/form/cubit/ai_description_chat_cubit_test.dart` donde se eliminó `city:` en los 6 call-sites.
- [ ] Verificar `npx prisma migrate status` en `events-ms` para confirmar que la historia de migraciones está sincronizada.
