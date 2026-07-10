# REVIEW_CHECKLIST — eliminacion-cuenta-phase-01

_Pasos manuales antes de commitear. Tech Lead review: 2026-07-10T16:09:26Z (contenido); veredicto
**needs_changes** (2026-07-10T17:01:49Z); re-verificado 2026-07-10T17:06:49Z sin cambios — sigue
**needs_changes** — ver `handoffs/tech_lead.md`. Los pasos 1-2 de este checklist (separar el
working tree) y el paso 4 (desbloquear Pencil y completar la UI) no son opcionales: son la
condición para que esta fase pueda considerarse lista._

## 0. Contexto obligatorio

Esta fase quedo **PARCIAL**: solo backend completo + domain/data/cubit de Flutter. La UI
(`DeleteAccountConfirmationPage`, sus 4 widgets, `GoRoute`, item en `ProfileActionsList`) **no
existe** — bloqueada porque Pencil MCP no pudo abrir `rideglory.pen`. No hay ningun flujo
end-to-end demostrable en la app todavia. Esto es intencional y documentado, no un olvido.

## 1. Commitear SOLO lo de esta fase — el working tree tiene ~80 archivos de otras fases sin commitear

El `git status` de `Rideglory` y de `rideglory-api` tiene cambios grandes no relacionados
(borradores de eventos eliminados, tracking, login social, etc.). **No uses `git add -A` / `git
add .`**. Agrega archivo por archivo o con paths explicitos, usando exactamente la lista de
"Archivos" en `SUMMARY.md`.

- [ ] En `Rideglory`: `git add` solo los 12 archivos/paths listados en `SUMMARY.md` § Archivos
      (incluye los `.g.dart`/`app_localizations*.dart` regenerados por l10n si cambiaron).
- [ ] En `rideglory-api/api-gateway`: `git add` solo los 3 archivos modificados + 3 `.spec.ts`
      nuevos.
- [ ] En `rideglory-api/users-ms`: `git add` solo los 2 archivos modificados + 2 `.spec.ts`
      nuevos.
- [ ] Confirmar con `git diff --cached --stat` en cada repo que el conteo de archivos staged
      coincide con la lista antes de commitear.

## 2. Verificar que `analytics_events.dart` y `app_es.arb` no traigan el cambio de otra fase sin querer

Estos dos archivos de Flutter tienen, en el mismo diff sin commitear, tanto los agregados de esta
fase (3 eventos de analytics, 14 claves l10n) como una eliminacion no relacionada
(`eventsDraftSaved`, `event_saveDraft`, `draft_myDraftsTitle`, etc. — feature de borradores).

- [ ] Decidir con el equipo si el borrado de esas claves de borradores va en el commit de esta
      fase, en un commit aparte, o si se revierte antes de commitear esta fase (para no mezclar
      dos features en un commit "feat(users): ..."). Recomendado: commit aparte con su propio
      mensaje (`chore(events): eliminar constantes de borradores obsoletas`), ya que
      `eventsDraftSaved` no tiene referencias activas.

## 3. Backend — antes de mergear

- [ ] Levantar el stack local (`docker-compose`) y probar `DELETE /api/users/me` con una cuenta
      de prueba **desechable** (nunca `qa1@gmail.com`/`qa2@gmail.com`, nunca un usuario real).
      Verificar:
  - [ ] Respuesta `204` sin body.
  - [ ] La fila del usuario desaparece de `User` en `users-ms` (hard delete real, no
        `isDeleted: true`).
  - [ ] Un intento de login posterior con las mismas credenciales falla (Firebase Auth ya no
        tiene el usuario) — cubre AC9, que ningun test automatizado ejercito todavia.
  - [ ] Un segundo `DELETE /api/users/me` con el mismo token ya no es valido.
- [ ] Confirmar en migraciones/infra que no se necesita ningun cambio de esquema (esta fase no
      agrega columnas — `hardDelete` es `prisma.user.delete()` puro).

## 4. Frontend — siguiente paso obligatorio antes de continuar la UI

- [ ] Abrir `rideglory.pen` en la app de escritorio de Pencil y confirmar que el MCP puede
      leerlo (`get_editor_state`) antes de relanzar Design → UX Review → Frontend para la pieza
      de UI bloqueada.
- [ ] No usar los mensajes de commit de `SUMMARY.md` para dar a entender que la fase esta
      "completa" — el PR/commit debe dejar explicito en su descripcion que la UI queda pendiente.

## 5. Regresion

- [ ] Confirmar que `removeUser` (soft-delete) sigue intacto: `grep -rn "removeUser"
      rideglory-api` solo debe listar la definicion en `users-ms/src/users/users.controller.ts`
      (cero callers activos, verificado en esta review).
- [ ] Correr `flutter test` completo (no solo los archivos nuevos) antes de commitear, para
      confirmar que no hay regresiones fuera del alcance de esta fase.
- [ ] Correr `dart run build_runner build --delete-conflicting-outputs` una vez mas si se tocan
      mas claves de l10n antes de commitear, para que los generados queden sincronizados.

## 6. Post-commit

- [ ] Actualizar `docs/plans/eliminacion-cuenta/` (si existe indice de fases) marcando fase 1
      como "backend completo / UI pendiente de diseno" en vez de "completa".
