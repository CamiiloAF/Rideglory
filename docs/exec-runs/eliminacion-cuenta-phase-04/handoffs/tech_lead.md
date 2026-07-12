# Tech Lead handoff — eliminacion-cuenta-phase-04

_Generado: 2026-07-11T18:15:28Z_

## Veredicto

**ready** (sin blockers). El código revisado directamente en `git diff` (Flutter) y en los
submódulos de `rideglory-api` cumple el change map del Architect, los guardrails del PRD, y no
introduce regresiones. Existen gaps de prueba manual en staging (AC1, AC2, verificación en BD de
AC5) — aceptados explícitamente por el Architect como fuera del alcance de este entorno de agente,
documentados en `REVIEW_CHECKLIST.md` para ejecución humana antes del cierre completo de la fase.

## Hallazgos

Ninguno bloqueante. Notas no bloqueantes:

- El working tree mezcla los cambios de esta fase con residuos de otras corridas (fix de race de
  Mapbox en `crash_handler_setup.dart`/`main.dart`, ajuste del test Patrol de registro, y
  actualizaciones de `QA_CHECKLIST.md`/artefactos de fase-02/03). Ninguno de estos toca la lógica
  de idempotencia de borrado de cuenta ni el interceptor — confirmado leyendo cada diff línea por
  línea. Recomendado separarlos en commits distintos (ver `REVIEW_CHECKLIST.md` §1).
- Doble `signOut()`/doble snackbar ante dos 401 casi simultáneos: aceptado por diseño (idempotente,
  solo ruido visual), documentado por el Architect — no es un hallazgo nuevo.

## Seguridad

- Sin secretos, sin SQL concatenado, sin PII en logs nuevos: los `console.warn`/`this.logger.log`
  agregados en `firebase-auth.service.ts`, `account-deletion.service.ts` y `users.service.ts` solo
  loguean `uid`/mensajes genéricos de "ya borrado", nunca email/datos personales en texto plano
  más allá de lo que ya se logueaba antes.
- El copy del snackbar (`auth_sessionEndedSnackbar`) es neutral ("Tu sesión terminó, inicia sesión
  de nuevo.") — no filtra que la cuenta fue eliminada, cumple el guardrail.
- El guard de idempotencia es específico por código de error en los 3 puntos tocados:
  `isNotFoundRpcError` chequea `status === HttpStatus.NOT_FOUND`;
  `error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2025'`;
  `error.code === 'auth/user-not-found'`. Ningún catch genérico oculta otras excepciones — todos
  relanzan en el `else`/fuera del `if`. Verificado leyendo los 3 diffs completos.
- La lista `_sessionInvalidatedCodes` en el interceptor Flutter es exactamente
  `{'user-not-found', 'user-disabled', 'user-token-expired'}` — no incluye
  `network-request-failed` ni otros códigos de conectividad, confirmado en el código y cubierto
  por test negativo explícito.
- Auth/CORS: no se tocó ningún guard de autenticación ni configuración CORS; el contrato
  `DELETE /users/me` (`204/409/401/502`) permanece intacto — el único cambio de comportamiento
  observable es que un 404 espurio por reintento-tras-éxito-completo ahora colapsa a `204`.

## Arquitectura

- Clean Architecture respetada: el interceptor Flutter vive en `core/http/` (capa de
  infraestructura), no en domain/presentation; obtiene `AuthCubit` vía el mismo patrón defensivo
  ya usado en `_crashReporter()`, sin nuevo acceso directo a `BuildContext`.
- Backend (NestJS, fuera del alcance de domain/data/presentation de Flutter): los 3 archivos
  tocados son servicios de infraestructura (`account-deletion.service.ts`,
  `firebase-auth.service.ts`, `users.service.ts`); ningún cambio de firma de controller ni de
  contrato HTTP.
- Sin URLs hardcodeadas, sin env vars nuevas, sin migraciones de Prisma — confirmado en los
  handoffs de Backend/Architect y en el diff (`git diff --stat` no muestra `schema.prisma` ni
  `.env*`).
- Shape de API sin cambios: `DELETE /users/me` mantiene `204/409/401/502` exactamente.
- `hardDelete(id)` en `users-ms` cambia de "lanza si no existe" a "retorna `null` si no existe" —
  verificado que el único caller (`users.controller.ts` línea 47-48, RPC `hardDelete`) solo
  reenvía el resultado sobre el transporte de microservicios sin depender de un valor no-null;
  no rompe el contrato del `MessagePattern`.
- No se reordenaron los pasos de la orquestación de 8 pasos; no se agregó polling ni tabla de
  estado de borrado; no se subió el timeout global de `AppDio` (solo un comentario documental en
  `user_repository_impl.dart`).
- l10n: única string nueva (`auth_sessionEndedSnackbar`) está en `app_es.arb`, sin hardcodeo en el
  interceptor (usa `RidegloryL10n.current.auth_sessionEndedSnackbar`).

## Tests

- Cada AC automatizable tiene al menos un test que falla sin el cambio correspondiente:
  - AC3/AC7: `firebase_auth_interceptor_test.dart` — los 3 casos de código de sesión invalidada
    fallarían (nunca se llamaría `signOut()`) sin el nuevo bloque `on FirebaseAuthException catch`;
    el caso `network-request-failed` fallaría (llamaría `signOut()` indebidamente) si el set de
    códigos no estuviera acotado.
  - AC4/AC5 backend: los tests nuevos de `account-deletion.service.spec.ts` (retry tras 404 objeto
    plano/`RpcException`, carrera concurrente) fallarían contra el código pre-fase-04 (el
    `findUserByEmail` sin try/catch relanzaría el 404). El test de `users.service.spec.ts`
    ("idempotent no-op cuando prisma.user.delete throws P2025") falla contra el código viejo
    porque `findOne` lanzaba antes de llegar al catch. El test de `firebase-auth.service.spec.ts`
    (no-op `auth/user-not-found`) falla contra el código viejo porque relanzaba cualquier error.
  - Regresión (vehicles-ms, events-ms): tests nuevos que documentan comportamiento ya correcto,
    sin cambio de producción — correctamente etiquetados como "regression", no como AC nuevo.
- Suites completas verdes en ambos repos tras los cambios (ver `SUMMARY.md` §Pruebas), sin
  regresiones atribuibles a esta fase.
- Gaps de test aceptados y documentados (no ejecutables desde este entorno de agente): AC1 (no
  requiere cambio de código, solo verificación manual del comportamiento existente de
  `AuthCubit.checkAuthState()`), AC2 (verificado por lectura de código, no por test de integración
  con socket real — no hay infraestructura para simularlo sin overreach de scope), y la
  verificación en BD real de AC5 (los tests de carrera son unit tests con `ClientProxy` mockeado,
  no HTTP/e2e contra BD real).

## Pruebas manuales

Ver `REVIEW_CHECKLIST.md` §3 — pendientes de ejecución humana en staging antes de cerrar la fase
por completo:

1. AC1 — cierre de app antes de que la petición llegue al backend.
2. AC2 — corte de socket a mitad de la petición, verificado en BD de staging.
3. AC3 end-to-end — snackbar + redirect real con usuario ya borrado.
4. AC5 en BD real — dos llamadas superpuestas contra staging, sin filas huérfanas/duplicadas.
5. Regresión de `qa2@gmail.com` (organizador bloqueado por 409) — confirmar que sigue intacto.

Ninguno de estos gaps es un blocker de código: son verificaciones de comportamiento en un entorno
(staging + BD real) que no está disponible desde esta corrida de agente, y el Architect los
aceptó explícitamente como tales.
