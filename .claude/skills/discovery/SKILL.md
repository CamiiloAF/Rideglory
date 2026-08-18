---
name: discovery
description: Conduce la toma de requerimientos de Rideglory desde el problema y no desde el inventario de features. Levanta evidencia sobre lo construido, entrevista al usuario una pregunta a la vez sin proponer soluciones, contrasta sus respuestas contra el codigo y sintetiza un brief de producto y un backlog de problemas priorizados en docs/product/.
---

# discovery

Uso: `/discovery [tema o foco]` (ej. `/discovery`, `/discovery tracking y SOS`, `/discovery vale la pena el wizard de eventos`).

Este flujo existe porque el refactor de Rideglory arranca con una trampa a la vista: `lib/features/` es un inventario muy convincente de lo que se construyo, y es facil confundirlo con la lista de lo que la app necesita. No lo es. El orden de trabajo del proyecto es **toma de requerimientos → diseno en Pencil → implementacion**, y esta es la primera etapa.

## Antes de empezar: declara el encuadre al usuario

Diselo literalmente, en una o dos frases, antes de la primera pregunta. No es un tramite: fija las reglas de la conversacion y evita que termine siendo una revision de features.

- `lib/features/` es el inventario de lo que **se construyo**, no evidencia de lo que **se necesita**. Cada feature actual entra a esta conversacion sin privilegios.
- El costo hundido no cuenta. Que algo funcione y este testeado no es razon para conservarlo.
- No voy a proponer soluciones durante la entrevista: voy a preguntar por problemas, y voy a preguntar mas de lo que parece necesario.
- Todo lo que no tenga respaldo en el codigo o en una respuesta suya queda marcado `[SUPUESTO]` en el artefacto final.

## Pasos

1. **Scan (sin el usuario).** Lanza el workflow para levantar evidencia antes de preguntar nada:
   `Workflow({ name: 'discovery', args: '<foco o vacio>' })`
   Devuelve el inventario real de lo construido, las senales de uso (que en este proyecto seran casi todas "ausente": hubo 2 usuarios reales y se descartaron los datos), las promesas incumplidas y una lista de `pendingQuestions`. Esas preguntas son el guion — no las inventes tu.
2. **Entrevista al usuario.** Esto lo haces **tu, en el hilo principal**, nunca un subagente. Reglas:
   - **Una pregunta a la vez.** Espera la respuesta antes de la siguiente. Nada de cuestionarios de seis puntos.
   - **Nunca propongas una solucion**, ni siquiera como ejemplo ("¿y si el mapa mostrara...?"). Pregunta por la ultima vez que le paso, que hizo entonces, y que perdio por eso.
   - Persigue **frecuencia y severidad** en cada problema: ¿cada rodada? ¿una vez al ano? ¿que pasa si no se resuelve?
   - Cuando responda con una feature ("necesito filtros en el mapa"), devuelve la pregunta al problema: ¿que estabas intentando lograr cuando te falto eso?
   - Si una respuesta choca con lo que viste en el codigo, dilo y preguntale — la contradiccion es informacion, no un error suyo.
3. **Temas que entran con nombre propio.** No cierres la entrevista sin haberlos tocado, porque son las decisiones que gobiernan el alcance del refactor:
   - **Mapas y rutas** — el usuario los considera inutiles **como estan**. Averigua que esperaba ver ahi y en que momento de la rodada, antes de asumir que el problema es el mapa.
   - **Tracking y SOS** — es su mayor dolor. Aqui la conversacion no es solo de producto: hay un defecto que ya estuvo en produccion (el SOS se descartaba en silencio si el transporte estaba caido) y hay reglas no negociables en `CLAUDE.md`.
   - **SOAT y RTM** — ¿son una feature de documentos, o son dos recordatorios? La respuesta cambia si merecen pantallas propias o una sola bandeja de vencimientos.
   - **El wizard de eventos** — cuanto de sus pasos se usa de verdad al crear una rodada, y cuales se saltan siempre.
4. **Challenge y sintesis.** Vuelve a lanzar el workflow con las respuestas textuales:
   `Workflow({ name: 'discovery', args: { focus: '<foco>', interview: '<respuestas del usuario, textuales>' } })`
   Contrasta cada respuesta contra el codigo, separa hecho de `[SUPUESTO]`, y produce los problemas priorizados y un veredicto `keep` / `redesign` / `kill` por cada feature construida, con su costo de eliminacion.
5. **Escribe los artefactos** (esto lo haces tu; el workflow no escribe archivos):
   - `docs/product/PRODUCT-BRIEF.md` — para quien es la app, los problemas que resuelve en orden, los JTBD, el mayor supuesto sin verificar, y la tabla de veredictos por feature con su razon y su costo de eliminacion.
   - `docs/product/backlog.md` — **problemas, no features**. Cada entrada: problema, segmento, frecuencia, severidad, evidencia (o `[SUPUESTO]`), y la pregunta abierta que falta responder. Si una entrada se puede leer como una pantalla, esta mal escrita.
6. **Cierra con lo que NO se sabe.** El ultimo mensaje al usuario incluye `biggestUnknown` y las contradicciones sin resolver. Un descubrimiento que termina en certeza total es un descubrimiento que no pregunto lo suficiente.

## Notas

- No disenes ni una pantalla en este flujo, ni siquiera de palabra. El diseno viene despues, en `/pencil-screen`, y solo para problemas que sobrevivieron a este paso.
- Si el usuario pide "solo dame la lista de lo que hay que hacer", el encuadre del paso 0 es la respuesta: la lista sin la entrevista seria el inventario de features otra vez.
- Un `kill` no se ejecuta aqui. Este flujo produce el veredicto y su costo; eliminar codigo es otra corrida.
