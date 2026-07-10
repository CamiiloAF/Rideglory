> Slim handoff — read this before handoffs/architect.md

# Architect → Backend (eliminacion-cuenta-phase-01)

## Estado: ya completo, verificado de nuevo en este run

Releí de punta a punta `account-deletion.service.ts`, `users.controller.ts` (api-gateway),
`firebase-auth.service.ts`, `users.controller.ts`/`users.service.ts` (users-ms) y todos sus specs.
Todo coincide exactamente con el contrato fijado: `DELETE /users/me` → 5 pasos fijos
(`findUserByEmail` → TODO fase 2 → TODO fase 3 → `hardDeleteUser` → `firebaseAuthService.deleteUser(uid)`),
`uid`/`email` siempre de `request.user`, `removeUser` intacto sin callers (grep repetido, cero
hits activos), specs cubren la secuencia exacta que pide AC7 (orden, corte en 404, corte cuando el
paso 4 falla).

**No hay trabajo pendiente de backend en esta fase.** No toques ningún archivo de
`rideglory-api` salvo que Build/QA detecten una regresión real al correr los tests.

Si necesitas el detalle del contrato de todas formas (para las fases 2/3 futuras, no para esta
corrida): ver `## Contratos` en `handoffs/architect.md`.

> Full detail: handoffs/architect.md
