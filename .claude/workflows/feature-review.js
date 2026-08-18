export const meta = {
  name: 'feature-review',
  description:
    'Revisa una feature de Rideglory en 4 dimensiones (convenciones de codigo, arquitectura Clean, las 5 reglas de UI de tolerancia cero, y seguridad del rider/privacidad), con verificacion adversarial de cada hallazgo antes de reportarlo',
  phases: [
    { title: 'Review', detail: 'agentes por dimension: convenciones, arquitectura, ui-conventions, safety-privacy' },
    { title: 'Verify', detail: 'verificacion adversarial de cada hallazgo' },
  ],
}

const FINDINGS_SCHEMA = {
  type: 'object',
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          file: { type: 'string' },
          line: { type: 'number' },
          summary: { type: 'string' },
          detail: { type: 'string' },
        },
        required: ['file', 'summary', 'detail'],
      },
    },
  },
  required: ['findings'],
}

const VERDICT_SCHEMA = {
  type: 'object',
  properties: {
    refuted: { type: 'boolean' },
    reason: { type: 'string' },
  },
  required: ['refuted', 'reason'],
}

const featureName = args || 'la feature indicada por el usuario en la conversacion'

const DIMENSIONS = [
  {
    key: 'conventions',
    agentType: 'rideglory-code-reviewer',
    prompt: `Lee CLAUDE.md en la raiz del repo. Luego revisa todo el codigo bajo lib/features/${featureName}/ (y lib/core/ o lib/shared/ si esta feature los toca). Busca violaciones de: resultados asincronos modelados con flags booleanos de carga/error en vez de la union freezed ResultState<T>; estados con dos o mas resultados independientes que no usan una clase @freezed con un ResultState<T> por resultado; repositorios que no devuelven Either<DomainException, T> (dartz); cubits registrados como @singleton o leidos con getIt desde un widget en vez de @injectable + BlocProvider en el arbol (la unica excepcion justificable es el cubit de autenticacion, por el router); navegacion con goNamed dentro de un flujo de feature en vez de pushNamed, o cambios de sesion que no usan goAndClearStack; codigo generado desactualizado respecto a los .freezed.dart / .g.dart; y estilo: comillas dobles, tipos de retorno implicitos, uso de print, nombres de una letra (v, e) donde deberia ir el nombre de dominio, botones en MAYUSCULA en vez de sentence case. Devuelve findings con archivo, linea aproximada y detalle. Si no hay codigo aun (solo .gitkeep, el repo esta en refactor total), devuelve findings: [].`,
  },
  {
    key: 'architecture',
    agentType: 'rideglory-code-reviewer',
    prompt: `Lee CLAUDE.md en la raiz del repo, seccion "Estructura por feature". Revisa lib/features/${featureName}/ y verifica la direccion de dependencias presentation → domain ← data, que nunca apunta hacia afuera: domain/ tiene modelos puros, interfaces abstractas de repositorio y un caso de uso por accion de negocio, y NO importa Flutter, no hace I/O, no toca dart:io ni el cliente de Supabase; data/ tiene DTOs, datasources de Supabase e implementaciones concretas de los repositorios de domain/, y NO importa widgets ni usa BuildContext; presentation/ tiene cubits, paginas y widgets que dependen de casos de uso, y NO llama a la red ni al cliente de Supabase directamente ni expone DTOs hacia afuera. Reporta ademas cualquier logica de negocio que viva en el cubit en vez de en un caso de uso, y cualquier import de una feature a otra que deberia pasar por lib/core/ o lib/shared/. Si la feature no tiene codigo aun, devuelve findings: [].`,
  },
  {
    key: 'ui-conventions',
    agentType: 'ui-convention-reviewer',
    prompt: `Revisa todo el codigo bajo lib/features/${featureName}/ buscando exactamente las 5 reglas de tolerancia cero de CLAUDE.md, que ningun lint cubre: (1) mas de una clase que extienda StatelessWidget/StatefulWidget/PreferredSizeWidget en el mismo archivo — la clase State<T> si acompana a su StatefulWidget y no cuenta; (2) metodos o funciones (que no sean build ni un closure builder:) con tipo de retorno Widget o subclase de Widget, tipo Widget _buildHeader() o Widget _ctaBar(context) — cada pieza de UI debe ser su propia clase en su propio archivo; (3) literales de texto visible al usuario en el codigo en vez de lib/l10n/app_es.arb con context.l10n.<key> — esto INCLUYE los mensajes de error de red y de autenticacion, que en la version anterior estaban incrustados en Dart; se excluyen los parametros tecnicos (name, src, package, fontFamily, restorationId, debugLabel, routeName) y los strings fuera de un constructor de widget (excepciones, logs); (4) Material crudo donde existe el equivalente compartido en lib/shared/widgets/form/ o lib/design_system/ — con caso especial: la app tiene UN SOLO switch, AppSwitch/AppSwitchTile, asi que Switch, SwitchListTile, CupertinoSwitch y FormBuilderSwitch son violacion siempre; (5) texto, iconos, knob de switch encendido o badges en blanco (Colors.white, textOnDarkPrimary) sobre el naranja primario #f98c1f — deben usar colorScheme.onPrimary o #0D0D0F, y los badges sobre primario un relleno oscuro translucido. Reporta tambien cualquier hex hardcodeado en vez de la variable del sistema de diseno. Devuelve findings con archivo, linea aproximada y cual de las 5 reglas viola. Si no hay codigo aun, devuelve findings: [].`,
  },
  {
    key: 'safety-privacy',
    agentType: 'safety-compliance-reviewer',
    prompt: `Lee CLAUDE.md en la raiz del repo, secciones "Seguridad del rider" y "Requisitos legales". Revisa lib/features/${featureName}/ (y las migraciones bajo supabase/ y las Edge Functions si esta feature las toca) buscando:
- SOS que puede fallar en silencio: una ruta de fallo que termina en un return mudo, un catch vacio, o una alerta que se descarta si el transporte esta caido (este defecto ya estuvo en produccion en este proyecto: el SOS viajaba por un WebSocket que, si estaba caido, descartaba la alerta sin avisarle a nadie). El SOS debe persistirse localmente ANTES de intentar la red, sobrevivir a que maten la app, y toda ruta de fallo debe terminar en alerta entregada o fallback ofrecido.
- UI que dice "enviado" antes de que el servidor confirme.
- Fallback sin datos (llamada al contacto de emergencia y SMS con coordenadas) que lee los datos del contacto DURANTE la emergencia en vez de usarlos cacheados desde el inicio de la rodada.
- SOS que se cierra por una desconexion o por el fin del evento en vez de por una persona.
- Ubicacion compartida sin consentimiento explicito: sin aviso propio antes del dialogo del sistema, sin indicador visible mientras esta activa, o sin parada siempre accesible.
- Tracking en background que no termina de verdad al terminar la rodada (suscripciones, streams o servicios que quedan vivos).
- Enmascarado de datos sensibles hecho en el cliente (filtrar en Dart un campo que la consulta ya trajo) en vez de en la base con RLS y vistas — si el dato viajo, ya se filtro.
- Datos medicos tratados sin consentimiento expreso (Ley 1581 de 2012), fotos de documentos publicas por defecto, o inscripcion a una rodada sin validacion de edad minima en el servidor.
- Borrado de cuenta que solo cierra sesion en vez de borrar datos reales en Postgres y en Storage.
- Timestamps o versiones de consentimiento sellados por el cliente en vez de por el servidor, o que no sobreviven a la anonimizacion.
- Estados sin permiso de ubicacion, sin GPS o sin conexion resueltos con una pantalla vacia en vez de un mensaje y una salida.
Si nada de esto aplica a la feature, devuelve findings: [].`,
  },
]

const reviewResults = await pipeline(DIMENSIONS, (d) =>
  agent(d.prompt, { label: `review:${d.key}`, phase: 'Review', schema: FINDINGS_SCHEMA, agentType: d.agentType }),
)

const allFindings = reviewResults.filter(Boolean).flatMap((r) => r.findings || [])

if (!allFindings.length) {
  return { feature: featureName, confirmed: [], note: 'Sin hallazgos en la revision inicial.' }
}

log(`${allFindings.length} hallazgos preliminares, verificando cada uno...`)

// Verificacion adversarial: cada hallazgo se somete a un agente que INTENTA
// refutarlo leyendo el archivo real. El sesgo es explicito y deliberado: ante
// duda razonable NO se refuta, porque un falso positivo cuesta una lectura y un
// falso negativo puede costar el SOS.
const verified = await parallel(
  allFindings.map((f) => () =>
    agent(
      `Intenta refutar este hallazgo de revision de codigo en Rideglory. Hallazgo: "${f.summary}" — ${f.detail} (archivo: ${f.file}, linea: ${f.line ?? 'N/A'}). Lee el archivo real (y CLAUDE.md si necesitas confirmar la regla) y decide si el problema existe de verdad o es un falso positivo. Si tienes dudas razonables, marca refuted=false: favorece reportar sobre ocultar.`,
      { label: `verify:${f.file}`, phase: 'Verify', schema: VERDICT_SCHEMA },
    ).then((v) => ({ ...f, verdict: v })),
  ),
)

const confirmed = verified.filter(Boolean).filter((v) => v.verdict && !v.verdict.refuted)

return { feature: featureName, totalRaised: allFindings.length, confirmed }
