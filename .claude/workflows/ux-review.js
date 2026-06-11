export const meta = {
  name: 'ux-review',
  description:
    'Audita pantallas de Pencil contra heurísticas UX (Nielsen, Laws of UX, WCAG 2.1 AA, HIG/Material, reglas Rideglory). Standalone — no toca codigo. Args: string (nombre del feature) o {feature, frameIds?, featureDoc?}. Reporte en docs/exec-runs/ux-review-<slug>/.',
  phases: [{ title: 'Review', detail: 'Auditoría UX en Pencil — hallazgos Bloqueante/Sugerencia/Conforme + reporte' }],
}

// ---------------------------------------------------------------------------
// Parsear args
// ---------------------------------------------------------------------------
const input = typeof args === 'string' ? { feature: args } : (typeof args === 'object' && args !== null ? args : {})
if (!input.feature) {
  throw new Error(
    'ux-review requiere args = "nombre del feature" o {feature: "...", frameIds?: ["id1","id2"], featureDoc?: "docs/features/x.md"}.',
  )
}

const FEATURE = String(input.feature).trim()
const FRAME_IDS = Array.isArray(input.frameIds) ? input.frameIds : []
const FEATURE_DOC = typeof input.featureDoc === 'string' ? input.featureDoc : null

const slug = FEATURE.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 40)
const SLUG = `ux-review-${slug}`
const WS = `docs/exec-runs/${SLUG}`

const HARD_RULES = `
HARD RULES — no las violes:
1. NUNCA ejecutes: git add / commit / push / merge / rebase / restore / reset, ni gh pr create / merge / review.
2. NUNCA modifiques: archivos de la app (lib/, rideglory-api/), .claude/agents/**, .claude/skills/**, .claude/workflows/**, rideglory.pen.
3. Escribe SOLO bajo ${WS}/.
4. Timestamps con Bash \`date -u +%Y-%m-%dT%H:%M:%SZ\`.
`

log(`UX Review standalone: "${FEATURE}" — workspace ${WS}/`)

// ---------------------------------------------------------------------------
// Phase: Review
// ---------------------------------------------------------------------------
phase('Review')

const UX_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['verdict', 'framesReviewed', 'blockers', 'suggestions', 'summary'],
  properties: {
    verdict: { type: 'string', enum: ['approved', 'approved_with_notes', 'blocked'] },
    framesReviewed: { type: 'array', items: { type: 'string' } },
    blockers: { type: 'array', items: { type: 'string' } },
    suggestions: { type: 'array', items: { type: 'string' } },
    summary: { type: 'string' },
  },
}

const result = await agent(
  `Eres el UX Reviewer standalone de Rideglory. Auditas el feature: "${FEATURE}".

${HARD_RULES}

CONTEXTO:
- .claude/agents/ux-reviewer.md — tu playbook completo (frameworks, reglas, protocolo).
- .claude/skills/ux-reviewer-skill.md — contexto de proyecto, design tokens, anti-patrones conocidos.
- .claude/skills/design-skill.md — inventario de frames Pencil y design system.
${FEATURE_DOC ? `- ${FEATURE_DOC} — doc del feature (leer para entender el alcance).` : ''}
${FRAME_IDS.length > 0 ? `- Frames explícitos a revisar: ${FRAME_IDS.join(', ')} (+ relacionados que encuentres).` : '- Identificar los frames relevantes desde el inventario de Pencil.'}

TU TRABAJO:
1. Crea el workspace: mkdir -p ${WS}/handoffs
2. Pencil MCP: get_editor_state(include_schema: true) → inventariar todos los frames.
3. Identificar los frames relevantes para "${FEATURE}"${FRAME_IDS.length > 0 ? ' (usa los IDs provistos de base)' : ''}.
4. batch_get → leer contenido de cada frame afectado. get_screenshot para captura visual (fondos oscuros: snapshot_layout si retorna blanco).
5. Evaluar CADA frame contra los 5 frameworks del playbook (Nielsen, Laws of UX, WCAG 2.1 AA, HIG/Material, Gestalt) + reglas Rideglory-específicas.
6. Por cada hallazgo: Frame ID | Heurística/Ley | Severidad (Bloqueante/Sugerencia/Conforme) | Descripción específica | Fix requerido.
7. Escribe ${WS}/handoffs/ux-review.md (## Frames revisados [tabla], ## Hallazgos por frame [tabla completa], ## Bloqueantes, ## Sugerencias, ## Resumen ejecutivo, ## Veredicto final).
8. Escribe ${WS}/REPORT.md — versión legible para el humano: encabezado con fecha+veredicto, secciones claras, hallazgos priorizados.

Regla de veredicto: 'blocked' si ≥1 Bloqueante; 'approved_with_notes' si Sugerencias sin Bloqueantes; 'approved' si todo Conforme.
Devuelve (verdict, framesReviewed[], blockers[], suggestions[], summary).`,
  { label: 'ux-reviewer', phase: 'Review', model: 'sonnet', schema: UX_SCHEMA },
)

log(
  `[ux-review] ${result.verdict.toUpperCase()} — ${result.framesReviewed.length} frames revisados, ${result.blockers.length} bloqueantes, ${result.suggestions.length} sugerencias.`,
)
if (result.blockers.length > 0) {
  log(`[ux-review] Bloqueantes: ${result.blockers.slice(0, 3).join(' | ')}${result.blockers.length > 3 ? ` (+${result.blockers.length - 3} más)` : ''}`)
}

return {
  feature: FEATURE,
  slug: SLUG,
  workspace: WS,
  verdict: result.verdict,
  framesReviewed: result.framesReviewed,
  blockers: result.blockers,
  suggestions: result.suggestions,
  summary: result.summary,
  artifacts: {
    report: `${WS}/REPORT.md`,
    reviewHandoff: `${WS}/handoffs/ux-review.md`,
  },
  note: `Reporte disponible en ${WS}/REPORT.md — sin cambios en código ni diseño. El Design agent resuelve los Bloqueantes.`,
}
