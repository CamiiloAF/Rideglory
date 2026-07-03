# Architect handoff — legal-privacidad-edad-fase7-organizador

**Date:** 2026-07-03T16:38:12Z
**Status:** in progress (hallazgo bloqueante menor identificado, ver Riesgos)

## Hallazgo principal (léase antes que todo lo demás)

Esta corrida es **retroactiva**: al abrir el código real, casi el 100% del alcance
del PRD_NORMALIZED.md ya está implementado en el árbol de trabajo:

- `RegistrationDetailExtra.isOrganizerView` (+ `eventState`, `eventSosTriggeredAt`) — ya existe, default `false`.
- `RegistrationDetailPage` ya usa `isOrganizerView` (vía `isRegistrantViewer = !params.isOrganizerView`), no compara `userId`.
- `RegistrationDetailBottomBar` ya evalúa `showContact` independiente del early-return de acciones.
- `RegistrationContactActions` ya existe en archivo propio, variante `ghost` + `outlined`, usa `UrlLauncherHelper.openPhone/openWhatsApp`.
- Los 3 puntos de navegación (`attendees_list.dart` pending/processed, `event_detail_participants_section.dart`, `event_detail_view.dart`) ya pasan `isOrganizerView: true` + `eventState` + `eventSosTriggeredAt`.
- `my_registrations_data_view.dart` (vista piloto) NO pasa `isOrganizerView` → default `false` preservado correctamente.
- l10n keys `registration_callButton` / `registration_whatsappButton` ya existen en `app_es.arb`.
- Tests widget ya existen: `registration_detail_bottom_bar_test.dart`, `registration_contact_actions_test.dart`, `registration_detail_page_test.dart` (con casos de bloodType 1.1/1.2).

**Único gap real contra el PRD:** el Criterio de aceptación 10 (bloodType nullable)
NO está cumplido tal como está especificado. El código actual en
`registration_detail_page.dart` línea ~127 hace:

```dart
value: registration.bloodType?.label ?? context.l10n.registration_maskedValue,
```

Esto siempre muestra `"••••"` cuando `bloodType` es `null`, sin importar la razón
real (rider no compartió vs. backend envió un sentinel distinto). El PRD exige:

```dart
value: registration.bloodType?.label ?? registration.bloodTypeRaw ?? context.l10n.notAvailable,
```

Pero **`bloodTypeRaw` no existe** en `EventRegistrationModel` ni en
`EventRegistrationDto` — Fase 3 (prerrequisito bloqueante declarado en §7 del PRD)
no lo entregó, a pesar de que el PRD asume que sí. Confirmado con grep: cero
ocurrencias de `bloodTypeRaw` en todo `lib/`.

**Decisión de alcance:** en vez de bloquear la fase completa, extiendo el alcance
mínimamente para cerrar este gap aquí mismo, porque:
1. Es un cambio de solo-lectura sobre un campo (`bloodType`) que la API YA retorna — no requiere contrato nuevo, no requiere migración, no requiere tocar rideglory-api.
2. Es estrictamente aditivo (nuevo campo nullable en el modelo/DTO) — no rompe ningún consumidor existente.
3. Bloquear toda la fase por este único campo faltante sería desproporcionado dado que el 95% del trabajo ya está hecho y verificado.

Si el usuario prefiere tratar esto como bloqueo estricto de Fase 3, debe decirlo
explícitamente antes de que Backend/Frontend ejecuten.

## Feature architecture decisions

| Feature | Domain changes | Data changes | Presentation changes |
| ------- | -------------- | ------------ | --------------------- |
| event_registration | `EventRegistrationModel.bloodTypeRaw: String?` (nuevo campo) | `EventRegistrationDto`: captura manual del valor crudo de `json['bloodType']` cuando el converter no puede mapearlo a un `BloodType` válido | `RegistrationDetailPage`: fallback de fila "Tipo de sangre" pasa a `bloodType?.label ?? bloodTypeRaw ?? notAvailable` |

Todo lo demás del PRD (isOrganizerView, contact actions, navegación organizador,
bottom bar) ya está implementado y NO requiere cambios de arquitectura — solo
verificación (QA) y, si faltan, tests Patrol e2e del flujo organizador.

## API contracts (rideglory-api changes)

Ninguno. La fase es exclusivamente Flutter presentación + un campo de parsing
adicional sobre una respuesta que el backend ya envía (`bloodType` como string,
posiblemente un sentinel no mapeable a enum). No hay endpoint nuevo, no hay
campo nuevo en el contrato JSON — solo se lee el mismo campo dos veces
(una vez como enum tipado, otra vez como string crudo de respaldo).

## New models and DTOs

| Name | Layer | File path | Notes |
|------|-------|-----------|-------|
| `EventRegistrationModel.bloodTypeRaw` | domain | `lib/features/event_registration/domain/model/event_registration_model.dart` | Campo nuevo `final String? bloodTypeRaw;`, agregado a constructor (opcional, default `null`) y a `copyWith`. No rompe Pattern B (DTO sigue extendiendo Model). |
| `EventRegistrationDto` (fromJson custom) | data | `lib/features/event_registration/data/dto/event_registration_dto.dart` | El `fromJson` generado (`_$EventRegistrationDtoFromJson`) NO puede poblar `bloodTypeRaw` automáticamente (no hay clave `bloodTypeRaw` en el JSON del backend). Se necesita un factory manual: leer `json['bloodType'] as String?` ANTES de invocar el converter, y pasarlo como `bloodTypeRaw` solo cuando el parseo a `BloodType` resulta en `null` (para no duplicar el mismo valor dos veces quíitele cuando sí hay match). Ver detalle de implementación abajo. |

### Detalle de implementación sugerido para `EventRegistrationDto.fromJson`

No usar directamente `_$EventRegistrationDtoFromJson(json)` como único paso.
Patrón sugerido (mantiene Pattern B, el DTO sigue extendiendo el Model):

```dart
factory EventRegistrationDto.fromJson(Map<String, dynamic> json) {
  final dto = _$EventRegistrationDtoFromJson(json);
  final rawBloodType = json['bloodType'] as String?;
  if (dto.bloodType != null || rawBloodType == null) return dto;
  return EventRegistrationDto(
    // ...copiar todos los campos de dto...
    bloodTypeRaw: rawBloodType,
  );
}
```

Frontend debe evaluar si construir un `copyWith`-like manual es más limpio que
repetir todos los campos (dado que `EventRegistrationDto` no tiene `copyWith`
propio — usa el de `EventRegistrationModel`, que retorna `EventRegistrationModel`,
no `EventRegistrationDto`). Alternativa más simple: agregar `bloodTypeRaw` como
parámetro directo del constructor del DTO y pasarlo explícitamente en el
`fromJson` custom sin pasar por el generado dos veces — construir el objeto una
sola vez leyendo todos los campos con el `_$EventRegistrationDtoFromJson(json)`
y luego, SOLO si hace falta, reconstruir con el modelo base
`EventRegistrationModel` (no DTO) + `bloodTypeRaw`, ya que después de
`fromJson` el objeto no vuelve a serializarse con `toJson()` normalmente en
este flujo de lectura. Frontend tiene libertad de elegir el mecanismo más
limpio siempre que: (a) no rompa `EventRegistrationDto.toJson()` para los
flujos de escritura existentes (el campo no se envía al backend, es
solo-lectura), (b) `dart run build_runner build --delete-conflicting-outputs`
se ejecute después para regenerar `.g.dart`.

## Environment variables

Ninguna nueva.

## Change map

| File | Action | Reason | Risk |
|------|--------|--------|------|
| `lib/features/event_registration/domain/model/event_registration_model.dart` | modify | Agregar `bloodTypeRaw: String?` (campo + constructor param opcional + `copyWith`) para permitir el fallback de AC10 sin perder el valor crudo del backend | low |
| `lib/features/event_registration/data/dto/event_registration_dto.dart` | modify | `fromJson` custom que captura `json['bloodType']` crudo cuando el `_BloodTypeConverter` no logra mapear a un `BloodType` válido; pasar `bloodTypeRaw` al construir el DTO/Model | low |
| `lib/features/event_registration/data/dto/event_registration_dto.g.dart` | modify (regenerado) | `dart run build_runner build --delete-conflicting-outputs` tras el cambio de modelo — NO editar a mano | low |
| `lib/features/event_registration/presentation/registration_detail_page.dart` | modify | Fila "Tipo de sangre": `registration.bloodType?.label ?? registration.bloodTypeRaw ?? context.l10n.notAvailable` (reemplaza el fallback hardcodeado a `registration_maskedValue`) — cierra AC10 tal como está escrito en el PRD | low |
| `test/features/event_registration/presentation/registration_detail_page_test.dart` | modify | Agregar caso 1.3: `bloodType=null` + `bloodTypeRaw="__NOT_SHARED__"` (o `"••••"`) renderiza el string crudo tal cual, sin excepción; y caso 1.4: `bloodType=null` + `bloodTypeRaw=null` renderiza `"N/A"` | low |
| `integration_test/registration_organizer_patrol_test.dart` | create | Test Patrol e2e del flujo organizador ausente hoy: abrir detalle desde `AttendeesList` (pending y processed) verifica título "Detalles de solicitud"; inscripción aprobada + `allowOrganizerContact=true` muestra botones Llamar/WhatsApp; `allowOrganizerContact=false` los oculta; vista piloto (`MyRegistrations`) sigue mostrando "Mi inscripción" sin botones de contacto | med (nuevo archivo e2e, requiere fixtures de test/mock backend coherentes con el resto de la suite Patrol) |

Nada más en `lib/` requiere cambios — el resto del alcance del PRD (navegación,
extra, bottom bar, widget de contacto, l10n) ya está implementado y verificado
por lectura de código. QA debe correr los tests existentes + los nuevos para
confirmar comportamiento, no re-implementar.

## Datos/migraciones

Ninguna. No hay `analysis/MIGRATION_PLAN.md` — no aplica (sin cambios de schema
ni de contrato backend).

## Env

Ninguna. No hay `analysis/ENV_DELTA.md` — no aplica.

## Riesgos

- **R1 (alto → mitigado):** Fase 3 (prerrequisito bloqueante) no entregó
  `bloodTypeRaw` como el PRD asumía. Mitigado tratándolo como extensión mínima
  dentro de esta misma fase (ver "Hallazgo principal"). Si el usuario prefiere
  bloqueo estricto, debe indicarlo antes de Backend/Frontend.
- **R2 (bajo):** `registration_maskedValue` (clave ARB `"••••"`) queda sin uso
  tras el fix de AC10 (único call-site era el fallback que se reemplaza). No
  se agrega a change map su eliminación (fuera de alcance — el PRD no pide
  limpieza de ARB en esta fase); dejarla no rompe nada, solo es una clave
  muerta. Frontend puede opcionalmente eliminarla si quiere, no es obligatorio.
- **R3 (bajo):** El mecanismo exacto para poblar `bloodTypeRaw` en el `fromJson`
  del DTO tiene más de una forma válida de implementarse (ver detalle arriba);
  Frontend decide la más limpia respetando Pattern B y sin romper `toJson()`.
- **R4 (bajo, ya mitigado por diseño existente):** `RegistrationContactActions`
  confía en que `UrlLauncherHelper` ya usa `canLaunchUrl` internamente — no
  agregar guard adicional de teléfono vacío (correcto, según guardrail del PRD).
- **R5 (informativo):** No existe hoy ningún test Patrol e2e que cubra el flujo
  organizador (`isOrganizerView`, botones de contacto, ofuscación). El único
  Patrol existente (`integration_test/registration_patrol_test.dart`, 176
  líneas) cubre el flujo de inscripción del piloto, no el de organizador. QA
  debe generarlo como parte del cierre de esta corrida (según el título de la
  tarea "+ Patrol organizador").

## Orden

1. Frontend: `EventRegistrationModel.bloodTypeRaw` (domain) primero.
2. Frontend: `EventRegistrationDto` custom `fromJson` (data) — depende de (1).
3. Frontend: `dart run build_runner build --delete-conflicting-outputs` para regenerar `.g.dart`.
4. Frontend: `RegistrationDetailPage` fallback de bloodType (presentation) — depende de (1)-(3).
5. Frontend: actualizar `registration_detail_page_test.dart` con casos 1.3/1.4.
6. QA: correr `flutter test` completo (bottom_bar_test, contact_actions_test, detail_page_test) para confirmar que nada existente se rompió.
7. QA: generar/correr `integration_test/registration_organizer_patrol_test.dart` (flujo organizador e2e).
8. QA: `dart analyze` sin errores en archivos tocados.

## Superficie de regresion

- `RegistrationDetailPage`, `RegistrationDetailBottomBar`, `RegistrationContactActions` — ya en producción de facto (implementados), el único cambio de comportamiento es la fila de tipo de sangre.
- `MyRegistrationsDataView` (vista piloto) — no se toca, debe seguir mostrando "Mi inscripción" + banner + editar/cancelar sin cambios.
- Cualquier código que construya `EventRegistrationDto`/`EventRegistrationModel` manualmente (tests, mocks) — el nuevo parámetro `bloodTypeRaw` es opcional con default `null`, no rompe compilación de callers existentes.
- `EventRegistrationModel.toJson()` (extension) — confirmar que `bloodTypeRaw` NO se serializa en payloads de escritura (es un campo derivado de lectura, no debe viajar de vuelta al backend en `POST/PUT`).

## Fuera de alcance

- Localización de los sentinelas `"••••"` / `"__NOT_SHARED__"` — se muestran crudos, tal como especifica el PRD.
- Cualquier cambio a rideglory-api, contratos, migraciones — ninguno en esta fase.
- Eliminar la clave ARB `registration_maskedValue` (queda como deuda menor, no bloqueante).
- Pantallas nuevas — no aplica, `needsDesign = false`.
- `MyRegistrationsDataView` — sus puntos de navegación no pasan `isOrganizerView: true`, sin cambios.

## Next agent needs to know

- Backend (rideglory-api): **Stand-down. No ejecuta.** Cero cambios de contrato, cero migraciones, cero endpoints nuevos.
- Flutter dev (frontend): agregar `bloodTypeRaw` a modelo/DTO de `event_registration` + corregir el fallback en `registration_detail_page.dart` (línea ~127) según AC10 exacto del PRD. Regenerar `build_runner`. Todo lo demás del PRD ya está implementado — no reimplementar `isOrganizerView`, `RegistrationContactActions`, ni los 3 puntos de navegación (ya correctos).
- DevOps: no aplica, sin cambios de CI/env.
- QA: correr suite de tests existente + agregar casos 1.3/1.4 de bloodType + generar el Patrol e2e organizador ausente (`integration_test/registration_organizer_patrol_test.dart`). Trazar contra los 12 criterios de aceptación del PRD; los criterios 1-9 y 11-12 ya deberían pasar por lectura de código, el criterio 10 pasa solo después del fix de `bloodTypeRaw`.

## Change log

- 2026-07-03T16:38:12Z: Architect phase complete (retroactivo). Confirmado que ~95% del alcance del PRD ya está implementado en el árbol de trabajo. Único gap: AC10 (bloodType nullable fallback) requiere campo nuevo `bloodTypeRaw` inexistente hoy — agregado al change map como extensión mínima de esta misma fase en vez de bloqueo total. Backend stand-down confirmado. Sin cambios a DIAGRAMS.md (no hay entidades ni boundaries nuevas).
