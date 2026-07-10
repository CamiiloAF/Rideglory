# Plan: eliminacion-cuenta
> Estado: BORRADOR — revision humana pendiente. Generado: 2026-07-07T16:12:28Z

## Overview

Se consolidó el plan final de eliminación de cuenta en docs/plans/eliminacion-cuenta/05-sintesis.md, integrando los 18 ajustes de Architect y Plan Reviewer sobre la propuesta original del PO. Las 4 fases extienden el mismo endpoint DELETE /users/me y la misma orquestación backend (dominio → PII → Firebase Auth siempre al final), sin crear rutas paralelas. Fase 1 fija el núcleo de identidad con una pantalla dedicada de confirmación (Pencil) cuyo copy ya cubre todo lo que se borra en las 4 fases. Fase 2 resuelve el hallazgo de que Soat/Tecnomecanica no tienen cascada automática desde Vehicle. Fase 3 anonimiza historial de eventos preservando evidencia legal de consentimiento y bloquea (sin transferir) a organizadores con eventos activos, validando en el primer tap. Fase 4 se acota estrictamente al caso de cierre de app / borrado a medias e idempotencia, sin solapar con el error/retry base de fase 1. Las 4 fases se recomiendan en nivel full por tocar el mismo endpoint de alto riesgo con cambios de contrato de rideglory-api, PII/datos legales centrales y un paso irreversible (Firebase Auth deleteUser).

## Fases

- Fase 1 [FULL]: [Fase 1 — Eliminación de cuenta — núcleo de identidad](phases/phase-01-eliminacion-de-cuenta-nucleo-de-identidad.md)
- Fase 2 [FULL]: [Fase 2 — Eliminación de cuenta — vehículos y documentos](phases/phase-02-eliminacion-de-cuenta-vehiculos-y-documentos.md)
- Fase 3 [FULL]: [Fase 3 — Eliminación de cuenta — historial de eventos y organizadores activos](phases/phase-03-eliminacion-de-cuenta-historial-de-eventos-y-org.md)
- Fase 4 [FULL]: [Fase 4 — Eliminación de cuenta — manejo de fallas y estados intermedios](phases/phase-04-eliminacion-de-cuenta-manejo-de-fallas-y-estados.md)

## Supuestos

Heredados de `02-po-proposal.md`, sin cambios:

- Hay ~10 usuarios reales en producción hoy (confirmado 2026-07-10). El hard-delete directo sin
  migración de datos históricos en fases 1 y 2 sigue siendo la decisión correcta (es la promesa ya
  publicada en `docs/web/delete-account.html` y 10 usuarios no ameritan infraestructura de
  migración), pero toda prueba destructiva del flujo (`DELETE /users/me`) debe ejecutarse
  exclusivamente contra cuentas QA dedicadas (`qa1@gmail.com`/`qa2@gmail.com`), nunca contra
  ninguno de los usuarios reales existentes.
- Reutilización de correo tras eliminar cuenta: sin lista negra de emails, comportamiento ya
  publicado se mantiene.
- Retención de logs técnicos (30 días) mencionada en la página pública queda fuera de alcance de
  estas 4 fases.
- El video de demostración para Apple es un entregable operativo posterior, no una fase del plan.

## Riesgos

Consolidados de Architect + Plan Reviewer:

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
   grabar el video de demostración para Apple. Con usuarios reales ya en producción, este punto es
   además una salvaguarda de seguridad, no solo de cobertura: todas las pruebas end-to-end del
   borrado (incluidas fases 3 y 4) deben correr sobre cuentas QA desechables, nunca sobre datos
   reales.

## Como ejecutar una fase

> Cada fase se implementa con rg-exec en el NIVEL recomendado (ver el [LITE/NORMAL/FULL] del titulo y la seccion "Ejecucion recomendada" de cada fase):
> Workflow({ name: 'rg-exec', args: { source: 'docs/plans/eliminacion-cuenta/phases/phase-01-eliminacion-de-cuenta-nucleo-de-identidad.md', mode: '<lite|normal|full>' } })
> lite = mecanico/bajo riesgo; normal = feature acotada; full = complejo/riesgoso (contratos, migraciones, seguridad).
