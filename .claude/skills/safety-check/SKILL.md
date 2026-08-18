---
name: safety-check
description: Checklist de seguridad del rider y privacidad de ubicacion de Rideglory antes de cerrar una feature (SOS que nunca falla en silencio, consentimiento explicito de ubicacion, tracking que termina de verdad, enmascarado en la base, borrado real de cuenta). Delega en safety-compliance-reviewer y cierra con un veredicto binario.
---

# safety-check

Uso: `/safety-check [ruta o nombre de feature]`. Sin argumento, revisa los cambios actuales (`git status` / `git diff`).

Este flujo existe porque los defectos que cubre no fallan un test ni ensucian un lint: se ven perfectos hasta la primera emergencia real. En este proyecto el SOS ya viajaba por un WebSocket que, si estaba caido, descartaba la alerta sin avisarle a nadie.

## Pasos

1. Delega la revision al subagente `safety-compliance-reviewer` (via Agent, subagent_type: `safety-compliance-reviewer`), indicandole el alcance (ruta, feature o "diff actual"). Su veredicto es un **gate**, no una opinion.
2. Si reporta hallazgos, presentalos priorizados, en este orden:
   1. **SOS que puede fallar en silencio** — cualquier ruta de fallo que termine en un `return` mudo o un `catch` vacio, alerta que no se persiste localmente antes de intentar la red, o que no sobrevive a que maten la app. Bloqueante absoluto.
   2. **UI que dice "enviado" antes de la confirmacion del servidor.**
   3. **Fallback sin datos roto** — contacto de emergencia o SMS con coordenadas que se leen *durante* la emergencia en vez de estar cacheados desde el inicio de la rodada.
   4. **SOS que cierra solo** por una desconexion o por el fin del evento, en vez de por una persona.
   5. **Ubicacion sin consentimiento explicito**, sin indicador visible mientras esta activa, o sin parada accesible; y tracking en background que no termina de verdad al terminar la rodada.
   6. **Enmascarado hecho en el cliente** en vez de en la base con RLS y vistas — si el dato viajo, ya se filtro.
   7. El resto: estados sin permiso / sin GPS / sin conexion sin disenar, fotos de documentos publicas por defecto, edad minima validada solo en el cliente.
3. **No corrijas los hallazgos automaticamente sin que el usuario lo pida** — este flujo es de verificacion, no de arreglo. Pregunta si quiere que se apliquen los fixes (y si los pide, es trabajo de `flutter-dev` o `supabase-backend-dev`).
4. Si el alcance incluye el borrado de cuenta, el consentimiento de datos medicos, o cualquier feature de ubicacion en background, verifica explicitamente (aunque el subagente no lo mencione) que exista: el borrado real de datos en Postgres **y en Storage** (no solo cierre de sesion — Apple y Google Play lo exigen), el consentimiento expreso de la Ley 1581 para datos sensibles con timestamp y version sellados por el servidor, y el *prominent disclosure* de Google Play / Apple 5.1.5 para ubicacion en background. Son requisitos de aprobacion de tienda y de ley, no opcionales.
5. Cierra con un veredicto **binario**: **"listo"** o **"bloqueado por: ..."** con la lista exacta. No dejes la conclusion ambigua, y no degrades un hallazgo del grupo 1 a "observacion" porque la feature ya este casi entregada — ese es precisamente el momento en que se cuela.

## Notas

- `feature-dev` ya corre este agente dos veces por su cuenta (sobre el plan, antes de escribir codigo; y sobre el codigo, en Review) cuando la feature toca SOS o ubicacion. Este skill sirve para revisar codigo que no paso por ese workflow, para un repaso antes de un release, o cuando el usuario quiera el veredicto suelto.
- Si el alcance no toca nada de seguridad ni de ubicacion, dilo en una linea y no fabriques hallazgos para justificar la corrida.
