> Slim handoff — read this before handoffs/architect.md

# Architect → QA (eliminacion-cuenta-phase-01)

## Estado ya cubierto (backend) — verificado de nuevo, no repetir trabajo

AC7 y AC8 ya tienen tests en verde: `account-deletion.service.spec.ts` (orden exacto de 3 pasos
observables, corte en 404 del paso 1, corte cuando el paso 4 falla), `users.controller.spec.ts`
(api-gateway, incluye "uid/email envenenados" en params/body), `users.service.spec.ts` +
`users.controller.spec.ts` (users-ms, con regresión explícita de `remove()`/`removeUser`). No hace
falta generar tests nuevos de backend para esta fase salvo que encuentres un gap real al leerlos.

## Trazabilidad AC → test

| AC | Qué verificar | Estado | Dónde |
|----|----------------|--------|-------|
| AC1 | Ítem "Eliminar cuenta" navega a página dedicada, no abre `ConfirmationDialog` | pendiente (bloqueado por diseño) | widget test `profile_actions_list_test.dart` |
| AC2 | Lista completa incluye ítems de fase 2/3 (no implementados aún, sin badge) | pendiente | widget test de `DeleteAccountConfirmationPage` |
| AC3 | Botón deshabilitado hasta activar el `AppSwitchTile` | pendiente | widget test |
| AC4 | Segundo tap durante `loading` no dispara segunda llamada HTTP | **ya cubierto a nivel cubit** (`delete_account_cubit_test.dart`) | falta réplica a nivel widget (tap real en botón) |
| AC5 | Éxito limpia `AuthCubit`/`VehicleCubit`/`ProfileCubit` y navega con `goAndClearStack`, sin dejar la pantalla en el stack | pendiente | widget/integration test |
| AC6 | Error vuelve a estado `error` con mensaje en español, retry manual, sin loop automático | parcial (cubit cubierto, falta UI) | test de cubit ya existe + falta widget test |
| AC7 | `DELETE /users/me` ejecuta los 5 pasos en orden fijo; Firebase `deleteUser` siempre último; fallo en paso 4 no invoca paso 5 | **completo** | `account-deletion.service.spec.ts` |
| AC8 | `hardDeleteUser` borra la fila (`prisma.user.delete`); `removeUser` sigue intacto | **completo** | `users-ms` specs |
| AC9 | Login post-borrado falla (usuario ya no existe en Firebase Auth ni en `users-ms`) | pendiente | manual o e2e con cuenta desechable — nunca `qa1@gmail.com`/`qa2@gmail.com` ni usuarios reales |
| AC10 | Cero strings hardcodeados en la página nueva | pendiente (página no existe aún) | grep + `analytics_taxonomy_no_pii_test.dart` (eventos ya pasan) |
| AC11 | `dart analyze` limpio; un widget por archivo; sin `_buildX()` | pendiente (código no existe aún) | `dart analyze`, revisión manual |

## Cuentas de prueba

**Nunca** ejecutar el flujo de hard-delete real contra `qa1@gmail.com` / `qa2@gmail.com` ni contra
los ~10 usuarios reales en producción. Usa cuentas desechables creadas y destruidas dentro del
propio test/run manual.

## Verificación en BD

Tras un hard-delete exitoso en un entorno de prueba: confirmar en `users-ms` (Postgres) que la fila
`User` ya no existe, no solo confiar en la respuesta `204` de la API.

## Nota sobre el bloqueo de diseño

AC1, AC2, AC3, AC5, AC6 (parcial), AC9, AC10, AC11 dependen de que exista
`DeleteAccountConfirmationPage`, que sigue bloqueada por Pencil MCP (ver `handoffs/design.md`). No
es un gap de QA — es la razón documentada por la que esta fase sigue `PARCIAL`.

> Full detail: handoffs/architect.md
