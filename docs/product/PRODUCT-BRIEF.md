# Rideglory — Brief de producto

> Producto de la corrida de `/discovery` del 2026-08-18. Fuentes: escaneo del código en `refactor/v2` + entrevista con el fundador (único usuario activo).
>
> **Cómo leer este documento.** Todo lo que no tiene respaldo en el código o en una respuesta textual del usuario está marcado `[SUPUESTO]`. La palabra "evidencia" aquí es literal: una cita o una ruta de archivo. Este documento no diseña ninguna pantalla.

## 1. Para quién es la app

Tres segmentos, muy desiguales en evidencia:

| Segmento | Qué hace | Evidencia |
|---|---|---|
| **Dueño de moto que quiere no perder el historial** | Registra sus motos, mantenimientos y documentos. Consulta cuándo puso una pieza y con cuántos km. | **Real y recurrente.** El fundador lo usa hoy. Antes de la app llevaba fotos del odómetro a un grupo de WhatsApp consigo mismo. `n=1`, y ese 1 construyó la app |
| **Participante de una rodada en marcha** | Quiere saber dónde está el grupo y a dónde llegar sin depender de que alguien conteste | **Casi todo `[SUPUESTO]`.** Una sola rodada real, en la que el tracking nunca se inició. El usuario marcó su propia descripción como supuesto |
| **Organizador de rodada oficial de marca o empresa** | Recoge inscripciones con datos de emergencia; hoy usa Google Forms | `[SUPUESTO]` **de segunda mano.** El usuario participó en esas rodadas, nunca habló con una marca. El dolor está atribuido, no observado |

## 2. El límite que fijó el usuario (y que gobierna el alcance)

Textual: *"la coordinación toda se puede hacer por WhatsApp, pero ya a nivel de cuando uno está inmerso en una ruta, conviene que uno sea autónomo y pueda saber dónde está el grupo y a dónde llegar."*

De ahí salen dos reglas de producto:

- **Rideglory no compite con WhatsApp por la coordinación previa ni por lo social.** El propio fundador dice que allí se resuelve *"sin ningún lío"*. Chat in-app: descartado por él mismo. Grupos/comunidad in-app: él mismo los marcó como idea débil (*"es como replicarle a WhatsApp, por eso no le hago mucha fuerza"*).
- **El valor propuesto es la autonomía en marcha:** no depender de que otro conteste. Es la mejor formulación que salió de la entrevista — y descansa sobre un solo episodio.

Con una advertencia dura: **el manubrio ya está ocupado.** El usuario lleva Waze o Maps ahí (fotomultas, retenes, imprevistos) y la mayoría de las veces el teléfono va guardado. Rideglory se consulta puntualmente y **casi siempre parado**, cerrando la app que sí estaba usando.

## 3. Los problemas que resuelve, en orden

Orden por frecuencia × severidad × calidad de la evidencia, penalizando lo marcado `[SUPUESTO]`. El detalle está en [`backlog.md`](./backlog.md).

1. **Nunca hubo distribución.** Hay varios usuarios registrados e inactivos, pero la app jamás se promocionó: solo la probaron amigos cercanos. No hay retención que explicar porque no hubo adquisición — y por tanto no existe hoy ninguna fuente de evidencia externa.
2. **El historial de mantenimiento se pierde.** Evidencia más fuerte del set: hubo workaround sostenido antes de que la app existiera.
3. **Toda la propuesta "en marcha" descansa sobre cero rodadas observadas con tracking encendido.**
4. **No hay ninguna razón demostrada por la que un grupo motero abandone WhatsApp.**
5. **El SOS dice "enviado" sin que ningún servidor lo confirme**, y si no hay canal descarta la alerta en silencio.
6. **En una emergencia el SOS está detrás de cinco pantallas** y solo existe si hay rodada en curso e inscripción aprobada.
7. **Cuando alguien se queda atrás nadie se entera** — y avisar por parada automática choca con la tasa base de paradas normales.
8. **El plan acordado deja de estar vigente y nadie se entera** (destino impreciso, ruta que cambia en marcha y la noche antes).
9. **Perder el contacto con el grupo obliga a depender de que alguien conteste**, y la incertidumbre escala a miedo.
10. **SOAT y RTM vencen cada año y el aviso depende de terceros con datos desactualizados.**
11. **El documento hay que tenerlo a la mano en un retén sin señal**, y poder compartirlo con quien presta la moto.
12. **El contacto de emergencia solo se captura inscribiéndose a una rodada**, y quien lo necesita no lo puede usar.
13. **La app entera depende de una infraestructura ya declarada muerta**, y el refactor no ha empezado.

## 4. Jobs to be done

Los que tienen evidencia real, en las palabras del problema:

- *Cuando una pieza se me acaba, quiero saber cuándo la puse y con cuántos kilómetros, para juzgar si me duró lo que debía y cuándo toca la próxima.* — **evidencia real, recurrente**
- *Cuando pierdo de vista al grupo, quiero saber dónde están sin depender de que alguien conteste el teléfono, para no perder diez minutos parado ni asumir que algo malo pasó.* — un episodio real
- *Cuando un compañero se queda atrás, quiero enterarme antes de alejarme kilómetros, para poder devolverme cuando todavía sirve de algo.* — un incidente real, fuera de la app
- *Cuando quedo tirado, quiero que los que van cerca sepan dónde estoy exactamente, para que se devuelvan por mí sin tener que explicarles dónde es.* — `[SUPUESTO]`, pero es el diferencial defendible del SOS
- *Cuando se acerca el vencimiento del SOAT o la RTM, quiero enterarme por un canal que yo controlo, para no depender de que la aseguradora tenga bien mis datos.* — hecho legal verificable
- *Cuando me para un agente de tránsito, quiero mostrar el documento en segundos aunque no tenga señal.* — `[SUPUESTO]` en el retén; el dolor de perder el archivo sí es real
- *Cuando un participante de mi rodada tiene un problema en la vía, quiero llamar a su contacto de emergencia desde el teléfono que llevo encima.* — `[SUPUESTO]` de segunda mano
- *Cuando arranca la rodada, quiero que el grupo quede visible sin que dependa de que alguien se acuerde de pulsar un botón.* — **evidencia real: falló 1 de 1**

## 5. El mayor supuesto sin verificar

> **Que exista algún problema del rider *en marcha* que justifique abrir Rideglory en la vía.**

Es el supuesto cuyo error invalidaría más trabajo: eventos (286 archivos), tracking (58), el SOS, el permiso de ubicación en segundo plano con su *prominent disclosure* ante ambas tiendas, y la apuesta de negocio completa.

Tres hechos independientes lo empujan hacia el lado equivocado, y los tres salieron del propio usuario:

1. *"Es un supuesto. Así me imagino que hubiese sido la rodada basado en experiencias anteriores."*
2. *"Solamente lo uso cuando me pierdo... generalmente solo lo hago parando"*, con el manubrio ocupado por Waze o Maps.
3. *"Todo se hace directamente por WhatsApp... no hay ningún lío."*

Y un cuarto, del código: la cadena que da sentido al producto — un rider pulsa SOS y otro rider lo ve — **nunca se ha verificado ni una sola vez**. El único e2e que la cubriría declara la recepción cross-user fuera de alcance y está en `skip: true`.

**Es barato de matar:** tres rodadas reales con el tracking encendido, aunque sea con la app actual y sus crashes. Cuesta menos que una semana de refactor.

Si el supuesto resulta falso, lo único que sobrevive es el garaje y el historial de mantenimiento — que es lo único que alguien resolvía con esfuerzo antes de que la app existiera.

## 6. Veredictos por feature construida

`keep` = el problema y la forma se sostienen · `redesign` = el problema es real, la forma falla · `kill` = no sirve a ningún problema de la lista.

Las obligaciones legales y de seguridad no se someten a veredicto de producto: van `keep` o `redesign` por requisito, nunca `kill`.

| Feature | Veredicto | Razón (resumen) | Costo de eliminarla |
|---|---|---|---|
| Garaje (`vehicles`) | **keep** | Única parte con uso real, voluntario y recurrente. Hubo workaround sostenido antes de la app | Es la fuente de verdad de 5 features. Se pierde lo único que hay evidencia de que se echaría de menos |
| Mantenimiento | **keep** | Sirve al problema con mejor evidencia y es el motivo declarado de existencia del producto | Se elimina lo único con uso recurrente demostrado. Es el dato cuyo borrado el usuario lamentó en voz alta |
| SOAT | **keep** | El problema es hecho legal verificable; el canal actual (aseguradora) es demostrablemente poco fiable | Se pierde el único recordatorio implementado punta a punta y el único uso productivo del OCR on-device |
| Inscripción con capa legal | **keep** | Requisito, no elección: Ley 1581, edad mínima, sellos de consentimiento. El enmascarado en servidor está bien hecho | Sin ella no hay forma legal de recoger datos médicos. Es hoy la única vía de capturar el contacto de emergencia |
| Borrado de cuenta in-app | **keep** | Requisito de ambas tiendas y de habeas data. La forma es correcta y poco común de ver bien hecha | Rechazo en revisión de tiendas e incumplimiento legal. Sin decisión de producto que tomar |
| Estados obligatorios de pantalla | **keep** | Requisito de seguridad del rider. **Hoy no existen**: `shared/widgets/states/` tiene 2 archivos, no hay paquete de connectivity | Nada que eliminar. Sin ellos, montaña y túnel terminan en spinner infinito |
| Analítica y observabilidad | **keep** | Único instrumento capaz de responder por qué se fueron los usuarios. Hasta hoy no ha respondido nada | Se pierde la única vía de separar abandono por falta de valor de abandono por app rota |
| Refactor v2 sobre Supabase | **redesign** | La decisión es correcta; el **alcance** está fijado sobre el inventario de features, no sobre los problemas | Nada que perder: no hay una línea escrita. Renunciar deja la app sobre una EC2 que ya se decidió apagar |
| SOS durante la rodada | **redesign** | Requisito de contrato; se condena la **forma**. `publishSos` es `void` y termina en `_channel?.sink.add(...)` | No es opción eliminarlo. Su valor entregado hoy es cero verificado |
| Tracking en vivo | **redesign** | 58 archivos sobre cero rodadas observadas. No existe nada de lo que el usuario dice necesitar en la vía | Se cae la pantalla del SOS, el foreground service y la justificación del permiso en segundo plano |
| Parada del tracking / fin de rodada | **redesign** | Obligación de contrato que el código contradice: no hay control de dejar de compartir; el apagado depende del WS que falla en silencio | Si se quita sin reemplazo el tracking muere al salir del mapa; si se deja, un teléfono puede transmitir indefinidamente |
| Consentimiento y aviso de ubicación | **redesign** | Obligación legal; la forma quema el permiso más caro en el splash, sin pantalla de contexto | No se puede eliminar: sin ella no hay tracking ni SOS, y su ausencia es rechazo en tiendas |
| Rodadas: crear, publicar, ciclo de vida | **redesign** | La feature más grande (286 archivos) falló en el único momento que importaba: nadie pulsó "iniciar" y nadie se enteró | Es la puerta a inscripción, tracking, SOS y asistentes. Sin eventos no hay contexto donde compartir ubicación |
| Tecnomecánica (RTM) | **redesign** | Problema tan real como el del SOAT, pero **no existe ni un tipo de notificación de RTM**. Hoy es registro pasivo | Se pierde la abstracción `vehicle_documents/` que SOAT debería usar y no usa |
| Notificaciones (centro + FCM) | **redesign** | El transporte funciona; el catálogo no incluye ninguno de los eventos que fallaron en la vida real (inicio de rodada, cambio de ruta, RTM) | Se cae el único canal que el usuario controla para los vencimientos legales |
| Perfil propio: edición | **redesign** | Mentira funcional: `_save()` valida y hace `pop()` sin llamar ningún use case, y la pantalla es inalcanzable | Cero técnico — y ese cero **es** el hallazgo: llevaba meses rota y nadie lo notó |
| Autenticación (Firebase Auth) | **redesign** | Habilitador. Decide si los usuarios existentes se recuperan o hay que pedirles crear cuenta de nuevo | No se puede eliminar sin volver la app anónima. Migrar el proveedor tiene costo no cuantificado |
| Home (dashboard) | **kill** | 36 archivos que no sirven a ningún problema. Repite el próximo evento y la moto principal, que ya viven en sus pestañas | Hay que decidir a qué pestaña cae la app al abrir. Rescatar el botón de notificaciones y el badge de SOAT |
| Perfil de otro rider / comunidad | **kill** | Sin búsqueda, sin directorio, sin parche. "Seguir" abre un sheet "Muy pronto". El fundador descartó él mismo el chat y los grupos | **No arrastrar** el camino asistentes → `RegistrationDetailPage`: por ahí el organizador ve el contacto de emergencia |
| Escaneo de tarjeta de propiedad | **kill** | `// TODO` en dos banners y un PRD. Registrar la moto ocurre una vez por vehículo | Casi nulo. El OCR on-device **no** se toca: lo usa SOAT |
| Sistema de diseño escrito (`design-system/`) | **kill** | **No existe en disco**, y el contrato ya resuelve la ambigüedad solo: si el `.md` difiere del `.pen`, manda el `.pen` | Tres skills quedan sin objeto o hay que reapuntarlas. **`rideglory.pen` no se toca**: sigue siendo la fuente de verdad |

> Ningún `kill` se ejecuta en esta corrida. Este documento produce el veredicto y su costo; eliminar código es otro trabajo.

## 7. Correcciones que necesita el contrato (`CLAUDE.md`)

Cuatro afirmaciones del contrato quedaron desmentidas en esta corrida:

1. **"Solo había 2 usuarios reales... no hay migración, ni ETL, ni ventana de corte"** → hay varios usuarios, inactivos hace más de un mes, que **no abandonaron**: la app nunca se promocionó. La migración importa (*"si es posible recuperar esa data... estaría genial"*) pero es **deseable, no bloqueante**. ✅ corregido.
2. **El SOS que fallaba en silencio descrito en pasado** ("un defecto que ya estuvo en producción") → sigue vivo, sin un cambio, en esta rama. ✅ corregido: ahora el contrato cita el archivo y la línea, y añade el requisito de cola offline y la definición del SOS como rescate entre pares.
3. **Las reglas de seguridad del rider redactadas como si describieran la app** → aviso previo de ubicación, indicador visible, parada accesible y fin real del tracking: ninguna implementada. ✅ corregido: la sección abre ahora con una nota de que son criterios de aceptación de la v2, no comportamiento existente.
4. **`design-system/rideglory/MASTER.md`, `pages/*.md`, `docs/dev-runs/`** → no existen en disco, y tres skills dependen de ellos. ✅ corregido: el contrato dice ahora que se escriben a medida que `/pencil-screen` aprueba cada pantalla, y que mientras falten manda el `.pen`.

## 8. Lo que sigue

Antes de diseñar una sola pantalla, hay dos cosas baratas que cambian el orden de todo lo demás:

- **Poner la app frente a alguien que no le deba un favor a nadie.** Hasta hoy solo la probaron amigos cercanos por petición: no hay un solo usuario que haya llegado solo. Sin eso, todo el backlog se decide sobre `n=1`. Y a los amigos que ya la probaron se les puede preguntar qué estaban intentando hacer la última vez que la abrieron — con la advertencia de que van a responder cosas amables.
- **Tres rodadas reales con el tracking encendido.** Es la forma barata de matar o confirmar el mayor supuesto del proyecto.
