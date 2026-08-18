export const meta = {
  name: 'discovery',
  description:
    'Automatiza las partes de la toma de requerimientos de Rideglory que NO necesitan al humano: levanta evidencia sobre que esta construido y que senales de uso hay (Scan), contrasta adversarialmente las respuestas de la entrevista contra esa evidencia separando hecho de supuesto (Challenge), y sintetiza problemas priorizados y un veredicto keep/redesign/kill por feature existente (Synthesize). NO entrevista al usuario: eso lo hace el skill discovery en el hilo principal, que le pasa las respuestas por args. Args: "<tema o foco>" o {focus, interview: "<respuestas de la entrevista>"}.',
  whenToUse:
    'Cuando se este haciendo la toma de requerimientos de Rideglory y haga falta levantar evidencia, contrastar lo que dijo el usuario o consolidar el backlog de problemas. Para implementar una feature usa feature-dev.',
  phases: [
    { title: 'Scan', detail: 'product-discovery: evidencia de lo construido, senales de uso y promesas incumplidas' },
    { title: 'Challenge', detail: 'product-discovery: contraste adversarial de las respuestas de la entrevista contra la evidencia' },
    { title: 'Synthesize', detail: 'product-discovery: problemas priorizados + veredicto keep/redesign/kill por feature actual' },
  ],
}

// ---------------------------------------------------------------------------
// Args
// ---------------------------------------------------------------------------
const input = typeof args === 'object' && args !== null ? args : { focus: args }
const FOCUS =
  typeof input.focus === 'string' && input.focus.trim()
    ? input.focus.trim()
    : 'toda la app: rodadas, garaje, mantenimiento, documentos legales, tracking en vivo y SOS'
const INTERVIEW = typeof input.interview === 'string' && input.interview.trim() ? input.interview.trim() : null

const FRAME = `
ENCUADRE (no lo negocies):
- lib/features/ es el inventario de lo que se CONSTRUYO, no evidencia de lo que se NECESITA. Que una feature exista no prueba que resuelva un problema real.
- El repo esta en refactor total (rama refactor/v2): el codigo viejo en main es referencia de comportamiento, no un compromiso. Toda feature esta sobre la mesa.
- Solo hubo 2 usuarios reales y los datos de produccion se descartaron: casi no hay senales de uso cuantitativas. Digelo cuando no las haya, en vez de inventar metricas.
- Nunca propongas soluciones ni features. Tu producto son problemas, segmentos y evidencia.
- Todo lo que no tenga respaldo en el codigo, en un doc del repo o en una respuesta textual del usuario va marcado como [SUPUESTO]. Un supuesto sin marcar es un defecto de tu trabajo.
- Eres de SOLO LECTURA: no escribas archivos, no ejecutes git. Toda tu salida va en el objeto estructurado.
`

// ---------------------------------------------------------------------------
// Schemas
// ---------------------------------------------------------------------------
const EVIDENCE_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['built', 'usageSignals', 'brokenPromises', 'openQuestions'],
  properties: {
    built: {
      type: 'array',
      description: 'que existe de verdad en el codigo, feature por feature',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['feature', 'state', 'whatItDoes', 'evidence'],
        properties: {
          feature: { type: 'string' },
          state: { type: 'string', enum: ['completa', 'parcial', 'esqueleto', 'eliminada'] },
          whatItDoes: { type: 'string', description: 'lo que hace observando el codigo, no lo que pretendia hacer' },
          evidence: { type: 'string', description: 'rutas de archivo, docs o commits que lo respaldan' },
        },
      },
    },
    usageSignals: {
      type: 'array',
      description: 'senales de que algo se usa o no: analytics, tracking docs, dev-runs, bugs recurrentes, ausencia de datos',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['signal', 'source', 'strength'],
        properties: {
          signal: { type: 'string' },
          source: { type: 'string' },
          strength: { type: 'string', enum: ['fuerte', 'debil', 'ausente'] },
        },
      },
    },
    brokenPromises: {
      type: 'array',
      description: 'lo que la app promete al usuario (UI, textos, docs) y no cumple de verdad en el codigo',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['promise', 'reality', 'evidence', 'impact'],
        properties: {
          promise: { type: 'string' },
          reality: { type: 'string' },
          evidence: { type: 'string' },
          impact: { type: 'string', enum: ['critico', 'alto', 'medio', 'bajo'] },
        },
      },
    },
    openQuestions: {
      type: 'array',
      items: { type: 'string' },
      description: 'lo que el codigo no puede responder y solo el usuario puede — insumo para la entrevista',
    },
  },
}

const PROBLEMS_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['problems', 'contradictions', 'unfalsifiable'],
  properties: {
    problems: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['problem', 'segment', 'frequency', 'severity', 'evidence', 'jtbd'],
        properties: {
          problem: { type: 'string', description: 'el problema en las palabras del usuario, no la solucion' },
          segment: { type: 'string', description: 'a quien le pasa: organizador, participante, dueno de moto sin rodadas...' },
          frequency: { type: 'string', enum: ['cada rodada', 'semanal', 'mensual', 'anual', 'raro', 'desconocida'] },
          severity: { type: 'string', enum: ['critico', 'alto', 'medio', 'bajo'] },
          evidence: {
            type: 'string',
            description: 'la cita textual del usuario, la ruta de codigo o el doc que lo respalda; si no hay respaldo, empieza el texto con "[SUPUESTO]"',
          },
          jtbd: { type: 'string', description: 'el job to be done detras del problema' },
        },
      },
    },
    contradictions: {
      type: 'array',
      description: 'donde lo que dijo el usuario choca con lo que muestra el codigo o con otra respuesta suya',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['claim', 'contradictedBy', 'question'],
        properties: {
          claim: { type: 'string' },
          contradictedBy: { type: 'string' },
          question: { type: 'string', description: 'la pregunta que hay que devolverle al usuario para resolverlo' },
        },
      },
    },
    unfalsifiable: {
      type: 'array',
      items: { type: 'string' },
      description: 'afirmaciones que no se pueden probar ni refutar con nada disponible — quedan como hipotesis abiertas',
    },
  },
}

const SCOPE_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['verdicts', 'topProblems', 'biggestUnknown'],
  properties: {
    verdicts: {
      type: 'array',
      description: 'un veredicto por cada feature actualmente construida',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['feature', 'verdict', 'reason', 'problemsServed', 'removalCost'],
        properties: {
          feature: { type: 'string' },
          verdict: { type: 'string', enum: ['keep', 'redesign', 'kill'] },
          reason: { type: 'string' },
          problemsServed: { type: 'array', items: { type: 'string' }, description: 'que problemas de la lista resuelve; vacio es una senal por si misma' },
          removalCost: { type: 'string', description: 'que se rompe o que se pierde si se elimina: dependencias, datos, expectativa del usuario' },
        },
      },
    },
    topProblems: {
      type: 'array',
      description: 'los problemas priorizados que deberian gobernar el refactor, en orden',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['problem', 'why', 'openQuestion'],
        properties: {
          problem: { type: 'string' },
          why: { type: 'string', description: 'por que va en esta posicion: frecuencia x severidad x evidencia' },
          openQuestion: { type: 'string', description: 'lo que falta saber antes de disenar nada para el' },
        },
      },
    },
    biggestUnknown: { type: 'string', description: 'el supuesto que, de estar equivocado, invalidaria mas trabajo' },
  },
}

// ---------------------------------------------------------------------------
// Phase: Scan — evidencia. Sin entrevista todavia: primero el terreno.
// ---------------------------------------------------------------------------
phase('Scan')

const evidence = await agent(
  `Levanta la evidencia disponible sobre Rideglory antes de cualquier conversacion de producto. FOCO: ${FOCUS}

${FRAME}

Sigue tu playbook (.claude/agents/product-discovery.md). Fuentes a leer, en este orden:
1. CLAUDE.md — que dice el contrato que es la app, y que reglas de seguridad del rider y legales ya estan comprometidas.
2. El codigo real: lib/features/ en la rama actual y, si esta vacio por el refactor, el codigo viejo en main como referencia de COMPORTAMIENTO (usa git show main:<ruta> o git log). Distingue siempre lo que existe hoy de lo que existia antes.
3. docs/ — dev-runs, features, prds, tracking de fidelidad y de e2e, bugs. Ahi estan las promesas escritas y los incidentes reales.
4. design-system/rideglory/ y los .md de pantallas, si existen: dicen que se diseno, que es otra cosa distinta de lo que se construyo.

Para cada feature construida di que hace OBSERVANDO el codigo, no lo que su nombre sugiere. Marca el estado real (completa / parcial / esqueleto / eliminada).
En usageSignals se honesto: si no hay analytics ni datos, la senal es "ausente" y eso se reporta tal cual — no inventes metricas.
En brokenPromises busca especialmente el hueco entre lo que la UI le promete al motociclista y lo que el codigo entrega (el caso conocido: el SOS que se descartaba en silencio si el transporte estaba caido).
En openQuestions deja lo que solo el usuario puede responder — se convierte en la entrevista.

No propongas soluciones. Devuelve el objeto estructurado.`,
  { label: 'scan', phase: 'Scan', schema: EVIDENCE_SCHEMA, agentType: 'product-discovery', effort: 'high' },
)

const builtStr = evidence.built.map((b) => `- ${b.feature} [${b.state}]: ${b.whatItDoes} (${b.evidence})`).join('\n')
const promisesStr = evidence.brokenPromises.map((p) => `- [${p.impact}] promete "${p.promise}" pero ${p.reality} (${p.evidence})`).join('\n')
const signalsStr = evidence.usageSignals.map((s) => `- [${s.strength}] ${s.signal} (${s.source})`).join('\n')

log(
  `[scan] ${evidence.built.length} features inventariadas, ${evidence.brokenPromises.length} promesas incumplidas, ${evidence.usageSignals.filter((s) => s.strength === 'fuerte').length} senales fuertes, ${evidence.openQuestions.length} preguntas abiertas`,
)

// ---------------------------------------------------------------------------
// Phase: Challenge — contraste adversarial de la entrevista contra la evidencia.
// Si no hubo entrevista todavia, esta fase igual corre: contrasta la evidencia
// contra si misma y devuelve las preguntas que hay que hacerle al usuario.
// ---------------------------------------------------------------------------
phase('Challenge')

const problems = await agent(
  `Convierte en problemas ${INTERVIEW ? 'las respuestas de la entrevista al usuario' : 'la evidencia levantada'}, contrastandolas adversarialmente contra lo que muestra el codigo. FOCO: ${FOCUS}

${FRAME}

EVIDENCIA DEL SCAN — que esta construido:
${builtStr || '(nada)'}

EVIDENCIA DEL SCAN — senales de uso:
${signalsStr || '(ninguna)'}

EVIDENCIA DEL SCAN — promesas incumplidas:
${promisesStr || '(ninguna)'}

${
  INTERVIEW
    ? `RESPUESTAS DE LA ENTREVISTA (textuales, del usuario — son la fuente primaria; el codigo solo las contrasta):
${INTERVIEW}

Tu trabajo aqui es adversarial, no complaciente:
- Toma cada respuesta y busca si el codigo la respalda, la contradice o no dice nada. Los tres casos son informacion.
- Separa el problema de la solucion: si el usuario dijo "necesito X", tu salida es el problema que X pretendia resolver, no X.
- Distingue una queja de un problema recurrente: pregunta por frecuencia y severidad, y si no las sabes ponlas en "desconocida" en vez de estimarlas.
- Cuando una respuesta choque con el codigo o con otra respuesta suya, va en contradictions con la pregunta exacta que hay que devolverle.
- Lo que no se puede probar ni refutar con nada disponible va en unfalsifiable. No lo escondas en un problema con evidencia inventada.`
    : `Todavia NO hay entrevista. Deriva los problemas candidatos SOLO de la evidencia, marca CADA UNO con "[SUPUESTO]" al inicio de su evidence (porque ninguno tiene respaldo del usuario), y usa contradictions para las tensiones internas de la evidencia (una feature completa sin ninguna senal de uso, una promesa incumplida critica que nadie reporto). Las preguntas de contradictions son el guion de la entrevista pendiente.`
}

Devuelve el objeto estructurado. Nunca propongas features.`,
  { label: 'challenge', phase: 'Challenge', schema: PROBLEMS_SCHEMA, agentType: 'product-discovery', effort: 'high' },
)

const problemsStr = problems.problems
  .map((p) => `- [${p.severity}/${p.frequency}] ${p.problem} (segmento: ${p.segment}) — JTBD: ${p.jtbd} — evidencia: ${p.evidence}`)
  .join('\n')

log(
  `[challenge] ${problems.problems.length} problemas, ${problems.contradictions.length} contradicciones, ${problems.unfalsifiable.length} afirmaciones no falsables`,
)

// ---------------------------------------------------------------------------
// Phase: Synthesize — veredicto por feature + priorizacion.
// ---------------------------------------------------------------------------
phase('Synthesize')

const scope = await agent(
  `Sintetiza el alcance del refactor de Rideglory: para CADA feature actualmente construida, un veredicto keep / redesign / kill, y la priorizacion de los problemas que deberian gobernarlo. FOCO: ${FOCUS}

${FRAME}

FEATURES CONSTRUIDAS:
${builtStr || '(ninguna)'}

PROBLEMAS IDENTIFICADOS:
${problemsStr || '(ninguno)'}

CONTRADICCIONES SIN RESOLVER:
${problems.contradictions.map((c) => `- "${c.claim}" vs ${c.contradictedBy} → preguntar: ${c.question}`).join('\n') || '(ninguna)'}

AFIRMACIONES NO FALSABLES:
${problems.unfalsifiable.join('\n') || '(ninguna)'}

Reglas del veredicto:
- keep: la feature sirve a un problema de la lista con evidencia real y su forma actual es adecuada.
- redesign: el problema es real pero la forma actual no lo resuelve bien. Di que parte falla, no como arreglarla.
- kill: no sirve a ningun problema identificado, o el problema no justifica el costo de mantenerla. Una feature completa sin ningun problema asociado es una candidata a kill, no una excepcion.
- Ninguna feature se queda por haber costado trabajo. El costo hundido no es un argumento.
- removalCost es obligatorio incluso en keep: si nadie sabe que se rompe al eliminarla, eso es un hallazgo.
- Las obligaciones legales y de seguridad de CLAUDE.md (borrado de cuenta, consentimientos, SOS confiable) no se someten a veredicto de producto: si aparecen, van como keep con la razon explicita de que son requisito, no eleccion.

En topProblems ordena por frecuencia x severidad x calidad de la evidencia, penalizando lo marcado [SUPUESTO]. En biggestUnknown pon el supuesto cuyo error invalidaria mas trabajo.

Devuelve el objeto estructurado. No disenes soluciones ni pantallas.`,
  { label: 'synthesize', phase: 'Synthesize', schema: SCOPE_SCHEMA, agentType: 'product-discovery', effort: 'high' },
)

log(
  `[synthesize] veredictos: ${scope.verdicts.filter((v) => v.verdict === 'keep').length} keep / ${scope.verdicts.filter((v) => v.verdict === 'redesign').length} redesign / ${scope.verdicts.filter((v) => v.verdict === 'kill').length} kill`,
)

return {
  focus: FOCUS,
  interviewed: Boolean(INTERVIEW),
  evidence,
  problems,
  scope,
  pendingQuestions: [...evidence.openQuestions, ...problems.contradictions.map((c) => c.question)],
  note: INTERVIEW
    ? 'Descubrimiento consolidado. Escribe docs/product/PRODUCT-BRIEF.md y docs/product/backlog.md desde este objeto — el workflow no escribe archivos.'
    : 'Corrida SIN entrevista: todo problema esta marcado [SUPUESTO]. Usa pendingQuestions como guion, entrevista al usuario una pregunta a la vez y vuelve a lanzar el workflow con {interview: "<respuestas>"} antes de escribir el brief.',
}
