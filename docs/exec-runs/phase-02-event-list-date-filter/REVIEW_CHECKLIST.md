# REVIEW CHECKLIST — Phase 02: Event List Date Filter

**Generado:** 2026-06-20T02:14:08Z

Pasos manuales a completar antes de commitear.

---

## Estático

- [ ] `dart analyze` en el repo raíz — confirmar 0 errores, 0 warnings nuevos
- [ ] Revisar diff de `lib/features/events/presentation/list/events_cubit.dart` línea 102: confirmar que NO hay `.toUtc()` y que `_isMyEvents` es la condición correcta

## Tests

- [ ] `flutter test test/features/events/presentation/list/events_cubit_date_filter_test.dart` → +4: All tests passed!
- [ ] `flutter test test/features/events/presentation/cubit/events_filter_cubit_test.dart test/features/events/presentation/list/events_cubit_analytics_test.dart` → todos pasan
- [ ] `flutter test` (suite completa) — 0 FAILED, 0 ERROR

## Manual en simulador/dispositivo

- [ ] **CA-1:** Abrir lista de eventos sin filtros. Verificar que ningún evento con fecha anterior a hoy aparece. Con proxy (Charles/Proxyman): confirmar `GET /api/events?dateFrom=YYYY-MM-DD` donde `YYYY-MM-DD` = hoy local.
- [ ] **CA-2:** Aplicar filtro de fecha con una fecha pasada (ej. 2025-01-01). Confirmar que eventos de 2025 aparecen (filtro manual sobreescribe el piso).
- [ ] **CA-3:** Limpiar filtros ("Clear"). Confirmar que la lista vuelve a mostrar solo eventos desde hoy.
- [ ] **CA-4:** Navegar a "Mis rodadas". Confirmar que eventos pasados SÍ aparecen (piso no aplica a myEvents).

## Archivos fuera de alcance (pre-existentes)

- [ ] Revisar que los cambios en `live_tracking_cubit.dart` corresponden a una fase separada y decidir si van en el mismo commit o en uno separado
- [ ] Confirmar que `integration_test/test_bundle.dart` referencia archivos que existen y compilan correctamente (app_test, events_patrol_test, home_patrol_test, profile_patrol_test)

## Antes de push

- [ ] Los archivos fuera de alcance (live_tracking, test_bundle, route_builder_section, 2 widget tests) tienen su propia historia o se incluyen intencionalmente en este commit
