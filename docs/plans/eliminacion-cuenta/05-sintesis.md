# Síntesis final — Eliminación de cuenta

_Generado: 2026-07-07T15:56:54Z_

## Overview

El plan cubre el requisito de App Store de permitir eliminar la cuenta desde dentro de la app,
en 4 fases incrementales que extienden un único endpoint backend (`DELETE /users/me`) y un único
flujo de UI en el perfil. Fase 1 entrega el núcleo de identidad (perfil, credenciales, Firebase
Auth) con una pantalla dedicada de confirmación (diseñada en Pencil) que ya incluye, en su copy,
todo lo que se borra a través de las 4 fases — para no mentir por omisión ni retrabajar la UI.
Fase 2 extiende la orquestación backend para borrar vehículos, fotos, mantenimientos y documentos
(SOAT/RTM), resolviendo un hallazgo del Architect: no hay cascada automática de `Vehicle` hacia
`Soat`/`Tecnomecanica` en el schema actual, así que deben borrarse explícitamente. Fase 3 anonimiza
el historial de participación en eventos y bloquea (no transfiere) la eliminación si el usuario es
organizador con eventos activos, validando esa condición en el primer tap para evitar hacer
confirmar dos veces a alguien que terminará bloqueado. Fase 4 se acota estrictamente al caso de
cierre de app / reapertura con borrado a medias e idempotencia del reintento — el manejo de
error/retry simple del flujo activo ya es criterio base de fase 1, evitando solape entre fases.

El orden de orquestación backend (dominio → PII de usuario → Firebase Auth siempre al final, por
ser el único paso irreversible) se fija desde la fase 1 y se extiende, no se rediseña, en fases 2 y
3 — todas comparten el mismo endpoint y el mismo contrato, evitando endpoints paralelos.

## Cambios aplicados

Respecto a `02-po-proposal.md`, se integraron los 18 ajustes de `03-architect-review.md` y
`04-plan-review.md`:

1. **Fase 1** — se decide explícitamente reemplazar el soft-delete parcial de `removeUser` por un
   `MessagePattern` nuevo `hardDeleteUser` (no mutar `removeUser` sin antes verificar sus otros
   llamadores existentes en `api-gateway`).
2. **Fase 1** — se fija desde ya el orden de 5 pasos de la orquestación: precondición (fase 3) →
   dominio (vehículos+docs+mantenimientos, fase 2) → anonimización de eventos (fase 3) → PII de
   usuario (`hardDeleteUser`) → Firebase Auth (`deleteUser`, último paso, irreversible). No se deja
   para que fase 4 lo arregle después.
3. **Fase 1** — se reemplazan los "dos `ConfirmationDialog` encadenados" de la propuesta original
   por una pantalla dedicada `DeleteAccountConfirmationPage` (diseñada en Pencil) con lista de qué
   se borra + `AppSwitchTile` de entendimiento que habilita el botón final.
4. **Fase 1** — el copy de "qué se borra" incluye desde el inicio los ítems de fase 2 (motos,
   fotos, mantenimientos, documentos) y fase 3 (historial anonimizado), para evitar retrabajo de UI
   y copy engañoso en releases intermedios.
5. **Fase 1** — se exige explícitamente estado `loading` con botón deshabilitado/spinner y
   prevención de doble-tap como criterio base de esta fase (no delegado a fase 4).
6. **Fase 2** — se agrega al alcance el borrado explícito de `Soat`/`Tecnomecanica` por
   `vehicleId IN (...)` antes/junto al `deleteMany` de `Vehicle` (no hay `onDelete: Cascade` hoy).
7. **Fase 2** — se fija la convención de carpeta de Storage por `ownerId` (o el método de derivar
   el path desde la download URL guardada) como prerequisito del borrado en lote de imágenes.
8. **Fase 2** — se agrega un `MessagePattern` nuevo `softDeleteMaintenancesByUserId` (por `userId`
   directo, ya existe el campo) en vez de loopear el endpoint existente por `vehicleId`.
9. **Fase 3** — se recorta el alcance de "organizador con eventos activos" a solo bloquear + pedir
   cancelar; se elimina "transferir" del alcance (no hay soporte de datos para reasignar `ownerId`
   hoy; se dejaría como sub-historia futura si se decide invertir en ello).
10. **Fase 3** — se especifica campo por campo qué se anonimiza vs. se preserva en
    `EventRegistration`: PII de contacto/salud se anonimiza; `riskAcceptedAt`/
    `riskAcceptanceVersion` y `medicalConsentAcceptedAt`/`medicalConsentVersion` preservan
    timestamp/versión sin el nombre asociado (evidencia legal de consentimiento).
11. **Fase 3** — se fija la definición formal de "evento activo" (`state IN (DRAFT, SCHEDULED,
    IN_PROGRESS)`) y el contrato `409 ACTIVE_EVENTS_AS_ORGANIZER` antes de que fase 4 diseñe
    reintentos.
12. **Fase 3** — la validación de organizador con eventos activos se ejecuta en el primer tap del
    ítem "Eliminar cuenta", antes de cualquier paso de confirmación.
13. **Fase 3** — el mensaje de bloqueo por organizador es un estado dedicado con CTA accionable a
    gestión de eventos, no un diálogo de error genérico.
14. **Fase 3** — se agrega la verificación explícita de si vistas de terceros (lista de
    asistentes/detalle de evento) necesitan placeholder tipo "Usuario eliminado".
15. **Fase 4** — se reclasifica complejidad de media a alta (no hay precedente en el repo de
    operación multi-paso con manejo de fallo parcial); se fija que el endpoint es una sola llamada
    síncrona de extremo a extremo (recomendado), no polling de estado, salvo que pruebas reales
    demuestren que el timeout es insuficiente.
16. **Fase 4** — se acota su criterio de aceptación exclusivamente al caso "cierre de app /
    reapertura con borrado a medias" + idempotencia; el manejo de error/retry simple del flujo
    activo queda como criterio base de fase 1, evitando solape entre fases.
17. **Todas las fases** — se refuerza que cualquier pantalla nueva se diseña en `rideglory.pen`
    (nunca HTML mockup nuevo) y que la ejecución se detiene si el MCP de Pencil está caído.
18. **Todas las fases** — se fija que las fases 1→2→3 extienden el MISMO endpoint
    `DELETE /users/me` y la misma orquestación backend (añadiendo pasos), sin crear endpoints
    paralelos; el orden de operaciones (validar elegibilidad organizador → confirmación UI →
    borrado en cascada) queda como contrato explícito coordinado con el plan de backend.

## Lista final de fases

| # | Título | Depende de | Nivel | Por qué |
|---|--------|-----------|-------|---------|
| 1 | Eliminación de cuenta — núcleo de identidad | — | **full** | Toca contrato nuevo de `rideglory-api` (`DELETE /users/me`, `hardDeleteUser`, `deleteUser` de Firebase Auth), es la primera vez que se fija el orden de orquestación de 5 pasos con el único paso irreversible del sistema (borrado de Firebase Auth), y requiere decidir si se reemplaza o no un `MessagePattern` existente (`removeUser`) verificando todos sus llamadores — alto blast radius y difícil de revertir si el orden queda mal desde el día uno. |
| 2 | Eliminación de cuenta — vehículos y documentos | 1 | **full** | Extiende el mismo contrato con lógica cross-MS nueva (bulk-delete de `Vehicle`+`Soat`+`Tecnomecanica` sin cascada automática en el schema, nuevo `MessagePattern` `softDeleteMaintenancesByUserId`, borrado en lote de Storage) — cambios de contrato entre microservicios y manejo de datos PII/documentos legales del usuario, sin precedente de "bulk por owner" en el repo. |
| 3 | Eliminación de cuenta — historial de eventos y organizadores activos | 1, 2 | **full** | Anonimización cross-MS de datos con matices legales (consentimiento de riesgo/médico) que exige distinguir campo por campo qué se preserva, más una precondición de negocio nueva (bloqueo 409 por organizador con eventos activos) que es un cambio de contrato de API y de UX con impacto en terceros (posible placeholder "Usuario eliminado" visible a otros usuarios) — riesgo de negocio y de auditoría, no solo técnico. |
| 4 | Eliminación de cuenta — manejo de fallas y estados intermedios | 1, 2, 3 | **full** | Reclasificada explícitamente de "media" a "alta" por el Architect: no hay precedente en el repo de operación multi-paso con manejo de fallo parcial; exige decidir arquitectura de idempotencia/reintento sobre un endpoint que ya es de alto riesgo (borrado irreversible de cuenta) — cualquier error de diseño aquí puede dejar cuentas en estado dañado e irreversible. |

Las 4 fases se recomiendan en **full** porque las 4 tocan el mismo endpoint de alto riesgo
(`DELETE /users/me`), con cambios de contrato de `rideglory-api`, PII/datos legales centrales, y
un paso genuinamente irreversible (Firebase Auth `deleteUser`). Ninguna es candidata a `lite`/
`normal`: incluso la fase 1, que en apariencia es "solo un botón más en el perfil", requiere
decisiones de arquitectura backend de alto impacto (orden de orquestación, reemplazo de
`MessagePattern` existente) que se propagan sin posibilidad de revertir limpiamente una vez un
usuario real ejecuta el flujo.

## Supuestos y riesgos

**Supuestos** (heredados de `02-po-proposal.md`, sin cambios):
- No hay usuarios reales en producción hoy, lo que permite hard-delete directo sin migración de
  datos históricos en fases 1 y 2.
- Reutilización de correo tras eliminar cuenta: sin lista negra de emails, comportamiento ya
  publicado se mantiene.
- Retención de logs técnicos (30 días) mencionada en la página pública queda fuera de alcance de
  estas 4 fases.
- El video de demostración para Apple es un entregable operativo posterior, no una fase del plan.

**Riesgos principales** (consolidados de Architect + Plan Reviewer):
1. Si fases 1 y 2 se liberan por separado y una build llega a revisión de Apple solo con fase 1
   completa, el revisor podría notar que motos/documentos no se eliminan de inmediato — conviene
   agrupar 1+2 antes de la próxima re-sumisión a la tienda.
2. Cascada de borrado incompleta en `vehicles-ms`: `Soat`/`Tecnomecanica` no tienen
   `onDelete: Cascade` — mitigado en fase 2 con borrado explícito por `vehicleId IN (...)`.
3. Convención de Storage path vs. download URL: hoy se guarda la URL completa, no el path relativo
   — fase 2 debe fijar la convención de carpeta por `ownerId` antes de implementar el bulk-delete.
4. Timeout de orquestación síncrona de 4-5 pasos encadenados puede acercarse al timeout de Dio
   (20s) — fase 4 debe decidir si sube el timeout específico de este endpoint o si documenta por
   qué no hace falta tras medir en pruebas reales.
5. `removeUser` en uso por otros llamadores no auditados: cambiar su comportamiento sin verificar
   quién más lo invoca podría romper código existente — fase 1 debe hacer el grep antes de tocarlo.
6. Anonimización de `EventRegistration` sin distinguir consentimiento legal de PII podría borrar
   evidencia de aceptación de riesgo/consentimiento médico — mitigado con la especificación campo
   por campo de fase 3.
7. Dependencia cruzada con el plan de backend: el orden de operaciones (validar elegibilidad
   organizador → confirmación UI → borrado en cascada) debe coordinarse explícitamente entre este
   plan de Flutter y el plan de `rideglory-api` — si el backend invierte el orden, la fase 3 de UI
   no puede prevenir el bloqueo con una validación previa.
8. No hay usuario/dato de prueba con todos los tipos de datos simultáneos (vehículo, mantenimiento,
   documento, registro a evento) — QA debe crear ese escenario antes de cerrar cada fase y antes de
   grabar el video de demostración para Apple.
