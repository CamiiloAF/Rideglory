# CLAUDE.md

Guía para trabajar en este repositorio. Léela antes de proponer o escribir código. **Este documento es el contrato**: cuando un agente y este archivo difieran, manda este archivo.

## Qué es este proyecto

**Rideglory** es una app móvil en Flutter para la comunidad motera de Colombia: organizar y unirse a **rodadas**, gestionar el **garaje** de motos, llevar el **mantenimiento**, mantener al día los **documentos legales** (SOAT y tecnomecánica) y **seguir al grupo en tiempo real** durante una salida, con **SOS** en caso de emergencia.

UI 100% en **español colombiano**. Se usa al aire libre, con guantes, con sol directo sobre la pantalla, con casco y a menudo sin señal — eso condiciona cada decisión de diseño y de arquitectura.

## Estado: refactor total en curso

El repositorio está en la rama `refactor/v2`, reconstruyendo la app desde cero. Lo que había antes funcionaba y estaba testeado, pero acumulaba decisiones tomadas sobre la marcha y un backend desproporcionado para el producto.

Qué cambia y qué no:

| | |
|---|---|
| **Se conserva** | Los identificadores de app (`com.camiloagudelo.rideglory`), la marca y la paleta, y el archivo de diseño `rideglory.pen` |
| **Se reescribe** | Todo `lib/` desde cero, el modelo de datos, y la infraestructura de agentes |
| **Se elimina** | El backend NestJS (`rideglory-api`, 6 microservicios en una EC2), y con él Retrofit, Dio y toda la capa REST propia |
| **Se descarta** | El backend y el esquema, no necesariamente los datos. Hay **varios usuarios registrados, todos inactivos hace más de un mes** — no se fueron: la app nunca se promocionó, solo la probaron amigos cercanos. Recuperar su garaje, mantenimientos y documentos hacia Supabase es **deseable pero no bloqueante**: si la migración no sale, se arranca con la base vacía. **Sí hay ventana de corte**: la EC2 sigue encendida hasta que la v2 entre a producción, y ese mismo día se migra y se apaga |

Orden de trabajo: **toma de requerimientos → diseño en Pencil → implementación**. No se diseña una pantalla antes de saber qué problema resuelve, y no se implementa una pantalla que no esté diseñada y aprobada.

Mientras el refactor avanza, el código viejo sigue en `main` como referencia de comportamiento. Léelo para entender qué hacía una feature; no lo copies sin decidir si esa feature sobrevive.

## Comandos

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # freezed, json, injectable
flutter gen-l10n                                           # tras tocar un .arb
dart analyze                                               # debe salir limpio
flutter test
flutter test --coverage
dart format lib/
flutter run
```

Tras cambiar **DTOs, modelos freezed, anotaciones de inyección o el `.env`**, regenera con `build_runner`. Tras tocar `lib/l10n/app_es.arb`, corre `flutter gen-l10n`. Los cambios en interfaces de servicio o en la configuración de DI no los toma el hot reload: requieren rebuild completo.

## Arquitectura y decisiones (no cambiar sin justificación)

- **Estado:** `flutter_bloc`, patrón Cubit. Todo resultado asíncrono se modela con la unión freezed `ResultState<T>` (`initial` / `loading` / `data` / `empty` / `error`). **Cero flags booleanos** de carga o error. Estado con dos o más resultados independientes → clase `@freezed` con un `ResultState<T>` por resultado.
- **Datos y backend:** **Supabase** — Postgres con RLS, Auth (Google y Apple), Realtime, Storage y Edge Functions. Las reglas de acceso viven en la base, no en el cliente.
- **Push y analítica:** **Firebase**, únicamente FCM y Analytics. No hay Firestore ni Cloud Functions.
- **Errores:** Sentry. En desarrollo siempre a consola, nunca a Sentry.
- **Inyección:** `get_it` + `injectable`. **Cubits `@injectable` provistos con `BlocProvider` en el árbol**, nunca `@singleton` ni accedidos con `getIt` desde un widget; los cubits globales se leen con `context.read`. Única excepción justificable: el cubit de autenticación, por el router.
- **Navegación:** `go_router`. `context.pushNamed()` para transiciones normales (deja el back funcionando); `context.goAndClearStack(ruta)` solo para cambios de estado de sesión (logout, fin del onboarding). Evita `goNamed` dentro de un flujo de feature.
- **Repositorios** devuelven `Either<DomainException, T>` (`dartz`).
- **Sin modo offline general** — la app asume conexión. **Excepción crítica:** el SOS es durable y funciona sin red (ver abajo).

### Estructura por feature

`lib/features/<feature>/` con tres capas y las dependencias siempre apuntando hacia adentro (`presentation → domain ← data`):

- **`domain/`** — modelos puros, interfaces de repositorio (`abstract class XRepository`), y un caso de uso por acción de negocio. **Prohibido** importar Flutter, hacer I/O o tocar `dart:io`.
- **`data/`** — DTOs, datasources de Supabase e implementaciones concretas de los repositorios. **Prohibido** importar widgets o usar `BuildContext`.
- **`presentation/`** — cubits, páginas y widgets. **Prohibido** llamar a la red directamente o exponer DTOs hacia afuera.

Lo transversal (configuración, tema, l10n, errores, router, utilidades) vive en `lib/core/` y `lib/shared/`.

## Reglas de código (violación de tolerancia cero)

Estas son las que ningún lint cubre y las hace cumplir el subagente `ui-convention-reviewer`:

1. **Un widget por archivo.** Máximo una clase que extienda `StatelessWidget` / `StatefulWidget` / `PreferredSizeWidget` por archivo. La clase `State<T>` sí acompaña a su `StatefulWidget`.
2. **Prohibidos los métodos que devuelven `Widget`.** Nada de `Widget _buildHeader()` ni `Widget _ctaBar(context)`: cada pieza de UI es su propia clase, en su propio archivo.
3. **Cero strings de UI en el código.** Todo texto visible va en `lib/l10n/app_es.arb` y se usa con `context.l10n.<key>`, con prefijo de feature (`event_`, `vehicle_`, `maintenance_`). **Esto incluye los mensajes de error de red y de autenticación**, que en la versión anterior estaban incrustados en Dart.
4. **Nunca Material crudo si existe el equivalente compartido.** Revisa `lib/shared/widgets/form/` y `lib/design_system/` antes de escribir un control. La app tiene **un solo switch**: `AppSwitch` / `AppSwitchTile` — nunca `Switch`, `SwitchListTile`, `CupertinoSwitch` ni `FormBuilderSwitch`.
5. **Sobre el naranja primario, todo va oscuro.** Texto, iconos, el knob de un switch encendido y los badges sobre `#f98c1f` usan `colorScheme.onPrimary` o `#0D0D0F`. **Nunca blanco.** Los badges sobre primario usan un relleno oscuro translúcido.

Además: comillas simples, tipos de retorno explícitos, sin `print`, nombres de dominio en las variables (`vehicle`, `event`, `error` — no `v`, `e`), botones en *sentence case* (`Iniciar sesión`, no `INICIAR SESIÓN`), y `dart analyze` limpio antes de cerrar cualquier cambio.

## Seguridad del rider (reglas de producto, no de estilo)

Las hace cumplir el subagente `safety-compliance-reviewer`, y su veredicto es un gate.

> **Estas reglas describen la v2 que hay que construir, no la app que existe hoy.** El descubrimiento del 2026-08-18 verificó que **ninguna** de ellas está implementada en el código actual. Léelas como criterios de aceptación, nunca como comportamiento que se pueda dar por hecho.

- **El SOS nunca falla en silencio.** Se persiste localmente antes de intentar la red, sobrevive a que maten la app, y toda ruta de fallo termina en alerta entregada o en fallback ofrecido. Nunca en un `return` mudo. *Este defecto está **vivo hoy**, no es historia: `tracking_ws_client.dart` publica el SOS con `_channel?.sink.add(...)` sobre un WebSocket — si el canal está caído la alerta se descarta sin excepción, sin reintento y sin persistencia — y `live_tracking_cubit.dart` emite `hasSentSos: true` en la línea siguiente. Estuvo en producción y sigue igual en `refactor/v2`.*
- **La UI no dice "enviado" hasta que el servidor confirma.** Sin señal, dice que no salió y lo encola; reintenta solo al recuperar cobertura. Hay tramos sin señal reales en el uso previsto: montaña, offroad y túneles.
- **Fallback sin datos**: llamada al contacto de emergencia y SMS con las coordenadas. Esos datos se cachean **al empezar la rodada**, no se leen durante la emergencia.
- **El SOS solo lo cierra una persona**, nunca una desconexión ni el fin del evento.
- **El SOS es de rescate entre pares, no de emergencia médica.** Su razón de ser es que los compañeros que van cerca sepan dónde estás y se devuelvan por ti — eso es lo que el SOS nativo del teléfono no puede hacer, porque no conoce al grupo de la rodada. Si alguna vez llama a servicios de emergencia, es una decisión explícita y configurable, nunca implícita.
- **La ubicación se comparte con consentimiento explícito**, con aviso propio antes del diálogo del sistema, indicador visible mientras está activa y parada siempre accesible.
- **El tracking en background termina de verdad** al terminar la rodada.
- **El enmascarado de datos sensibles ocurre en la base**, con RLS y vistas. El cliente nunca recibe un campo que no le corresponde: filtrarlo en Dart no cuenta, porque el dato ya viajó.
- **Sin permiso de ubicación, sin GPS y sin conexión son estados diseñados**, con mensaje y salida. Nunca una pantalla vacía.

## Requisitos legales (no omitir)

- **Borrado de cuenta dentro de la app**, que borre datos de verdad en Supabase y en Storage, no solo cierre sesión (Apple y Google Play lo exigen).
- **Ley 1581 de 2012** (habeas data, Colombia) como marco principal: los datos médicos son sensibles y requieren consentimiento expreso.
- **Edad mínima 18 años** para inscribirse a una rodada, validada en el servidor.
- **Ubicación en segundo plano**: *prominent disclosure* de Google Play y Apple 5.1.5.
- Las fotos de documentos contienen datos de terceros y la placa: nunca públicas por defecto.
- Los timestamps y versiones de consentimiento son **evidencia legal**: los sella el servidor, son inmutables y sobreviven a la anonimización.

## Diseño (Pencil)

- **Fuente de verdad:** `rideglory.pen`. Está encriptado y solo se lee con las herramientas MCP de Pencil — nunca con `Read` o `Grep`.
- **Reglas escritas:** `design-system/rideglory/MASTER.md` (globales) + `design-system/rideglory/pages/<pantalla>.md` (overrides por pantalla). **Hoy no existen en disco**: se escriben a medida que `/pencil-screen` aprueba cada pantalla. Mientras falten, el `.pen` es la única fuente — que es justo lo que el orden de precedencia de abajo ya establece.
- **Orden de precedencia:** `pages/<pantalla>.md` → `MASTER.md` → y si cualquiera difiere del `.pen`, **manda el `.pen`** y se corrige el `.md`.
- **Gate obligatorio:** mirar el frame antes de implementar una pantalla diseñada no es opcional. El `.md` *describe* el diseño; el `.pen` **es** el diseño. **Si Pencil no abre, el desarrollo de esa UI se detiene** — no se implementa a ciegas. Esto ya produjo deriva real: en una iteración temprana el agente de diseño no pudo abrir Pencil e inventó los diseños en HTML.
- `flutter-dev` tiene acceso de **solo lectura**; escribir en el `.pen` es exclusivo de `pencil-designer`.
- **Nunca hardcodear un hex**: usar la variable del `.pen`.

### Identidad visual

Dark-only, paleta *Asphalt*. **Los valores mandan desde `rideglory.pen`** (30 variables); esta tabla es su reflejo y se corrige contra el archivo, nunca al revés:

| Rol | Variable del `.pen` | Valor |
|---|---|---|
| Fondo | `$bg-primary` | `#0D0D0F` |
| Superficie | `$bg-secondary` | `#1A1A1F` |
| Superficie elevada | `$bg-tertiary` | `#242429` |
| Card | `$bg-card` | `#1E1E24` |
| Borde | `$border` / `$border-light` | `#2A2A32` / `#3A3A44` |
| Acento | `$accent` / `$accent-light` / `$accent-subtle` | `#F98C1F` / `#FFAB4F` / `#2D2117` |
| Texto sobre acento | `$text-inverse` | `#0D0D0F` |
| Texto | `$text-primary` / `$text-secondary` / `$text-tertiary` | `#FFFFFF` / `#9CA3AF` / `#6B7280` |
| Estado | `$success` / `$error` / `$warning` / `$info` | `#22C55E` / `#EF4444` / `#EAB308` / `#3B82F6` |
| Tab bar | `$tab-bar-bg` / `$tab-inactive` | `#15151A` / `#6B7280` |

Tipografía **Space Grotesk** (`$font-primary`). Radios `$radius-sm` 8 (inputs, botones), `$radius-md` 12 (cards), `$radius-lg` 16 (cards grandes), `$radius-xl` 24 (bottom sheets). Espaciados `$spacing-xs/sm/md/lg/xl` = 4/8/16/24/32. Navegación con **Pill Tab Bar** flotante de 4 destinos: **MANTENIMIENTO, EVENTOS, GARAJE, PERFIL**. *(El Home/INICIO se eliminó el 2026-08-19: el descubrimiento lo dejó en `kill` por repetir lo que ya vive en otras pestañas, y su puesto lo tomó Mantenimiento, que es lo único de la app con uso real y recurrente. Con eso, consultar el historial cuesta 1 toque y registrar 2.)*

Tono: directo y funcional. Es una herramienta, no una red social.

**Estados obligatorios** en toda pantalla: contenido, vacío, carga (skeleton/shimmer, **nunca spinner**), error accionable (mensaje en español llano **con** botón de reintentar), y los tres propios de esta app: **sin permiso de ubicación, sin GPS, sin conexión**.

**Contexto moto**, que se verifica en cada revisión de UI: legible bajo sol directo, targets ≥48dp para uso con guantes, comprensible en menos de dos segundos con el casco puesto, operable a una mano, y **ninguna interacción compleja diseñada para usarse en marcha**.

## Subagentes, skills y workflows

Definidos en `.claude/` para automatizar este documento. El contexto viaja **en memoria** entre agentes (salida estructurada), no en archivos intermedios; cada corrida deja **un solo artefacto** en `docs/dev-runs/<slug>.md` y **no commitea**.

**Subagentes** (`.claude/agents/`):

| Agente | Rol |
|---|---|
| `product-discovery` | Descubrimiento desde el problema. Adversarial, solo lectura, nunca propone features |
| `architect` | Triage de una petición: tamaño, criterios de aceptación y change map. Solo lectura |
| `flutter-dev` | Implementa en `lib/`. Lectura obligatoria del frame de Pencil antes de tocar `presentation/` |
| `supabase-backend-dev` | Esquema, RLS, Edge Functions, `pg_cron`, Realtime, Storage |
| `sql-migration-helper` | Migraciones SQL versionadas y seguras |
| `feature-scaffolder` | Boilerplate Clean Architecture de una feature nueva |
| `qa-automator` | Dueño del testing: unit, widget, golden y Patrol. Solo escribe en `test/` e `integration_test/` |
| `patrol-e2e-runner` | Solo ejecuta las suites e2e ya escritas. Nunca contra producción |
| `rideglory-code-reviewer` | Convenciones de código y arquitectura. Solo lectura |
| `ui-convention-reviewer` | Las 5 reglas de tolerancia cero de arriba. Solo lectura |
| `safety-compliance-reviewer` | Seguridad del rider, ubicación y datos sensibles. Solo lectura, es un gate |
| `pencil-designer` | Construye y edita pantallas en `rideglory.pen` |
| `ui-ux-reviewer` | Audita diseño dentro de Pencil y anota el canvas |
| `pencil-fidelity-reviewer` | Compara los golden tests contra su nodeId de Pencil. Solo lectura |
| `privacy-legal-officer` | Documentos legales auditando el código real, nunca desde plantilla |

**Convención de artefactos:** `docs/dev-runs/<slug>.md` (una por corrida), `docs/fidelidad-visual-tracking.md`, `docs/patrol-e2e-tracking.md`, `docs/product/` (descubrimiento), `docs/features/<feature>.md` (documentación viva: al cambiar el comportamiento de una feature, actualiza su doc).

## Trampas conocidas

- **Golden tests y Space Grotesk.** Sin desactivar la descarga en runtime de `google_fonts`, los goldens se generan con una fuente de fallback y toda la auditoría de fidelidad visual queda invalidada **sin que ningún test falle**. El helper compartido de `test/support/golden_helpers.dart` debe encargarse de esto.
- **Mapbox no renderiza en golden tests.** Las pantallas con mapa se auditan por sus overlays aislados (banner de SOS, tarjetas de rider, controles); el mapa es un gap conocido y documentado.
- **El SDK de Mapbox es frágil** y la versión anterior acumuló parches defensivos para sus condiciones de carrera. Si vuelve a aparecer, trátalo como conocimiento a documentar, no a esconder tras un `catch` global.
- **Nunca pruebes contra la base de producción.** Usa Supabase local (`supabase start`). Una suite e2e contra producción crea eventos, inscripciones y usuarios reales.
