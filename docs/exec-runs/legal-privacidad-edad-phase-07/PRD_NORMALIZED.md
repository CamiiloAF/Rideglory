# PRD Normalizado — Fase 7: Vista del organizador con ofuscación y contacto

**Slug:** `legal-privacidad-edad-fase7-organizador`
**Fuente:** `docs/plans/legal-privacidad-edad/phases/phase-07-vista-del-organizador-con-ofuscacion-y-contacto.md`
**Generado:** 2026-07-03T16:35:56Z
**Nivel rg-exec:** normal

---

## 1 Objetivo

Adaptar `RegistrationDetailPage` para que el organizador vea los datos de cada inscrito tal como los retorna el backend (reales u ofuscados según las reglas de privacidad de Fase 2), y pueda contactar directamente al rider con un tap cuando `allowOrganizerContact == true`. La distinción organizador/piloto pasa a un campo explícito `isOrganizerView: bool` en `RegistrationDetailExtra`, eliminando la ambigüedad del patrón actual basado en comparar `userId`.

## 2 Por que

- El patrón actual (`registration.userId == currentUserId`) es ambiguo: si el organizador también está inscrito en su propio evento, comparar `userId` no distingue correctamente entre "ver mi propia inscripción" y "ver la inscripción de otro rider como organizador".
- Fase 3 cambia `bloodType` de `BloodType` a `BloodType?`, lo que rompe el acceso actual (`registration.bloodType.label`) con `Null check operator used on a null value` en runtime si el backend ofusca el dato.
- Sin botones de contacto explícitos, el organizador no tiene forma de llamar/escribir por WhatsApp a un rider aprobado que autorizó el contacto (`allowOrganizerContact == true`).
- El early-return actual en `RegistrationDetailBottomBar` (línea 48) esconde los botones de contacto cuando no hay acciones de aprobar/rechazar pendientes (caso común: inscripción ya aprobada).

## 3 Alcance

### Entra
- Extensión de `RegistrationDetailExtra` con `isOrganizerView: bool` (default `false`), `eventState: EventState?`, `eventSosTriggeredAt: DateTime?`.
- Actualización de los 3 puntos de navegación del organizador (`attendees_list.dart` ramas pending/processed, `event_detail_participants_section.dart`, `event_detail_view.dart`) para pasar `isOrganizerView: true` + estado del evento.
- Refactor de `RegistrationDetailPage` para usar `extra.isOrganizerView` en lugar de comparar `userId`.
- Refactor de `RegistrationDetailBottomBar`: evaluar visibilidad de `RegistrationContactActions` antes del early-return de acciones.
- Widget nuevo `RegistrationContactActions` (archivo independiente) con botones Llamar y WhatsApp, variante `AppButtonVariant.ghost` + `AppButtonStyle.outlined`.
- Corrección de acceso nullable a `bloodType` en `RegistrationDetailPage`: `registration.bloodType?.label ?? registration.bloodTypeRaw ?? context.l10n.notAvailable`.
- Dos strings l10n nuevos: `registration_callButton`, `registration_whatsappButton`.

### No entra
- Localización de los centinelas `"••••"` / `"__NOT_SHARED__"` a texto descriptivo — la UI muestra el string crudo tal cual.
- Cambios de backend, contratos o migraciones (ninguno en esta fase).
- Pantallas nuevas; todo el trabajo es sobre páginas/widgets existentes.
- `MyRegistrationsDataView` (vista del piloto sobre sus propias inscripciones) — esos puntos de navegación no pasan `isOrganizerView: true`.

## 4 Areas afectadas (best-effort)

- `lib/features/event_registration/presentation/registration_detail_extra.dart` (modificar)
- `lib/features/event_registration/presentation/registration_detail_page.dart` (modificar)
- `lib/features/event_registration/presentation/widgets/registration_detail_bottom_bar.dart` (modificar)
- `lib/features/event_registration/presentation/widgets/registration_contact_actions.dart` (crear)
- `lib/features/events/presentation/attendees/widgets/attendees_list.dart` (modificar, ramas pending/processed)
- `lib/features/events/presentation/detail/widgets/event_detail_participants_section.dart` (modificar)
- `lib/features/events/presentation/detail/event_detail_view.dart` (modificar)
- `lib/l10n/app_es.arb` (modificar) → regenerar `lib/l10n/app_localizations_es.dart` via `flutter gen-l10n`
- Dependencias externas al widget: `EventRegistrationModel.allowOrganizerContact`, `EventModel.sosTriggeredAt`, `BloodType?`/`bloodTypeRaw` (todos provistos por Fase 3, prerequisito bloqueante).

## 5 Criterios de aceptacion (numerados, observables, testeables)

1. **isOrganizerView explícito:** Abrir el detalle de la inscripción de un rider desde `AttendeesList` (pending o processed) muestra el título "Detalles de solicitud" y no "Mi inscripción"; deriva de `isRegistrantViewer = false` <- `params.isOrganizerView = true`.
2. **isOrganizerView en detalle de evento:** Abrir el detalle desde `EventDetailParticipantsSection` también pasa `isOrganizerView: true` y produce la misma vista organizador.
3. **Vista del piloto no afectada:** Abrir una inscripción propia desde `MyRegistrationsDataView` sigue mostrando "Mi inscripción", banner de estado y botones editar/cancelar; `isOrganizerView` por defecto es `false` en esos puntos de navegación.
4. **Organizador-participante:** Si el organizador está inscrito en su propio evento, abrir el detalle de OTRO rider desde `AttendeesList` muestra vista organizador (ya no depende de comparar `userId`).
5. **Botones de contacto visibles:** En vista organizador de una inscripción `status == approved` y `allowOrganizerContact == true`, la bottom bar muestra "Llamar" y "WhatsApp" en fila de dos columnas, incluso sin acciones de aprobar/rechazar pendientes.
6. **Botones de contacto ocultos:** Si `allowOrganizerContact == false`, la bottom bar no muestra botones de contacto; si tampoco hay acciones de organizador, la bottom bar es `SizedBox.shrink()`.
7. **Tap en Llamar:** Invoca `UrlLauncherHelper.openPhone(phone)` → construye `tel:<phone>` y lo lanza vía `url_launcher`. El teléfono está garantizado real (`allowOrganizerContact == true` es condición de render).
8. **Tap en WhatsApp:** Invoca `UrlLauncherHelper.openWhatsApp(phone)` → construye `https://wa.me/<sanitized_phone>` y lo lanza.
9. **Datos ofuscados renderizados:** Si el backend retorna `"••••"` en `phone`, la fila de teléfono muestra literalmente `"••••"`, sin excepción ni vacío.
10. **bloodType nullable:** Si `registration.bloodType` es `null` (backend retornó `"__NOT_SHARED__"` parseado a `null` por Fase 3), la fila de grupo sanguíneo muestra el string crudo via `bloodTypeRaw`, o en su defecto `"N/A"` (`context.l10n.notAvailable`, clave ya existente en ARB). No lanza `Null check operator used on a null value`. No se agrega clave nueva al ARB.
11. **l10n verificado:** "Llamar"/"WhatsApp" provienen de `context.l10n.registration_callButton` / `registration_whatsappButton`; sin strings hardcodeados.
12. **dart analyze limpio:** `dart analyze` sin errores en archivos modificados/creados.

## 6 Guardrails de regresion

- No romper la vista del piloto (`MyRegistrationsDataView`): `isOrganizerView` default `false` debe preservar título "Mi inscripción", banner de estado y botones editar/cancelar sin cambios de comportamiento.
- No renderizar botones de contacto cuando `isOrganizerView == false`, aunque `allowOrganizerContact == true` (el contacto es exclusivo de la vista organizador).
- No introducir crash de `Null check operator` en el acceso a `bloodType` — validar explícitamente con nullable + fallback antes de cerrar la fase.
- No eliminar `context.watch<AuthCubit>()` en `RegistrationDetailPage` si se usa para algo más en la página aparte de la comparación de `userId` (verificar antes de remover import).
- El refactor del early-return de `RegistrationDetailBottomBar` no debe alterar los flags existentes `showApprove`/`showOwnerActions`/`showRequestEdit`/`showCancel` (su lógica condicionada a `status` ya es correcta y no cambia).
- `RegistrationContactActions` debe vivir en archivo propio (`registration_contact_actions.dart`) — prohibido como método `_buildContactActions()` dentro de otro widget (regla cero-tolerancia "un widget por archivo").
- No agregar guard adicional de teléfono vacío en el widget salvo que cambie el contrato de backend (documentado como riesgo aceptado R5); confiar en que `UrlLauncherHelper` ya usa `canLaunchUrl` internamente.
- No tocar contratos, DTOs de backend ni migraciones — la fase es exclusivamente de presentación Flutter.
- No usar `AppButtonVariant.secondary` para los botones de contacto (produce relleno sólido más prominente de lo deseado); usar `ghost` + `outlined` según decisión ya fijada en el plan.
- Correr `dart analyze` y `flutter gen-l10n`/`build_runner build --delete-conflicting-outputs` tras editar el ARB.

## 7 Constraints heredados

- **Bloqueo de dependencias:** Fase 2 (backend: ofuscación condicional) y Fase 3 (modelos/DTOs Flutter: `allowOrganizerContact`, `sosTriggeredAt`, `bloodType`/`bloodTypeRaw`) deben estar cerradas antes de ejecutar esta fase. Si no lo están, la fase queda bloqueada (pre-flight Paso 1 del plan original).
- Un widget por archivo; prohibidos métodos que retornan widgets (`_buildX()`).
- Siempre usar componentes de `lib/shared/widgets/form/` (`AppButton`, etc.) antes de implementar UI nueva — nunca `ElevatedButton`/`TextButton` directos.
- Strings de UI siempre vía `app_es.arb` + `context.l10n.<key>` — cero tolerancia a hardcodeo.
- Cubits/Blocs `@injectable` + `BlocProvider` en árbol (no `@singleton`/`getIt`), salvo `AuthCubit`.
- Sobre `AppColors.primary` (naranja) el texto/iconos deben ser oscuros, nunca blancos — no aplica directamente a esta fase (botones ghost/outlined) pero es constraint global del design system.
- Arquitectura Clean: presentación no expone DTOs ni hace HTTP directo; los modelos de dominio (`EventRegistrationModel`, `EventModel`) son la única fuente que consume la UI.
- No commitear cambios — el árbol de trabajo queda sucio para revisión humana (regla del runner rg-exec).
