export const meta = {
  name: 'rg-plan',
  description:
    'Planeacion aislada por fases para Rideglory (Flutter + rideglory-api): escanea el sistema, PO propone fases, Architect y Plan Reviewer auditan en paralelo, PO consolida, y un agente por fase escribe su archivo detallado bajo el control de un AUDITOR Opus que itera con cada agente hasta un resultado optimo. Entrega un plan completo en docs/plans/<slug>/ con un archivo por fase + indice PLAN.md. Solo escribe bajo docs/plans/<slug>/; no toca codigo ni docs globales.',
  phases: [
    { title: 'Intake', detail: 'Resolver la fuente y derivar slug + objetivo' },
    { title: 'Scan', detail: 'Inventario brownfield (Flutter lib/ + rideglory-api)' },
    { title: 'Propose', detail: 'PO propone las fases del plan' },
    { title: 'Review', detail: 'Architect y Plan Reviewer en paralelo' },
    { title: 'Synthesize', detail: 'PO consolida + Auditor Opus aprueba la lista final' },
    { title: 'Write phases', detail: 'Por fase: agente escribe -> Auditor Opus itera hasta aprobar -> indice' },
  ],
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
const kebab = (s) =>
  String(s)
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 48)

const pad2 = (n) => String(n).padStart(2, '0')

const HARD_RULES = `
HARD RULES — no las violes:
1. NUNCA ejecutes: git add / commit / push / merge / rebase / restore / reset, ni gh pr create / merge / review.
2. NUNCA modifiques: docs/PRD.md, docs/PLAN.md, docs/PLAN_FEEDBACK.md, docs/PRODUCT_STATUS.md, docs/handoffs/** (legado), .claude/**.
3. Esta es una sesion de PLANEACION: NO modificas codigo de la app. Solo escribes artefactos bajo docs/plans/<slug>/.
4. Lee tu playbook de rol en .claude/agents/<rol>.md para tono y criterio, pero las RUTAS DE SALIDA de esta corrida MANDAN sobre el playbook.
5. Para timestamps usa Bash: \`date -u +%Y-%m-%dT%H:%M:%SZ\`. Nunca inventes fechas.
`

const AUDIT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['approved', 'score', 'findings', 'requestedChanges'],
  properties: {
    approved: { type: 'boolean', description: 'true solo si el artefacto esta listo para ejecutar sin preguntas' },
    score: { type: 'integer', description: 'calidad 0-100' },
    findings: { type: 'array', items: { type: 'string' }, description: 'observaciones (vacio si perfecto)' },
    requestedChanges: {
      type: 'array',
      items: { type: 'string' },
      description: 'cambios concretos y accionables que el agente productor debe aplicar; vacio si approved',
    },
  },
}

const FILE_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['file', 'title'],
  properties: { file: { type: 'string' }, title: { type: 'string' } },
}

// Bucle auditor Opus: produce -> audita (opus) -> reinyecta cambios -> repite hasta aprobar o agotar rondas.
async function audited({ label, phaseName, artifactPath, criteria, produce, maxRounds = 3 }) {
  let result = await produce(null)
  let verdict = null
  for (let round = 1; round <= maxRounds; round++) {
    verdict = await agent(
      `Eres el AUDITOR de calidad (Opus) del plan "${SLUG}" de Rideglory. Auditas con rigor el artefacto: ${artifactPath}

${HARD_RULES}

FUENTES DE VERDAD (lee lo que necesites): ${WS}/05-sintesis.md, ${WS}/01-scan.md, ${WS}/03-architect-review.md, ${WS}/04-plan-review.md.

CRITERIOS DE AUDITORIA para este artefacto:
${criteria}

Lee el artefacto COMPLETO. Eres exigente: aprueba SOLO si un desarrollador podria ejecutarlo sin hacer preguntas, las rutas son reales, los criterios de aceptacion son observables y testeables, y respeta Clean Architecture + rideglory-coding-standards.
Si no esta listo, devuelve requestedChanges concretos y accionables (no vaguedades). ${round === maxRounds ? 'Esta es la ULTIMA ronda: si aun falla, aprueba lo que sea defendible y deja findings.' : ''}

Devuelve el objeto estructurado (approved, score, findings, requestedChanges).`,
      { label: `${label}:audit#${round}`, phase: phaseName, model: 'opus', schema: AUDIT_SCHEMA },
    )
    log(`[audit:opus] ${label} ronda ${round}: ${verdict.approved ? 'APROBADO' : 'cambios solicitados'} (score ${verdict.score})`)
    if (verdict.approved || round === maxRounds) break
    result = await produce(verdict)
  }
  return { result, verdict }
}

// ---------------------------------------------------------------------------
// Schemas de fase
// ---------------------------------------------------------------------------
const INTAKE_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['slug', 'goal', 'scopeSummary'],
  properties: {
    slug: { type: 'string' },
    goal: { type: 'string' },
    scopeSummary: { type: 'string' },
  },
}

const PROPOSAL_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['phases', 'assumptions', 'risks'],
  properties: {
    phases: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['id', 'title', 'goal', 'summary'],
        properties: {
          id: { type: 'integer' },
          title: { type: 'string' },
          goal: { type: 'string' },
          summary: { type: 'string' },
        },
      },
    },
    assumptions: { type: 'array', items: { type: 'string' } },
    risks: { type: 'array', items: { type: 'string' } },
  },
}

const REVIEW_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['verdict', 'adjustments', 'concerns'],
  properties: {
    verdict: { type: 'string', enum: ['ok', 'ok_con_ajustes', 'replantear'] },
    adjustments: { type: 'array', items: { type: 'string' } },
    concerns: { type: 'array', items: { type: 'string' } },
  },
}

const FINAL_PLAN_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['overview', 'phases'],
  properties: {
    overview: { type: 'string' },
    phases: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['id', 'title', 'goal', 'summary', 'dependsOn', 'recommendedTier', 'tierRationale'],
        properties: {
          id: { type: 'integer' },
          title: { type: 'string' },
          goal: { type: 'string' },
          summary: { type: 'string' },
          dependsOn: { type: 'array', items: { type: 'integer' } },
          recommendedTier: { type: 'string', enum: ['lite', 'normal', 'full'] },
          tierRationale: { type: 'string', description: 'por que ese nivel: riesgo, blast radius, contratos/migraciones, reversibilidad' },
        },
      },
    },
  },
}

// Rubrica de niveles de ejecucion (la usa la sintesis para recomendar y rg-exec para ejecutar).
const TIER_RUBRIC = `RUBRICA DE NIVEL DE EJECUCION (rg-exec) por fase:
- lite  = cambio mecanico / bajo riesgo, una sola area, reversible, SIN contratos rideglory-api, SIN migraciones, SIN seguridad/PII central. Ej: agregar call sites, constantes/taxonomia, copy, config, un observer, UI simple. (1 implementador + 1 ronda de auditor Opus).
- normal= feature acotada con algo de logica o UI, una area principal, riesgo medio, sin migraciones ni cambios de contrato sensibles. (Architect + Build + QA + 2 rondas de auditor + Tech Lead).
- full  = complejo o riesgoso: cambios de contrato rideglory-api, migraciones de datos, seguridad/auth/PII central, cross-cutting, alto blast radius o dificil de revertir. (todo + QA adversarial + 3 rondas + fix loops).
Ante la duda entre dos niveles, recomienda el MENOR que cubra el riesgo y explica por que.`

// ---------------------------------------------------------------------------
// Phase: Intake
// ---------------------------------------------------------------------------
phase('Intake')

const SOURCE = typeof args === 'string' && args.trim() ? args.trim() : 'docs/PRD.md'

const intake = await agent(
  `Eres el agente de Intake de una sesion de PLANEACION de Rideglory (Flutter + rideglory-api).

Fuente del objetivo: ${SOURCE}
- Si es una ruta existente (\`test -f\`), leela COMPLETA.
- Si NO existe como archivo, trata el texto literal como el objetivo en bruto.
- Si la fuente es docs/PRD.md, leela completa.

${HARD_RULES}

TU TRABAJO:
1. Resume el objetivo de planeacion en 1-2 frases.
2. Deriva un SLUG kebab-case corto (ej: 'tracking-en-vivo-v2').
3. Crea el workspace: \`mkdir -p docs/plans/<SLUG>/phases\`.
4. Escribe docs/plans/<SLUG>/00-intake.md con: ## Fuente, ## Objetivo, ## Alcance percibido, ## Preguntas abiertas.
Devuelve (slug, goal, scopeSummary).`,
  { label: 'intake', phase: 'Intake', model: 'sonnet', schema: INTAKE_SCHEMA },
)

const SLUG = intake.slug
const WS = `docs/plans/${SLUG}`
log(`Planeando "${SLUG}" — workspace: ${WS}/`)

// ---------------------------------------------------------------------------
// Phase: Scan
// ---------------------------------------------------------------------------
phase('Scan')

await agent(
  `Eres el System Scanner de la planeacion de Rideglory. Slug: ${SLUG}.

BROWNFIELD:
- App Flutter: /Users/cami/Developer/Personal/Rideglory/lib/
- Backend: /Users/cami/Developer/Personal/rideglory-api

${HARD_RULES}

CONTEXTO: lee ${WS}/00-intake.md como lente de gap-analysis.

ESCANEO (resume nombres, NO pegues codigo):
1. lib/features/ — por feature: domain/data/presentation y archivos clave.
2. pubspec.yaml — dependencias clave.
3. rideglory-api — microservicios + grupos de endpoints (metodo+path+proposito).
4. Gap vs objetivo: implemented | partial (que falta) | not started.
5. Artefactos de diseno en docs/design/ y docs/handoffs/design.md si existen.

SALIDA: ${WS}/01-scan.md con: ## Inventario Flutter, ## Dependencias, ## Superficie rideglory-api, ## Gap analysis, ## Patrones, ## Implicaciones para el plan.
Devuelve 3-5 bullets de lo mas relevante.`,
  { label: 'scan', phase: 'Scan', model: 'sonnet' },
)

// ---------------------------------------------------------------------------
// Phase: Propose
// ---------------------------------------------------------------------------
phase('Propose')

const proposal = await agent(
  `Eres el Product Owner de la planeacion de Rideglory. Slug: ${SLUG}.

${HARD_RULES}

CONTEXTO: ${WS}/00-intake.md, ${WS}/01-scan.md, .claude/agents/po.md.

TU TRABAJO:
1. Descompon el objetivo en FASES secuenciales y entregables (cada fase deja la app funcional). Comportamiento de usuario movil, no tareas tecnicas sueltas.
2. Cada fase: id (1..N), title, goal (1 frase de valor), summary.
3. Lista assumptions y risks.
4. Escribe ${WS}/02-po-proposal.md: ## Fases propuestas (tabla), ## Supuestos, ## Riesgos, ## Criterios de exito globales.
Devuelve el objeto estructurado.`,
  { label: 'po-proposal', phase: 'Propose', model: 'sonnet', schema: PROPOSAL_SCHEMA },
)

log(`PO propuso ${proposal.phases.length} fases. Revisando en paralelo...`)

// ---------------------------------------------------------------------------
// Phase: Review (Architect ∥ Plan Reviewer)
// ---------------------------------------------------------------------------
phase('Review')

const phasesTable = proposal.phases.map((p) => `${p.id}. ${p.title} — ${p.goal}`).join('\n')

const [architectReview, planReview] = await parallel([
  () =>
    agent(
      `Eres el Architect de la planeacion de Rideglory. Slug: ${SLUG}.

${HARD_RULES}

Stack existente: Flutter + Firebase + rideglory-api. VALIDAS, no eliges desde cero.
CONTEXTO: ${WS}/01-scan.md, ${WS}/02-po-proposal.md, .claude/agents/architect.md, .claude/skills/architect-skill.md.

Fases propuestas:
${phasesTable}

TU TRABAJO:
1. Viabilidad tecnica por fase + complejidad (baja|media|alta) y por que.
2. Contratos rideglory-api, cambios de datos/migraciones, code-gen, plataforma, WebSocket.
3. AJUSTES concretos a la lista de fases.
4. Riesgos arquitectonicos + mitigaciones.
5. Escribe ${WS}/03-architect-review.md: ## Validacion por fase, ## Contratos, ## Riesgos, ## Ajustes.
Devuelve (verdict, adjustments, concerns).`,
      { label: 'architect-review', phase: 'Review', model: 'sonnet', schema: REVIEW_SCHEMA },
    ),
  () =>
    agent(
      `Eres el Plan Reviewer (UX movil + calidad/Clean Architecture) de Rideglory. Slug: ${SLUG}.

${HARD_RULES}

CONTEXTO: ${WS}/01-scan.md, ${WS}/02-po-proposal.md, .claude/agents/design.md, .claude/agents/tech_lead.md, docs/design/html-mockups/ si existe.

Fases propuestas:
${phasesTable}

TU TRABAJO:
1. UX movil: 375px, touch targets, navegacion, estados (idle/loading/empty/error) por fase.
2. Calidad: Clean Architecture, rideglory-coding-standards (un widget por archivo, sin metodos que retornan widgets, AppButton/AppTextField/AppSwitch, texto oscuro sobre primario).
3. Cada fase verificable y bien dimensionada.
4. AJUSTES concretos.
5. Escribe ${WS}/04-plan-review.md: ## UX por fase, ## Gates de calidad, ## Riesgos de scope, ## Ajustes.
Devuelve (verdict, adjustments, concerns).`,
      { label: 'plan-review', phase: 'Review', model: 'sonnet', schema: REVIEW_SCHEMA },
    ),
])

// ---------------------------------------------------------------------------
// Phase: Synthesize (PO consolida + Auditor Opus aprueba la lista final)
// ---------------------------------------------------------------------------
phase('Synthesize')

const archAdj = (architectReview?.adjustments || []).map((a) => `- [arch] ${a}`).join('\n') || '- (sin ajustes)'
const planAdj = (planReview?.adjustments || []).map((a) => `- [plan] ${a}`).join('\n') || '- (sin ajustes)'

let finalPlan
const synth = await audited({
  label: 'sintesis',
  phaseName: 'Synthesize',
  artifactPath: `${WS}/05-sintesis.md`,
  criteria: `- La lista final de fases integra coherentemente los ajustes de Architect y Plan Reviewer.
- Las fases estan en orden ejecutable, con dependsOn correcto (sin ciclos).
- Ninguna fase mezcla responsabilidades de capas ni rompe Clean Architecture.
- El alcance de cada fase es entregable y verificable.`,
  produce: (feedback) =>
    agent(
      `Eres el Product Owner consolidando el plan final de Rideglory. Slug: ${SLUG}.

${HARD_RULES}

CONTEXTO: ${WS}/02-po-proposal.md, ${WS}/03-architect-review.md, ${WS}/04-plan-review.md.
Ajustes recibidos:
${archAdj}
${planAdj}

${TIER_RUBRIC}

TU TRABAJO:
1. Integra los ajustes en una lista de fases FINAL coherente.
2. Cada fase: id (renumera 1..N en orden de ejecucion), title, goal, summary, dependsOn, y ademas recommendedTier (lite|normal|full) + tierRationale segun la RUBRICA de arriba.
3. Escribe ${WS}/05-sintesis.md: ## Overview, ## Cambios aplicados, ## Lista final de fases (tabla con columna Nivel + por que), ## Supuestos y riesgos.
${feedback ? `\nMODO CORRECCION — el Auditor Opus pidio aplicar TODOS estos cambios y reescribir ${WS}/05-sintesis.md:\n${feedback.requestedChanges.map((c) => '- ' + c).join('\n')}` : ''}
Devuelve (overview, phases).`,
      { label: 'po-synthesis', phase: 'Synthesize', model: 'sonnet', schema: FINAL_PLAN_SCHEMA },
    ),
})
finalPlan = synth.result
log(`Plan final aprobado por auditor: ${finalPlan.phases.length} fases (score ${synth.verdict.score}).`)

// ---------------------------------------------------------------------------
// Phase: Write phases — cada fase: escribir -> Auditor Opus itera -> aprobar
// (todas las fases en paralelo, cada una con su propio bucle de auditoria)
// ---------------------------------------------------------------------------
phase('Write phases')

const phaseResults = await parallel(
  finalPlan.phases.map((p) => async () => {
    const fname = `phase-${pad2(p.id)}-${kebab(p.title)}.md`
    const rel = `${WS}/phases/${fname}`
    const { result, verdict } = await audited({
      label: `fase-${pad2(p.id)}`,
      phaseName: 'Write phases',
      artifactPath: rel,
      criteria: `- ## Que se debe hacer: pasos concretos, ordenados y suficientes para ejecutar sin preguntar.
- ## Archivos a crear/modificar: rutas REALES del repo (verificables), con "que cambia" por archivo.
- ## Criterios de aceptacion: numerados, observables, cada uno convertible en un test que falle sin el cambio.
- Respeta Clean Architecture (domain/data/presentation) y rideglory-coding-standards.
- Contratos rideglory-api y migraciones explicitos o marcados "ninguno".`,
      produce: (feedback) =>
        agent(
          `Eres Tech Lead/PO de Rideglory escribiendo el archivo DETALLADO de UNA fase del plan "${SLUG}".

${HARD_RULES}

CONTEXTO: ${WS}/05-sintesis.md, ${WS}/01-scan.md, ${WS}/03-architect-review.md.

FASE:
- id: ${p.id} | titulo: ${p.title}
- objetivo: ${p.goal}
- resumen: ${p.summary}
- depende de: ${JSON.stringify(p.dependsOn)}
- nivel rg-exec recomendado: ${p.recommendedTier} — ${p.tierRationale}

ESCRIBE EXACTAMENTE ${rel} con:
# Fase ${p.id} — ${p.title}
## Objetivo
## Alcance (entra / no entra)
## Que se debe hacer (pasos concretos y ordenados)
## Archivos a crear/modificar (rutas reales, una linea de "que cambia")
## Contratos / API rideglory-api (o "ninguno")
## Cambios de datos / migraciones (o "ninguno")
## Criterios de aceptacion (numerados, observables, testeables)
## Pruebas (unitarias/widget/integracion)
## Riesgos y mitigaciones
## Dependencias (fases prerequisito y por que)
## Ejecucion recomendada (nivel rg-exec: ${p.recommendedTier}) — por que ese nivel: ${p.tierRationale}

Abre el codigo si dudas de una ruta. Respeta Clean Architecture + rideglory-coding-standards.
${feedback ? `\nMODO CORRECCION — el Auditor Opus pidio aplicar TODOS estos cambios y reescribir ${rel}:\n${feedback.requestedChanges.map((c) => '- ' + c).join('\n')}` : ''}
Devuelve {file, title}.`,
          { label: `fase-${pad2(p.id)}`, phase: 'Write phases', model: 'sonnet', schema: FILE_SCHEMA },
        ),
    })
    return { id: p.id, file: fname, title: result.title, approved: verdict.approved, score: verdict.score, tier: p.recommendedTier }
  }),
)

const writtenPhases = phaseResults.filter(Boolean).sort((a, b) => a.id - b.id)
const indexList = writtenPhases.map((f) => `- Fase ${f.id} [${(f.tier || 'normal').toUpperCase()}]: [${f.title}](phases/${f.file}) ${f.approved ? '' : '(auditoria con observaciones)'}`).join('\n')
const firstFile = writtenPhases[0] ? writtenPhases[0].file : 'phase-01-...md'

await agent(
  `Eres el PO cerrando el plan "${SLUG}" de Rideglory. Escribe el INDICE maestro.

${HARD_RULES}

CONTEXTO: ${WS}/05-sintesis.md y los archivos en ${WS}/phases/.

ESCRIBE ${WS}/PLAN.md con:
# Plan: ${SLUG}
> Estado: BORRADOR — revision humana pendiente. Generado: (usa \`date -u\`)
## Overview
${finalPlan.overview}
## Fases
${indexList}
## Supuestos
## Riesgos
## Como ejecutar una fase
> Cada fase se implementa con rg-exec en el NIVEL recomendado (ver el [LITE/NORMAL/FULL] del titulo y la seccion "Ejecucion recomendada" de cada fase):
> Workflow({ name: 'rg-exec', args: { source: '${WS}/phases/${firstFile}', mode: '<lite|normal|full>' } })
> lite = mecanico/bajo riesgo; normal = feature acotada; full = complejo/riesgoso (contratos, migraciones, seguridad).

Toma supuestos/riesgos de 05-sintesis.md. Devuelve {file, title}.`,
  { label: 'plan-index', phase: 'Write phases', model: 'sonnet', schema: FILE_SCHEMA },
)

return {
  slug: SLUG,
  workspace: WS,
  planIndex: `${WS}/PLAN.md`,
  phaseCount: writtenPhases.length,
  phases: writtenPhases.map((f) => ({ id: f.id, file: `${WS}/phases/${f.file}`, approved: f.approved, score: f.score })),
  note: `Plan aislado escrito y auditado por Opus bajo ${WS}/. Revisa ${WS}/PLAN.md.`,
}
