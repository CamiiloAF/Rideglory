# Fase 10 — Auditoría no-PII transversal y documento de QA de analítica

- Slug del plan: `analytics-crashlytics-cobertura-total`
- ID de fase: **10** (esquema 1..11 de `05-sintesis.md`)
- Depende de: **2, 3, 4, 5, 6, 7, 8, 9**
- ¿UI nueva? **No**. ¿Añade call sites de analítica? **No** (es revisión + documentación).
- Estado de captura: **n/a** (esta fase no instrumenta; verifica lo ya instrumentado).
- Fecha de redacción (UTC): 2026-06-04T01:08:35Z

> Sesión de PLANEACIÓN. Este archivo NO modifica código de la app. Describe el trabajo
> que un ejecutor hará después, bajo `/iter`/`rg-exec`.

---

## Objetivo

El equipo obtiene **garantía documentada de cero PII** en toda la analítica y el crash
reporting (fases 2–9) y un **procedimiento de QA reproducible** para validar la analítica
en GA4 DebugView y en la consola de Crashlytics. La fase **no bloquea** la fase 11 (UI de
opt-out): los hallazgos de la auditoría se registran como **tareas** independientes.

El cierre de esta fase responde una sola pregunta de forma verificable: *¿qué eventos,
parámetros y custom keys salen del dispositivo, y ninguno de ellos contiene PII ni valores
de alta cardinalidad?* — más el "cómo lo comprueba cualquiera del equipo".

---

## Alcance (entra / no entra)

### Entra
- **Auditoría no-PII transversal** del catálogo completo de telemetría producido por las
  fases 2–9:
  - Todas las **constantes de eventos y parámetros** centralizadas en
    `lib/core/services/analytics/` (taxonomía de la fase 2).
  - Todos los **call sites** que invocan `AnalyticsService.logEvent` / `logScreenView` /
    `setUserId` / `setUserProperty` en los 11 features.
  - El **mapa canónico ruta→nombre** del observer (fase 3): nombres estables sin `:id`.
  - Los **reportes de no-fatales y custom keys** en `handlerExceptionHttp` (fase 4):
    mensajes/URLs sanitizados, sin body, sin ids dinámicos.
  - El **`setUserId`** de `AuthCubit` (fase 5): siempre hash SHA-256, nunca uid en claro ni
    email.
- **Documento de QA de analítica** (`docs/testing/analytics-qa.md`): procedimiento paso a
  paso para validar eventos en DebugView y no-fatales/custom keys en Crashlytics.
- **Checklist de cobertura no-PII por feature** (11 features): tabla firmable que enumera,
  por feature, los eventos esperados y la marca de "auditado sin PII".
- **Registro de hallazgos como tareas** (formato BUG/TASK del repo) cuando algo incumpla el
  checklist; estas tareas NO bloquean la fase 11.
- Actualización de `docs/testing/TEST_CATALOG.md` si esta auditoría agrega un test de
  regresión no-PII (ver sección Pruebas).

### No entra
- **Cualquier UI**. El opt-out, su switch, persistencia y la política `privacy-policy.html`
  son de la **fase 11**.
- **Añadir o cambiar eventos/params/call sites.** Si la auditoría detecta que falta un
  evento o que un param lleva PII, se **registra como tarea**; el *fix* se ejecuta en la fase
  correspondiente (2–9) o como tarea de seguimiento, no aquí.
- **Cambios de gating, DI o crash handlers** (fase 1).
- **Backend `rideglory-api`** (la analítica es 100% client-side).
- **Performance/rendimiento percibido** (fuera de alcance del plan).

---

## Que se debe hacer (pasos concretos y ordenados)

1. **Construir el inventario de telemetría (fuente de verdad).** A partir de las constantes
   en `lib/core/services/analytics/` (fase 2) y de un grep de call sites, listar en una
   tabla: `evento → params → tipo de cada param → feature → call site (archivo:símbolo)`.
   Incluir `screen_view` (mapa de rutas, fase 3), las custom keys de `handlerExceptionHttp`
   (fase 4) y el `setUserId`/user properties de `AuthCubit` (fase 5).
   - Grep guía (no exhaustivo): `logEvent(`, `logScreenView(`, `setUserId(`,
     `setUserProperty(`, `setCustomKey(`, `recordError(`.

2. **Aplicar el checklist no-PII a cada entrada del inventario.** Reglas (deben quedar
   escritas como tabla de aprobación):
   - **Prohibido en valor de param o nombre de evento:** email, nombre/apellido, teléfono,
     placa/patente, VIN, número/aseguradora de SOAT, lat/lng/coordenadas, id de evento, id de
     registro, id de vehículo, id de mantenimiento, id de otro rider, uid de Firebase en
     claro, FCM token, URL con id, body de request/response.
   - **Permitido:** uid **hasheado SHA-256** vía `setUserId`; categorías/enums estables
     (método de login, estado de SOAT, categoría de error, paso de embudo); contadores
     agregados; booleanos representados como `0/1` `Object` (sin `bool`, por límite GA4);
     nombres de pantalla canónicos sin `:id`.
   - **Cardinalidad:** ningún param debe usar un valor dinámico de alta cardinalidad como
     valor; "ids canónicos de pantalla, nunca el valor dinámico".

3. **Auditar `setUserId` (fase 5).** Confirmar que el único call site (en `AuthCubit`)
   pasa **siempre** el hash SHA-256 y que no existe ningún otro call site que envíe el uid en
   claro, email o nombre. Verificar también que las user properties son categóricas no-PII.

4. **Auditar los reportes de `handlerExceptionHttp` (fase 4).** Confirmar que mensajes y URLs
   van **sanitizados** (sin ids, sin query con id, sin body) antes de `recordError`, y que las
   custom keys no contienen PII. Confirmar que no hay doble-conteo (alineado con la matriz de
   severidad de la fase 4).

5. **Validar límites GA4 sobre el inventario (fase 2).** Confirmar para cada entrada:
   nombre de evento ≤40 chars, key de param ≤40, value string ≤100, params de tipo `Object`,
   sin `bool` crudo.

6. **Escribir el documento de QA de analítica** (`docs/testing/analytics-qa.md`) con:
   - Prerrequisitos (build staging/release; `firebase` DebugView habilitado vía
     `adb shell setprop debug.firebase.analytics.app <package>` en Android / argumento
     `-FIRAnalyticsDebugEnabled` en iOS; estado de captura por build de la tabla de
     `05-sintesis.md`).
   - **Procedimiento DebugView por feature/embudo** (auth, home, events lectura, events
     escritura/aprobación, tracking/SOS, garaje/mant/SOAT, perfil/users/notif): qué acciones
     ejecutar y qué eventos/params esperar (referenciando la taxonomía).
   - **Procedimiento Crashlytics:** cómo forzar un no-fatal de prueba (timeout/5xx), dónde
     verlo categorizado, y cómo confirmar que mensajes/URLs/custom keys están sanitizados.
   - **Verificación no-PII manual:** cómo inspeccionar en DebugView que ningún param lleva los
     campos prohibidos del paso 2.
   - **Gating:** cómo confirmar que en `kDebugMode` los crash handlers no reportan y que la
     suite de tests usa la no-op impl con `setEnabled(false)`.

7. **Escribir la checklist de cobertura no-PII por feature** (dentro del mismo doc o tabla
   adjunta): una fila por feature (los 11), columnas `eventos esperados | params auditados |
   sin PII (✓) | hallazgos | firmado por`.

8. **Registrar hallazgos como tareas.** Cada incumplimiento detectado se anota como tarea
   (formato del repo) con feature, call site, regla violada y fix propuesto. Marcar
   explícitamente que **no bloquean la fase 11**.

9. **(Opcional, recomendado) Añadir un test de regresión no-PII** que congele el inventario
   de constantes de la taxonomía y falle si aparece una key/valor prohibido (ver Pruebas), y
   registrarlo en `docs/testing/TEST_CATALOG.md`.

---

## Archivos a crear/modificar (rutas reales, una linea de "que cambia")

| Ruta | Qué cambia |
|---|---|
| `docs/testing/analytics-qa.md` | **Crear.** Doc de QA de analítica: procedimiento DebugView + Crashlytics + verificación no-PII + gating + checklist de cobertura por feature (11). |
| `docs/plans/analytics-crashlytics-cobertura-total/phases/phase-10-auditoria-no-pii-transversal-y-documento-de-qa-d.md` | **Este archivo** (artefacto de planeación). |
| `docs/testing/TEST_CATALOG.md` | **Modificar (si se añade el test de regresión no-PII)**: registrar el nuevo test y su propósito. |
| `test/core/services/analytics/analytics_taxonomy_no_pii_test.dart` | **Crear (opcional, recomendado)**: test que recorre las constantes de taxonomía y falla ante una key/valor prohibido. |
| `lib/core/services/analytics/` (constantes de taxonomía) | **Solo lectura (auditoría).** No se modifica en esta fase; un hallazgo se registra como tarea, no como edición aquí. |
| `lib/core/http/rest_client_functions.dart` (`handlerExceptionHttp`) | **Solo lectura (auditoría)** de la sanitización de mensajes/URLs/custom keys (fase 4). |
| Call sites de `setUserId`/`logEvent`/`logScreenView` en `lib/features/**` | **Solo lectura (auditoría).** |

> Nota de capa: esta fase no añade código de producción salvo, opcionalmente, un test bajo
> `test/`. No introduce dependencias nuevas ni toca DI. El test de regresión vive en `test/`
> y consume solo las constantes Dart-puras de `core/services/analytics/`.

---

## Contratos / API rideglory-api (o "ninguno")

**Ninguno.** La analítica y el crash reporting son 100% client-side. La auditoría confirma,
entre otras cosas, que el id anónimo se resuelve hasheando el uid en cliente (SHA-256) y que
**no** se tocó `GET /me`. No se añade, cambia ni consume ningún endpoint nuevo.

---

## Cambios de datos / migraciones (o "ninguno")

**Ninguno.** No hay migraciones de BD, ni esquemas, ni claves nuevas de `SharedPreferences`
en esta fase (la clave de opt-out es de la fase 11). La auditoría no persiste datos.

---

## Criterios de aceptacion (numerados, observables, testeables)

1. **Inventario completo.** Existe en `docs/testing/analytics-qa.md` (o anexo) una tabla con
   **todas** las entradas de telemetría (eventos, params con su tipo, `screen_view`, custom
   keys de no-fatales, `setUserId`/user properties), cada una mapeada a su feature y call
   site (`archivo:símbolo`). Verificable cruzando contra `grep -rn 'logEvent(\|logScreenView(\|setUserId(\|setUserProperty(\|setCustomKey(\|recordError(' lib/`.
2. **Cero PII confirmado.** Ninguna entrada del inventario lleva email, nombre, teléfono,
   placa, VIN, aseguradora, número de SOAT, lat/lng, id de evento/registro/vehículo/
   mantenimiento, id de otro rider, uid en claro, FCM token, ni URL/body con id como nombre
   de evento o valor de param. Marcado ✓ por entrada en la checklist.
3. **`setUserId` siempre hash.** Se verifica que el único call site de `setUserId` (en
   `AuthCubit`) envía hash SHA-256 y que `grep` no encuentra ningún `setUserId` con uid en
   claro/email en `lib/`.
4. **No-fatales sanitizados.** En `handlerExceptionHttp` los reportes a `recordError` y las
   custom keys van sin ids/body/URL-con-id; documentado y verificado en el doc QA con un
   no-fatal de prueba.
5. **Límites GA4 cumplidos.** Para cada entrada: nombre de evento ≤40, key ≤40, value string
   ≤100, params `Object`, sin `bool` crudo. Marcado en el inventario.
6. **Checklist no-PII firmado por feature (11).** La tabla de cobertura tiene una fila por
   cada uno de los 11 features con columna "firmado por" diligenciada; los 11 marcan "sin PII".
7. **Doc QA reproducible.** `docs/testing/analytics-qa.md` permite a alguien sin contexto
   previo: (a) habilitar DebugView en Android e iOS, (b) ejecutar el embudo de un feature y
   ver sus eventos, (c) forzar y localizar un no-fatal en Crashlytics, (d) confirmar gating en
   debug/tests. Cada paso es ejecutable sin información implícita.
8. **Hallazgos como tareas, sin bloquear la fase 11.** Todo incumplimiento queda registrado
   como tarea (con feature, call site, regla, fix) y el doc declara explícitamente que estas
   tareas **no** bloquean el opt-out (fase 11).
9. **(Si se implementa)** El test `analytics_taxonomy_no_pii_test.dart` pasa en `flutter test`
   y falla deliberadamente si se introduce una key/valor de la lista prohibida; `dart analyze`
   limpio.

---

## Pruebas (unitarias/widget/integracion)

- **Unitaria (recomendada) — regresión no-PII de taxonomía**
  (`test/core/services/analytics/analytics_taxonomy_no_pii_test.dart`):
  recorre las constantes de eventos/params expuestas por la taxonomía (fase 2) y asegura que
  ninguna **key** ni **nombre de evento** contenga substrings prohibidos
  (`email`, `placa`, `plate`, `vin`, `lat`, `lng`, `lon`, `coord`, `phone`, `token`, `:id`),
  y que ningún nombre exceda los límites GA4 (≤40). Sirve de "candado" para que futuras fases
  no introduzcan PII en constantes. Usa solo Dart puro (sin Firebase), no requiere mocks.
- **Verificación manual reproducible (no automatizable)** — documentada en
  `docs/testing/analytics-qa.md`: DebugView por feature/embudo y Crashlytics para no-fatales.
  Esta fase **no** añade tests de widget ni de integración (no hay UI nueva ni call sites
  nuevos; los tests con mock de `AnalyticsService`/`CrashReporter` por call site ya los
  aportan las fases 2–9).
- **Gating** ya cubierto por la fase 1 (no-op impl + `setEnabled(false)`); esta fase solo
  **documenta cómo verificarlo**, no añade test de gating.

---

## Riesgos y mitigaciones

1. **Auditoría incompleta (un call site se escapa).** Mitigación: el inventario se construye
   por **grep exhaustivo** de los símbolos de telemetría sobre todo `lib/`, no por memoria; el
   test de regresión congela el catálogo de constantes para detectar futuras desviaciones.
2. **PII que entra por el valor dinámico, no por la key.** Una key inocente (`item_id`) con un
   valor de alta cardinalidad. Mitigación: el checklist audita **valor + tipo**, no solo la
   key; DebugView se usa para inspeccionar valores reales en runtime.
3. **El doc QA queda teórico (no reproducible).** Mitigación: criterio de aceptación 7 exige
   que un tercero sin contexto pueda ejecutarlo; incluir comandos concretos de habilitación de
   DebugView por plataforma y un no-fatal de prueba real.
4. **Confundir esta fase con la 11.** Mitigación: separación explícita escrita en el doc y en
   el alcance; hallazgos son tareas que **no** bloquean el opt-out.
5. **Hallazgo grave (PII real en producción) bloqueando todo.** Mitigación: se registra como
   tarea priorizada hacia la fase de origen (2–9), pero la **fase 10 cierra** con el hallazgo
   documentado; el opt-out (11) avanza en paralelo.
6. **Drift futuro tras cerrar la fase.** Mitigación: el test de regresión no-PII + la checklist
   en `docs/testing/` quedan como artefactos vivos referenciados desde `TEST_CATALOG.md`.

---

## Dependencias (fases prerequisito y por que)

- **Fase 2 (taxonomía, mapa de rutas, límites GA4):** define las constantes y las reglas que
  esta auditoría verifica. Sin la taxonomía no hay catálogo que auditar.
- **Fase 3 (screen_view):** aporta el mapa canónico ruta→nombre cuya ausencia de `:id` se
  audita.
- **Fase 4 (no-fatales de red):** aporta los reportes y custom keys de `handlerExceptionHttp`
  cuya sanitización (mensajes/URLs sin ids/body) se audita.
- **Fase 5 (auth + `setUserId`):** aporta el `setUserId` hasheado cuyo hash SHA-256 se
  confirma.
- **Fases 6, 7, 8, 9 (embudos por dominio):** aportan el grueso de eventos/params por feature
  que la checklist no-PII firma feature por feature.

La fase 10 **no** depende de la fase 1 directamente para su contenido (la fase 1 es
prerequisito transitivo vía 2–9) ni de la fase 11 (la fase 11 depende de esta, no al revés).
