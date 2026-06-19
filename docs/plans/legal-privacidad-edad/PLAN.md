# Plan: legal-privacidad-edad
> Estado: BORRADOR — revisión humana pendiente. Generado: 2026-06-19T20:06:03Z

## Overview

Plan de 6 fases para cumplir los requisitos legales de la app: validación de edad mínima (≥18), consentimiento informado de datos médicos (Ley 1581), waiver de riesgos para riders, declaración de responsabilidad para organizadores, y ofuscación condicional de datos PII en la vista del organizador. El plan cubre backend (events-ms, users-ms, rideglory-contracts) y Flutter de forma coordinada. Las Fases 1-3 son de infraestructura; las Fases 4-6 son de producto. La cadena crítica es: Fase 1 → (Fase 2 || Fase 3) → Fase 4 → Fases 5/6.

## Fases

| # | Título | dependsOn | Nivel |
|---|--------|-----------|-------|
| 1 | Contratos, schema de backend y endpoint medical-consent | [] | **FULL** |
| 2 | Validación de edad y ofuscación condicional en backend | [1] | **FULL** |
| 3 | Modelos y DTOs Flutter | [1] | **NORMAL** |
| 4 | Waiver del rider en el flujo de inscripción | [2, 3] | **FULL** |
| 5 | Consentimientos legales: responsabilidad del organizador y Ley 1581 | [1, 3] | **NORMAL** |
| 6 | Vista del organizador con ofuscación y contacto | [2, 3] | **NORMAL** |

- Fase 1 [FULL]: [Fase 1 — Contratos, schema de backend y endpoint medical-consent](phases/phase-01-contratos-schema-de-backend-y-endpoint-medical-c.md)
- Fase 2 [FULL]: [Fase 2 — Validación de edad y ofuscación condicional en backend](phases/phase-02-validacion-de-edad-y-ofuscacion-condicional-en-b.md)
- Fase 3 [NORMAL]: [Fase 3 — Modelos y DTOs Flutter](phases/phase-03-modelos-y-dtos-flutter.md)
- Fase 4 [FULL]: [Fase 4 — Waiver del rider en el flujo de inscripción](phases/phase-04-waiver-del-rider-en-el-flujo-de-inscripcion.md)
- Fase 5 [NORMAL]: [Fase 5 — Consentimientos legales: responsabilidad del organizador y Ley 1581](phases/phase-05-aceptacion-de-responsabilidad-del-organizador.md)
- Fase 6 [NORMAL]: [Fase 6 — Vista del organizador con ofuscación y contacto](phases/phase-07-vista-del-organizador-con-ofuscacion-y-contacto.md)

## Supuestos

| # | Supuesto | Impacto si falla |
|---|----------|-----------------|
| S1 | No hay usuarios reales en producción (confirmado en `project_no_real_users.md`) — el default retroactivo `shareMedicalInfo = false` no afecta datos reales. | Ninguno en esta iteración. |
| S2 | "Evento en curso" = `EventState.inProgress` (ya existe en `EventModel`). | Si la definición cambia, la Fase 2 requiere ajuste en el predicado. |
| S3 | `sosTriggeredAt` puede o no existir en el schema de Prisma de events-ms — **verificar en pre-flight de Fase 2 (gate accionable)**. Si no existe, agregar migración en Fase 1 o al inicio de Fase 2 antes de cualquier lógica de ofuscación de Capa B. | Bloquea la Fase 2b si no se verifica antes de implementar. |
| S4 | El texto del waiver (v0) y la declaración Ley 1581 se implementan como placeholders en ARB. El texto definitivo del abogado se incorpora sin cambios de código. | Si el texto del abogado requiere interactividad (formularios, firmas), amplía el scope. |
| S5 | Centinela semántico elegido: `"__NOT_SHARED__"` (acordado en Fase 1 antes de cerrar contratos). | Si se usa string literal en español, se genera deuda de localización. |
| S6 | Autorización Ley 1581 intercepta el paso médico del wizard (no flujo de perfil nuevo). | Si se decide interceptar en el perfil del usuario, la Fase 6 requiere nueva sección en `EditProfilePage`. |
| S7 | `rideglory-contracts` es submódulo; el flujo de PR puede tomar tiempo. Backend y Flutter se desarrollan en paralelo con contratos localmente enlazados. | Si el PR de contratos tarda, la cadena completa espera. |
| S8 | `RegistrationStepIndicator` recibe `stepCount` como parámetro (verificar en pre-flight de Fase 4 — primer paso obligatorio). Si está hardcodeado, generalizar antes de agregar el paso de waiver. | Sin generalización previa, el indicador visual rompe al agregar el paso 5. |

## Riesgos

| # | Riesgo | Probabilidad | Impacto | Mitigación |
|---|--------|-------------|---------|------------|
| R1 | `rideglory-contracts` como cuello de botella | Alta | Bloquea Fases 1-7 si el PR tarda. | Priorizar como primera acción; usar `npm link` local mientras tanto. |
| R2 | `bloodType` ofuscado rompe deserialización del enum en Flutter | Media | `EventRegistrationDto.fromJson()` lanza excepción en runtime. | Fase 3 implementa getter de parse seguro. Cubierto en el plan. |
| R3 | Default retroactivo `shareMedicalInfo = false` para inscripciones existentes | Baja (sin usuarios reales) | Organizadores perderían acceso a datos médicos de rodadas activas. | Documentado en migración. Con usuarios reales, considerar default temporal `true` con banner. |
| R4 | Descarte silencioso de campos en `toJson()` de `EventRegistrationModelExtension` | Alta (confirmado por auditor) | Los 4 campos legales no viajan en el POST aunque el modelo los tenga. | Fase 3 requiere criterio de aceptación verificable: test/curl confirma presencia de los 4 campos en el body. |
| R5 | `RegistrationDetailBottomBar` early-return oculta botones de contacto en inscripciones aprobadas | Media | El organizador no puede llamar/contactar al rider aunque lo haya autorizado. | Fase 7 refactoriza el `build()` para independizar `RegistrationContactActions` del early-return. |
| R6 | `RegistrationDetailPage` no tiene acceso al estado del evento | Media | La coherencia de la UI entre ofuscación backend y vista Flutter depende de datos que no fluyen hoy. | Fase 7 extiende `RegistrationDetailExtra` con `eventState` y `eventSosTriggeredAt`. |
| R7 | Consentimiento Ley 1581 solo en `SharedPreferences` | Baja | Pérdida de consentimiento al reinstalar; riesgo de compliance. | Persistencia offline-first: caché local + backend como fuente de verdad. |
| R8 | Organizador que también es participante | Baja | `isRegistrantViewer` basado en `userId` da falso positivo. | Fase 7 usa `isOrganizerView: bool` explícito en `RegistrationDetailExtra`. |
| R9 | Texto legal no disponible a tiempo | Media | Flujo completo bloqueado en producción aunque técnicamente funcional. | Placeholder v0 con texto genérico hasta obtener asesoría legal. |
| R10 | `sosTriggeredAt` no existe en Prisma de events-ms | Media | La ofuscación de Capa B (cédula/correo/ciudad en SOS) no puede implementarse. | Gate accionable en pre-flight de Fase 2: verificar antes de escribir lógica de Fase 2b. |

## Como ejecutar una fase

> Cada fase se implementa con `rg-exec` en el NIVEL recomendado (ver el `[LITE/NORMAL/FULL]` del título y la sección "Ejecución recomendada" de cada fase):

```js
Workflow({ name: 'rg-exec', args: { source: 'docs/plans/legal-privacidad-edad/phases/phase-01-contratos-schema-de-backend-y-endpoint-medical-c.md', mode: 'full' } })
```

> `lite` = mecánico/bajo riesgo; `normal` = feature acotada; `full` = complejo/riesgoso (contratos, migraciones, seguridad).

Sustituir el `source` por el archivo de la fase a ejecutar y `mode` por el nivel indicado en el título de la fase.
