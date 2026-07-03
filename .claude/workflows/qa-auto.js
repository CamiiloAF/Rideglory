export const meta = {
  name: 'qa-auto',
  description:
    'Automatiza el QA_CHECKLIST.md de una fase de rg-exec: clasifica cada caso (unit/widget/Patrol e2e/técnico/manual), GENERA y CORRE los tests automatizables reusando el agente qa-automator, un auditor Opus rechaza tests vacíos, y ANOTA EL MISMO QA_CHECKLIST.md en su lugar con tri-estado (🤖 auto / 🚫 no automatizable / 👤 manual). Escribe test files SIN commitear; nunca toca lib/. Args: slug de la corrida (string) o {slug, checklist?, mode?, generateE2e?}. Salida en docs/exec-runs/<slug>/.',
  phases: [
    { title: 'Classify', detail: 'Parsear el checklist y clasificar cada caso por estrategia de test' },
    { title: 'Preflight', detail: 'Detectar emulador/simulador y baseline verde de flutter test/dart analyze' },
    { title: 'E2E Regression', detail: 'Corre el Patrol e2e de inscripción si hay device (regresión permanente)' },
    { title: 'Generate', detail: 'qa-automator genera y corre unit/widget/Patrol para los casos automatizables' },
    { title: 'Verify', detail: 'Auditor Opus: rechaza tests vacíos/tautológicos que no prueban el resultado esperado' },
    { title: 'Report', detail: 'Anotar el mismo QA_CHECKLIST.md con el tri-estado + lista de pruebas manuales' },
  ],
}

// ---------------------------------------------------------------------------
// Parsear args
// ---------------------------------------------------------------------------
// Robusto: acepta objeto {slug|checklist}, un slug pelón, o —por si se pasó mal—
// un string que en realidad es JSON (ej. '{"checklist":"..."}').
let parsedArgs = args
if (typeof args === 'string') {
  const t = args.trim()
  if (t.startsWith('{') || t.startsWith('[')) {
    try { parsedArgs = JSON.parse(t) } catch { parsedArgs = args }
  }
}
const input = typeof parsedArgs === 'string'
  ? { slug: parsedArgs }
  : (typeof parsedArgs === 'object' && parsedArgs !== null ? parsedArgs : {})
if (!input.slug && !input.checklist) {
  throw new Error(
    'qa-auto requiere args = "<slug de la corrida>" o {slug: "...", checklist?: "ruta/al/QA_CHECKLIST.md", mode?: "normal"|"lite", generateE2e?: true}.\n' +
    'Ejemplos:\n' +
    '  /qa-auto phase-02-event-list-date-filter\n' +
    '  /qa-auto {"slug":"phase-02-event-list-date-filter","generateE2e":false}',
  )
}

// Dos formas de invocar:
//  - {slug}          → WS = docs/exec-runs/<slug> en el repo principal.
//  - {checklist}     → ruta (absoluta o relativa) a un QA_CHECKLIST.md; WS = su carpeta.
//    Esto soporta corridas en worktrees (.claude/worktrees/<x>/docs/exec-runs/<slug>/...).
const rawChecklist = typeof input.checklist === 'string' ? input.checklist.trim() : null
let WS, CHECKLIST, SLUG
if (rawChecklist) {
  CHECKLIST = rawChecklist
  WS = rawChecklist.replace(/\/[^/]*$/, '') // dirname del checklist
  SLUG = WS.replace(/\/+$/, '').replace(/^.*\//, '') // basename del WS
} else {
  SLUG = String(input.slug).trim()
  WS = `docs/exec-runs/${SLUG}`
  CHECKLIST = `${WS}/QA_CHECKLIST.md`
}
if (!SLUG) throw new Error('No pude derivar el slug. Pasa {slug:"..."} o {checklist:"ruta/al/QA_CHECKLIST.md"} explícito.')
const MODE = input.mode === 'lite' ? 'lite' : 'normal' // lite = solo correr lo existente (secc. técnica), no generar
// generateE2e por defecto true; se apaga solo si no hay device (se decide en Preflight).
let wantE2e = input.generateE2e !== false

// Raíz del repo Flutter para esta corrida. Si el checklist vive en un worktree
// (.claude/worktrees/<x>/...), el código Flutter bajo prueba está en ESE worktree,
// no en el repo principal. Los tests Flutter deben escribirse/correrse ahí.
const wtMatch = WS.match(/^(.*\/\.claude\/worktrees\/[^/]+)\//)
const REPO_ROOT = wtMatch ? wtMatch[1] : '.'
const IN_WORKTREE = Boolean(wtMatch)

const HARD_RULES = `
HARD RULES — no las violes:
1. NUNCA ejecutes: git add / commit / push / merge / rebase / restore / reset, ni gh pr create / merge / review.
2. NUNCA edites código de producción de la app: lib/ (Flutter) ni src/ de rideglory-api. SOLO puedes crear/editar archivos de test:
   - Flutter: test/** e integration_test/**
   - Backend: *.spec.ts dentro de rideglory-api (solo si el caso lo exige y no existe spec).
3. Deja el working tree SUCIO (sin commitear) para revisión humana.
4. Escribe artefactos (reportes, checklist anotado) SOLO bajo ${WS}/.
5. Timestamps con Bash \`date -u +%Y-%m-%dT%H:%M:%SZ\`.
6. Reusa patrones existentes: test/features/**, integration_test/**_patrol_test.dart, mocktail + bloc_test. NO inventes helpers si ya existen.
7. RAÍZ DEL REPO FLUTTER de esta corrida: ${REPO_ROOT}${IN_WORKTREE ? ' (¡es un git WORKTREE!)' : ''}. El código Flutter bajo prueba (lib/, test/, integration_test/, pubspec.yaml) está AHÍ. Antes de escribir/correr cualquier test Flutter o comando flutter/dart/patrol, haz \`cd ${REPO_ROOT}\`. El backend rideglory-api está en su propia ruta (ver handoffs), independiente de esto.
`

log(`qa-auto "${SLUG}" — checklist: ${CHECKLIST} — modo: ${MODE}${wantE2e ? ' (+e2e)' : ' (sin e2e)'}`)

// ---------------------------------------------------------------------------
// Phase: Classify — parsear el checklist y clasificar cada caso
// ---------------------------------------------------------------------------
phase('Classify')

const CLASSIFY_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['feature', 'isFlutter', 'isBackend', 'cases', 'criticalSections'],
  properties: {
    feature: { type: 'string' },
    isFlutter: { type: 'boolean' },
    isBackend: { type: 'boolean' },
    // Secciones cuyo fallo = RECHAZO (según "Resultado final" del checklist).
    criticalSections: { type: 'array', items: { type: 'string' } },
    cases: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['id', 'section', 'title', 'expected', 'repo', 'strategy', 'reason'],
        properties: {
          id: { type: 'string' }, // ej "1.1", "5A.2", "6.5"
          section: { type: 'string' }, // ej "1", "5A", "6"
          title: { type: 'string' }, // acción resumida
          expected: { type: 'string' }, // resultado esperado (observable)
          repo: { type: 'string', enum: ['flutter', 'backend', 'na'] },
          // unit/widget/e2e = generable; run-existing = ya hay test/comando, solo correr;
          // manual = requiere humano sí o sí; cannot = automatizable en teoría pero no en este entorno.
          strategy: { type: 'string', enum: ['unit', 'widget', 'e2e', 'run-existing', 'manual', 'cannot'] },
          reason: { type: 'string' }, // por qué esa estrategia (para el estado 🚫/👤 en el reporte)
        },
      },
    },
  },
}

const classification = await agent(
  `Eres el clasificador de QA de rg-auto para la corrida "${SLUG}" de Rideglory (Flutter + rideglory-api).
Tu trabajo: leer el checklist de QA y clasificar CADA caso por la estrategia de test que le corresponde. NO escribes tests todavía.

${HARD_RULES}

CONTEXTO (lee los que existan):
- ${CHECKLIST} — el checklist a automatizar. Es la FUENTE. Extrae CADA fila de CADA tabla (secciones de flujo 1..N, casos de borde N+1, verificaciones técnicas N+2).
- ${WS}/PRD_NORMALIZED.md — §5 criterios de aceptación, §6 guardrails.
- ${WS}/handoffs/frontend.md — pantallas/cubits/widgets implementados (nombres reales de clases y archivos).
- ${WS}/handoffs/backend.md — endpoints y specs jest ya creados.
- ${WS}/handoffs/qa.md — catálogo de pruebas ya identificado por QA.
- test/ e integration_test/ del repo — para saber qué patrones y qué cubro ya existe.
- \`git -C . diff --stat\` y (si aplica) el diff de rideglory-api — archivos realmente tocados.

REGLAS DE CLASIFICACIÓN (aplica una por caso, en este orden de preferencia):
- **unit**: el caso valida LÓGICA pura de un cubit/usecase/repositorio/servicio (ej. "dateFrom = hoy", "el filtro sobrescribe el piso", idempotencia, mapeo). Preferir unit sobre widget/e2e cuando la lógica se pueda probar sin UI. bloc_test para cubits.
- **widget**: el caso valida un ESTADO DE UI renderizado que se puede montar con mocks sin backend real (loading spinner, empty state, error state, que un texto/botón aparezca/desaparezca). Sin navegación multi-pantalla.
- **e2e**: el caso es un FLUJO end-to-end multi-pantalla con gestos reales (navegar, tocar, aplicar filtro, verificar lista) → Patrol en integration_test/. Solo si el flujo es guionizable de forma determinista.
- **run-existing**: la fila de la sección técnica YA dice un comando (\`flutter test ...\`, \`dart analyze ...\`, \`npm run test\`) o el backend ya tiene el spec jest que la cubre → no generamos, solo corremos y capturamos el resultado real.
- **manual**: requiere humano SÍ o SÍ. Ejemplos: verificación VISUAL/estética, gesto en dispositivo físico real, notificación push recibida en device, permisos del SO, interceptar tráfico con Proxyman/Charles a mano, comportamiento dependiente de datos seed reales que no podemos fabricar en test, revisión de UX subjetiva.
- **cannot**: automatizable en teoría pero NO en este entorno/fase (ej. requiere backend corriendo con datos específicos, zona horaria del dispositivo, feature no implementada aún, dependencia externa no mockeable razonablemente). Explica la razón concreta.

Para cada caso reporta: id exacto (ej "1.1","5A.2","6.5"), section ("1","5A","6"), title (acción resumida), expected (resultado esperado observable, textual del checklist), repo (flutter|backend|na), strategy, reason (1 frase; para manual/cannot es lo que se le mostrará al humano).

También:
- feature: título legible del checklist.
- isFlutter / isBackend: según qué toca la fase.
- criticalSections: los números de sección que la tabla "Resultado final" marca como criterio de RECHAZO (ej ["1","2","3","4"]).

NO OMITAS NINGÚN CASO. Si el checklist tiene 30 filas, devuelve 30 casos.`,
  { label: 'classify', phase: 'Classify', model: 'sonnet', schema: CLASSIFY_SCHEMA },
)

const total = classification.cases.length
const byStrat = (s) => classification.cases.filter((c) => c.strategy === s)
log(
  `[classify] ${total} casos — unit:${byStrat('unit').length} widget:${byStrat('widget').length} ` +
  `e2e:${byStrat('e2e').length} run-existing:${byStrat('run-existing').length} ` +
  `manual:${byStrat('manual').length} cannot:${byStrat('cannot').length}`,
)

// ---------------------------------------------------------------------------
// Phase: Preflight — capacidades del entorno + baseline verde
// ---------------------------------------------------------------------------
phase('Preflight')

const CAPS_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  // 'notes' narrativo → NO requerido (un modelo lo olvida y tumba la corrida).
  required: ['deviceAvailable', 'deviceKind', 'baselineFlutterTests', 'analyzeClean'],
  properties: {
    deviceAvailable: { type: 'boolean' }, // hay emulador Android o simulador iOS booteado para Patrol
    deviceKind: { type: 'string' }, // "android-emulator" | "ios-simulator" | "none"
    baselineFlutterTests: { type: 'string', enum: ['green', 'red', 'na'] },
    analyzeClean: { type: 'boolean' },
    notes: { type: 'string' },
  },
}

const needsE2e = wantE2e && byStrat('e2e').length > 0
const caps = await agent(
  `Eres el preflight de qa-auto "${SLUG}". Detecta capacidades del entorno de test. NO escribes código.

${HARD_RULES}

Esta fase toca: ${classification.isFlutter ? 'Flutter' : ''}${classification.isFlutter && classification.isBackend ? ' + ' : ''}${classification.isBackend ? 'backend (rideglory-api)' : ''}.

Ejecuta y reporta (haz \`cd ${REPO_ROOT}\` antes de los comandos flutter/dart):
1. Device para Patrol e2e:
   - Android: \`adb devices\` → ¿hay alguna línea con estado "device"?
   - iOS: \`xcrun simctl list devices booted\` → ¿hay algún simulador "Booted"?
   - deviceAvailable=true si cualquiera de los dos; deviceKind = "android-emulator" | "ios-simulator" | "none".
2. Baseline Flutter (asegura que partimos de verde, para no atribuir a la fase fallos preexistentes):
   ${classification.isFlutter
      ? '- `flutter test` — baselineFlutterTests = "green" si todo pasa, "red" si hay fallos. Puedes acotar con `flutter test --reporter compact`.\n   - `dart analyze lib/` — analyzeClean = true si "No issues found!" (ignora los lints conocidos de api_base_url_resolver.dart, config local del usuario).'
      : '- Esta fase NO toca Flutter: NO corras `flutter test` (sería lento e irrelevante). Reporta baselineFlutterTests="na" y analyzeClean=true directamente.'}
3. notes: cualquier cosa relevante (device usado, si baseline venía rojo y por qué, comandos que fallaron).

${needsE2e ? 'La fase TIENE casos e2e clasificados; si no hay device, avísalo claramente en notes (se degradarán a "no automatizable — sin emulador/simulador").' : 'No hay casos e2e o el usuario pidió sin e2e.'}`,
  { label: 'preflight', phase: 'Preflight', model: 'sonnet', schema: CAPS_SCHEMA },
)

if (needsE2e && !caps.deviceAvailable) {
  wantE2e = false
  log(`[preflight] Sin emulador/simulador booteado → los ${byStrat('e2e').length} casos e2e se marcarán 🚫 no automatizable (sin device).`)
} else {
  log(`[preflight] device:${caps.deviceKind} baseline:${caps.baselineFlutterTests} analyze:${caps.analyzeClean ? 'limpio' : 'con issues'}`)
}
if (caps.baselineFlutterTests === 'red') {
  log(`[preflight] ⚠️ La suite ya venía ROJA antes de generar tests. Los fallos preexistentes NO cuentan contra esta fase; se anotarán aparte.`)
}

// ---------------------------------------------------------------------------
// Phase: E2E Regression — corre SIEMPRE el Patrol e2e de inscripción cuando hay
// device, independiente de si el checklist de esta fase tiene casos e2e. Así el
// flujo crítico de inscripción (Personal→Médico→consentimiento→Emergencia→
// Vehículo→waiver) se ejercita en cada corrida de qa-auto (y por ende de rg-exec,
// que llama a qa-auto al cierre).
// ---------------------------------------------------------------------------
const E2E_REGRESSION_TEST = 'integration_test/registration_patrol_test.dart'
// Verificación de BD post-e2e: la UI mostrando "pendiente de revisión" no prueba
// que el backend PERSISTIÓ el consentimiento. Tras el Patrol consultamos la BD del
// events-ms y confirmamos que la inscripción trae medicalConsentVersion +
// riskAcceptanceVersion no nulos; luego limpiamos el dato de prueba.
const BACKEND_EVENTS_MS = '/Users/cami/Developer/Personal/rideglory-api/events-ms'
const E2E_TARGET_EVENT = 'Mi Evento' // owner qa2; lo inscribe qa1
const E2E_RIDER_EMAIL = 'qa1@gmail.com'
let e2eRegression = {
  result: 'skip',
  note: 'sin device booteado: no se corrió el Patrol e2e de inscripción',
  command: '',
  dbVerification: { result: 'skip', note: 'e2e no corrido' },
}
if (caps.deviceAvailable) {
  phase('E2E Regression')
  const E2E_REGRESSION_SCHEMA = {
    type: 'object',
    additionalProperties: false,
    required: ['result', 'note', 'dbVerification'],
    properties: {
      result: { type: 'string', enum: ['pass', 'fail', 'skip'] },
      note: { type: 'string' },
      command: { type: 'string' },
      // Prueba de persistencia real en BD (no solo la UI).
      dbVerification: {
        type: 'object',
        additionalProperties: false,
        required: ['result', 'note'],
        properties: {
          result: { type: 'string', enum: ['pass', 'fail', 'skip'] },
          note: { type: 'string' }, // qué valores se vieron en la BD
        },
      },
    },
  }
  e2eRegression = await agent(
    `Eres qa-automator corriendo la REGRESIÓN e2e permanente de INSCRIPCIÓN para "${SLUG}", CON verificación de base de datos. NO escribes tests, NO tocas lib/ ni src/. Corres UN Patrol e2e ya existente, verificas en la BD que la inscripción realmente persistió, y limpias el dato de prueba.

${HARD_RULES}
EXCEPCIÓN de datos para ESTA fase: SÍ puedes LEER la BD del backend y BORRAR únicamente inscripciones de prueba del rider ${E2E_RIDER_EMAIL} (jamás de otros usuarios, jamás del owner). Es lectura + limpieza de datos de test vía psql, no es tocar código.

Haz \`cd ${REPO_ROOT}\`. Test: \`${E2E_REGRESSION_TEST}\` (device ${caps.deviceKind}).

Conexión a la BD del events-ms (deriva y quita el sufijo \`?schema=...\` que psql no acepta):
  DBURL=$(grep -E '^DATABASE_URL=' ${BACKEND_EVENTS_MS}/.env | head -1 | cut -d= -f2- | tr -d "\\"'" | sed 's/?.*$//')
Evento objetivo: "${E2E_TARGET_EVENT}" (owner qa2). Rider que se inscribe: ${E2E_RIDER_EMAIL}.
DELETE de limpieza (se usa en el paso 2 y en el 6):
  psql "$DBURL" -c "DELETE FROM \\"EventRegistration\\" er USING \\"Event\\" e WHERE er.\\"eventId\\"=e.id AND e.name='${E2E_TARGET_EVENT}' AND er.email='${E2E_RIDER_EMAIL}' AND er.status='PENDING';"

PASOS (en orden):
1. Si \`${E2E_REGRESSION_TEST}\` NO existe → result='skip', note='no existe ${E2E_REGRESSION_TEST}', dbVerification.result='skip'. NO lo generes (otra fase lo escribe).
2. PRE-LIMPIEZA: corre el DELETE de arriba para que ${E2E_RIDER_EMAIL} quede SIN inscripción en "${E2E_TARGET_EVENT}" (así el detalle muestra "Inscribirme" y el flujo puede inscribir en fresco). Si no hay psql o la BD no es alcanzable, sigue pero deja dbVerification.result='skip' con la razón.
3. Corre el Patrol (credenciales SOLO si están en el entorno — \`printenv TEST_EMAIL\` / \`printenv TEST_PASSWORD\`). OJO: patrol usa \`-d\`, no \`--device-id\`:
   \`patrol test -t ${E2E_REGRESSION_TEST} -d <device real de adb devices / simctl> --flavor dev --dart-define-from-file=config/dev.json\` + (si hay creds) \`--dart-define=TEST_EMAIL=$TEST_EMAIL --dart-define=TEST_PASSWORD=$TEST_PASSWORD\`.
4. Interpreta el Patrol:
   - result='pass' si pasó.
   - result='fail' si falló por aserción/flujo roto (posible REGRESIÓN real → el humano revisa; di qué paso falló).
   - result='skip' si no se pudo correr por falta de credenciales o datos seed (vehículo, etc.).
5. VERIFICACIÓN DE BD (solo si result='pass'): confirma que la inscripción persistió el consentimiento:
   psql "$DBURL" -c "SELECT \\"medicalConsentVersion\\", \\"riskAcceptanceVersion\\" FROM \\"EventRegistration\\" er JOIN \\"Event\\" e ON er.\\"eventId\\"=e.id WHERE e.name='${E2E_TARGET_EVENT}' AND er.email='${E2E_RIDER_EMAIL}' AND er.status='PENDING';"
   - dbVerification.result='pass' si AMBAS columnas salen NO nulas (anota los valores en note, ej. medicalConsentVersion=v0.1-2026-06).
   - dbVerification.result='fail' si están nulas o no hay fila: la UI dijo éxito pero el backend NO persistió → BUG REAL, explícalo.
   - dbVerification.result='skip' si no pudiste consultar la BD.
6. LIMPIEZA FINAL: vuelve a correr el DELETE del paso 2 para dejar la BD idempotente (borra SOLO la PENDING de ${E2E_RIDER_EMAIL}; NUNCA la del owner qa2 ni otros correos).

Reporta result, note (conciso), command (el patrol exacto que corriste) y dbVerification {result, note}.`,
    { label: 'e2e-inscripcion', phase: 'E2E Regression', model: 'sonnet', schema: E2E_REGRESSION_SCHEMA, agentType: 'qa-automator' },
  )
  log(`[e2e-regression] ${e2eRegression.result}${e2eRegression.note ? ` — ${e2eRegression.note}` : ''} | db:${e2eRegression.dbVerification?.result ?? 'skip'}`)
} else {
  log(`[e2e-regression] sin device booteado → se omite el Patrol e2e de inscripción`)
}

// ---------------------------------------------------------------------------
// Phase: Generate — qa-automator genera y corre los tests automatizables
// ---------------------------------------------------------------------------
phase('Generate')

// Qué casos vamos a intentar automatizar de verdad.
const e2eBlockedNoDevice = !wantE2e && byStrat('e2e').length > 0
const automatable = classification.cases.filter((c) => {
  if (c.strategy === 'run-existing') return true
  if (c.strategy === 'unit' || c.strategy === 'widget') return true
  if (c.strategy === 'e2e') return wantE2e
  return false // manual / cannot no se intentan
})

const CASE_RESULT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['id', 'state', 'testFile', 'testName', 'note'],
  properties: {
    id: { type: 'string' },
    // auto-pass | auto-fail = se generó/corrió y el test pasó/falló;
    // no-auto = se intentó pero no se pudo automatizar (razón en note).
    state: { type: 'string', enum: ['auto-pass', 'auto-fail', 'no-auto'] },
    testFile: { type: 'string' }, // ruta del test que cubre el caso ("" si no-auto)
    testName: { type: 'string' }, // nombre del test/grupo ("" si no-auto)
    note: { type: 'string' }, // para auto-fail: qué falló; para no-auto: por qué
  },
}
const GEN_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  // 'summary' narrativo → NO requerido.
  required: ['filesWritten', 'caseResults', 'commandsRun'],
  properties: {
    filesWritten: { type: 'array', items: { type: 'string' } },
    caseResults: { type: 'array', items: CASE_RESULT_SCHEMA },
    commandsRun: { type: 'array', items: { type: 'string' } },
    summary: { type: 'string' },
  },
}

let gen = { filesWritten: [], caseResults: [], commandsRun: [], summary: 'Nada que automatizar.' }

if (MODE === 'lite') {
  // lite: solo correr lo que ya existe (sección técnica + specs backend), sin generar.
  const runOnly = automatable.filter((c) => c.strategy === 'run-existing')
  if (runOnly.length > 0) {
    gen = await agent(
      `Eres qa-automator en MODO LITE para "${SLUG}". NO generas tests nuevos; solo CORRES lo que ya existe y capturas el resultado real de cada caso.

${HARD_RULES}

Casos a correr (run-existing):
${runOnly.map((c) => `- ${c.id} [${c.repo}]: ${c.title} → esperado: ${c.expected}\n  reason: ${c.reason}`).join('\n')}

Para cada caso: identifica el comando exacto (del checklist o del handoff backend), ejecútalo, y reporta state=auto-pass si el resultado coincide con lo esperado, auto-fail si no, no-auto si el comando no se pudo correr (di por qué). Reporta commandsRun con los comandos reales ejecutados y filesWritten=[] (no escribiste tests).`,
      { label: 'run-existing', phase: 'Generate', model: 'sonnet', schema: GEN_SCHEMA, agentType: 'qa-automator' },
    )
  }
} else if (automatable.length > 0) {
  gen = await agent(
    `Eres el agente qa-automator de Rideglory ejecutando qa-auto para la corrida "${SLUG}".
Tu misión: para CADA caso automatizable de abajo, escribir (o reusar) un test que pruebe el RESULTADO ESPERADO del caso, correrlo, y reportar si pasó.

${HARD_RULES}

CONTEXTO obligatorio:
- Playbook: .claude/agents/qa-automator.md y .claude/skills/qa-automator-skill.md (convenciones, thresholds, naming).
- Handoffs de la fase: ${WS}/handoffs/frontend.md, ${WS}/handoffs/backend.md, ${WS}/handoffs/qa.md — dan los NOMBRES REALES de cubits, widgets, endpoints. Úsalos; no inventes.
- Patrones existentes: test/features/** (unit/widget con mocktail + bloc_test), integration_test/**_patrol_test.dart (e2e Patrol). Copia el estilo.
- Localización: los widgets usan context.l10n.<key>; para encontrar textos en tests, mira lib/l10n/app_es.arb.

CONVENCIONES DE NAMING (obligatorias):
- Unit:   test/features/<feature>/domain|presentation/<algo>_test.dart
- Widget: test/features/<feature>/presentation/pages|widgets/<algo>_test.dart
- E2E:    integration_test/<feature>_patrol_test.dart (extiende el archivo del feature si ya existe)

CASOS A AUTOMATIZAR (${automatable.length}):
${automatable.map((c) => `- ${c.id} [${c.repo}/${c.strategy}]: ${c.title}\n    esperado: ${c.expected}\n    pista: ${c.reason}`).join('\n')}

REGLAS CRÍTICAS DE CALIDAD (un auditor Opus revisará esto y RECHAZA tests vacíos):
- Cada test debe ASSERTAR el resultado esperado del caso, no solo "que no crashee". Nada de \`expect(true, isTrue)\` ni tests sin expect significativo.
- Un test puede cubrir varios casos relacionados; mapea claramente cuál test cubre cuál id.
- Si un caso clasificado como automatizable resulta NO automatizable al intentarlo (ej. el cubit no expone el estado, el widget necesita backend real), NO lo fuerces: márcalo state=no-auto con la razón. Es preferible honesto a un test falso-verde.
- Para run-existing: corre el comando real y reporta el resultado; no escribas test nuevo.

EJECUCIÓN:
- Corre los tests que escribiste: \`flutter test <archivos>\` (unit/widget), \`patrol test -t <archivo>\` (e2e, device ${caps.deviceKind}).
- Corre \`dart analyze\` sobre los archivos de test nuevos; deben quedar limpios.
- NO toques lib/. Si un test revela un bug real del código, NO lo arregles: repórtalo en note del caso (state=auto-fail) para que el humano decida.

Reporta: filesWritten (rutas reales), caseResults (uno por cada id de la lista, con state auto-pass|auto-fail|no-auto, testFile, testName, note), commandsRun, summary.`,
    { label: 'qa-automator', phase: 'Generate', model: 'sonnet', schema: GEN_SCHEMA, agentType: 'qa-automator' },
  )
}

log(
  `[generate] ${gen.filesWritten.length} archivos de test — ` +
  `pass:${gen.caseResults.filter((r) => r.state === 'auto-pass').length} ` +
  `fail:${gen.caseResults.filter((r) => r.state === 'auto-fail').length} ` +
  `no-auto:${gen.caseResults.filter((r) => r.state === 'no-auto').length}`,
)

// ---------------------------------------------------------------------------
// Phase: Verify — auditor Opus rechaza tests vacíos/tautológicos
// ---------------------------------------------------------------------------
phase('Verify')

const VERIFY_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  // 'reRunResult' y 'notes' son narrativos → NO requeridos (esto tumbó la 1ª corrida).
  required: ['verdict', 'vacuousCases'],
  properties: {
    verdict: { type: 'string', enum: ['solid', 'has_vacuous', 'na'] },
    // ids cuyo test NO prueba de verdad el resultado esperado (falso-verde)
    vacuousCases: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['id', 'reason'],
        properties: { id: { type: 'string' }, reason: { type: 'string' } },
      },
    },
    reRunResult: { type: 'string' }, // salida resumida de re-correr la suite generada
    notes: { type: 'string' },
  },
}

const passingCases = gen.caseResults.filter((r) => r.state === 'auto-pass')
let verify = { verdict: 'na', vacuousCases: [], reRunResult: 'sin tests que auditar', notes: '' }

if (passingCases.length > 0) {
  verify = await agent(
    `Eres el AUDITOR de calidad (Opus) de qa-auto "${SLUG}". Los tests autogenerados son propensos al FALSO-VERDE: pasan sin probar lo que dicen. Tu trabajo es cazar eso.

${HARD_RULES}

Para cada caso reportado como auto-pass, abre su testFile y verifica que el test REALMENTE assertaría el resultado esperado del caso:
${passingCases.map((r) => `- ${r.id} → ${r.testFile} :: ${r.testName}`).join('\n')}

Contexto del resultado esperado por caso (del checklist):
${passingCases.map((r) => { const c = classification.cases.find((x) => x.id === r.id); return `- ${r.id}: esperado = ${c ? c.expected : '(?)'}` }).join('\n')}

Marca como VACÍO (vacuousCases) cualquier test que:
- no tenga un expect() que ligue el assert al resultado esperado (tautológico, expect(true), expect(x, isNotNull) trivial);
- mockee justo la cosa que debería probar (se prueba a sí mismo);
- pase por accidente (no ejerce el código de la fase);
- afirme algo distinto a lo que el caso pide.

Además RE-CORRE la suite generada para confirmar que el verde es real y reproducible:
- \`flutter test <los archivos generados>\` (y \`patrol test\` si hubo e2e). Resume el resultado en reRunResult.

verdict: 'solid' si ningún test es vacío y la re-corrida es verde; 'has_vacuous' si encontraste ≥1 vacío o la re-corrida no reproduce el verde; 'na' si no había nada que auditar.
NO edites los tests tú; solo reporta. El humano/otra corrida los corrige.`,
    { label: 'auditor', phase: 'Verify', model: 'opus', schema: VERIFY_SCHEMA },
  )
  log(`[verify] ${verify.verdict}${verify.vacuousCases.length ? ` — ${verify.vacuousCases.length} test(s) vacío(s): ${verify.vacuousCases.map((v) => v.id).join(', ')}` : ''}`)
}

// Los casos marcados vacíos por el auditor DEJAN de contar como auto-pass: pasan a no-auto.
const vacuousIds = new Set(verify.vacuousCases.map((v) => v.id))
const finalResults = gen.caseResults.map((r) =>
  vacuousIds.has(r.id)
    ? { ...r, state: 'no-auto', note: `Auditor Opus: test no prueba el resultado esperado (${verify.vacuousCases.find((v) => v.id === r.id).reason}). ${r.note}` }
    : r,
)

// ---------------------------------------------------------------------------
// Phase: Report — checklist COMPLETO anotado tri-estado + reporte
// ---------------------------------------------------------------------------
phase('Report')

// Construimos el estado final por caso para pasárselo al report writer.
const resultById = new Map(finalResults.map((r) => [r.id, r]))
const annotated = classification.cases.map((c) => {
  const r = resultById.get(c.id)
  let stateTag, detail
  if (r && r.state === 'auto-pass') {
    stateTag = '🤖✅ auto-pass'
    detail = `${r.testFile}${r.testName ? ` :: ${r.testName}` : ''}`
  } else if (r && r.state === 'auto-fail') {
    stateTag = '🤖❌ auto-fail'
    detail = `${r.testFile} — ${r.note}`
  } else if (r && r.state === 'no-auto') {
    stateTag = '🚫 no automatizable'
    detail = r.note
  } else if (c.strategy === 'manual') {
    stateTag = '👤 manual'
    detail = c.reason
  } else if (c.strategy === 'cannot') {
    stateTag = '🚫 no automatizable'
    detail = c.reason
  } else if (c.strategy === 'e2e' && e2eBlockedNoDevice) {
    stateTag = '🚫 no automatizable'
    detail = 'Sin emulador/simulador booteado. Corre con un device activo para automatizar este flujo.'
  } else {
    stateTag = '👤 manual'
    detail = c.reason || 'No cubierto por la corrida.'
  }
  return { id: c.id, section: c.section, title: c.title, expected: c.expected, stateTag, detail }
})

const counts = {
  autoPass: annotated.filter((a) => a.stateTag.includes('auto-pass')).length,
  autoFail: annotated.filter((a) => a.stateTag.includes('auto-fail')).length,
  noAuto: annotated.filter((a) => a.stateTag.startsWith('🚫')).length,
  manual: annotated.filter((a) => a.stateTag.startsWith('👤')).length,
}

const REPORT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  // 'notes' narrativo → NO requerido.
  required: ['status', 'filesChanged'],
  properties: {
    status: { type: 'string', enum: ['pass', 'fail'] },
    filesChanged: { type: 'array', items: { type: 'string' } },
    notes: { type: 'string' },
  },
}

const report = await agent(
  `Eres el report writer de qa-auto "${SLUG}". Escribes en español colombiano. Tu trabajo es EDITAR EN SU LUGAR el checklist original — NO crees archivos nuevos. NO editas código ni tests.

${HARD_RULES}

ARCHIVO A EDITAR (in place): ${CHECKLIST}
Léelo COMPLETO primero.

GUARDA DE IDEMPOTENCIA (crítica — hazla ANTES de anotar):
- Busca en el archivo el sentinela \`<!-- qa-auto:annotated -->\`.
- Si YA ESTÁ PRESENTE, el checklist es de una corrida anterior de qa-auto. Debes REGENERAR DESDE LIMPIO, no apilar: primero reconstruye el checklist ORIGINAL removiendo TODO lo que qa-auto agregó en la corrida previa:
  1. el bloque \`<!-- qa-auto:annotated -->\` y el blockquote "> **Automatización qa-auto** ..." del encabezado;
  2. la columna "Estado auto" de CADA tabla (elimina el header y la celda correspondiente de cada fila, dejando las columnas originales | # | Acción | Resultado esperado | ✅/❌ | y vaciando las ✅ que qa-auto había puesto);
  3. las secciones "## 👤 Solo para ti — pruebas manuales restantes", "## 🚫 No automatizable en este entorno" y "## 🤖 Resumen de automatización".
  Tras remover eso te queda el checklist pristino; recién ahí aplica las anotaciones frescas de ESTA corrida.
- Si NO está el sentinela, es la primera corrida: anota directamente.

Debes PRESERVAR todo el contenido original (título, pre-condiciones, TODAS las secciones y filas, "Resultado final", firmas) y solo AGREGARLE la información de automatización de esta corrida. No borres ninguna fila de casos.

Anotación por caso (estado final tras generación + auditoría Opus):
${JSON.stringify(annotated, null, 2)}

Metadatos:
- Feature: ${classification.feature}
- Entorno: device=${caps.deviceKind}, baseline flutter test=${caps.baselineFlutterTests}, dart analyze ${caps.analyzeClean ? 'limpio' : 'con issues'}.
- Auditor Opus: ${verify.verdict} (${verify.vacuousCases.length} tests rechazados por vacíos).
- Conteos: 🤖✅ ${counts.autoPass} · 🤖❌ ${counts.autoFail} · 🚫 ${counts.noAuto} · 👤 ${counts.manual} (de ${annotated.length} casos).
- Archivos de test escritos: ${JSON.stringify(gen.filesWritten)}
- Regresión e2e inscripción (Patrol, corre siempre que hay device): ${e2eRegression.result}${e2eRegression.note ? ` — ${e2eRegression.note}` : ''}${e2eRegression.command ? ` [cmd: ${e2eRegression.command}]` : ''}
- Verificación de BD post-e2e (persistencia real del consentimiento): ${e2eRegression.dbVerification?.result ?? 'skip'}${e2eRegression.dbVerification?.note ? ` — ${e2eRegression.dbVerification.note}` : ''}
- Secciones críticas (fallo = rechazo): ${JSON.stringify(classification.criticalSections)}

EDICIONES A APLICAR SOBRE ${CHECKLIST} (todas en el mismo archivo):

1. Bajo el bloque de encabezado (después de **Estado:**), inserta exactamente (el comentario sentinela va PRIMERO y es obligatorio — habilita la guarda de idempotencia):
   \`\`\`
   <!-- qa-auto:annotated -->
   > **Automatización qa-auto** (<fecha, Bash date -u>): 🤖✅ ${counts.autoPass} verificados · 🤖❌ ${counts.autoFail} fallando · 👤 ${counts.manual} manuales · 🚫 ${counts.noAuto} no automatizables (de ${annotated.length} casos).
   > Entorno: device=${caps.deviceKind}, baseline=${caps.baselineFlutterTests}. Auditor Opus: ${verify.verdict}.
   \`\`\`
   Actualiza también **Estado:** a reflejar el resultado si aplica.

2. A CADA tabla de casos agrégale una columna "Estado auto" entre "Resultado esperado" y "✅/❌", usando el tag de la anotación por id:
   🤖✅ Auto-PASS (\`<testFile>\`) · 🤖❌ Auto-FAIL (motivo) · 🚫 No automatizable (motivo) · 👤 Manual (motivo).
   Marca ya la columna ✅/❌ con ✅ para los 🤖✅; déjala VACÍA para 👤 manual y 🤖❌ auto-fail (los que el humano debe revisar). Cada fila conserva su #, acción y resultado esperado intactos.

3. Antes de "## Resultado final", inserta dos secciones nuevas:
   - "## 👤 Solo para ti — pruebas manuales restantes": lista SOLO los casos 👤 manual y 🤖❌ auto-fail (id + acción + qué revisar + por qué no se automatizó). Es la lista corta que el humano ejecuta.
   - "## 🚫 No automatizable en este entorno": los 🚫 con cómo habilitarlos (ej. "bootea un simulador y re-corre qa-auto", "requiere Proxyman").

4. Al final del documento, agrega "## 🤖 Resumen de automatización":
   - Tabla: por cada caso automatizado, id · estrategia · test file · resultado.
   - Tests rechazados por el auditor Opus (con razón), si los hubo.
   - "### Cómo correr los tests generados": comandos exactos (flutter test <archivos>, patrol test ... si hubo e2e).
   - "### Regresión e2e de inscripción (Patrol)": estado \`${e2eRegression.result}\`${e2eRegression.note ? ` (${e2eRegression.note})` : ''} y el comando \`${e2eRegression.command || ('patrol test -t ' + E2E_REGRESSION_TEST)}\`. Incluye la **verificación de BD** post-e2e: \`${e2eRegression.dbVerification?.result ?? 'skip'}\`${e2eRegression.dbVerification?.note ? ` (${e2eRegression.dbVerification.note})` : ''} — confirma que la inscripción persistió medicalConsentVersion + riskAcceptanceVersion, no solo que la UI mostró "pendiente". Este e2e + verificación de BD corre en CADA corrida de qa-auto cuando hay device (regresión permanente del flujo de inscripción), independiente de los casos del checklist.
   - "### Siguientes pasos": si hay 🤖❌ auto-fail, posibles bugs reales a investigar; si hay 🚫 por device, cómo habilitar.

NO crees QA_CHECKLIST_ANNOTATED.md ni QA_AUTO_REPORT.md ni ningún archivo nuevo: todo va dentro de ${CHECKLIST}.

status='fail' si algún caso de una sección crítica (${JSON.stringify(classification.criticalSections)}) quedó 🤖❌ auto-fail; si no, 'pass'.
Devuelve {status, filesChanged:['${CHECKLIST}'], notes}.`,
  { label: 'report', phase: 'Report', model: 'sonnet', schema: REPORT_SCHEMA },
)

const criticalFails = annotated.filter(
  (a) => a.stateTag.includes('auto-fail') && classification.criticalSections.includes(a.section),
)

log(
  `[qa-auto] LISTO — ${counts.autoPass}/${total} verificados auto · ${counts.autoFail} fallando · ` +
  `${counts.manual} manuales · ${counts.noAuto} no automatizables.` +
  (criticalFails.length ? ` ⚠️ ${criticalFails.length} fallo(s) en sección crítica.` : ''),
)

return {
  slug: SLUG,
  feature: classification.feature,
  workspace: WS,
  status: report.status,
  counts,
  totalCases: total,
  auditor: verify.verdict,
  vacuousRejected: verify.vacuousCases.length,
  device: caps.deviceKind,
  e2eRegression,
  testFilesWritten: gen.filesWritten,
  criticalFailures: criticalFails.map((c) => c.id),
  artifacts: {
    checklist: CHECKLIST,
  },
  note:
    `${CHECKLIST} anotado en su lugar (tri-estado por caso + sección "Solo para ti" + resumen de automatización). ` +
    `Solo debes probar a mano los ${counts.manual} casos 👤 + revisar ${counts.autoFail} 🤖❌. ` +
    `Tests generados SIN commitear — revisa con git diff.`,
}
