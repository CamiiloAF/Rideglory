# REVIEW_CHECKLIST — legal-privacidad-edad-fase2

Pasos manuales antes de commitear (working tree de `rideglory-api` queda sucio a propósito).

## 1. Alcance del diff

Único archivo modificado: `events-ms/src/registrations/registrations.service.ts`. Dos archivos nuevos de test en el mismo directorio. Confirmado por `git status --short` en `events-ms`: sin diff en `rideglory-contracts`, `users-ms`, `api-gateway`, ni en `lib/` del worktree Flutter.

## 2. Revisar el diff

- [ ] `ensureRiderIsAdult(birthDate)`: confirmar que se inserta exactamente entre `ensureUserHasNoActiveRegistration()` y `ensureVehicleIdForNonOwner()` en `create()` — antes de `persistRiderProfile()`.
- [ ] `applyPrivacyMask()`: confirmar que se aplica **después** de `enrichRegistrationsWithVehicle()` en `findByEvent()`, y que `vehicleSummary` sigue presente en la respuesta.
- [ ] Confirmar por grep que `applyPrivacyMask` NO se invoca en `findMyRegistrationForEvent` ni `findMyRegistrations`.
- [ ] Confirmar que el mensaje de error de edad usa el campo `message` (no `code`) — `RpcException({ status: 422, message: 'UNDERAGE_RIDER' })`, consistente con lo que Fase 4 (Flutter) espera parsear.

## 3. Re-correr suite antes de commitear

```
cd events-ms
npx tsc --noEmit
npx jest
```

Confirmar: 0 errores de tipos, 5 suites / 42 tests / 0 failures (sin regresión sobre los tests preexistentes de Fase 1).

## 4. Gaps de cobertura a considerar (no bloqueantes)

- [ ] Evaluar si vale la pena, antes de Fase 7 (vista del organizador en Flutter), agregar un test dedicado que instancie `findMyRegistrationForEvent`/`findMyRegistrations` y afirme ausencia de sentinelas — hoy solo está confirmado por lectura de código.

## 5. Commit sugerido

Un solo commit en `events-ms` (ver `SUMMARY.md` → "Mensaje de commit sugerido").

## 6. Confirmar que el resto del árbol compartido no se tocó

```
cd /Users/cami/Developer/Personal/rideglory-api
git status --short
```

Debe mostrar cambios únicamente dentro de `events-ms/` para esta fase (además de cualquier trabajo sin commitear de otras sesiones, que no se toca).
