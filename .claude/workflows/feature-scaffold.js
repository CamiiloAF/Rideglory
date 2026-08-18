export const meta = {
  name: 'feature-scaffold',
  description:
    'Genera el boilerplate Clean Architecture (domain/data/presentation) para una nueva feature de Rideglory sobre Supabase, capa por capa, con DI injectable, ruta en go_router y keys en app_es.arb, y verifica el resultado con rideglory-code-reviewer',
  phases: [{ title: 'Domain' }, { title: 'Data' }, { title: 'Presentation' }, { title: 'Review' }],
}

const featureName = args
if (!featureName || typeof featureName !== 'string') {
  throw new Error('Pasa el nombre de la feature en args, ej: Workflow({ name: "feature-scaffold", args: "tracking" })')
}

phase('Domain')
const domainSummary = await agent(
  `Lee CLAUDE.md en la raiz del repo (arquitectura Clean feature-first y convenciones criticas) y las migraciones bajo supabase/migrations/ (tablas, enums y politicas RLS existentes). Crea la capa domain/ de la feature "${featureName}" en lib/features/${featureName}/domain/:
- models/: modelos puros de Dart (freezed cuando el modelo tenga varios campos o necesite copyWith), SIN importar Flutter, sin I/O, sin dart:io y sin tocar el cliente de Supabase.
- repositories/: una interfaz abstracta (abstract class ${featureName}Repository o el nombre de dominio que corresponda) cuyos metodos devuelvan Future<Either<DomainException, T>> (dartz).
- usecases/: una clase por accion de negocio, con metodo call(), que dependa solo de la interfaz del repositorio.
Estilo: comillas simples, comas finales, tipos de retorno explicitos, nombres de dominio en las variables. Si ya existen archivos en esa carpeta, respetalos y solo completa lo que falte. NO commitees nada. Devuelve un resumen breve (texto plano) de los archivos creados y de los modelos y casos de uso definidos.`,
  { label: 'domain', phase: 'Domain', agentType: 'feature-scaffolder' },
)

phase('Data')
const dataSummary = await agent(
  `Lee CLAUDE.md y la capa domain/ ya creada en lib/features/${featureName}/domain/ (resumen del agente anterior: ${domainSummary}). Crea la capa data/ en lib/features/${featureName}/data/:
- dto/: DTOs con json_serializable que mapeen las filas de Supabase a los modelos de domain/.
- datasources/: el datasource que habla con el cliente de Supabase (consultas, Realtime o Storage segun aplique). Recuerda que las reglas de acceso viven en la base con RLS: el datasource no reimplementa permisos en Dart, y nunca filtra en el cliente un campo sensible que la consulta ya trajo.
- repositories/: la implementacion concreta de la interfaz de domain/, que atrapa los errores del datasource y los traduce a Either<DomainException, T>. Los mensajes de error visibles al usuario NO se escriben aqui: van en lib/l10n/app_es.arb y los resuelve presentation/.
Esta capa NO importa widgets ni usa BuildContext, y nunca expone DTOs hacia afuera. Registra las clases con las anotaciones de injectable que correspondan (@Injectable(as: XRepository) para el repositorio) y corre dart run build_runner build --delete-conflicting-outputs. Estilo: comillas simples, comas finales, tipos de retorno explicitos. NO commitees nada. Devuelve un resumen breve de los archivos creados.`,
  { label: 'data', phase: 'Data', agentType: 'feature-scaffolder' },
)

phase('Presentation')
const presentationSummary = await agent(
  `Lee CLAUDE.md, y los resumenes de las capas domain/ (${domainSummary}) y data/ (${dataSummary}) ya creadas en lib/features/${featureName}/. Crea la capa presentation/ en lib/features/${featureName}/presentation/:
- cubit/: un cubit @injectable que dependa SOLO de los casos de uso de domain/usecases/ (nunca de repositorios ni del cliente de Supabase), sobre la union freezed ResultState<T> — cero flags booleanos de carga o error. Si el estado tiene dos o mas resultados independientes, una clase @freezed con un ResultState<T> por resultado, en el mismo archivo del cubit. Nada de @singleton ni de getIt desde un widget: el cubit se provee con BlocProvider en el arbol.
- pages/ y widgets/: una pagina minima que consuma el cubit con BlocBuilder, y los widgets que necesite. Un widget por archivo, cero metodos que devuelvan Widget, y todos los textos en lib/l10n/app_es.arb con prefijo de feature, usados con context.l10n.<key> (corre flutter gen-l10n). Deja esbozados los estados obligatorios: contenido, vacio, carga con skeleton (nunca spinner) y error accionable con boton de reintentar.
Usa los componentes compartidos de lib/shared/widgets/ y lib/design_system/ antes que Material crudo. No inventes hexadecimales: usa el tema. Registra la ruta en lib/shared/router/app_routes.dart y lib/shared/router/app_router.dart siguiendo la convencion existente. Estilo: comillas simples, comas finales, tipos de retorno explicitos. NO commitees nada. Devuelve un resumen breve de los archivos creados.`,
  { label: 'presentation', phase: 'Presentation', agentType: 'feature-scaffolder' },
)

phase('Review')
const review = await agent(
  `Revisa todo lo creado en lib/features/${featureName}/ (domain, data, presentation) contra CLAUDE.md: direccion de dependencias correcta (domain sin Flutter ni I/O; data sin widgets ni BuildContext; presentation sin red directa ni DTOs expuestos), ResultState<T> en vez de flags booleanos, Either<DomainException, T> en los repositorios, cubit @injectable provisto con BlocProvider (nunca @singleton ni getIt desde un widget), un widget por archivo, cero metodos que devuelvan Widget, cero strings de UI hardcodeados, y estilo Dart (comillas simples, comas finales, tipos de retorno explicitos, sin print). Corre dart analyze y reporta los errores reales de compilacion. Eres de solo lectura: no edites archivos ni ejecutes git — cada violacion va en el reporte con ruta archivo:linea y la correccion concreta, para que quien la aplique sea feature-scaffolder o flutter-dev. Devuelve un resumen final: que quedo listo, que hay que corregir, y que falta (migracion SQL y RLS en supabase/migrations/, wiring de DI si quedo incompleto, registrar la pagina en la navegacion, diseno en Pencil de las pantallas, tests).`,
  { label: 'review', phase: 'Review', agentType: 'rideglory-code-reviewer' },
)

return { feature: featureName, domainSummary, dataSummary, presentationSummary, review }
