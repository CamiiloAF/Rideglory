---
name: feature-dev
description: Entrega una feature completa de Rideglory en una sola corrida multi-agente - triage automatico del esfuerzo, gate de acceso a Pencil y gate de seguridad del rider sobre el plan, implementacion Clean Architecture sobre Supabase, tests (unit/widget/golden/Patrol), review escalado al riesgo y verificacion de fidelidad visual. Un solo artefacto de salida en docs/dev-runs/.
---

# feature-dev

Uso: `/feature-dev <descripcion de la feature o ruta a una nota>`

Objetivo: una ejecucion = una feature completa y verificada, sin que el usuario tenga que elegir nivel de esfuerzo ni correr fases por separado. El workflow dimensiona solo (s/m/l) y escala agentes, tests y review al riesgo real.

## Pasos

1. Si no viene descripcion, pregunta que feature construir antes de continuar.
2. Lanza el workflow con la descripcion tal cual:
   `Workflow({ name: 'feature-dev', args: '<descripcion o ruta>' })`
   - Si el usuario pidio explicitamente un tamano ("hazlo ligero", "esto es grande/riesgoso"), pasalo: `args: { source: '<descripcion>', size: 's'|'m'|'l' }`. En cualquier otro caso NO fuerces tamano — el triage decide.
3. Al terminar, relata al usuario el resultado del objeto retornado: que se implemento, si hubo cambios de esquema o server-side, estado de tests/review, gaps de cobertura, los requisitos que exigio el gate de seguridad si aplico, el checklist de verificacion manual (👤) y donde quedo el resumen (`docs/dev-runs/<slug>.md`).
4. Recuerdale que el codigo quedo **sin commitear** para su revision.
5. Si el workflow retorno `aborted: true`, no intentes implementar la feature por otra via. Hay tres bloqueos posibles y cada uno se explica distinto:
   - **Regla de CLAUDE.md**: la peticion viola el contrato. Explica cual regla y que habria que cambiar de la peticion.
   - **Sin acceso a Pencil**: el `.pen` no abrio. La UI no se implementa a ciegas — dile al usuario que reintente cuando Pencil responda, y no ofrezcas "avanzar solo con el `.md`" como alternativa.
   - **Gate de seguridad del rider**: el plan, tal como estaba escrito, llevaba a una violacion del SOS o de la privacidad de ubicacion. Muestra los `safetyBlockers` y ayuda al usuario a reformular el plan; abortar aqui fue barato a proposito.

No dupliques el trabajo del workflow revisando o testeando tu mismo despues; el resultado ya viene verificado. Solo interviene si el retorno trae `remainingBlockers` o hallazgos de fidelidad pendientes y el usuario pide resolverlos.
