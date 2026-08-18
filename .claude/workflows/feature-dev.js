export const meta = {
  name: 'feature-dev',
  description:
    'Entrega una feature COMPLETA de Rideglory en una sola corrida: triage automatico del tamano (s/m/l), gate de acceso real a Pencil antes de tocar UI, gate de seguridad del rider sobre el PLAN antes de escribir codigo, implementacion Clean Architecture con el equipo de agentes (Supabase + Flutter), suite de tests completa (unit/widget/golden/Patrol via qa-automator), review escalado al riesgo con fix loop acotado, verificacion de fidelidad visual contra rideglory.pen si hay UI, y UN solo artefacto de cierre (docs/dev-runs/<slug>.md) que tambien deja al dia docs/fidelidad-visual-tracking.md. El contexto viaja en memoria entre agentes (structured output), no en archivos. Codigo queda SIN commitear. Args: "<descripcion o ruta a una nota>" o {source, size?: "auto"|"s"|"m"|"l"}.',
  whenToUse:
    'Cuando el usuario pida implementar una feature o mejora de Rideglory de punta a punta. Para solo scaffold usa feature-scaffold; para solo revisar usa feature-review; para descubrimiento usa discovery.',
  phases: [
    { title: 'Plan', detail: 'architect: triage de tamano, AC, change map y flags (esquema, edge functions, UI, seguridad, ubicacion)' },
    { title: 'Gate Pencil', detail: 'Si hay UI: ui-ux-reviewer confirma acceso REAL al .pen. Sin acceso, se aborta' },
    { title: 'Gate Safety', detail: 'Si toca SOS/ubicacion: safety-compliance-reviewer audita el PLAN y puede abortar antes de escribir codigo' },
    { title: 'Build', detail: 'sql-migration-helper → supabase-backend-dev → flutter-dev (domain+data) → flutter-dev (presentation)' },
    { title: 'Test', detail: 'qa-automator: analyze + suite + goldens si hay UI + Patrol, con fix loop contra flutter-dev' },
    { title: 'Review', detail: 'Escalado por tamano: rideglory-code-reviewer (s) / + ui-convention + safety (m) / feature-review adversarial (l)' },
    { title: 'Fidelity', detail: 'Si hay UI: pencil-fidelity-reviewer compara goldens vs nodeId, con fix loop sobre CRITICO/IMPORTANTE' },
    { title: 'Close', detail: 'Unico artefacto: docs/dev-runs/<slug>.md + actualiza docs/fidelidad-visual-tracking.md' },
  ],
}

// ---------------------------------------------------------------------------
// Args
// ---------------------------------------------------------------------------
const input = typeof args === 'object' && args !== null ? args : { source: args }
const SOURCE = typeof input.source === 'string' && input.source.trim() ? input.source.trim() : null
if (!SOURCE) {
  throw new Error(
    'feature-dev requiere args = "<descripcion de la feature o ruta a una nota>" o {source: "...", size?: "auto"|"s"|"m"|"l"}.',
  )
}
const SIZE_OVERRIDE = ['s', 'm', 'l'].includes(input.size) ? input.size : null

const HARD_RULES = `
HARD RULES — no las violes:
1. NUNCA ejecutes git add/commit/push/merge/rebase/restore/reset ni gh pr *. El arbol queda SUCIO a proposito; el humano commitea.
2. Solo puedes editar: lib/**, test/**, integration_test/**, supabase/**, y pubspec.yaml si el plan lo exige. NUNCA toques .claude/**, CLAUDE.md, docs/** (excepto el UNICO archivo docs/dev-runs/<slug>.md que escribe el cierre), ni analysis_options.yaml.
3. NO escribas archivos .md, reportes ni notas intermedias: toda tu salida va en el objeto estructurado que devuelves.
4. NUNCA apuntes a la base de produccion. Supabase se corre en local (supabase start / supabase db reset); prohibido supabase db push, supabase link o cualquier comando contra el proyecto remoto. Patrol corre contra el flavor dev.
5. CLAUDE.md en la raiz es el contrato (ResultState, Either, un widget por archivo, cero strings hardcodeados, RLS en la base, seguridad del rider). Tu playbook de rol esta en .claude/agents/.
6. rideglory.pen esta encriptado: se lee SOLO con las herramientas MCP de Pencil, nunca con Read ni Grep. Nunca hardcodees un hex: usa la variable del .pen.
`

// ---------------------------------------------------------------------------
// Schemas
// ---------------------------------------------------------------------------
const PLAN_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: [
    'slug',
    'featureDir',
    'size',
    'goal',
    'acceptanceCriteria',
    'needsDbSchema',
    'needsEdgeFunctions',
    'needsUi',
    'touchesSafety',
    'touchesLocation',
    'changeMap',
    'risks',
  ],
  properties: {
    slug: { type: 'string', description: 'kebab-case corto para la corrida' },
    featureDir: { type: 'string', description: 'carpeta principal bajo lib/features/ (ej "events", "vehicles", "tracking")' },
    size: { type: 'string', enum: ['s', 'm', 'l'] },
    goal: { type: 'string' },
    acceptanceCriteria: { type: 'array', items: { type: 'string' } },
    needsDbSchema: { type: 'boolean', description: 'toca tablas, columnas, indices, politicas RLS o vistas en Postgres' },
    needsEdgeFunctions: { type: 'boolean', description: 'toca Edge Functions, pg_cron, Realtime, Storage o push FCM' },
    needsUi: { type: 'boolean', description: 'toca la capa presentation/ de una pantalla disenada' },
    touchesSafety: { type: 'boolean', description: 'toca SOS, alertas de emergencia, contactos de emergencia o cierre de una emergencia' },
    touchesLocation: { type: 'boolean', description: 'toca permisos de ubicacion, tracking en vivo o background, o datos sensibles del rider' },
    changeMap: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['file', 'action', 'reason'],
        properties: {
          file: { type: 'string' },
          action: { type: 'string', enum: ['create', 'modify', 'delete'] },
          reason: { type: 'string' },
        },
      },
    },
    risks: { type: 'array', items: { type: 'string' } },
  },
}

const IMPL_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['status', 'filesChanged', 'testResult', 'notes'],
  properties: {
    status: { type: 'string', enum: ['pass', 'fail'] },
    filesChanged: { type: 'array', items: { type: 'string' } },
    testResult: { type: 'string', description: 'comando + conteo pass/fail (o "n/a")' },
    notes: { type: 'string' },
  },
}

const QA_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['analyzeClean', 'testsGreen', 'newFailures', 'filesWritten', 'acCoverage', 'e2e', 'manualChecks'],
  properties: {
    analyzeClean: { type: 'boolean' },
    testsGreen: { type: 'boolean', description: 'true si la suite pasa (ignorando fallos preexistentes documentados en notes)' },
    newFailures: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['file', 'description'],
        properties: { file: { type: 'string' }, description: { type: 'string' } },
      },
    },
    filesWritten: { type: 'array', items: { type: 'string' } },
    acCoverage: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['ac', 'status', 'test'],
        properties: {
          ac: { type: 'string' },
          status: { type: 'string', enum: ['covered', 'gap'] },
          test: { type: 'string', description: 'archivo::test que lo cubre, o razon del gap' },
        },
      },
    },
    e2e: { type: 'string', enum: ['pass', 'fail', 'skip'] },
    manualChecks: { type: 'array', items: { type: 'string' }, description: 'lo que solo un humano puede verificar' },
    notes: { type: 'string' },
  },
}

const PENCIL_ACCESS_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['accessible', 'reason'],
  properties: {
    accessible: {
      type: 'boolean',
      description:
        'true SOLO si pudiste leer el .pen real (get_app_state + ver los frames de la pantalla relevante), no solo el spec .md',
    },
    reason: { type: 'string' },
  },
}

const SAFETY_GATE_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['verdict', 'reason', 'blockers', 'requirements'],
  properties: {
    verdict: { type: 'string', enum: ['ok', 'blocked'] },
    reason: { type: 'string' },
    blockers: {
      type: 'array',
      items: { type: 'string' },
      description: 'lo que hace inviable el plan tal como esta escrito (vacio si verdict=ok)',
    },
    requirements: {
      type: 'array',
      items: { type: 'string' },
      description: 'condiciones que la implementacion DEBE cumplir; se le pasan literalmente a flutter-dev',
    },
  },
}

const FIDELITY_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['applicable', 'accessible', 'reason', 'findings', 'gapsMdWithoutGolden', 'gapsGoldenWithoutMd'],
  properties: {
    applicable: {
      type: 'boolean',
      description: 'false si la feature no tiene design-system/rideglory/pages/<pantalla>.md todavia (sin frame que auditar) — no es un fallo, es N/A',
    },
    accessible: {
      type: 'boolean',
      description: 'true solo si pudiste leer el .pen real (get_app_state) y comparar goldens reales contra nodeId; false si el MCP de Pencil no respondio',
    },
    reason: { type: 'string' },
    findings: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['severity', 'golden', 'nodeId', 'description'],
        properties: {
          severity: { type: 'string', enum: ['CRITICO', 'IMPORTANTE', 'MENOR'] },
          golden: { type: 'string', description: 'path del .png afectado' },
          nodeId: { type: 'string' },
          description: { type: 'string' },
        },
      },
    },
    gapsMdWithoutGolden: { type: 'array', items: { type: 'string' }, description: 'filas del .md sin golden generado' },
    gapsGoldenWithoutMd: { type: 'array', items: { type: 'string' }, description: 'goldens sin fila correspondiente en el .md' },
  },
}

const REVIEW_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['approved', 'blockers', 'observations'],
  properties: {
    approved: { type: 'boolean' },
    blockers: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['file', 'description'],
        properties: { file: { type: 'string' }, description: { type: 'string' } },
      },
    },
    observations: { type: 'array', items: { type: 'string' }, description: 'mejoras no bloqueantes, quedan en el resumen' },
  },
}

// ---------------------------------------------------------------------------
// Phase: Plan — un solo agente architect, salida en memoria
// ---------------------------------------------------------------------------
phase('Plan')

const plan = await agent(
  `Haz el triage de esta peticion de feature para Rideglory y devuelve el plan estructurado (NO escribas archivos).

FUENTE: ${SOURCE}
- Si es una ruta de archivo existente, leela completa; si no, trata el texto como la peticion.
${SIZE_OVERRIDE ? `- El usuario FORZO el tamano "${SIZE_OVERRIDE}": usalo, pero valida el resto del plan normalmente.` : ''}

${HARD_RULES}

Sigue tu playbook (.claude/agents/architect.md): lee CLAUDE.md, las migraciones bajo supabase/migrations/ y el codigo real de las features afectadas. El repo esta en refactor total: puede haber carpetas vacias o con solo .gitkeep (lienzo en blanco) — eso no es un error.

Devuelve slug, featureDir, size (rubrica del playbook), goal, acceptanceCriteria (numerados, testeables), changeMap (rutas reales o nuevas segun la convencion feature-first), risks, y las cinco banderas:
- needsDbSchema: la feature crea/altera tablas, columnas, indices, vistas o politicas RLS.
- needsEdgeFunctions: la feature necesita Edge Functions, pg_cron, canales de Realtime, politicas de Storage o push FCM.
- needsUi: la feature toca presentation/ de alguna pantalla.
- touchesSafety: la feature toca el SOS, alertas de emergencia, contactos de emergencia o el cierre de una emergencia.
- touchesLocation: la feature toca permisos de ubicacion, tracking en vivo o en background, o datos sensibles del rider (medicos, placa, fotos de documentos).
Se conservador con touchesSafety/touchesLocation: ante la duda, marca true — un falso positivo cuesta una revision, un falso negativo cuesta el SOS.

Si la peticion viola una regla de CLAUDE.md (seguridad del rider, requisitos legales, arquitectura), ponlo como primer risk con prefijo "BLOQUEANTE:".`,
  { label: 'architect', phase: 'Plan', schema: PLAN_SCHEMA, agentType: 'architect', effort: 'medium' },
)

const SIZE = SIZE_OVERRIDE || plan.size
const CFG = {
  s: { fixRounds: 1, review: 'quick', e2e: false },
  m: { fixRounds: 1, review: 'combined', e2e: true },
  l: { fixRounds: 2, review: 'deep', e2e: true },
}[SIZE]
const SLUG = plan.slug
const SUMMARY_FILE = `docs/dev-runs/${SLUG}.md`

const hardBlocker = plan.risks.find((r) => r.startsWith('BLOQUEANTE:'))
if (hardBlocker) {
  return {
    slug: SLUG,
    aborted: true,
    reason: hardBlocker,
    plan,
    note: 'El architect detecto que la peticion viola una regla de CLAUDE.md. No se implemento nada.',
  }
}

const changeMapStr = plan.changeMap.map((c) => `${c.action} ${c.file} — ${c.reason}`).join('\n')
const acStr = plan.acceptanceCriteria.map((a, i) => `${i + 1}. ${a}`).join('\n')
log(
  `[plan] "${SLUG}" tamano=${SIZE.toUpperCase()} — ${plan.changeMap.length} archivos, esquema=${plan.needsDbSchema}, edge=${plan.needsEdgeFunctions}, ui=${plan.needsUi}, safety=${plan.touchesSafety}, ubicacion=${plan.touchesLocation}`,
)

// ---------------------------------------------------------------------------
// Gate: acceso a Pencil — obligatorio antes de implementar UI disenada.
// El .pen esta encriptado y solo se lee con MCP de Pencil; si el MCP esta caido,
// flutter-dev solo puede trabajar contra el spec .md — y eso ya produjo deriva
// real en este proyecto (un agente de diseno sin acceso invento los mockups en
// HTML). Un agente CON acceso (ui-ux-reviewer) confirma que el .pen abre antes
// de que arranque cualquier implementacion de presentation/. Sin eso, se detiene.
// ---------------------------------------------------------------------------
if (plan.needsUi) {
  phase('Gate Pencil')
  const pencilCheck = await agent(
    `Antes de que flutter-dev implemente la capa presentation/ de la corrida "${SLUG}" (${plan.goal}), verifica que tienes acceso FUNCIONAL y REAL a rideglory.pen — no basta con que exista el spec .md.

Pasos: llama a mcp__pencil__get_app_state (include_schema:true, include_canvas_design:true, include_scripts_and_shaders:false), y luego localiza y mira (mcp__pencil__get_screenshot o Get dentro de mcp__pencil__execute) la o las pantallas relevantes a este objetivo dentro del canvas. Revisa tambien si existe el override design-system/rideglory/pages/<pantalla>.md correspondiente y el MASTER.md.

Recuerda: rideglory.pen esta encriptado, NUNCA intentes leerlo con Read o Grep.

Devuelve accessible=true SOLO si lograste ver el diseno real (frames del canvas), no solo leer el .md. Si el MCP de Pencil no responde, el archivo no carga, o no encuentras las pantallas de esta feature en el canvas, accessible=false y explica la causa exacta en reason.`,
    { label: 'pencil-access-check', phase: 'Gate Pencil', schema: PENCIL_ACCESS_SCHEMA, agentType: 'ui-ux-reviewer', effort: 'low' },
  )
  if (!pencilCheck || !pencilCheck.accessible) {
    return {
      slug: SLUG,
      aborted: true,
      reason: `BLOQUEANTE: sin acceso real a Pencil (rideglory.pen) antes de implementar UI — ${pencilCheck ? pencilCheck.reason : 'el agente de verificacion no respondio.'}`,
      plan,
      note: 'Regla del proyecto (CLAUDE.md): el .md describe el diseno, el .pen ES el diseno. Si Pencil no abre, el desarrollo de esa UI se detiene — no se implementa a ciegas. Reintenta esta corrida cuando Pencil este accesible.',
    }
  }
  log(`[gate-pencil] acceso confirmado — ${pencilCheck.reason}`)
}

// ---------------------------------------------------------------------------
// Gate: seguridad del rider — auditar el PLAN, no el codigo.
//
// Por que esta fase existe aqui y no solo en Review: cuando lo que esta en juego
// es el SOS, un hallazgo en Review llega cuando el diseno equivocado ya esta
// implementado, testeado y con goldens generados — corregirlo significa rehacer
// capas enteras, y la presion de "ya casi esta" empuja a degradar el hallazgo a
// observacion. Abortar en Plan cuesta una llamada de agente. Ademas hay defectos
// que solo se ven en el plan: elegir un transporte que descarta la alerta si esta
// caido (el bug real que ya estuvo en produccion en este proyecto) es una decision
// de arquitectura, no una linea de codigo que un reviewer pueda senalar despues.
// Review sigue corriendo con este mismo agente; este gate no lo reemplaza, lo
// adelanta. Su salida (requirements) viaja al prompt de Build.
// ---------------------------------------------------------------------------
let safetyGate = null
if (plan.touchesSafety || plan.touchesLocation) {
  phase('Gate Safety')
  safetyGate = await agent(
    `Audita el PLAN (todavia NO existe codigo) de la corrida "${SLUG}" de Rideglory contra la seccion "Seguridad del rider" y "Requisitos legales" de CLAUDE.md. Sigue tu playbook (.claude/agents/safety-compliance-reviewer.md).

OBJETIVO: ${plan.goal}
BANDERAS: toca SOS/emergencia=${plan.touchesSafety}, toca ubicacion/tracking/datos sensibles=${plan.touchesLocation}
CRITERIOS DE ACEPTACION:
${acStr}
CHANGE MAP PROPUESTO:
${changeMapStr}
RIESGOS QUE YA IDENTIFICO EL ARCHITECT:
${plan.risks.join('\n') || '(ninguno)'}

Tu trabajo NO es revisar codigo (no hay), es responder si este plan, implementado tal como esta escrito, puede producir una violacion de seguridad del rider. Revisa especificamente:
- SOS: ¿se persiste localmente ANTES de intentar la red? ¿sobrevive a que maten la app? ¿toda ruta de fallo termina en alerta entregada o fallback ofrecido, nunca en un return mudo? ¿la UI espera confirmacion del servidor antes de decir "enviado"? ¿los datos del contacto de emergencia se cachean al EMPEZAR la rodada, no durante la emergencia? ¿el cierre lo hace una persona y no una desconexion?
- Ubicacion: ¿hay consentimiento explicito con aviso propio antes del dialogo del sistema? ¿indicador visible mientras esta activa y parada siempre accesible? ¿el tracking en background termina de verdad al terminar la rodada?
- Datos: ¿el enmascarado ocurre en la base (RLS/vistas) y no filtrando en Dart? ¿los datos medicos tienen consentimiento expreso (Ley 1581)? ¿las fotos de documentos quedan privadas por defecto?
- Estados: ¿sin permiso, sin GPS y sin conexion estan disenados, con mensaje y salida?

Devuelve verdict='blocked' SOLO si el plan tal como esta escrito lleva inevitablemente a una violacion — no por omisiones que la implementacion puede resolver bien. Esas van en requirements: condiciones concretas y verificables que la implementacion debe cumplir; se le pasan literalmente a flutter-dev y al backend, asi que redactalas como instrucciones, no como preguntas.`,
    { label: 'safety-plan-gate', phase: 'Gate Safety', schema: SAFETY_GATE_SCHEMA, agentType: 'safety-compliance-reviewer', effort: 'medium' },
  )
  if (!safetyGate || safetyGate.verdict === 'blocked') {
    return {
      slug: SLUG,
      aborted: true,
      reason: `BLOQUEANTE: el plan no pasa el gate de seguridad del rider — ${safetyGate ? safetyGate.reason : 'el agente de verificacion no respondio.'}`,
      plan,
      safetyBlockers: safetyGate ? safetyGate.blockers : [],
      note: 'Se aborto en Plan a proposito: cuando lo que esta en juego es el SOS o la ubicacion, corregir el diseno antes de escribir codigo cuesta una llamada de agente; corregirlo en Review cuesta rehacer capas enteras. Ajusta el plan con estos blockers y vuelve a lanzar.',
    }
  }
  log(`[gate-safety] OK — ${safetyGate.requirements.length} requisitos obligatorios para la implementacion`)
}

const safetyRequirementsStr =
  safetyGate && safetyGate.requirements.length
    ? `\nREQUISITOS DE SEGURIDAD DEL RIDER (obligatorios, salidos del gate de seguridad sobre el plan — incumplir uno invalida la corrida):\n${safetyGate.requirements.map((r) => `- ${r}`).join('\n')}\n`
    : ''

// ---------------------------------------------------------------------------
// Phase: Build — por etapas segun flags (secuencial: las capas dependen entre si)
// ---------------------------------------------------------------------------
phase('Build')

const allFilesChanged = []
const buildNotes = []

async function build(label, agentType, mission) {
  const r = await agent(
    `Estas implementando la corrida "${SLUG}" de Rideglory. VAS A EDITAR CODIGO. Sigue tu playbook (.claude/agents/${agentType}.md).

${HARD_RULES}
${safetyRequirementsStr}
OBJETIVO: ${plan.goal}
CRITERIOS DE ACEPTACION:
${acStr}
CHANGE MAP (solo toca lo que aparezca aqui; si descubres que falta un archivo indispensable, agregalo y justificalo en notes):
${changeMapStr}
${allFilesChanged.length ? `\nYA IMPLEMENTADO por etapas anteriores (no lo rehagas, construye encima):\n${allFilesChanged.join('\n')}` : ''}

TU MISION EN ESTA ETAPA:
${mission}

Cierra con dart analyze limpio sobre lo tocado (y flutter test si escribiste Dart). Devuelve {status, filesChanged, testResult, notes}.`,
    { label, phase: 'Build', schema: IMPL_SCHEMA, agentType },
  )
  if (r) {
    allFilesChanged.push(...r.filesChanged)
    buildNotes.push(`[${label}] ${r.notes}`)
    log(`[build:${label}] ${r.status} — ${r.filesChanged.length} archivos (${r.testResult})`)
  }
  return r
}

if (SIZE === 's') {
  await build(
    'implementer',
    'flutter-dev',
    `Implementa TODO el cambio en una pasada (es tamano S: mecanico/bajo riesgo). Domain, data y presentation juntos, mas las keys nuevas en lib/l10n/app_es.arb con flutter gen-l10n.${plan.needsDbSchema ? ' Incluye la migracion SQL en supabase/migrations/ con su politica RLS y prueba contra Supabase local.' : ''}${plan.needsUi ? ' Antes de tocar presentation/, lee el frame real en rideglory.pen con las herramientas MCP de Pencil — nunca a partir del .md solo.' : ''}`,
  )
} else {
  if (plan.needsDbSchema) {
    await build(
      'schema',
      'sql-migration-helper',
      'SOLO el cambio de esquema: una migracion SQL versionada en supabase/migrations/ con tablas/columnas/indices, PKs UUID, timestamps, y las politicas RLS que correspondan (el acceso vive en la base, nunca en el cliente; el enmascarado de datos sensibles se hace con RLS y vistas). Toda migracion destructiva lleva checklist de rollback. Verifica contra Supabase local (supabase db reset) y regenera los tipos. Nada de logica de feature ni de Dart todavia.',
    )
  }
  if (plan.needsEdgeFunctions) {
    await build(
      'backend',
      'supabase-backend-dev',
      'SOLO la parte server-side: Edge Functions en Deno, jobs de pg_cron, canales de Realtime (Broadcast/Presence), politicas de Storage y el envio de push a FCM si aplica. Las validaciones que no pueden confiarse al cliente (edad minima, cupos, cierre de un SOS) van aqui. Desarrolla y prueba contra Supabase local. Nada de Dart todavia.',
    )
  }
  await build(
    'core',
    'flutter-dev',
    'Las capas domain/ y data/ de la feature: modelos puros, interfaces de repositorio (abstract class XRepository), un caso de uso por accion de negocio, DTOs y datasources de Supabase, e implementaciones de repositorio que devuelvan Either<DomainException, T>. Domain no importa Flutter ni hace I/O; data no importa widgets ni usa BuildContext. Corre build_runner tras tocar freezed/DTOs/injectable. Con sus tests unit (casos de uso) y de data.',
  )
  if (plan.needsUi) {
    await build(
      'ui',
      'flutter-dev',
      'La capa presentation/: LEE PRIMERO el frame real en rideglory.pen con las herramientas MCP de Pencil (get_app_state + screenshot de la pantalla) — el .md describe el diseno, el .pen ES el diseno; si difieren manda el .pen. Luego cubits @injectable sobre ResultState<T> (cero flags booleanos), provistos con BlocProvider en el arbol, paginas y widgets. Respeta las 5 reglas de tolerancia cero: un widget por archivo, nada de metodos que devuelvan Widget, todos los strings en lib/l10n/app_es.arb con context.l10n.<key>, componentes compartidos antes que Material crudo (AppSwitch, nunca Switch), y todo oscuro sobre el naranja primario. Cubre los estados obligatorios: contenido, vacio, carga con skeleton (nunca spinner), error accionable con reintentar, y sin permiso de ubicacion / sin GPS / sin conexion cuando apliquen. Con bloc_test para el cubit.',
    )
  }
}

// ---------------------------------------------------------------------------
// Phase: Test — qa-automator: gate determinista + cobertura + Patrol
// ---------------------------------------------------------------------------
phase('Test')

const qaPrompt = (note) =>
  `Eres qa-automator cerrando la corrida "${SLUG}" de Rideglory. Sigue tu playbook (.claude/agents/qa-automator.md).

${HARD_RULES}

OBJETIVO: ${plan.goal}
CRITERIOS DE ACEPTACION:
${acStr}
ARCHIVOS TOCADOS POR LOS IMPLEMENTADORES:
${allFilesChanged.join('\n') || '(ninguno reportado)'}

TU TRABAJO:
1. dart analyze y flutter test completos (gate determinista). Distingue fallos NUEVOS (newFailures, con archivo) de preexistentes (notes).
2. Por cada criterio de aceptacion: ¿hay un test que fallaria sin el cambio? Si falta y es automatizable (unit > widget), ESCRIBELO y correlo. Los cubits se prueban con bloc_test + mocktail sobre ResultState; los repositorios, con el cliente de Supabase mockeado.
3. ${plan.needsUi ? 'Esta corrida SI toca UI: completa los golden tests de TODAS las paginas y sheets nuevos/tocados bajo presentation/, un caso por estado distinguible (contenido, vacio, carga, error, y los estados de permiso/GPS/conexion si aplican). La app es DARK-ONLY: no generes variante clara. Usa el helper compartido test/support/golden_helpers.dart — es el que desactiva la descarga en runtime de google_fonts; sin eso los goldens salen con fuente de fallback y toda la auditoria de fidelidad queda invalidada SIN que ningun test falle. Las pantallas con Mapbox no renderizan el mapa en goldens: audita sus overlays aislados (banner de SOS, tarjetas de rider, controles) y anota el gap. No dejes los goldens como manualCheck.' : 'Esta corrida no toca UI: sin goldens que generar.'}
4. ${CFG.e2e ? 'Patrol e2e: verifica device con `adb devices` / `xcrun simctl list devices booted`. Si no hay ninguno booteado, NO marques skip todavia — intenta bootear uno tu mismo (`flutter emulators` para listar, `flutter emulators --launch <id>`) y reintenta. Escribe/extiende el Patrol e2e (integration_test/) para el flujo multi-pantalla de esta feature y correlo contra ese device con el flavor `dev` y Supabase LOCAL — NUNCA contra produccion. Marca e2e="skip" solo si, tras intentar bootear, sigue sin haber device, o si el flujo no es multi-pantalla/determinista — y dilo explicito en notes, no en silencio.' : 'Tamano S: NO hagas e2e (e2e="skip").'}
5. manualChecks: la lista CORTA de lo que solo un humano puede verificar (legibilidad bajo sol, uso con guantes, gestos reales, GPS real) — la fidelidad contra Pencil NO va aqui, la cierra una fase aparte del workflow.
${note ? `\nNOTA: ${note}` : ''}
Devuelve el objeto estructurado. NO edites lib/: los bugs reales van en newFailures.`

let qa = await agent(qaPrompt(null), { label: 'qa-automator', phase: 'Test', schema: QA_SCHEMA, agentType: 'qa-automator' })
log(
  `[test] analyze=${qa.analyzeClean ? 'limpio' : 'ISSUES'} tests=${qa.testsGreen ? 'verde' : 'ROJO'} e2e=${qa.e2e} — ${qa.filesWritten.length} tests nuevos, ${qa.acCoverage.filter((a) => a.status === 'gap').length} gaps`,
)

// Fix loop determinista: fallos nuevos o analyze roto se corrigen ANTES de gastar en review.
let fixRound = 0
while ((!qa.testsGreen || !qa.analyzeClean) && qa.newFailures.length > 0 && fixRound < CFG.fixRounds + 1) {
  fixRound++
  log(`[test] rojo (ronda ${fixRound}) — flutter-dev corrige ${qa.newFailures.length} fallos`)
  await agent(
    `Eres flutter-dev en MODO FIX para "${SLUG}". Corrige SOLO estos fallos detectados por QA (no re-implementes nada mas), re-corre dart analyze y flutter test, deja verde:
${qa.newFailures.map((f) => `- ${f.file}: ${f.description}`).join('\n')}
${HARD_RULES}
${safetyRequirementsStr}
Devuelve {status, filesChanged, testResult, notes}.`,
    { label: `fix#${fixRound}`, phase: 'Test', schema: IMPL_SCHEMA, agentType: 'flutter-dev' },
  ).then((r) => r && allFilesChanged.push(...r.filesChanged))
  qa = await agent(qaPrompt(`Re-verificacion tras correcciones (ronda ${fixRound}). No re-escribas tests que ya existen; solo re-corre y reevalua.`), {
    label: 'qa-automator',
    phase: 'Test',
    schema: QA_SCHEMA,
    agentType: 'qa-automator',
  })
}

// ---------------------------------------------------------------------------
// Phase: Review — escalado por tamano
// ---------------------------------------------------------------------------
phase('Review')

const filesList = [...new Set(allFilesChanged)].join('\n')

async function runReview(note) {
  if (CFG.review === 'deep') {
    // Tamano L: reusa el workflow feature-review (4 dimensiones + verificacion adversarial).
    const deep = await workflow('feature-review', plan.featureDir)
    const confirmed = (deep && deep.confirmed) || []
    return {
      approved: confirmed.length === 0,
      blockers: confirmed.map((f) => ({ file: f.file, description: `${f.summary} — ${f.detail || ''}` })),
      observations: [],
    }
  }
  if (CFG.review === 'quick') {
    const quick = await agent(
      `Revision RAPIDA (tamano S) de la corrida "${SLUG}" de Rideglory: convenciones criticas (ResultState sin flags booleanos, Either<DomainException,T> en repositorios, direccion de dependencias presentation → domain ← data, cubits sin getIt desde widgets, navegacion pushNamed/goAndClearStack, naming, estilo Dart, codigo generado al dia) y que el cambio cumpla los AC. Se selectivo: blockers solo para violaciones reales, lo demas en observations.

Archivos a revisar (leelos; usa git diff solo si ayuda):
${filesList}
CRITERIOS DE ACEPTACION:
${acStr}
${note ? `NOTA: ${note}` : ''}
Devuelve (approved, blockers[{file,description}], observations[]).`,
      { label: 'code-review', phase: 'Review', schema: REVIEW_SCHEMA, agentType: 'rideglory-code-reviewer' },
    )
    return quick || { approved: true, blockers: [], observations: [] }
  }
  const reviews = await parallel([
    () =>
      agent(
        `Revision COMBINADA (tamano M) de la corrida "${SLUG}" de Rideglory: convenciones criticas (ResultState sin flags booleanos, Either<DomainException,T>, cubits @injectable provistos con BlocProvider y nunca leidos con getIt desde un widget, navegacion, naming, estilo Dart, codigo generado al dia), direccion de dependencias Clean Architecture (presentation → domain ← data; domain sin Flutter ni I/O; data sin widgets ni BuildContext), y que cada AC tenga test.

Archivos a revisar:
${filesList}
CRITERIOS DE ACEPTACION:
${acStr}
${note ? `NOTA: ${note}` : ''}
Blockers solo para violaciones reales; lo demas en observations. Devuelve (approved, blockers[{file,description}], observations[]).`,
        { label: 'code-review', phase: 'Review', schema: REVIEW_SCHEMA, agentType: 'rideglory-code-reviewer' },
      ),
    () =>
      agent(
        `Revisa SOLO las 5 convenciones de widgets/UI de tolerancia cero de CLAUDE.md (un widget por archivo; nada de metodos que devuelvan Widget; cero strings de UI en el codigo — incluidos los mensajes de error de red y auth; nunca Material crudo si existe el componente compartido, con AppSwitch/AppSwitchTile como unico switch; todo oscuro sobre el naranja primario) en estos archivos de la corrida "${SLUG}":
${filesList}
${note ? `NOTA: ${note}` : ''}
Devuelve (approved, blockers[{file,description}], observations[]). Blockers solo para violaciones reales, cada uno con archivo:linea y la correccion concreta.`,
        { label: 'ui-convention', phase: 'Review', schema: REVIEW_SCHEMA, agentType: 'ui-convention-reviewer' },
      ),
    () =>
      plan.touchesSafety || plan.touchesLocation
        ? agent(
            `Revisa SOLO la seguridad del rider y la privacidad de ubicacion en el CODIGO YA ESCRITO de la corrida "${SLUG}": el SOS se persiste antes de la red y nunca falla en silencio (ninguna ruta de fallo termina en un return mudo), la UI no dice "enviado" antes de la confirmacion del servidor, el fallback sin datos usa contactos cacheados al empezar la rodada, el SOS solo lo cierra una persona, la ubicacion se comparte con consentimiento explicito y con parada accesible, el tracking en background termina de verdad, el enmascarado de datos sensibles ocurre en la base (RLS/vistas) y no filtrando en Dart, y los estados sin permiso / sin GPS / sin conexion estan disenados.
${safetyGate && safetyGate.requirements.length ? `\nEste plan ya paso por un gate de seguridad. Verifica ademas que la implementacion cumple estos requisitos que salieron de ahi:\n${safetyGate.requirements.map((r) => `- ${r}`).join('\n')}\n` : ''}
Archivos:
${filesList}
${note ? `NOTA: ${note}` : ''}
Devuelve (approved, blockers[{file,description}], observations[]). Blockers solo para violaciones reales.`,
            { label: 'safety-review', phase: 'Review', schema: REVIEW_SCHEMA, agentType: 'safety-compliance-reviewer' },
          )
        : Promise.resolve({ approved: true, blockers: [], observations: [] }),
  ])
  const [code, uiConvention, safety] = reviews.map((r) => r || { approved: true, blockers: [], observations: [] })
  return {
    approved: code.approved && uiConvention.approved && safety.approved,
    blockers: [...code.blockers, ...uiConvention.blockers, ...safety.blockers],
    observations: [...code.observations, ...uiConvention.observations, ...safety.observations],
  }
}

let review = await runReview(null)
log(`[review] ${review.approved ? 'APROBADO' : `${review.blockers.length} blockers`} (${CFG.review})`)

let reviewRound = 0
while (!review.approved && review.blockers.length > 0 && reviewRound < CFG.fixRounds) {
  reviewRound++
  log(`[review] corrigiendo blockers (ronda ${reviewRound}/${CFG.fixRounds})`)
  await agent(
    `Eres flutter-dev en MODO FIX (review) para "${SLUG}". Corrige SOLO estos blockers, re-corre dart analyze y flutter test, deja verde:
${review.blockers.map((b) => `- ${b.file}: ${b.description}`).join('\n')}
${HARD_RULES}
${safetyRequirementsStr}
Devuelve {status, filesChanged, testResult, notes}.`,
    { label: `review-fix#${reviewRound}`, phase: 'Review', schema: IMPL_SCHEMA, agentType: 'flutter-dev' },
  ).then((r) => r && allFilesChanged.push(...r.filesChanged))
  review = await runReview(`Re-revision tras correcciones (ronda ${reviewRound}); enfocate en verificar que los blockers previos quedaron resueltos.`)
  log(`[review] re-revision ${reviewRound}: ${review.approved ? 'APROBADO' : `${review.blockers.length} blockers restantes`}`)
}

// ---------------------------------------------------------------------------
// Phase: Fidelity — goldens vs. Pencil (solo si needsUi). Cierra el loop que el
// gate de acceso (Gate Pencil) no cierra por si solo: tener acceso al .pen antes
// de construir reduce la deriva pero no la elimina, porque el layout final
// depende de decisiones que el frame no especifica. Aqui se compara el render
// real (goldens de la fase Test) contra el nodeId real.
// ---------------------------------------------------------------------------
let fidelity = null
if (plan.needsUi) {
  phase('Fidelity')

  async function runFidelity(note) {
    return agent(
      `Revisa la fidelidad visual completa de la feature "${plan.featureDir}" (corrida "${SLUG}") comparando cada golden test ya generado contra su nodeId real en rideglory.pen. Sigue tu playbook (.claude/agents/pencil-fidelity-reviewer.md).

1. Confirma primero si existe el spec de estas pantallas. Los archivos bajo design-system/rideglory/pages/ estan nombrados en ESPANOL por pantalla, NO por el nombre ingles de la carpeta de lib/features/. "${plan.featureDir}" es el nombre de carpeta en ingles — nunca lo uses tal cual como nombre de archivo. Primero haz Glob("design-system/rideglory/pages/*.md") y elige los archivos que correspondan semanticamente (traduccion directa, o un Read rapido de las primeras lineas si el nombre no es obvio). Solo si ese Glob no produce ningun candidato razonable, devuelve applicable=false y explica en reason — no es un fallo, esa pantalla aun no tiene spec.
2. Si existe, confirma acceso real al .pen (get_app_state). rideglory.pen esta encriptado: nunca lo abras con Read ni Grep. Si el MCP no responde, devuelve applicable=true, accessible=false y explica en reason — no compares a ciegas contra el .md solo.
3. Si tienes acceso: Glob sobre test/features/${plan.featureDir}/presentation/golden/goldens/*.png y compara CADA .png contra su fila en el .md (la app es dark-only: no esperes variantes claras). No te limites a una muestra. Las pantallas con Mapbox no renderizan el mapa en goldens — audita sus overlays y reporta el mapa como gap conocido, no como hallazgo.
${note ? `\nNOTA: ${note}` : ''}
Devuelve {applicable, accessible, reason, findings[{severity,golden,nodeId,description}], gapsMdWithoutGolden[], gapsGoldenWithoutMd[]}. Severidad: CRITICO (un usuario lo notaria de inmediato: componente equivocado, layout roto, color fuera de la paleta Asphalt), IMPORTANTE (divergencia real acotada: spacing, peso de fuente, icono equivocado), MENOR (sutil/discutible). No inventes hallazgos para tener contenido.`,
      { label: note ? 'fidelity-reverify' : 'fidelity', phase: 'Fidelity', schema: FIDELITY_SCHEMA, agentType: 'pencil-fidelity-reviewer' },
    )
  }

  fidelity = await runFidelity(null)

  if (!fidelity || !fidelity.applicable) {
    log(`[fidelity] N/A — ${fidelity ? fidelity.reason : 'el agente no respondio'}`)
  } else if (!fidelity.accessible) {
    log(`[fidelity] BLOQUEADO sin acceso a Pencil — ${fidelity.reason}`)
  } else {
    const blockerFindings = fidelity.findings.filter((f) => f.severity === 'CRITICO' || f.severity === 'IMPORTANTE')
    log(
      `[fidelity] ${blockerFindings.length ? `${blockerFindings.length} hallazgos CRITICO/IMPORTANTE` : 'sin hallazgos bloqueantes'} (${fidelity.findings.length} totales, ${fidelity.gapsMdWithoutGolden.length + fidelity.gapsGoldenWithoutMd.length} gaps de cobertura)`,
    )

    const blockerFindingsRemain = () =>
      fidelity && fidelity.accessible && fidelity.findings.some((f) => f.severity === 'CRITICO' || f.severity === 'IMPORTANTE')

    let fidelityRound = 0
    while (blockerFindingsRemain() && fidelityRound < CFG.fixRounds) {
      fidelityRound++
      const toFix = fidelity.findings.filter((f) => f.severity === 'CRITICO' || f.severity === 'IMPORTANTE')
      log(`[fidelity] corrigiendo ${toFix.length} hallazgos (ronda ${fidelityRound}/${CFG.fixRounds})`)
      await agent(
        `Eres flutter-dev en MODO FIX (fidelidad visual vs Pencil) para "${SLUG}". Corrige SOLO estos hallazgos de fidelidad, confirmando primero contra el nodeId real en rideglory.pen con las herramientas MCP de Pencil (no adivines, y nunca hardcodees un hex: usa la variable del .pen), y regenera los goldens afectados con flutter test --update-goldens sobre el path exacto tras el fix:
${toFix.map((f) => `- ${f.golden} (nodeId ${f.nodeId}): [${f.severity}] ${f.description}`).join('\n')}
${HARD_RULES}
Devuelve {status, filesChanged, testResult, notes}.`,
        { label: `fidelity-fix#${fidelityRound}`, phase: 'Fidelity', schema: IMPL_SCHEMA, agentType: 'flutter-dev' },
      ).then((r) => r && allFilesChanged.push(...r.filesChanged))
      fidelity = await runFidelity(
        `Re-verificacion tras correcciones (ronda ${fidelityRound}); enfocate en confirmar que estos hallazgos quedaron resueltos: ${toFix.map((f) => f.golden).join(', ')}.`,
      )
      log(
        `[fidelity] re-verificacion ${fidelityRound}: ${fidelity && fidelity.accessible ? `${fidelity.findings.filter((f) => f.severity === 'CRITICO' || f.severity === 'IMPORTANTE').length} restantes` : 'BLOQUEADO'}`,
      )
    }
  }
}

// ---------------------------------------------------------------------------
// Phase: Close — UN solo artefacto humano
// ---------------------------------------------------------------------------
phase('Close')

const gaps = qa.acCoverage.filter((a) => a.status === 'gap')

const fidelitySummaryStr = !plan.needsUi
  ? 'N/A (feature sin UI)'
  : !fidelity || !fidelity.applicable
    ? `N/A — ${fidelity ? fidelity.reason : 'el agente no respondio'}`
    : !fidelity.accessible
      ? `BLOQUEADO sin acceso a Pencil — ${fidelity.reason}`
      : `${fidelity.findings.filter((f) => f.severity === 'CRITICO' || f.severity === 'IMPORTANTE').length ? 'PARCIAL' : 'APROBADA'} — ${fidelity.findings.length} hallazgos (${fidelity.findings.map((f) => `[${f.severity}] ${f.golden}: ${f.description}`).join(' | ') || 'ninguno'}); gaps: ${[...fidelity.gapsMdWithoutGolden, ...fidelity.gapsGoldenWithoutMd].join(' | ') || 'ninguno'}`

const close = await agent(
  `Escribe el UNICO artefacto de dev-run de la corrida "${SLUG}" de Rideglory: ${SUMMARY_FILE} (crea la carpeta con mkdir -p docs/dev-runs). Espanol colombiano, conciso — es para que el humano revise y commitee.

Ademas, y SOLO ademas de eso, actualiza la tabla de docs/fidelidad-visual-tracking.md para la feature "${plan.featureDir}" (crea el archivo con su cabecera si no existe todavia; agrega la fila si falta; si existe, edita su Estado/Fecha/Goldens/Fuente/Notas) con las columnas Feature | Estado | Fecha | Goldens | Fuente | Notas, donde Estado es uno de ✅ Aprobada / 🟡 Parcial / ⏳ Agendada / ❌ Sin auditar / ⬜️ N/A. Usa el resultado de fidelidad de esta corrida:
${fidelitySummaryStr}
- Sin hallazgos CRITICO/IMPORTANTE pendientes y sin gaps de cobertura → ✅ Aprobada.
- Con hallazgos sin corregir o gaps de cobertura → 🟡 Parcial, anota en Notas que sigue pendiente.
- Si applicable=false (sin .md todavia) o accessible=false (sin acceso a Pencil) → deja el estado que ya tuviera la fila, o ❌ Sin auditar si es nueva, y anota la razon.
- Fecha: usa Bash date -u +%Y-%m-%d. Fuente: ${SUMMARY_FILE}.
Si esta corrida resuelve un pendiente listado en "Pendientes activos" de ese mismo doc, quitalo de esa lista en vez de dejarlo duplicado.

NO toques ningun otro archivo fuera de estos dos.

Datos de la corrida:
- Objetivo: ${plan.goal}
- Tamano: ${SIZE} | Review: ${CFG.review} ${review.approved ? 'APROBADO' : 'CON BLOCKERS PENDIENTES'}
- Banderas: esquema=${plan.needsDbSchema}, edge functions=${plan.needsEdgeFunctions}, ui=${plan.needsUi}, seguridad=${plan.touchesSafety}, ubicacion=${plan.touchesLocation}
- Gate de seguridad sobre el plan: ${safetyGate ? `PASO — requisitos exigidos: ${safetyGate.requirements.join(' | ') || 'ninguno'}` : 'no aplico'}
- AC:\n${acStr}
- Archivos tocados:\n${[...new Set(allFilesChanged)].join('\n')}
- Tests: analyze=${qa.analyzeClean ? 'limpio' : 'con issues'}, suite=${qa.testsGreen ? 'verde' : 'roja'}, e2e=${qa.e2e}. Tests escritos: ${qa.filesWritten.join(', ') || 'ninguno nuevo'}
- Cobertura AC: ${qa.acCoverage.map((a) => `${a.status === 'covered' ? '✅' : '⚠️ GAP'} ${a.ac} → ${a.test}`).join(' | ')}
- Fidelidad visual vs Pencil: ${fidelitySummaryStr}
- Blockers sin resolver: ${review.blockers.map((b) => `${b.file}: ${b.description}`).join(' | ') || 'ninguno'}
- Observaciones no bloqueantes: ${review.observations.join(' | ') || 'ninguna'}
- Riesgos del plan: ${plan.risks.join(' | ') || 'ninguno'}
- Notas de build: ${buildNotes.join(' | ')}

FORMATO del archivo de dev-run (usa Bash date -u +%Y-%m-%d para la fecha):
# <titulo legible> (<slug>)
## Objetivo y criterios de aceptacion
## Que cambio (tabla archivo → que)
## Base de datos y server-side (migraciones, RLS, edge functions; "n/a" si no aplico)
## Tests (resultado + comandos exactos para re-correr, incluido patrol si aplica)
## Seguridad del rider (requisitos del gate y como quedaron cubiertos; "n/a" si no aplico)
## Fidelidad visual vs Pencil (resultado de esta corrida, hallazgos si los hay)
## 👤 Verifica a mano (checklist corto: ${qa.manualChecks.join('; ') || 'derivalo de los AC'}${qa.e2e === 'skip' ? '; el e2e quedo en skip pese al intento de bootear emulador — revisa por que' : ''})
## Pendientes y riesgos (gaps de cobertura, blockers, observaciones, gaps de fidelidad)
## Mensaje de commit sugerido

Devuelve {status:'pass', filesChanged:['${SUMMARY_FILE}','docs/fidelidad-visual-tracking.md'], testResult:'n/a', notes:'listo'}.`,
  { label: 'close', phase: 'Close', schema: IMPL_SCHEMA, effort: 'low' },
)

return {
  slug: SLUG,
  size: SIZE,
  goal: plan.goal,
  flags: {
    needsDbSchema: plan.needsDbSchema,
    needsEdgeFunctions: plan.needsEdgeFunctions,
    needsUi: plan.needsUi,
    touchesSafety: plan.touchesSafety,
    touchesLocation: plan.touchesLocation,
  },
  safety: safetyGate ? { gated: true, requirements: safetyGate.requirements } : { gated: false, requirements: [] },
  filesChanged: [...new Set(allFilesChanged)],
  tests: {
    analyzeClean: qa.analyzeClean,
    suiteGreen: qa.testsGreen,
    e2e: qa.e2e,
    newTestFiles: qa.filesWritten,
    coverageGaps: gaps.map((g) => `${g.ac} — ${g.test}`),
  },
  review: { mode: CFG.review, approved: review.approved, remainingBlockers: review.blockers },
  fidelity: !plan.needsUi
    ? { applicable: false }
    : {
        applicable: fidelity ? fidelity.applicable : false,
        accessible: fidelity ? fidelity.accessible : false,
        remainingFindings: fidelity && fidelity.accessible ? fidelity.findings : [],
        coverageGaps: fidelity && fidelity.accessible ? [...fidelity.gapsMdWithoutGolden, ...fidelity.gapsGoldenWithoutMd] : [],
      },
  manualChecks: qa.manualChecks,
  summary: SUMMARY_FILE,
  closeStatus: close ? close.status : 'unknown',
  note: `Feature "${SLUG}" implementada SIN commitear. Revisa ${SUMMARY_FILE} y el diff, prueba a mano el checklist 👤, y commitea tu.`,
}
