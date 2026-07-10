# Architect → QA — eliminacion-cuenta-phase-03

Contrato completo: `handoffs/architect.md`. Criterios de aceptación completos en
`PRD_NORMALIZED.md` §5 (12 AC numerados) — úsalos como base literal del checklist, no los
reinterpretes.

## Puntos de verificación que requieren BD real (no solo UI)

- **AC5**: `DELETE /users/me` con eventos activos como organizador → 409, y verificar en BD
  (`events-ms`, `vehicles-ms`, `users-ms`) que **nada** cambió — ni vehículos, ni
  `EventRegistration`, ni el usuario. No basta con ver el 409 en la UI/Postman.
- **AC6**: tras borrado exitoso, consultar `EventRegistration` directamente en la BD de
  `events-ms` y confirmar `fullName = 'Usuario eliminado'` (string exacto, no un placeholder de
  UI) y los 8 campos PII en `null`.
- **AC7**: mismos registros, confirmar que `riskAcceptedAt`, `riskAcceptanceVersion`,
  `medicalConsentAcceptedAt`, `medicalConsentVersion` **no cambiaron** de valor respecto a
  antes del borrado (comparar snapshot pre/post).
- **AC8**: llamar `anonymizeRegistrationsByUserId` (vía MessagePattern directo o disparando el
  borrado dos veces si el flujo lo permite en test) dos veces seguidas, mismo `userId` —
  `count` igual en ambas, estado de filas idéntico tras la segunda.

## Puntos de verificación de UI/flujo

- AC1–AC4: usar dos usuarios de prueba — uno sin eventos activos como organizador (bypass
  directo) y uno con al menos un evento `DRAFT`/`SCHEDULED`/`IN_PROGRESS` (bloqueo). Confirmar
  que el organizador bloqueado **nunca** ve el switch "entiendo lo que se borra" ni el botón
  final de confirmar (AC2 — no solo "el sheet aparece", sino "nunca llega a la pantalla").
  Nota: los usuarios de prueba de memoria (`qa1@gmail.com`/`qa2@gmail.com`, ver
  `project_qa_test_users`) pueden no tener eventos activos en el estado correcto — puede
  requerir crear/mover un evento a `DRAFT`/`SCHEDULED`/`IN_PROGRESS` para el organizador de
  prueba antes de correr este caso.
- AC4: cambiar el único evento activo del organizador a `CANCELLED` o `FINISHED` y repetir el
  tap — confirmar que ya no bloquea (la precondición se re-evalúa, no se cachea).
- AC9: como organizador, ver la lista de asistentes de un evento con un inscrito de cuenta ya
  eliminada — nombre `Usuario eliminado`, sin crash.
- AC10: `RegistrationDetailPage` sobre ese mismo inscrito — cada campo nulo muestra
  `"Cuenta eliminada"` (texto exacto de `registration_deletedAccountFieldPlaceholder`), nunca
  vacío/`"null"` literal/crash. Confirmar explícitamente que **no** aparece `"N/A"`
  (`notAvailable`) en estos campos — señal de que se reusó la key equivocada.
- AC12: inspeccionar las llamadas HTTP disparadas al tocar "Eliminar cuenta" (proxy/logs) —
  debe ser exactamente la misma llamada que dispara la pantalla "Mis eventos", ninguna nueva.

## Puntos técnicos

- AC11: `dart analyze` limpio tras el cambio de nulabilidad.
- Regresión de masking: un registro anonimizado con `shareMedicalInfo = false` (que la
  anonimización siempre fuerza) debe seguir mostrando `••••` en campos médicos vía el masking
  ya existente (`FULL_MASK`) — confirmar que no se rompió ni se mezcló con el nuevo
  `'Usuario eliminado'`.
- Confirmar que el `ownerId` de eventos del usuario eliminado **no** cambió — solo
  `EventRegistration.userId` fue el filtro de la anonimización.

## Fuera de alcance (no reportar como bug si no está)

- Transferencia de `ownerId`, cancelación automática de eventos, TTL de 3 años, nulabilidad de
  `bloodType`, endpoint de chequeo nuevo — todos explícitamente recortados en el PRD §3.
