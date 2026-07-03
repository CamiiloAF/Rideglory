export const meta = {
  name: 'rg-exec',
  description:
    'Ejecuta una mejora o una fase de plan en Rideglory (Flutter + rideglory-api) con NIVEL DE ESFUERZO ajustable (lite | normal | full). El AUDITOR corre con Opus; todo lo demas con Sonnet. Incluye UX Review gate (Nielsen/Laws of UX/WCAG/HIG) despues de Design y antes de Frontend cuando hay UI. Al cerrar genera el QA_CHECKLIST.md y lo AUTOMATIZA con qa-auto integrado (clasifica cada caso, genera+corre los tests automatizables auditados por Opus y anota el checklist con tri-estado 🤖/👤/🚫). Modifica codigo SIN commitear (working tree sucio para revision humana). Aislado bajo docs/exec-runs/<slug>/. args puede ser una ruta (string) o un objeto {source, mode}.',
  phases: [
    { title: 'Normalize', detail: 'Normalizar la nota/fase a PRD con AC + guardrails' },
    { title: 'Architect', detail: 'normal/full: change map + decisiones (Sonnet), auditado por Opus' },
    { title: 'Build', detail: 'lite: un implementador; normal/full: Design || Backend -> UX Review gate (si UI) -> Frontend, auditados' },
    { title: 'Verify', detail: 'QA + auditoria de cobertura Opus; adversarial solo en full' },
    { title: 'Review', detail: 'normal/full: Tech Lead; lite: cierre directo (SUMMARY/REVIEW_CHECKLIST). Al final genera el QA_CHECKLIST.md y lo automatiza con qa-auto (sub-workflow, tri-estado)' },
  ],
}

// ---------------------------------------------------------------------------
// Nivel de esfuerzo (mode)
// ---------------------------------------------------------------------------
const input = typeof args === 'object' && args !== null ? args : { source: args, mode: 'normal' }
const SOURCE = typeof input.source === 'string' && input.source.trim() ? input.source.trim() : null
const MODE = ['lite', 'normal', 'full'].includes(input.mode) ? input.mode : 'normal'
if (!SOURCE) {
  throw new Error(
    'rg-exec requiere args = ruta a una nota/fase (string), o {source: "<ruta>", mode: "lite|normal|full"}. Ej: {source: "docs/plans/x/phases/phase-02-...md", mode: "lite"}.',
  )
}

const CFG = {
  lite: { rounds: 1, adversarial: false, fixCap: 0, architect: false, techLead: false },
  normal: { rounds: 2, adversarial: false, fixCap: 1, architect: true, techLead: true },
  full: { rounds: 3, adversarial: true, fixCap: 2, architect: true, techLead: true },
}[MODE]

log(`Nivel de ejecucion: ${MODE.toUpperCase()} (auditor rondas=${CFG.rounds}, adversarial=${CFG.adversarial}, architect=${CFG.architect}, techLead=${CFG.techLead}).`)

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
const HARD_RULES = `
HARD RULES — no las violes:
1. NUNCA ejecutes: git add / commit / push / merge / rebase / restore / reset, ni gh pr create / merge / review. El arbol de trabajo queda SUCIO a proposito; el humano commitea.
2. NUNCA modifiques: docs/PRD.md, docs/PLAN.md, docs/PRODUCT_STATUS.md, docs/handoffs/** (legado), .claude/**, ni la nota fuente original.
3. Escribe artefactos de analisis bajo docs/exec-runs/<slug>/. Backend/Frontend SI pueden editar codigo de la app (Flutter lib/ y rideglory-api); NUNCA commitear.
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

// Bucle auditor Opus: produce -> auditor opus revisa git diff + AC -> reinyecta -> repite (maxRounds segun nivel).
async function audited({ label, phaseName, criteria, auditReads, produce, maxRounds = CFG.rounds }) {
  let result = await produce(null)
  let verdict = null
  for (let round = 1; round <= maxRounds; round++) {
    verdict = await agent(
      `Eres el AUDITOR de calidad (Opus) de la corrida "${SLUG}" de Rideglory. Auditas el trabajo del agente "${label}".

${HARD_RULES}

QUE LEER:
- ${WS}/PRD_NORMALIZED.md (criterios de aceptacion §AC y guardrails §regresion).
- ${auditReads}
- El cambio real: corre \`git diff\` y \`git diff --stat\` y LEE cada hunk de los archivos tocados por este agente. Si dudas de los tests, correlos.

CRITERIOS DE AUDITORIA:
${criteria}

Eres exigente. Aprueba SOLO si: cumple los AC, no viola Clean Architecture (domain sin Flutter/IO, data sin BuildContext, presentation sin HTTP/DTO), respeta rideglory-coding-standards (un widget por archivo, sin metodos que retornan widgets, AppButton/AppTextField/AppSwitch, texto oscuro sobre primario, strings en app_es.arb), sin secretos/SQL concatenado/URLs hardcodeadas/PII, y trae pruebas que fallarian sin el cambio (en verde).
Si falla, devuelve requestedChanges concretos (archivo + que cambiar). ${maxRounds === 1 ? 'UNICA ronda (nivel lite): si hay algo menor, dejalo en findings y aprueba lo defendible; bloquea solo ante fallos reales.' : round === maxRounds ? 'ULTIMA ronda: aprueba lo defendible y deja findings.' : ''}
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
// Helper: genera QA_CHECKLIST.md al final de cada corrida
// ---------------------------------------------------------------------------
async function generateQaChecklist(ws, slug, mode, sources) {
  return agent(
    `Eres el QA Checklist writer de rg-exec ${slug}. Tu unico trabajo es escribir UN DOCUMENTO HUMANO de prueba manual que el PO/QA usara para aprobar la fase. Escribe en espanol colombiano, segunda persona singular ("toca", "abre", "verifica").

${HARD_RULES}

CONTEXTO (lee todos los que existan):
- ${ws}/PRD_NORMALIZED.md — §5 AC y §6 guardrails son la fuente de verdad de que probar.
- ${ws}/handoffs/qa.md — catalogo de pruebas manuales ya identificadas por QA.
- ${ws}/handoffs/frontend.md — pantallas y flujos implementados.
- ${ws}/handoffs/backend.md — endpoints y comportamiento del API.
- ${ws}/SUMMARY.md — resumen de que cambio.
- git diff --stat — archivos reales tocados.
${sources ? sources : ''}

FORMATO OBLIGATORIO (respeta cada heading, tabla y campo exactamente):

# Checklist de QA — <titulo descriptivo de la feature, no el slug>

**Feature:** <nombre legible>
**Fases cubiertas:** <ej. "Fase 1 (backend) + Fase 3 (Flutter)">
**Estado:** Pendiente de aprobacion PO

---

## Pre-condiciones

Antes de empezar, asegurate de tener en la cuenta de prueba:

- [ ] <condicion 1 — datos de prueba necesarios>
- [ ] <condicion N>

---

## 1. <Titulo del flujo principal>

> <Instruccion de contexto: donde estar, que abrir>

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 1.1 | <imperativo concreto> | <observable, sin ambiguedad> | |

---

## N. <Flujo N>

...

## <N+1>. Casos de borde

### <N+1>A. <caso>

> <contexto>

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|

---

## <N+2>. Verificaciones tecnicas (equipo de desarrollo)

> Estas verificaciones requieren acceso a la base de datos o logs del backend.

| # | Verificacion | Resultado esperado | ✅/❌ |
|---|-------------|--------------------|-------|

---

## Resultado final

| Estado | Criterio |
|--------|----------|
| ✅ Aprobado | Todos los casos X–Y marcados como ✅ |
| ⚠️ Aprobado con observaciones | Maximo 2 casos fallidos de baja severidad, con ticket creado |
| ❌ Rechazado | Cualquier caso de las secciones criticas marcado como ❌ |

**Revisado por:** ___________________
**Fecha:** ___________________
**Resultado:** ___________________
**Observaciones:** ___________________

REGLAS DE CONTENIDO:
- Agrupa los casos por FLUJO DE USUARIO (no por AC tecnico). El tester no sabe de clases ni cubits — describe acciones UI reales.
- Cada caso: numero, accion concreta en imperativo, resultado esperado observable (lo que se ve en pantalla), columna ✅/❌ vacia.
- Pre-condiciones: datos de prueba especificos que el tester debe tener antes de empezar.
- Casos de borde: al menos los escenarios no-happy-path relevantes (error de red, lista vacia, usuario sin permisos, etc.).
- Verificaciones tecnicas: consultas a DB o logs de red que validen el comportamiento del backend (solo para dev).
- Criterio de rechazo en "Resultado final": menciona las secciones criticas por numero.
- Escribe el documento en ${ws}/QA_CHECKLIST.md.

Devuelve {status:'pass', filesChanged:['${ws}/QA_CHECKLIST.md'], testResult:'n/a', notes: '<N> casos en <M> secciones'}.`,
    { label: 'qa-checklist', phase: 'Review', model: 'sonnet', schema: IMPL_SCHEMA },
  )
}

// ---------------------------------------------------------------------------
// Helper: genera el QA_CHECKLIST.md y luego lo AUTOMATIZA con qa-auto integrado.
// qa-auto clasifica cada caso, genera+corre los tests automatizables (auditados
// por Opus) y anota el mismo QA_CHECKLIST.md con tri-estado (🤖/👤/🚫). Se corre
// como sub-workflow (un nivel de anidamiento). Si falla, la corrida NO se cae:
// el checklist manual queda igual y se registra el motivo.
// ---------------------------------------------------------------------------
async function generateAndAutomateQa(ws, slug, mode, sources) {
  await generateQaChecklist(ws, slug, mode, sources)
  try {
    log('[qa-auto] Automatizando el QA_CHECKLIST.md (clasifica, genera y corre tests, tri-estado)...')
    const qa = await workflow('qa-auto', slug)
    if (qa && qa.counts) {
      log(
        `[qa-auto] ${qa.counts.autoPass ?? 0}🤖✅ / ${qa.counts.autoFail ?? 0}🤖❌ · ${qa.counts.manual ?? 0}👤 · ${qa.counts.noAuto ?? 0}🚫 (auditor: ${qa.auditor ?? 'n/a'}).`,
      )
    } else {
      log('[qa-auto] terminó sin conteos; revisa el QA_CHECKLIST.md anotado.')
    }
    return qa
  } catch (e) {
    log(`[qa-auto] no se pudo automatizar el checklist (${e && e.message ? e.message : e}); queda solo el documento manual.`)
    return null
  }
}

// ---------------------------------------------------------------------------
// Phase: Normalize (siempre)
// ---------------------------------------------------------------------------
phase('Normalize')

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

// NOMENCLATURA ESTÁNDAR de carpetas de fase: `<feature>-phase-XX` (kebab, 2
// dígitos). Cuando la fuente es un archivo de fase de plan
// (docs/plans/<feature>/phases/phase-NN-*.md) derivamos el slug de forma
// DETERMINÍSTICA para que TODAS las fases de una misma feature queden juntas y
// sean fáciles de encontrar en docs/exec-runs/ (antes cada fase inventaba su
// propio prefijo y se desperdigaban). Si la fuente no es una fase de plan
// (una nota suelta), el agente deriva un slug kebab descriptivo.
function derivePhaseSlug(source) {
  const m = String(source).match(/docs\/plans\/([^/]+)\/phases\/phase-0*(\d+)/i)
  if (!m) return null
  return `${m[1]}-phase-${String(m[2]).padStart(2, '0')}`
}
const MANDATED_SLUG = derivePhaseSlug(SOURCE)

const norm = await agent(
  `Eres el PRD Normalizer de la corrida rg-exec de Rideglory (nivel ${MODE}). Pasada ligera.

Fuente (solo lectura): ${SOURCE} — leela COMPLETA. Puede ser una nota o un archivo de fase de plan (docs/plans/<slug>/phases/...).

${HARD_RULES}

CONTEXTO opcional: docs/handoffs/prd-digest.md si existe; si no, docs/PRD.md (solo lectura).

TU TRABAJO:
1. SLUG de la corrida: ${MANDATED_SLUG
      ? `usa EXACTAMENTE \`${MANDATED_SLUG}\` (nomenclatura estándar <feature>-phase-XX). NO inventes otro; devuélvelo tal cual en el campo slug.`
      : 'la fuente NO es un archivo de fase de plan; deriva un SLUG kebab-case corto y descriptivo del feature.'}
2. \`mkdir -p docs/exec-runs/<SLUG>/handoffs docs/exec-runs/<SLUG>/analysis\` (con el SLUG del paso 1).
3. Escribe docs/exec-runs/<SLUG>/PRD_NORMALIZED.md con: ## 1 Objetivo, ## 2 Por que, ## 3 Alcance, ## 4 Areas afectadas (best-effort), ## 5 Criterios de aceptacion (numerados, observables, testeables; si la fuente los trae, preservalos), ## 6 Guardrails de regresion, ## 7 Constraints heredados.
Si la fuente es un archivo de fase, sus "Criterios de aceptacion" y "Que se debe hacer" son la base — preservalos.
Devuelve (slug, goal, acceptanceCriteria, guardrails).`,
  { label: 'normalize', phase: 'Normalize', model: 'sonnet', schema: NORM_SCHEMA },
)

// El slug mandado gana siempre sobre lo que devuelva el agente (defensa por si
// se desvía de la nomenclatura estándar).
const SLUG = MANDATED_SLUG || norm.slug
const WS = `docs/exec-runs/${SLUG}`
if (MANDATED_SLUG && norm.slug !== MANDATED_SLUG) {
  log(`[normalize] ⚠️ el agente propuso "${norm.slug}"; se fuerza la nomenclatura estándar "${SLUG}". Si escribió PRD_NORMALIZED.md en otra carpeta, muévelo a ${WS}/.`)
}
log(`Ejecutando "${SLUG}" — workspace ${WS}/ (sin commits).`)

// ===========================================================================
// NIVEL LITE — un solo implementador + cierre directo (sin architect/tech-lead)
// ===========================================================================
if (MODE === 'lite') {
  phase('Build')
  const impl = await audited({
    label: 'implementer',
    phaseName: 'Build',
    auditReads: `${WS}/handoffs/implementer.md`,
    criteria: `- Cumple TODOS los AC de §5 con el cambio mas simple y directo.
- Pruebas (unit/widget) por cada path nuevo, en verde; dart analyze limpio.
- Clean Architecture + rideglory-coding-standards intactos; sin PII.`,
    produce: (feedback) =>
      agent(
        `Eres un Flutter/Backend dev implementando una fase de bajo riesgo de Rideglory en UNA pasada (nivel lite). VAS A EDITAR CODIGO. NO commitees.

${HARD_RULES}

CONTEXTO: ${WS}/PRD_NORMALIZED.md (el contrato — §4 areas, §5 AC, §6 guardrails), .claude/agents/frontend.md y .claude/agents/backend.md (criterio), y el codigo real en cada area del §4 (abre cada archivo).

TU TRABAJO:
1. Implementa lo necesario para cumplir los AC (puede ser frontend Flutter lib/ y/o backend rideglory-api segun la fase). Cambio minimo y directo; es trabajo mecanico/bajo riesgo.
2. Si tocas DTOs/DI/freezed/retrofit: \`dart run build_runner build --delete-conflicting-outputs\`.
3. Agrega pruebas por cada path nuevo. Corre \`dart analyze\` y \`flutter test\` (y pruebas backend si aplica). Deja en VERDE.
4. Escribe ${WS}/handoffs/implementer.md (## Archivos cambiados, ## Pruebas nuevas, ## Resultado final (comando+conteo), ## Verificacion manual, ## AC no cubiertos).
${fixBlock(feedback)}
Devuelve {status, filesChanged, testResult, notes}.`,
        { label: 'implementer', phase: 'Build', model: 'sonnet', schema: IMPL_SCHEMA },
      ),
  })

  phase('Review')
  const liteClose = await agent(
    `Eres el cierre (Sonnet) de la corrida lite "${SLUG}" de Rideglory. NO hay PR; revisas el working tree y produces los artefactos para el humano.

${HARD_RULES}

CONTEXTO: ${WS}/PRD_NORMALIZED.md, ${WS}/handoffs/implementer.md, \`git diff --stat\` y \`git diff\`.

TU TRABAJO:
- Verificacion rapida: cada AC §5 cubierto, sin secretos/PII/URLs hardcodeadas, Clean Architecture ok.
- Escribe ${WS}/SUMMARY.md (## Objetivo, ## Que cambio, ## Archivos (git diff --stat), ## Pruebas, ## Mensaje de commit sugerido) y ${WS}/REVIEW_CHECKLIST.md (pasos manuales antes de commitear).
verdict='needs_changes' solo si hay un blocker real. Devuelve (verdict, blockers, summary).`,
    {
      label: 'lite-close',
      phase: 'Review',
      model: 'sonnet',
      schema: {
        type: 'object',
        additionalProperties: false,
        required: ['verdict', 'blockers', 'summary'],
        properties: {
          verdict: { type: 'string', enum: ['ready', 'needs_changes'] },
          blockers: { type: 'array', items: { type: 'string' } },
          summary: { type: 'string' },
        },
      },
    },
  )

  const qaAuto = await generateAndAutomateQa(WS, SLUG, MODE, null)

  return {
    slug: SLUG,
    workspace: WS,
    mode: MODE,
    implStatus: impl.result.status,
    auditScore: impl.verdict.score,
    verdict: liteClose.verdict,
    blockers: liteClose.blockers,
    qaAutomation: qaAuto ? { counts: qaAuto.counts, auditor: qaAuto.auditor, status: qaAuto.status } : null,
    artifacts: {
      summary: `${WS}/SUMMARY.md`,
      reviewChecklist: `${WS}/REVIEW_CHECKLIST.md`,
      qaChecklist: `${WS}/QA_CHECKLIST.md`,
    },
    note: `Nivel lite. Codigo modificado SIN commitear. Revisa con \`git diff\` y ${WS}/REVIEW_CHECKLIST.md. QA (automatizado): ${WS}/QA_CHECKLIST.md.`,
  }
}

// ===========================================================================
// NIVEL NORMAL / FULL — Architect -> Build -> Verify -> Review
// ===========================================================================
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
  criteria: `- El change map cubre TODOS los AC y nada fuera de alcance.
- Las decisiones (ui/backend/frontend/db/needsDesign) son correctas segun el codigo real.
- El orden respeta dependencias (contrato backend antes de frontend).
- Contratos rideglory-api, migraciones y env deltas explicitos.`,
  produce: (feedback) =>
    agent(
      `Eres el Architect de rg-exec ${SLUG} (nivel ${MODE}). Contrato: ${WS}/PRD_NORMALIZED.md.

${HARD_RULES}

CONTEXTO: ${WS}/PRD_NORMALIZED.md (completo), .claude/agents/architect.md, .claude/skills/architect-skill.md, docs/architecture/DIAGRAMS.md (solo lectura), y el codigo real en cada area del §4 (abre cada archivo, corrige §4 contra la realidad).

TU TRABAJO:
1. Decide los 5 flags segun el codigo.
2. Change map: tabla file | action | reason | risk (lista maestra; Build solo toca lo que aparezca aqui).
3. Orden de implementacion.
4. Contratos rideglory-api, migraciones (analysis/MIGRATION_PLAN.md si aplica), env deltas (analysis/ENV_DELTA.md si aplica). NO ejecutes migraciones ni toques .env real.
5. Escribe ${WS}/handoffs/architect.md (## Decisiones, ## Change map, ## Contratos, ## Datos/migraciones, ## Env, ## Riesgos, ## Orden, ## Superficie de regresion, ## Fuera de alcance) y slim architect-for-backend.md / architect-for-frontend.md (segun flags) / architect-for-qa.md.
${fixBlock(feedback)}
Devuelve el objeto estructurado.`,
      { label: 'architect', phase: 'Architect', model: 'sonnet', schema: ARCH_SCHEMA },
    ),
})

const d = archRun.result.decisions
const changeMapStr = archRun.result.changeMap.map((c) => `${c.action} ${c.file} (${c.risk}) — ${c.reason}`).join('\n')

// ---------------------------------------------------------------------------
// Phase: Build — Design || Backend, luego Frontend
// ---------------------------------------------------------------------------
phase('Build')

const designNeeded = d.needsDesign || d.uiChanges

await parallel([
  () =>
    designNeeded
      ? audited({
          label: 'design',
          phaseName: 'Build',
          auditReads: `${WS}/handoffs/design.md`,
          criteria: `- Cubre todos los estados UX (idle/loading/success/cada error) de cada pantalla tocada.
- Copy en espanol consistente; reusa componentes shared; design system (texto oscuro sobre primario, AppButton/AppTextField/AppSwitch).`,
          produce: (feedback) =>
            agent(
              `Eres el Design agent de rg-exec ${SLUG}.

${HARD_RULES}

CONTEXTO: ${WS}/PRD_NORMALIZED.md, ${WS}/handoffs/architect.md, .claude/agents/design.md, .claude/skills/design-skill.md, docs/design/ (solo lectura).
Change map:
${changeMapStr}

TU TRABAJO: pantallas (NEW|EXTEND|UPDATE), estados UX, componentes (reusa primero), copy, accesibilidad.
Pencil MCP OBLIGATORIO: usa get_editor_state(include_schema:true) → batch_design sobre rideglory.pen (el unico .pen del proyecto; NO crees un .pen nuevo ni separado). Si Pencil MCP falla o lanza error, DETENTE inmediatamente: escribe ${WS}/handoffs/design.md con una seccion ## BLOQUEADO explicando el error, devuelve status:'fail', y NO crees mockups HTML ni alternativas. NUNCA generes archivos .html como sustituto de diseno.
Si Pencil MCP funciona: exporta screenshots con export_nodes a ${WS}/analysis/design/ para referencia del Frontend agent.
Escribe ${WS}/handoffs/design.md (## Pantallas, ## Flujos UX, ## Componentes, ## Copy, ## Accesibilidad, ## Notas para Frontend).
${fixBlock(feedback)}
Devuelve {status:'pass', filesChanged, testResult:'n/a', notes}.`,
              { label: 'design', phase: 'Build', model: 'sonnet', schema: IMPL_SCHEMA },
            ),
        }).then((r) => r.result)
      : Promise.resolve(null),
  () =>
    d.backendChanges
      ? audited({
          label: 'backend',
          phaseName: 'Build',
          auditReads: `${WS}/handoffs/backend.md`,
          criteria: `- Implementa el contrato exacto; valida inputs; SQL parametrizado; sin secretos.
- Pruebas unit+integration por cada path nuevo y guardrail backend; suite en verde.
- Solo archivos del change map.`,
          produce: (feedback) =>
            agent(
              `Eres el Backend agent (rideglory-api) de rg-exec ${SLUG}. VAS A EDITAR CODIGO. NO commitees.

${HARD_RULES}

CONTEXTO: ${WS}/handoffs/architect-for-backend.md (primero), ${WS}/PRD_NORMALIZED.md (ambiguedad), MIGRATION_PLAN.md/ENV_DELTA.md si existen, .claude/agents/backend.md, .claude/skills/backend-skill.md. Backend en /Users/cami/Developer/Personal/rideglory-api.
Change map:
${changeMapStr}

TU TRABAJO:
1. Baseline: corre pruebas backend. Si rojas ANTES, status:'fail' y para.
2. Aplica cambios en orden. Migraciones solo local. Env vars solo en .env.example si ENV_DELTA lo dice.
3. Pruebas unit+integration; cubre guardrails backend. Verde.
4. Escribe ${WS}/handoffs/backend.md (## Baseline, ## Archivos cambiados, ## Pruebas nuevas, ## Resultado final, ## Verificacion manual, ## Notas Frontend/QA).
${fixBlock(feedback)}
Devuelve {status, filesChanged, testResult, notes}.`,
              { label: 'backend', phase: 'Build', model: 'sonnet', schema: IMPL_SCHEMA },
            ),
        }).then((r) => r.result)
      : Promise.resolve(null),
])

// ---------------------------------------------------------------------------
// UX Review Gate — despues de Design, antes de Frontend (normal/full si hay UI)
// ---------------------------------------------------------------------------
const UX_REVIEW_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['verdict', 'blockers', 'suggestions'],
  properties: {
    verdict: { type: 'string', enum: ['approved', 'approved_with_notes', 'blocked'] },
    blockers: { type: 'array', items: { type: 'string' } },
    suggestions: { type: 'array', items: { type: 'string' } },
  },
}

const uxReviewPrompt = (note) =>
  `Eres el UX Reviewer de rg-exec ${SLUG} (nivel ${MODE}).

${HARD_RULES}

CONTEXTO: ${WS}/PRD_NORMALIZED.md (§5 AC), ${WS}/handoffs/design.md (frames diseñados y estados UX), .claude/agents/ux-reviewer.md (tu playbook), .claude/skills/ux-reviewer-skill.md, .claude/skills/design-skill.md.

TU TRABAJO:
1. Lee ${WS}/handoffs/design.md — identifica los frames afectados (seccion Pantallas/Frames).
2. Pencil MCP: get_editor_state(include_schema:true) → batch_get de cada frame → get_screenshot (fondos oscuros: snapshot_layout si retorna blanco).
3. Evalua CADA frame contra los 5 frameworks del playbook: Nielsen 10 heuristicas, Laws of UX (Fitts/Hick/Miller/Jakob/Postel), WCAG 2.1 AA (contraste, touch targets), HIG/Material Design 3, reglas Rideglory-especificas.
4. Clasifica cada hallazgo: Bloqueante (impide implementacion funcional) / Sugerencia (mejora no bloqueante) / Conforme.
5. Escribe ${WS}/handoffs/ux-review.md:
   ## Frames revisados (tabla ID | Nombre | Veredicto)
   ## Hallazgos (tabla Frame | Heuristica/Ley | Severidad | Descripcion especifica | Fix requerido)
   ## Bloqueantes — deben resolverse antes de que Frontend empiece
   ## Sugerencias — backlog de UX (no bloquean)
   ## Veredicto final
${note ? `\nNOTA: ${note}` : ''}
Regla de veredicto: 'blocked' si ≥1 Bloqueante; 'approved_with_notes' si Sugerencias sin Bloqueantes; 'approved' si todo Conforme.
Devuelve (verdict, blockers[], suggestions[]).`

let uxVerdict = null
if (designNeeded) {
  uxVerdict = await agent(uxReviewPrompt(null), {
    label: 'ux-reviewer',
    phase: 'Build',
    model: 'sonnet',
    schema: UX_REVIEW_SCHEMA,
  })
  log(
    `[ux-review] ${uxVerdict.verdict.toUpperCase()} — ${uxVerdict.blockers.length} bloqueantes, ${uxVerdict.suggestions.length} sugerencias.`,
  )

  let uxRound = 0
  while (uxVerdict.verdict === 'blocked' && uxVerdict.blockers.length > 0 && uxRound < CFG.fixCap) {
    uxRound++
    log(`[ux-review] blocked (ronda ${uxRound}/${CFG.fixCap}) — corrigiendo diseno en Pencil...`)
    await agent(
      `Eres el Design agent de rg-exec ${SLUG} en MODO FIX por UX Review. Edita los frames en Pencil MCP sobre rideglory.pen (el unico .pen del proyecto). NO commitees. NUNCA crees mockups HTML.
${HARD_RULES}
Si Pencil MCP falla, DETENTE: escribe el error en ${WS}/handoffs/design.md y devuelve status:'fail'.
El UX Reviewer bloqueo el diseno. Corrige SOLO estos Bloqueantes en los frames de Pencil (usa batch_design) y actualiza la seccion de cambios en ${WS}/handoffs/design.md:
${uxVerdict.blockers.map((b) => '- ' + b).join('\n')}
Devuelve {status:'pass', filesChanged, testResult:'n/a', notes}.`,
      { label: 'design-fix:ux', phase: 'Build', model: 'sonnet', schema: IMPL_SCHEMA },
    )
    uxVerdict = await agent(uxReviewPrompt(`Re-evaluacion tras correcciones de diseno (ronda ${uxRound}).`), {
      label: 'ux-reviewer',
      phase: 'Build',
      model: 'sonnet',
      schema: UX_REVIEW_SCHEMA,
    })
    log(`[ux-review] re-evaluacion ${uxRound}: ${uxVerdict.verdict.toUpperCase()}`)
  }
}

if (d.frontendChanges) {
  await audited({
    label: 'frontend',
    phaseName: 'Build',
    auditReads: `${WS}/handoffs/frontend.md`,
    criteria: `- Todos los estados UI (idle/loading/success/cada error); copy/componentes segun Design.
- Cubits con ResultState (sin flags booleanos); Clean Architecture intacta.
- Strings en app_es.arb; widgets shared; un widget por archivo; pruebas widget/integracion que fallarian sin el cambio.
- Solo archivos del change map; sin URLs hardcodeadas.`,
    produce: (feedback) =>
      agent(
        `Eres el Frontend agent (Flutter lib/) de rg-exec ${SLUG}. VAS A EDITAR CODIGO. NO commitees.

${HARD_RULES}

CONTEXTO: ${WS}/handoffs/architect-for-frontend.md (primero), ${WS}/handoffs/design.md si existe, ${WS}/handoffs/backend.md si existe, .claude/agents/frontend.md, .claude/skills/frontend-skill.md.
Change map:
${changeMapStr}

TU TRABAJO:
1. Baseline: \`flutter test\`.
2. Aplica cambios en orden. Si tocas DTOs/DI/freezed: \`dart run build_runner build --delete-conflicting-outputs\`.
3. Estados UI completos; validacion cliente espeja server; strings en app_es.arb.
4. Pruebas widget/integracion por cada path nuevo. \`dart analyze\` y \`flutter test\` en verde.
5. Escribe ${WS}/handoffs/frontend.md (## Baseline, ## Archivos cambiados, ## Pruebas nuevas, ## Resultado final, ## Verificacion manual, ## Notas para QA).
${fixBlock(feedback)}
Devuelve {status, filesChanged, testResult, notes}.`,
        { label: 'frontend', phase: 'Build', model: 'sonnet', schema: IMPL_SCHEMA },
      ),
  })
}

// ---------------------------------------------------------------------------
// Phase: Verify — QA (+ adversarial solo en full) + auditoria de cobertura Opus
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
  `Eres el QA agent de rg-exec ${SLUG} (nivel ${MODE}).

${HARD_RULES}

CONTEXTO: ${WS}/handoffs/architect-for-qa.md, ${WS}/PRD_NORMALIZED.md (§5 AC, §6 guardrails), backend.md/frontend.md si existen, .claude/agents/qa.md, .claude/skills/qa-skill.md, y el diff (\`git diff --stat\`).

TU TRABAJO:
1. Catalogo: cada AC §5 -> test que lo cubre (existente|nuevo|gap).
2. Matriz de regresion: cada guardrail §6 -> mecanismo.
3. Corre la suite (backend + \`flutter test\`/\`dart analyze\`). Fallos pre-existentes = pre_existing; regresiones = BUGs (area+file).
4. Escribe ${WS}/handoffs/qa.md (## Catalogo, ## Matriz, ## Ejecucion, ## Bugs, ## Pruebas manuales, ## Sign-off).
${note ? `\nNOTA: ${note}` : ''}
Devuelve (signOff, bugs, testSummary).`

let qa = await agent(qaPrompt(null), { label: 'qa', phase: 'Verify', model: 'sonnet', schema: QA_SCHEMA })

let qaRound = 0
while (qa.signOff === 'blocked' && qa.bugs.length > 0 && qaRound < CFG.fixCap) {
  qaRound++
  log(`[qa] blocked (ronda ${qaRound}) — ${qa.bugs.length} bugs. ${CFG.adversarial ? 'Verificando adversarialmente y ' : ''}corrigiendo...`)

  let realBugs = qa.bugs
  if (CFG.adversarial) {
    const verified = await parallel(
      qa.bugs.map((b) => () =>
        agent(
          `Eres un verificador adversarial de rg-exec ${SLUG}. Intenta REFUTAR este bug leyendo el codigo real (\`git diff\` + el archivo):
area=${b.area} file=${b.file}
"${b.description}"
${HARD_RULES}
Si es real y reproducible, confirmed=true. Si QA se equivoco o ya esta cubierto, confirmed=false. Ante la duda, confirmed=true.
Devuelve {confirmed, reason}.`,
          {
            label: `verify:${b.area}`,
            phase: 'Verify',
            model: 'sonnet',
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
    realBugs = verified.filter(Boolean).filter((v) => v.confirmed).map((v) => v.bug)
    if (realBugs.length === 0) {
      log('[qa] bugs refutados por verificacion adversarial. Re-corriendo QA.')
      qa = await agent(qaPrompt('Los bugs previos fueron refutados; reevalua honestamente.'), { label: 'qa', phase: 'Verify', model: 'sonnet', schema: QA_SCHEMA })
      continue
    }
  }

  const areas = [...new Set(realBugs.map((b) => b.area))]
  for (const area of areas) {
    const list = realBugs.filter((b) => b.area === area).map((b) => `- ${b.file}: ${b.description}`).join('\n')
    await agent(
      `Eres el ${area === 'backend' ? 'Backend (rideglory-api)' : 'Frontend (Flutter lib/)'} agent de rg-exec ${SLUG} en MODO FIX. VAS A EDITAR CODIGO. NO commitees.
${HARD_RULES}
Corrige SOLO estos bugs (no re-scaffold), re-corre pruebas, actualiza ${WS}/handoffs/${area}.md:
${list}
Devuelve {status, filesChanged, testResult, notes}.`,
      { label: `${area}-fix`, phase: 'Verify', model: 'sonnet', schema: IMPL_SCHEMA },
    )
  }
  qa = await agent(qaPrompt('Re-evaluacion tras correcciones.'), { label: 'qa', phase: 'Verify', model: 'sonnet', schema: QA_SCHEMA })
}

// Auditoria Opus de cobertura (cada AC con un test que falle sin el cambio).
const qaAudit = await agent(
  `Eres el AUDITOR Opus de cobertura de pruebas de rg-exec ${SLUG}.
${HARD_RULES}
Lee ${WS}/PRD_NORMALIZED.md (§5 AC, §6), ${WS}/handoffs/qa.md y el diff de tests (\`git diff\`). Para CADA AC verifica que exista una prueba que fallaria sin el cambio (no aserciones triviales).
Si falta cobertura, requestedChanges nombra el AC y el test faltante.
Devuelve (approved, score, findings, requestedChanges).`,
  { label: 'qa:audit', phase: 'Verify', model: 'opus', schema: AUDIT_SCHEMA },
)
if (!qaAudit.approved && qaAudit.requestedChanges.length > 0) {
  log(`[audit:opus] cobertura insuficiente — pidiendo tests adicionales.`)
  qa = await agent(
    qaPrompt(`El auditor Opus exige agregar estas pruebas (agregalas y re-corre):\n${qaAudit.requestedChanges.map((c) => '- ' + c).join('\n')}`),
    { label: 'qa', phase: 'Verify', model: 'sonnet', schema: QA_SCHEMA },
  )
}

// ---------------------------------------------------------------------------
// Phase: Review — Tech Lead + cierre, con bucle de correccion (fixCap)
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
  `Eres el Tech Lead de rg-exec ${SLUG} (nivel ${MODE}). NO hay PR: revisas el working tree via \`git diff\` y produces los artefactos para el humano.

${HARD_RULES}

CONTEXTO: ${WS}/PRD_NORMALIZED.md, ${WS}/handoffs/architect.md, design.md/backend.md/frontend.md/qa.md segun existan, .claude/agents/tech_lead.md, .claude/skills/tech_lead-skill.md, y \`git diff\` + \`git diff --stat\` (lee cada archivo cambiado).

REVISION:
- Cada hunk contra el change map; marca archivos fuera del mapa.
- Seguridad: sin secretos/SQL concatenado/XSS/PII en logs; auth/CORS.
- Arquitectura: Clean Architecture, env vars (no URLs hardcodeadas), shape API segun contrato, ERD vs migracion, rideglory-coding-standards.
- Tests: cada AC con un test que falla sin el cambio.

CIERRE: escribe ${WS}/SUMMARY.md (## Objetivo, ## Que cambio por area, ## Archivos, ## Pruebas, ## Riesgos/watchlist, ## Mensaje de commit sugerido), ${WS}/REVIEW_CHECKLIST.md (pasos manuales antes de commitear), ${WS}/handoffs/tech_lead.md (## Veredicto, ## Hallazgos, ## Seguridad, ## Arquitectura, ## Tests, ## Pruebas manuales).
${note ? `\nNOTA: ${note}` : ''}
verdict='needs_changes' solo si hay blockers reales (area+description). Devuelve (verdict, blockers, summary).`

let tl = await agent(techLeadPrompt(null), { label: 'tech-lead', phase: 'Review', model: 'sonnet', schema: VERDICT_SCHEMA })

let tlRound = 0
while (tl.verdict === 'needs_changes' && tl.blockers.length > 0 && tlRound < CFG.fixCap) {
  tlRound++
  log(`[tech-lead] needs_changes (ronda ${tlRound}) — ${tl.blockers.length} blockers. Corrigiendo...`)
  const areas = [...new Set(tl.blockers.map((b) => b.area))]
  for (const area of areas) {
    const list = tl.blockers.filter((b) => b.area === area).map((b) => `- ${b.description}`).join('\n')
    await agent(
      `Eres el ${area === 'backend' ? 'Backend (rideglory-api)' : 'Frontend (Flutter lib/)'} agent de rg-exec ${SLUG} en MODO FIX (Tech Lead). VAS A EDITAR CODIGO. NO commitees.
${HARD_RULES}
Corrige SOLO estos hallazgos, re-corre pruebas, actualiza ${WS}/handoffs/${area}.md:
${list}
Devuelve {status, filesChanged, testResult, notes}.`,
      { label: `${area}-fix`, phase: 'Review', model: 'sonnet', schema: IMPL_SCHEMA },
    )
  }
  tl = await agent(techLeadPrompt('Re-revision tras correcciones.'), { label: 'tech-lead', phase: 'Review', model: 'sonnet', schema: VERDICT_SCHEMA })
}

const qaAuto = await generateAndAutomateQa(WS, SLUG, MODE, null)

return {
  slug: SLUG,
  workspace: WS,
  mode: MODE,
  decisions: d,
  uxReview: uxVerdict
    ? { verdict: uxVerdict.verdict, blockers: uxVerdict.blockers, suggestions: uxVerdict.suggestions }
    : null,
  qaSignOff: qa.signOff,
  qaAutomation: qaAuto ? { counts: qaAuto.counts, auditor: qaAuto.auditor, status: qaAuto.status } : null,
  techLeadVerdict: tl.verdict,
  remainingBlockers: tl.blockers,
  artifacts: {
    summary: `${WS}/SUMMARY.md`,
    reviewChecklist: `${WS}/REVIEW_CHECKLIST.md`,
    techLead: `${WS}/handoffs/tech_lead.md`,
    uxReview: uxVerdict ? `${WS}/handoffs/ux-review.md` : null,
    qaChecklist: `${WS}/QA_CHECKLIST.md`,
  },
  note: `Nivel ${MODE}. Codigo modificado SIN commitear. Revisa con \`git diff\` y ${WS}/REVIEW_CHECKLIST.md. QA (automatizado con qa-auto): ${WS}/QA_CHECKLIST.md.`,
}
