export const meta = {
  name: 'rg-exec',
  description:
    'Ejecuta una mejora o una fase de plan en Rideglory (Flutter + rideglory-api): Normalize -> Architect -> [Design || Backend] -> Frontend -> QA (con verificacion adversarial) -> Tech Lead, donde un AUDITOR Opus revisa cada seccion de implementacion contra el git diff y los criterios de aceptacion, pide cambios al agente e itera hasta un resultado optimo. Modifica codigo SIN commitear (working tree sucio para revision humana). Aislado bajo docs/exec-runs/<slug>/. No toca workflow/state.json ni el sistema /iter.',
  phases: [
    { title: 'Normalize', detail: 'Normalizar la nota/fase a PRD con AC + guardrails' },
    { title: 'Architect', detail: 'Change map + decisiones (Opus), auditado por Opus' },
    { title: 'Build', detail: 'Design || Backend, luego Frontend — cada uno auditado por Opus' },
    { title: 'Verify', detail: 'QA + verificacion adversarial + auditoria de cobertura' },
    { title: 'Review', detail: 'Tech Lead Opus + cierre (SUMMARY/REVIEW_CHECKLIST)' },
  ],
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
const HARD_RULES = `
HARD RULES — no las violes:
1. NUNCA ejecutes: git add / commit / push / merge / rebase / restore / reset, ni gh pr create / merge / review. El arbol de trabajo queda SUCIO a proposito; el humano commitea.
2. NUNCA modifiques: workflow/state.json, workflow/artifact_log.json, docs/PRD.md, docs/PLAN.md, docs/ITERATION_HISTORY.md, docs/PRODUCT_STATUS.md, docs/handoffs/** (sistema /iter), .claude/skills/**, .claude/agents/**, .claude/workflows/**, ni la nota fuente original.
3. Escribe artefactos de analisis bajo docs/exec-runs/<slug>/. Backend/Frontend SI pueden editar codigo de la app (Flutter lib/ y rideglory-api) para implementar; NUNCA commitear.
4. Lee tu playbook en .claude/agents/<rol>.md; las RUTAS DE SALIDA de este prompt MANDAN sobre el playbook.
5. Timestamps con Bash \`date -u +%Y-%m-%dT%H:%M:%SZ\`. No inventes fechas.
`

const AUDIT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['approved', 'score', 'findings', 'requestedChanges'],
  properties: {
    approved: { type: 'boolean' },
    score: { type: 'integer' },
    findings: { type: 'array', items: { type: 'string' } },
    requestedChanges: { type: 'array', items: { type: 'string' } },
  },
}

const IMPL_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['status', 'filesChanged', 'testResult', 'notes'],
  properties: {
    status: { type: 'string', enum: ['pass', 'fail'] },
    filesChanged: { type: 'array', items: { type: 'string' } },
    testResult: { type: 'string', description: 'comando + conteo pass/fail' },
    notes: { type: 'string' },
  },
}

// Bucle auditor Opus para implementacion: produce -> auditor opus revisa git diff + AC -> reinyecta -> repite.
async function audited({ label, phaseName, criteria, auditReads, produce, maxRounds = 3 }) {
  let result = await produce(null)
  let verdict = null
  for (let round = 1; round <= maxRounds; round++) {
    verdict = await agent(
      `Eres el AUDITOR de calidad (Opus) de la corrida "${SLUG}" de Rideglory. Auditas el trabajo del agente "${label}".

${HARD_RULES}

QUE LEER:
- ${WS}/PRD_NORMALIZED.md (criterios de aceptacion §AC y guardrails §regresion).
- ${auditReads}
- El cambio real en el codigo: corre \`git diff\` y \`git diff --stat\` y LEE cada hunk de los archivos tocados por este agente.

CRITERIOS DE AUDITORIA:
${criteria}

Eres exigente. Aprueba SOLO si: cumple los AC, no viola Clean Architecture (domain sin Flutter/IO, data sin BuildContext, presentation sin HTTP/DTO), respeta rideglory-coding-standards (un widget por archivo, sin metodos que retornan widgets, usa AppButton/AppTextField/AppSwitch, texto oscuro sobre primario, strings en app_es.arb), sin secretos/SQL concatenado/URLs hardcodeadas, y trae pruebas que fallarian sin el cambio.
Si falla, devuelve requestedChanges concretos (archivo + que cambiar). ${round === maxRounds ? 'ULTIMA ronda: aprueba lo defendible y deja findings.' : ''}
Devuelve (approved, score, findings, requestedChanges).`,
      { label: `${label}:audit#${round}`, phase: phaseName, model: 'opus', schema: AUDIT_SCHEMA },
    )
    log(`[audit:opus] ${label} ronda ${round}: ${verdict.approved ? 'APROBADO' : 'cambios solicitados'} (score ${verdict.score})`)
    if (verdict.approved || round === maxRounds) break
    result = await produce(verdict)
  }
  return { result, verdict }
}

const fixBlock = (feedback) =>
  feedback
    ? `\nMODO CORRECCION — el Auditor Opus exige aplicar TODOS estos cambios (reedita el codigo y re-corre las pruebas):\n${feedback.requestedChanges.map((c) => '- ' + c).join('\n')}`
    : ''

// ---------------------------------------------------------------------------
// Phase: Normalize
// ---------------------------------------------------------------------------
phase('Normalize')

const SOURCE = typeof args === 'string' && args.trim() ? args.trim() : null
if (!SOURCE) {
  throw new Error(
    'rg-exec requiere args = ruta a una nota de mejora o a un archivo de fase del plan (p.ej. docs/plans/<slug>/phases/phase-01-...md).',
  )
}

const NORM_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['slug', 'goal', 'acceptanceCriteria', 'guardrails'],
  properties: {
    slug: { type: 'string' },
    goal: { type: 'string' },
    acceptanceCriteria: { type: 'array', items: { type: 'string' } },
    guardrails: { type: 'array', items: { type: 'string' } },
  },
}

const norm = await agent(
  `Eres el PRD Normalizer de la corrida rg-exec de Rideglory. Una pasada ligera (no escaneo exhaustivo; el Architect lee el codigo a fondo).

Fuente (solo lectura): ${SOURCE}  — leela COMPLETA. Puede ser una nota de mejora o un archivo de fase de plan (docs/plans/<slug>/phases/...).

${HARD_RULES}

CONTEXTO opcional: docs/handoffs/prd-digest.md si existe (constraints del producto); si no, docs/PRD.md (solo lectura).

TU TRABAJO:
1. Deriva un SLUG kebab-case corto.
2. \`mkdir -p docs/exec-runs/<SLUG>/handoffs docs/exec-runs/<SLUG>/analysis\`.
3. Escribe docs/exec-runs/<SLUG>/PRD_NORMALIZED.md con: ## 1 Objetivo, ## 2 Por que, ## 3 Alcance (entra/no entra), ## 4 Areas afectadas (best-effort; el Architect las verifica), ## 5 Criterios de aceptacion (numerados, observables, testeables — si la fuente ya los trae, preservalos), ## 6 Guardrails de regresion (flujos/pantallas/endpoints que no deben romperse), ## 7 Constraints heredados.
Si la fuente es un archivo de fase de plan, sus "Criterios de aceptacion" y "Que se debe hacer" son la base — preservalos.
Devuelve (slug, goal, acceptanceCriteria, guardrails).`,
  { label: 'normalize', phase: 'Normalize', schema: NORM_SCHEMA },
)

const SLUG = norm.slug
const WS = `docs/exec-runs/${SLUG}`
log(`Ejecutando "${SLUG}" — workspace ${WS}/ (sin commits).`)

// ---------------------------------------------------------------------------
// Phase: Architect (Opus, auditado por Opus)
// ---------------------------------------------------------------------------
phase('Architect')

const ARCH_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['decisions', 'changeMap', 'implementationOrder', 'regressionSurface'],
  properties: {
    decisions: {
      type: 'object',
      additionalProperties: false,
      required: ['uiChanges', 'backendChanges', 'frontendChanges', 'dbChanges', 'needsDesign'],
      properties: {
        uiChanges: { type: 'boolean' },
        backendChanges: { type: 'boolean' },
        frontendChanges: { type: 'boolean' },
        dbChanges: { type: 'boolean' },
        needsDesign: { type: 'boolean' },
      },
    },
    changeMap: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['file', 'action', 'reason', 'risk'],
        properties: {
          file: { type: 'string' },
          action: { type: 'string', enum: ['create', 'modify', 'delete'] },
          reason: { type: 'string' },
          risk: { type: 'string', enum: ['low', 'med', 'high'] },
        },
      },
    },
    implementationOrder: { type: 'array', items: { type: 'string' } },
    regressionSurface: { type: 'string' },
  },
}

const archRun = await audited({
  label: 'architect',
  phaseName: 'Architect',
  auditReads: `${WS}/handoffs/architect.md y los slim ${WS}/handoffs/architect-for-*.md`,
  criteria: `- El change map cubre TODOS los AC y nada fuera de alcance (cada archivo justifica su cambio).
- Las decisiones (ui/backend/frontend/db/needsDesign) son correctas segun el codigo real.
- El orden de implementacion respeta dependencias (contrato backend antes de frontend).
- Identifica contratos rideglory-api, migraciones y env deltas explicitamente.`,
  produce: (feedback) =>
    agent(
      `Eres el Architect (Opus) de rg-exec ${SLUG}. Contrato: ${WS}/PRD_NORMALIZED.md.

${HARD_RULES}

CONTEXTO: ${WS}/PRD_NORMALIZED.md (completo), .claude/agents/architect.md, .claude/skills/architect-skill.md, docs/architecture/DIAGRAMS.md (solo lectura), y el codigo real en cada area del PRD §4 (abre cada archivo, corrige §4 contra la realidad).

TU TRABAJO:
1. Decide los 5 flags (uiChanges, backendChanges, frontendChanges, dbChanges, needsDesign) segun el codigo.
2. Change map: tabla file | action | reason | risk. Es la lista maestra; Backend/Frontend solo tocan archivos que aparezcan aqui.
3. Orden de implementacion (dependencias entre archivos).
4. Contratos rideglory-api, migraciones (analysis/MIGRATION_PLAN.md si aplica), env deltas (analysis/ENV_DELTA.md si aplica). NO ejecutes migraciones ni toques .env real.
5. Escribe ${WS}/handoffs/architect.md (## Decisiones, ## Change map, ## Contratos, ## Datos/migraciones, ## Env, ## Riesgos, ## Orden de implementacion, ## Superficie de regresion, ## Fuera de alcance) y slim ${WS}/handoffs/architect-for-backend.md / architect-for-frontend.md (segun flags) / architect-for-qa.md.
${fixBlock(feedback)}
Devuelve el objeto estructurado.`,
      { label: 'architect', phase: 'Architect', model: 'opus', schema: ARCH_SCHEMA },
    ),
})

const d = archRun.result.decisions
const changeMapStr = archRun.result.changeMap.map((c) => `${c.action} ${c.file} (${c.risk}) — ${c.reason}`).join('\n')

// ---------------------------------------------------------------------------
// Phase: Build — Design || Backend, luego Frontend (cada uno auditado por Opus)
// ---------------------------------------------------------------------------
phase('Build')

const designNeeded = d.needsDesign || d.uiChanges

const [designRes, backendRes] = await parallel([
  () =>
    designNeeded
      ? audited({
          label: 'design',
          phaseName: 'Build',
          auditReads: `${WS}/handoffs/design.md y los mockups en ${WS}/analysis/design/`,
          criteria: `- Cubre todos los estados UX (idle/loading/success/cada error) de cada pantalla tocada.
- Copy en espanol consistente con el tono existente; reusa componentes shared antes de crear nuevos.
- Respeta el design system (texto oscuro sobre primario, AppButton/AppTextField/AppSwitch).`,
          produce: (feedback) =>
            agent(
              `Eres el Design agent de rg-exec ${SLUG}.

${HARD_RULES}

CONTEXTO: ${WS}/PRD_NORMALIZED.md, ${WS}/handoffs/architect.md, .claude/agents/design.md, .claude/skills/design-skill.md, docs/design/ (solo lectura).
Change map:
${changeMapStr}

TU TRABAJO: pantallas tocadas (NEW|EXTEND|UPDATE), estados UX, componentes (reusa primero), copy (labels/placeholders/errores), accesibilidad. Si Pencil MCP esta disponible NO toques el .pen global salvo autorizacion del architect; exporta a ${WS}/analysis/design/. Si no, mockups HTML en ${WS}/analysis/design/html-mockups/.
Escribe ${WS}/handoffs/design.md (## Pantallas, ## Flujos UX, ## Componentes, ## Copy, ## Accesibilidad, ## Notas para Frontend).
${fixBlock(feedback)}
Devuelve {status:'pass', filesChanged, testResult:'n/a', notes}.`,
              { label: 'design', phase: 'Build', schema: IMPL_SCHEMA },
            ),
        }).then((r) => r.result)
      : Promise.resolve(null),
  () =>
    d.backendChanges
      ? audited({
          label: 'backend',
          phaseName: 'Build',
          auditReads: `${WS}/handoffs/backend.md (archivos cambiados + pruebas)`,
          criteria: `- Implementa el contrato exacto; valida inputs; SQL parametrizado; sin secretos.
- Pruebas unitarias+integracion para cada path nuevo y para cada guardrail backend; suite en verde.
- Solo toca archivos del change map.`,
          produce: (feedback) =>
            agent(
              `Eres el Backend agent (rideglory-api) de rg-exec ${SLUG}. VAS A EDITAR CODIGO. NO commitees.

${HARD_RULES}

CONTEXTO: ${WS}/handoffs/architect-for-backend.md (primero), ${WS}/PRD_NORMALIZED.md (ambiguedad), ${WS}/analysis/MIGRATION_PLAN.md y ENV_DELTA.md si existen, .claude/agents/backend.md, .claude/skills/backend-skill.md. Backend vive en /Users/cami/Developer/Personal/rideglory-api.
Change map:
${changeMapStr}

TU TRABAJO:
1. Baseline: corre las pruebas backend. Si estan rojas ANTES, reporta status:'fail' y para.
2. Aplica cambios en el orden del architect. Migraciones solo local; nunca contra prod. Env vars solo en .env.example si ENV_DELTA lo dice.
3. Pruebas unit+integration por cada path nuevo; cubre guardrails backend. Suite en verde.
4. Escribe ${WS}/handoffs/backend.md (## Baseline, ## Archivos cambiados, ## Pruebas nuevas, ## Resultado final, ## Verificacion manual, ## Notas para Frontend/QA).
${fixBlock(feedback)}
Devuelve {status, filesChanged, testResult, notes}.`,
              { label: 'backend', phase: 'Build', schema: IMPL_SCHEMA },
            ),
        }).then((r) => r.result)
      : Promise.resolve(null),
])

let frontendRes = null
if (d.frontendChanges) {
  const fr = await audited({
    label: 'frontend',
    phaseName: 'Build',
    auditReads: `${WS}/handoffs/frontend.md (archivos cambiados + pruebas)`,
    criteria: `- Todos los estados UI (idle/loading/success/cada error); copy y componentes segun Design.
- Cubits con ResultState (sin flags booleanos de loading/error); Clean Architecture intacta.
- Strings en app_es.arb; widgets shared; un widget por archivo; pruebas widget/integracion que fallarian sin el cambio.
- Solo archivos del change map; sin URLs hardcodeadas (usa el patron de base URL).`,
    produce: (feedback) =>
      agent(
        `Eres el Frontend agent (Flutter lib/) de rg-exec ${SLUG}. VAS A EDITAR CODIGO. NO commitees.

${HARD_RULES}

CONTEXTO: ${WS}/handoffs/architect-for-frontend.md (primero), ${WS}/handoffs/design.md si existe, ${WS}/handoffs/backend.md si existe (contrato), .claude/agents/frontend.md, .claude/skills/frontend-skill.md.
Change map:
${changeMapStr}

TU TRABAJO:
1. Baseline: \`flutter test\`. Registra resultado.
2. Aplica cambios en el orden del architect. Si tocas DTOs/servicios/DI/freezed, corre \`dart run build_runner build --delete-conflicting-outputs\`.
3. Estados UI completos; validacion cliente espeja la del server; strings en app_es.arb.
4. Pruebas widget/integracion por cada path nuevo. \`dart analyze\` y \`flutter test\` en verde.
5. Escribe ${WS}/handoffs/frontend.md (## Baseline, ## Archivos cambiados, ## Pruebas nuevas, ## Resultado final, ## Verificacion manual, ## Notas para QA).
${fixBlock(feedback)}
Devuelve {status, filesChanged, testResult, notes}.`,
        { label: 'frontend', phase: 'Build', schema: IMPL_SCHEMA },
      ),
  })
  frontendRes = fr.result
}

// ---------------------------------------------------------------------------
// Phase: Verify — QA + fix loop + verificacion adversarial de cobertura
// ---------------------------------------------------------------------------
phase('Verify')

const QA_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['signOff', 'bugs', 'testSummary'],
  properties: {
    signOff: { type: 'string', enum: ['green', 'conditional', 'blocked'] },
    bugs: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['area', 'file', 'description'],
        properties: {
          area: { type: 'string', enum: ['backend', 'frontend'] },
          file: { type: 'string' },
          description: { type: 'string' },
        },
      },
    },
    testSummary: { type: 'string' },
  },
}

const qaPrompt = (note) =>
  `Eres el QA agent de rg-exec ${SLUG}.

${HARD_RULES}

CONTEXTO: ${WS}/handoffs/architect-for-qa.md, ${WS}/PRD_NORMALIZED.md (§5 AC, §6 guardrails), ${WS}/handoffs/backend.md y frontend.md si existen, .claude/agents/qa.md, .claude/skills/qa-skill.md, y el diff real (\`git diff --stat\`).

TU TRABAJO:
1. Catalogo: cada AC §5 -> test que lo cubre (existente|nuevo|gap).
2. Matriz de regresion: cada guardrail §6 -> mecanismo (test existente|nuevo|prueba manual).
3. Corre la suite (backend \`npm test\`/equivalente y \`flutter test\`/\`dart analyze\`). Marca fallos pre-existentes como pre_existing; las regresiones de esta corrida son BUGs (asignados a backend|frontend con file).
4. Escribe ${WS}/handoffs/qa.md (## Catalogo, ## Matriz de regresion, ## Ejecucion (comandos+conteos), ## Bugs, ## Pruebas manuales para el humano, ## Sign-off).
${note ? `\nNOTA: ${note}` : ''}
Devuelve (signOff, bugs, testSummary).`

let qa = await agent(qaPrompt(null), { label: 'qa', phase: 'Verify', schema: QA_SCHEMA })

let qaRound = 0
while (qa.signOff === 'blocked' && qa.bugs.length > 0 && qaRound < 2) {
  qaRound++
  log(`[qa] sign-off blocked (ronda ${qaRound}) — ${qa.bugs.length} bugs. Verificando adversarialmente y corrigiendo...`)

  // Verificacion adversarial: un esceptico confirma o refuta cada bug antes de gastar un fix.
  const verified = await parallel(
    qa.bugs.map((b) => () =>
      agent(
        `Eres un verificador adversarial de rg-exec ${SLUG}. Intenta REFUTAR este bug reportado por QA leyendo el codigo real (\`git diff\` + el archivo):
area=${b.area} file=${b.file}
"${b.description}"
${HARD_RULES}
Si el bug es real y reproducible, confirmed=true. Si QA se equivoco o ya esta cubierto, confirmed=false. Ante la duda, confirmed=true.
Devuelve {confirmed, reason}.`,
        {
          label: `verify:${b.area}`,
          phase: 'Verify',
          schema: {
            type: 'object',
            additionalProperties: false,
            required: ['confirmed', 'reason'],
            properties: { confirmed: { type: 'boolean' }, reason: { type: 'string' } },
          },
        },
      ).then((v) => ({ bug: b, confirmed: v.confirmed })),
    ),
  )
  const realBugs = verified.filter(Boolean).filter((v) => v.confirmed).map((v) => v.bug)
  if (realBugs.length === 0) {
    log('[qa] todos los bugs fueron refutados por verificacion adversarial. Re-corriendo QA.')
    qa = await agent(qaPrompt('Los bugs previos fueron refutados; reevalua honestamente.'), { label: 'qa', phase: 'Verify', schema: QA_SCHEMA })
    continue
  }

  const areas = [...new Set(realBugs.map((b) => b.area))]
  for (const area of areas) {
    const list = realBugs.filter((b) => b.area === area).map((b) => `- ${b.file}: ${b.description}`).join('\n')
    await agent(
      `Eres el ${area === 'backend' ? 'Backend (rideglory-api)' : 'Frontend (Flutter lib/)'} agent de rg-exec ${SLUG} en MODO FIX. VAS A EDITAR CODIGO. NO commitees.
${HARD_RULES}
Corrige SOLO estos bugs confirmados (no re-scaffold), re-corre las pruebas, actualiza ${WS}/handoffs/${area}.md:
${list}
Devuelve {status, filesChanged, testResult, notes}.`,
      { label: `${area}-fix`, phase: 'Verify', schema: IMPL_SCHEMA },
    )
  }
  qa = await agent(qaPrompt('Re-evaluacion tras correcciones.'), { label: 'qa', phase: 'Verify', schema: QA_SCHEMA })
}

// Auditoria Opus de adecuacion de pruebas (cada AC debe tener un test que falle sin el cambio).
const qaAudit = await agent(
  `Eres el AUDITOR Opus de cobertura de pruebas de rg-exec ${SLUG}.
${HARD_RULES}
Lee ${WS}/PRD_NORMALIZED.md (§5 AC, §6 guardrails), ${WS}/handoffs/qa.md y el diff de tests (\`git diff\`). Para CADA AC verifica que exista una prueba que fallaria sin el cambio (no aserciones trivialmente verdaderas).
Si falta cobertura, requestedChanges debe nombrar el AC y el test faltante.
Devuelve (approved, score, findings, requestedChanges).`,
  { label: 'qa:audit', phase: 'Verify', model: 'opus', schema: AUDIT_SCHEMA },
)
if (!qaAudit.approved && qaAudit.requestedChanges.length > 0) {
  log(`[audit:opus] QA cobertura insuficiente — pidiendo tests adicionales.`)
  qa = await agent(
    qaPrompt(`El auditor Opus exige agregar estas pruebas faltantes (agrega los tests y re-corre):\n${qaAudit.requestedChanges.map((c) => '- ' + c).join('\n')}`),
    { label: 'qa', phase: 'Verify', schema: QA_SCHEMA },
  )
}

// ---------------------------------------------------------------------------
// Phase: Review — Tech Lead Opus + cierre, con bucle de correccion
// ---------------------------------------------------------------------------
phase('Review')

const VERDICT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['verdict', 'blockers', 'summary'],
  properties: {
    verdict: { type: 'string', enum: ['ready', 'needs_changes'] },
    blockers: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['area', 'description'],
        properties: { area: { type: 'string', enum: ['backend', 'frontend'] }, description: { type: 'string' } },
      },
    },
    summary: { type: 'string' },
  },
}

const techLeadPrompt = (note) =>
  `Eres el Tech Lead (Opus) de rg-exec ${SLUG}. NO hay PR: revisas el working tree via \`git diff\` y produces los artefactos para el humano.

${HARD_RULES}

CONTEXTO: ${WS}/PRD_NORMALIZED.md, ${WS}/handoffs/architect.md, design.md/backend.md/frontend.md/qa.md segun existan, .claude/agents/tech_lead.md, .claude/skills/tech_lead-skill.md, y \`git diff\` + \`git diff --stat\` completos (lee cada archivo cambiado).

REVISION:
- Cada hunk contra el change map del architect; marca archivos fuera del mapa.
- Seguridad: sin secretos, sin SQL concatenado, sin XSS, sin PII en logs, auth/CORS respetados.
- Arquitectura: Clean Architecture intacta, env vars (no URLs hardcodeadas), shape de API segun contrato, ERD vs migracion consistentes, rideglory-coding-standards.
- Adecuacion de tests: cada AC con un test que falla sin el cambio.
- HARD RULES respetadas (sin commits, sin tocar protegidos).

CIERRE (escribe ademas):
- ${WS}/SUMMARY.md (## Objetivo, ## Que cambio por area, ## Archivos (git diff --stat), ## Pruebas, ## Riesgos/watchlist, ## Mensaje de commit sugerido).
- ${WS}/REVIEW_CHECKLIST.md (pasos que el humano corre antes de commitear).
- ${WS}/handoffs/tech_lead.md (## Veredicto, ## Hallazgos (file:line|severidad|fix), ## Seguridad, ## Arquitectura, ## Tests, ## Pruebas manuales).
${note ? `\nNOTA: ${note}` : ''}
verdict='needs_changes' solo si hay blockers reales (con area+description). Devuelve (verdict, blockers, summary).`

let tl = await agent(techLeadPrompt(null), { label: 'tech-lead', phase: 'Review', model: 'opus', schema: VERDICT_SCHEMA })

let tlRound = 0
while (tl.verdict === 'needs_changes' && tl.blockers.length > 0 && tlRound < 2) {
  tlRound++
  log(`[tech-lead] needs_changes (ronda ${tlRound}) — ${tl.blockers.length} blockers. Corrigiendo...`)
  const areas = [...new Set(tl.blockers.map((b) => b.area))]
  for (const area of areas) {
    const list = tl.blockers.filter((b) => b.area === area).map((b) => `- ${b.description}`).join('\n')
    await agent(
      `Eres el ${area === 'backend' ? 'Backend (rideglory-api)' : 'Frontend (Flutter lib/)'} agent de rg-exec ${SLUG} en MODO FIX (Tech Lead). VAS A EDITAR CODIGO. NO commitees.
${HARD_RULES}
Corrige SOLO estos hallazgos del Tech Lead, re-corre pruebas, actualiza ${WS}/handoffs/${area}.md:
${list}
Devuelve {status, filesChanged, testResult, notes}.`,
      { label: `${area}-fix`, phase: 'Review', schema: IMPL_SCHEMA },
    )
  }
  tl = await agent(techLeadPrompt('Re-revision tras correcciones de blockers.'), { label: 'tech-lead', phase: 'Review', model: 'opus', schema: VERDICT_SCHEMA })
}

return {
  slug: SLUG,
  workspace: WS,
  decisions: d,
  qaSignOff: qa.signOff,
  techLeadVerdict: tl.verdict,
  remainingBlockers: tl.blockers,
  artifacts: {
    summary: `${WS}/SUMMARY.md`,
    reviewChecklist: `${WS}/REVIEW_CHECKLIST.md`,
    techLead: `${WS}/handoffs/tech_lead.md`,
  },
  note: `Codigo modificado SIN commitear. Revisa con \`git diff\` y ${WS}/REVIEW_CHECKLIST.md. No se toco workflow/state.json ni el sistema /iter.`,
}
