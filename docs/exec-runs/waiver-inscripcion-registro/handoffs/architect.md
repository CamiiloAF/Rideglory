# Architect handoff — waiver-inscripcion-registro

**Date:** 2026-07-02T03:36:44Z
**Status:** done
**Nivel:** normal

---

## Decisiones

### 5 flags
| Flag | Valor | Por qué |
|------|-------|---------|
| `uiChanges` | **true** | Nuevo paso de wizard (`RegistrationWaiverStep`), 2 `AppSwitchTile` nuevos en el paso médico, ocultar nav bar en último paso. |
| `backendChanges` | **false** | Confirmado en `rideglory-api`: `UNDERAGE_RIDER` (422) ya existe en `events-ms/src/registrations/registrations.service.ts:328` (Fase 2 completa). Cero cambios de backend en esta fase. |
| `frontendChanges` | **true** | Cubit (guardia de edad, seam de testing, inyección de campos legales), widgets (2 nuevos/modificados), constantes, l10n. |
| `dbChanges` | **false** | Columnas `shareMedicalInfo`/`allowOrganizerContact`/`riskAcceptedAt`/`riskAcceptanceVersion` ya existen en DB desde Fase 1; sin migraciones nuevas. |
| `needsDesign` | **false** | El paso waiver compone widgets existentes (`RegistrationStepHeader`, `AppButton`, `AppTextButton`, `ConstrainedBox+SingleChildScrollView`) sin ningún patrón visual nuevo; los switches usan `AppSwitchTile` ya existente. No hay Pencil frame nuevo que diseñar — el layout ya está completamente especificado (código concreto) en la nota fuente del plan. |

### Auditoría de la nota fuente contra el código real (correcciones al §4 del PRD)

La nota fuente (`docs/plans/legal-privacidad-edad/phases/phase-04-...md`) fue escrita antes de que Fase 3 se ejecutara sobre este mismo codebase. Al abrir el código real hoy, encontré una diferencia importante que **Build debe conocer para no duplicar trabajo**:

1. **`RegistrationFormFields.shareMedicalInfo` y `RegistrationFormFields.allowOrganizerContact` YA EXISTEN** en `lib/features/event_registration/constants/registration_form_fields.dart` (confirmado leyendo el archivo completo). Fase 3 ya las agregó junto con los campos del modelo. **Único cambio pendiente en ese archivo:** agregar el quinto elemento `<String>[]` a `RegistrationWizardSteps.fieldsByStep` (el paso waiver no tiene campos `FormBuilder`).
2. **`EventRegistrationModel`** ya tiene `shareMedicalInfo`, `allowOrganizerContact`, `riskAcceptedAt`, `riskAcceptanceVersion` (confirmado, incluyendo `copyWith` y `==`/`hashCode` por `id`).
3. **`EventRegistrationDto` / `EventRegistrationModelExtension.toJson()`** ya serializan los 4 campos legales — confirmado en `lib/features/event_registration/data/dto/event_registration_dto.dart`. El payload del POST llevará estos campos automáticamente en cuanto `_buildRegistration()` los pase al constructor del modelo.
4. **`_preloadFromExistingRegistration()`** en `RegistrationFormCubit` **YA hace `patchValue` de `shareMedicalInfo` y `allowOrganizerContact`** (confirmado leyendo el archivo completo, líneas ~140-146). Este paso de la nota fuente (6e) **ya está implementado** — no requiere cambio.
5. Pendiente real en el cubit: guardia de edad en `saveRegistration()`, `_calculateAge()`, seam `birthDateOverrideForTesting`, e inyección de `riskAcceptedAt`/`riskAcceptanceVersion` (y lectura explícita de `shareMedicalInfo`/`allowOrganizerContact` del form) en `_buildRegistration()` — estos campos NO están en el constructor `EventRegistrationModel(...)` actual dentro de `_buildRegistration()` (confirmado: el método actual no los pasa, así que hoy siempre viajan con su default `false`/`null`).
6. `RegistrationWizardNavigationBar` **hoy se muestra siempre** (no hay condición `if (!_wizard.isLastStep)` en `registration_form_content.dart`) — el cambio 7d de la nota fuente sigue pendiente tal cual está descrito.
7. `RegistrationMedicalStep` termina hoy en `RegistrationBloodTypeSelector` (línea final del `Column`) — la sección "Privacidad" con `ProfileFormSectionHeader` + 2 `AppSwitchTile` sigue pendiente tal cual está descrita en la nota fuente.
8. No existe todavía `registration_waiver_step.dart` ni ningún test para waiver/medical-switches — todo por crear, tal cual la nota fuente.

**Conclusión:** el resto del plan de la nota fuente (`docs/plans/legal-privacidad-edad/phases/phase-04-...md`, secciones "Que se debe hacer", Pasos 1, 3-7) sigue siendo válido y preciso contra el código real, **excepto los puntos 1 y 4 de arriba, que ya están hechos**. Build no debe re-agregar esas constantes ni el patch de `_preloadFromExistingRegistration` — solo verificar que ya existen y seguir con el resto.

### Pre-flight de dependencias (Paso 0.6 de la nota fuente) — CONFIRMADO

- Fase 2 (backend `UNDERAGE_RIDER`): **completa**. `events-ms/src/registrations/registrations.service.ts:328` lanza `RpcException({ status: 422, message: 'UNDERAGE_RIDER' })`; tests en `registrations.service.age-validation.spec.ts`.
- Fase 3 (modelos/DTOs Flutter): **completa**. Ver puntos 2-4 arriba.
- **No hay bloqueo.** Build puede proceder con confianza.

### Mecanismo único de error `UNDERAGE_RIDER`

`DomainException` (`lib/core/exceptions/domain_exception.dart`) solo tiene `message: String` — no existe ni se debe inventar un campo `code`. El widget discrimina con `error.message.contains('UNDERAGE_RIDER')`. Riesgo documentado (R2 de la nota fuente): si el backend cambia el formato del mensaje, el rider vería el mensaje crudo. Aceptable para esta fase (sin usuarios reales).

### Estrategia de mensajes de error locales

El cubit emite el texto en español **directamente** en `error.message` para los dos errores locales (edad < 18, `birthDate` faltante) — no usa claves ARB para esos mensajes porque el widget necesita un único punto de discriminación (`.contains(...)`) y no un mapa de traducción. Textos exactos a emitir (deben coincidir con la detección del widget):
- Edad < 18: `'Debes tener al menos 18 años para inscribirte en una rodada.'`
- `birthDate` nulo: `'Debes ingresar tu fecha de nacimiento para continuar.'`

El widget detecta el caso "falta birthDate" con `error.message.contains('fecha de nacimiento')`. Alternativa más robusta (recomendada si Build quiere evitar acoplamiento por substring): exponer una constante `@visibleForTesting` en el cubit (p. ej. `missingBirthDateErrorMessage`) e importarla en el widget para comparar por igualdad exacta en vez de por substring. Build debe documentar en su handoff cuál estrategia usó.

### Seam de testing para la guardia de edad

`saveRegistration()` lee `birthDate` de `formKey.currentState!.value` **antes** de invocar `_buildRegistration()` (que a su vez tiene su propio seam `buildRegistrationOverride`, ya existente, para el resto del flujo). Como los tests unitarios no tienen un `FormBuilderState` real, se necesita un seam nuevo y separado: `@visibleForTesting DateTime? birthDateOverrideForTesting`. Cuando no es `null`, `saveRegistration()` usa este valor en lugar de leer el form. **Nunca usarlo desde código de producción** (mismo patrón que `buildRegistrationOverride`).

### Ruta de perfil verificada

`AppRoutes.editProfile = '/profile/edit'` **existe y está nominada** (`lib/shared/router/app_routes.dart:8`). El botón "Ir a mi perfil" puede usar `context.pushNamed(AppRoutes.editProfile)` sin necesidad de agregar rutas nuevas (cumple el guardrail "no modificar `app_router.dart`" — solo se navega a una ruta ya existente).

### `event.ownerName` nullable

Confirmado `final String? ownerName;` en `EventModel` (`lib/features/events/domain/model/event_model.dart:51`). El widget debe envolver el `Text` del organizador en `if (event.ownerName != null)`.

### `RegistrationStepHeader.subtitle` es `required`

Confirmado (`registration_step_header.dart:13`, `required this.subtitle`). El paso waiver DEBE pasar `subtitle: context.l10n.registration_waiverSubtitle` — no se toca el constructor.

### `ProfileFormSectionHeader` reutilizable cross-feature

No existe un widget de encabezado de sección compartido en `lib/shared/widgets/form/`. `ProfileFormSectionHeader` (`lib/features/profile/presentation/widgets/profile_form_section_header.dart`) es un `StatelessWidget` simple (`Text` mayúsculas + tracking) sin dependencias del feature de perfil — es seguro importarlo directamente en `registration_medical_step.dart`. No crear un duplicado.

### `AppSwitchTile.subtitle` es opcional en la firma pero obligatorio por esta fase

`AppSwitchTile` (`lib/shared/widgets/form/app_switch_tile.dart`) declara `final String? subtitle;` (nullable, sin default en subtitle). Esta fase impone que **ambos** switches nuevos pasen siempre un `subtitle` no nulo (ajuste A3 WCAG del Plan Review previo). No se modifica el widget compartido.

---

## Change map

| Ruta | Acción | Razón | Riesgo |
|------|--------|-------|--------|
| `lib/l10n/app_es.arb` | modify | +14 claves l10n bajo prefijo `registration_` (privacidad, waiver, edad, goToProfile) | low |
| `lib/l10n/app_localizations.dart` / `app_localizations_es.dart` (generado) | modify | Regenerado automáticamente por `flutter gen-l10n` tras editar el ARB | low |
| `lib/features/event_registration/constants/registration_form_fields.dart` | modify | Solo agregar `<String>[]` como 5º elemento de `RegistrationWizardSteps.fieldsByStep` (las 2 constantes de campo ya existen — ver Decisiones) | low |
| `lib/core/services/analytics/analytics_params.dart` | modify | +`stepNameWaiver = 'waiver'` | low |
| `lib/features/event_registration/presentation/wizard/steps/registration_medical_step.dart` | modify | +sección "Privacidad" (`ProfileFormSectionHeader` + 2 `AppSwitchTile` con `subtitle` obligatorio) al final del `Column` | med |
| `lib/features/event_registration/presentation/wizard/steps/registration_waiver_step.dart` | create | Nuevo paso 5 del wizard — header, organizador condicional, texto legal scrollable, error inline diferenciado, CTA + Cancelar vía callbacks | med |
| `lib/features/event_registration/presentation/cubit/registration_form_cubit.dart` | modify | +guardia de edad en `saveRegistration()` (antes de `_buildRegistration()`), +`_calculateAge()`, +seam `birthDateOverrideForTesting`, +inyección de `shareMedicalInfo`/`allowOrganizerContact`/`riskAcceptedAt`/`riskAcceptanceVersion` en `_buildRegistration()` (el patch de edición ya existe, no tocar) | high |
| `lib/features/event_registration/presentation/registration_form_content.dart` | modify | +import + `RegistrationWaiverStep` en `IndexedStack[4]`, +`stepNameWaiver` en `_stepNameFor()`, +`if (!_wizard.isLastStep)` envolviendo el `BlocBuilder` de la nav bar | med |
| `test/features/event_registration/presentation/cubit/registration_form_cubit_age_validation_test.dart` | create | Tests unitarios: edad<18 local, edad=18 exacta, birthDate nulo, campos legales en `_buildRegistration()`, error `UNDERAGE_RIDER` del backend emitido tal cual | low |
| `test/features/event_registration/presentation/wizard/steps/registration_waiver_step_test.dart` | create | Tests widget: render, organizador nullable, loading, error `UNDERAGE_RIDER` vs error local vs error genérico, callbacks `onBack`/`onSubmit` | low |
| `test/features/event_registration/presentation/wizard/steps/registration_medical_step_test.dart` | create | Tests widget: exactamente 2 `AppSwitchTile` con `subtitle` no nulo | low |

Build **solo** toca los archivos de esta tabla. Ningún cambio a `app_router.dart`, `registration_wizard_controller.dart`, `registration_step_indicator.dart`, `registration_wizard_navigation_bar.dart` (widget en sí no cambia, solo su punto de uso condicional en `registration_form_content.dart`), ni a `rideglory-api`.

---

## Contratos

Ninguno nuevo. `rideglory-api` no se toca en esta fase. Los contratos consumidos (ya resueltos en Fases 1-2) son:
- `POST /events/:eventId/registrations` puede retornar `422` con `message: 'UNDERAGE_RIDER'` cuando la edad calculada del rider es < 18.
- `CreateRegistrationDto`/`UpdateRegistrationDto`/respuesta ya aceptan/retornan `shareMedicalInfo: boolean`, `allowOrganizerContact: boolean`, `riskAcceptedAt: string (ISO)`, `riskAcceptanceVersion: string`.

## Datos/migraciones

Ninguno. Columnas ya existen desde Fase 1 (`legal-privacidad-edad-fase1`).

## Env

Ninguna variable nueva.

## Riesgos

| # | Riesgo | Mitigación |
|---|--------|-----------|
| R1 | Nav bar duplicada en el waiver si no se envuelve el `BlocBuilder` con `if (!_wizard.isLastStep)` | Cambio explícito en change map; QA verifica visualmente (criterio 4) |
| R2 | `error.message.contains('UNDERAGE_RIDER')` frágil ante cambio de formato del backend | Aceptado (sin usuarios reales); documentado para futura migración a campo `code` |
| R3 | `Expanded` dentro del `IndexedStack` (que vive en un `SingleChildScrollView` sin altura acotada) lanza excepción en runtime | Usar `ConstrainedBox(maxHeight: 280) + SingleChildScrollView` interno, nunca `Expanded`, en `RegistrationWaiverStep` |
| R4 | Bypass de validación de marca de vehículo si el waiver llama `cubit.saveRegistration()` directo | CTA usa `onSubmit: _submitRegistration` (callback del padre), nunca el cubit directo |
| R5 | Botón Cancelar cierra la página en vez de retroceder | `onBack: _onBack` (callback del padre), nunca `context.pop()` |
| R6 | `event.ownerName` null-check exception | `if (event.ownerName != null)` antes de renderizar el `Text` |
| R8 | Guardia de edad no ejercitable en tests unitarios sin árbol de widgets | Seam `birthDateOverrideForTesting`, análogo a `buildRegistrationOverride` ya existente |
| R9 | `registration_goToProfile` como clave l10n muerta si no se implementa la acción | Ruta `AppRoutes.editProfile` ya confirmada existente y nominada — implementar la acción, no eliminar la clave |

## Orden

1. `lib/l10n/app_es.arb` (+ `flutter gen-l10n`)
2. `lib/core/services/analytics/analytics_params.dart` (constante aislada, sin dependencias)
3. `lib/features/event_registration/constants/registration_form_fields.dart` (solo el 5º elemento de `fieldsByStep`)
4. `lib/features/event_registration/presentation/cubit/registration_form_cubit.dart` (guardia de edad, seam, inyección de campos legales) — antes del widget para poder testear el cubit de forma aislada
5. `lib/features/event_registration/presentation/wizard/steps/registration_medical_step.dart` (switches de privacidad)
6. `lib/features/event_registration/presentation/wizard/steps/registration_waiver_step.dart` (nuevo widget, consume el cubit ya modificado)
7. `lib/features/event_registration/presentation/registration_form_content.dart` (integración final: IndexedStack, `_stepNameFor`, ocultar nav bar)
8. Tests (cubit → medical step → waiver step)
9. `dart analyze` + `flutter gen-l10n` de cierre

## Superficie de regresión

- Flujo completo de inscripción (creación y edición) — el wizard pasa de 4 a 5 pasos; cualquier test o snapshot que asuma 4 pasos debe actualizarse.
- Analítica de wizard (`registrationStepAdvanced`/`registrationStepBack`) — nuevo `step_index: 4`/`step_name: 'waiver'`.
- Payload del POST/PUT de inscripción — ahora incluye 4 campos legales con valores reales (antes viajaban con default `false`/`null` porque `_buildRegistration()` no los pasaba).
- `RegistrationWizardNavigationBar` deja de renderizarse en el último paso — cualquier código que dependa de que la nav bar esté siempre presente debe revisarse.
- Ningún cambio de contrato en `rideglory-api` — cero riesgo de regresión backend.

## Fuera de alcance

- Router (`app_router.dart`) — sin cambios.
- Backend (`rideglory-api`) — sin cambios, Fases 1-2 ya resueltas.
- Modelos/DTOs Flutter — ya extendidos en Fase 3, sin cambios adicionales.
- Texto legal definitivo del abogado — placeholder `registration_waiverBodyV0`.
- `subtitle` opcional en `RegistrationStepHeader`.
- Pantalla de autorización Ley 1581 (Fase 6) y vista del organizador (Fase 7) del plan origen.

## Change log

- 2026-07-02: Architect phase complete. Confirmado que Fases 2-3 del plan `legal-privacidad-edad` están completas en el código real. Detectada y documentada discrepancia entre la nota fuente y el estado actual del código (constantes de campo y patch de edición ya existentes). Change map de 11 archivos (7 modify, 1 create de producción, 3 create de test). Sin cambios de backend/DB/env. `needsDesign = false`.
