# Backlog de problemas — Rideglory

> Corrida de `/discovery` del 2026-08-18. **Esto es un backlog de problemas, no de features.** Si una entrada se puede leer como una pantalla, está mal escrita — corríjala.
>
> Nada de aquí está aprobado para diseñar. El orden es por frecuencia × severidad × calidad de la evidencia, penalizando lo marcado `[SUPUESTO]`.
>
> **Escala de evidencia** (de más fuerte a más débil): `1` comportamiento observado · `2` hecho verificable · `3` alternativa actual sostenida con esfuerzo · `4` opinión declarada · `5` inferencia de tercero.

---

## P-01 · Nunca hubo distribución: la app no se ha puesto frente a un desconocido

- **Segmento:** el producto (problema de adquisición, no de retención)
- **Frecuencia:** n/a · **Severidad:** crítica · **Evidencia:** nivel 1
- **Evidencia:** hay varios usuarios registrados y **ninguno abre la app hace más de un mes** — pero no se fueron: *"simplemente no promocioné la app, solo le pedí a amigos cercanos que la probaran."* Contradice `CLAUDE.md:22` ("solo había 2 usuarios reales"), ya corregido.
- **Lectura correcta:** la inactividad de alguien que probó por favor **no es señal de falta de valor**. Tampoco es señal a favor: ninguno de esos amigos volvió por su cuenta, y eso es un dato débil pero real. Lo que no existe es el experimento — la app nunca se puso frente a alguien que no le debiera un favor a nadie.
- **Consecuencia para el refactor:** hoy **no hay ninguna fuente de evidencia externa**, y no la habrá mientras no haya distribución. Cualquier decisión de alcance se toma sobre `n=1`, y conviene decirlo en voz alta en vez de fingir que un backlog lo resuelve.
- **Contaminación adicional a tener presente:** `docs/sentry-bug-report-2026-06-16.md` registra 9 issues Flutter + 1 NestJS sin resolver en 24 h en ese mismo periodo (500 del gateway al cargar mantenimientos, `PlatformException` de Mapbox, "Cannot emit after close"). Si alguno de esos amigos abandonó por algo, pudo ser eso.
- **Pregunta abierta:** ¿cuántos son, y qué responden los que se puedan contactar cuando se les pregunte **qué estaban intentando hacer** la última vez que abrieron la app — no qué les gustaría que tuviera? Con amigos hay que preguntar con cuidado: van a decir cosas amables.

## P-02 · El historial de mantenimiento se pierde

- **Segmento:** dueño de moto, con o sin rodadas
- **Frecuencia:** recurrente (declarada) · **Severidad:** alta · **Evidencia:** nivel 3
- **Evidencia:** *"Fue la razón principal por la que creé la aplicación, porque no lo llevo, se me perdían esas cosas... esta llanta ya se me acabó, ¿cuánto me duró? Y no recordaba cuándo la cambié ni cuántos kilómetros tenía. Hace un año lo que yo hacía era que tomaba fotos del kilometraje y me las enviaba a un grupo de WhatsApp donde estaba solo."*
- **La señal más fuerte del set:** hubo **workaround sostenido con esfuerzo** antes de que la app existiera. Penalización honesta: `n=1`, y ese 1 construyó la app.
- **JTBD:** *cuando una pieza se me acaba, quiero saber cuándo la puse y con cuántos kilómetros, para juzgar si me duró lo que debía.*
- **Pregunta abierta:** en la base que todavía existe, ¿cuántos registros de mantenimiento hay de usuarios distintos del fundador? Un solo usuario ajeno con dos registros convierte esto de anécdota en patrón incipiente.

## P-03 · Toda la propuesta "en marcha" descansa sobre cero rodadas observadas

- **Segmento:** el producto entero
- **Frecuencia:** n/a · **Severidad:** crítica · **Evidencia:** `[SUPUESTO]` declarado por el propio usuario
- **Evidencia:** *"Es un supuesto. Así me imagino que hubiese sido la rodada basado en experiencias anteriores."* En la única rodada real el tracking nunca arrancó. Contraevidencia del mismo usuario: casi no mira el mapa, solo cuando se pierde y *"generalmente parando"*, con el manubrio ocupado por Waze o Maps.
- **Trabajo comprometido:** eventos (286 archivos) + tracking (58) + SOS + permiso de ubicación en segundo plano.
- **Pregunta abierta:** ¿se hacen tres rodadas reales con el tracking encendido —aunque sea con la app actual y sus crashes— antes de fijar el alcance del mapa, o se construye sobre el supuesto? ¿Y quién las organiza, si en la única que hubo el organizador olvidó iniciarla?

## P-04 · No hay ninguna razón demostrada para abandonar WhatsApp

- **Segmento:** el producto y su dueño (problema de negocio)
- **Frecuencia:** n/a · **Severidad:** crítica · **Evidencia:** nivel 4 + ausencia verificada en código
- **Evidencia:** dos citas del mismo usuario, enfrentadas: *"Honestamente, creo que todo se hace directamente por WhatsApp. Toda la coordinación se puede hacer allí, no hay ningún lío"* frente a *"lo que me va a hacer ganar recursos... va a ser la comunidad y las personas que interactúen en los eventos."* En código: 0 resultados de parche/grupo/club en `app_es.arb`, "Seguir" abre un sheet "Muy pronto", no hay búsqueda de riders.
- **Límite que él mismo fijó:** *"la coordinación toda se puede hacer por WhatsApp, pero ya a nivel de cuando uno está inmerso en una ruta, conviene que uno sea autónomo."*
- **Pregunta abierta:** ¿qué hace un evento en Rideglory que un mensaje de WhatsApp con hora, punto y link no haga ya? ¿Y qué hecho concreto y observable, en 60 días y sin que el fundador lo organice, se aceptaría como prueba de que la comunidad **no** va a ocurrir?

## P-05 · El SOS dice "enviado" sin que nadie lo haya confirmado

- **Segmento:** rider en emergencia
- **Frecuencia:** ningún SOS real se ha enviado nunca · **Severidad:** crítica · **Evidencia:** nivel 2 (código)
- **Evidencia:** `tracking_ws_client.dart:59-75` — `publishSos` es `void` y termina en `_channel?.sink.add(...)`; `live_tracking_cubit.dart:457-467` emite `hasSentSos: true` en la línea siguiente. Sin SMS en todo el repo (0 resultados de `scheme: 'sms'`), sin persistencia local, sin cacheo del contacto de emergencia. `CLAUDE.md:80` documenta este defecto como **ya ocurrido en producción** — sigue vivo.
- **Lo que el usuario pidió, textual:** *"que la aplicación diga que no hay señal, que se enviará tan pronto la recupere, y se encole esa llamada hacia el backend."*
- **Pregunta abierta:** ¿Rideglory llama al 123 o explícitamente **no** lo hace? El usuario dijo las dos cosas en la misma respuesta (*"se podría llamar al servicio de emergencias"* vs *"no necesito emergencias, necesito alguien que venga por mí"*), y son dos productos con responsabilidades legales distintas.

## P-06 · En una emergencia el SOS está detrás de cinco pantallas

- **Segmento:** rider en emergencia, dentro o fuera de una rodada
- **Frecuencia:** raro · **Severidad:** crítica · **Evidencia:** nivel 4 + código
- **Evidencia:** el usuario enumeró la cadena solo: *"tendría que abrir el teléfono, abrir la aplicación, abrir el evento, buscarlo, abrir el mapa."* En código: el FAB de SOS vive únicamente en la pantalla de tracking, alcanzable solo con `event.state == inProgress` y `RegistrationStatus.approved`.
- **Contradicción sin resolver:** fuera de un evento nadie comparte ubicación ni recibe el broadcast, así que un SOS "siempre accesible" hoy no tendría a quién avisar.
- **Pregunta abierta:** si se pulsa el SOS un martes yendo al trabajo, sin rodada activa: ¿quién exactamente lo recibe, cómo sabe dónde estás, y en qué se diferencia del SOS que ya trae el teléfono?

## P-07 · Nadie se entera de que un compañero se quedó atrás

- **Segmento:** grupo en marcha (el incidente ocurrió fuera de la app)
- **Frecuencia:** incidente raro, disparador falso cada rodada · **Severidad:** crítica · **Evidencia:** nivel 1 (incidente real, sin app)
- **Evidencia:** *"Un carro le pegó por detrás y lo hizo caer... mientras conversaba con él, un pasajero se bajó y le robó una maleta. Fueron dos sucesos de los que nadie se dio cuenta, porque nadie supo que esta persona se detuvo."*
- **Hallazgo que el usuario aceptó en la entrevista:** el afectado **no** habría pulsado ningún SOS — estaba negociando de pie con el conductor. Lo que falló fue que el grupo de adelante nunca supo que se detuvo.
- **Restricción dura, que el usuario identificó solo:** *"son más las razones que no conllevan peligro por las que una persona pueda detenerse... yo creería que unas cinco [falsas alarmas] y ya se vuelve cansón."* La tasa base juega en contra de cualquier detección automática.
- **Pregunta abierta:** en la rodada que sí hicieron, ¿cuántas veces se detuvo alguien más de un minuto por razones normales? Si fueron más de cinco, cualquier detección automática se apaga sola el primer día.

## P-08 · El plan acordado deja de estar vigente y nadie se entera

- **Segmento:** participante que no conoce la ruta; organizador e inscritos
- **Frecuencia:** cada rodada (declarada) · **Severidad:** alta · **Evidencia:** nivel 1, tres relatos convergentes
- **Evidencia:** *"Habíamos quedado en ir a un pueblo, pero nunca dijimos a qué lugar del pueblo... fueron directo al parqueadero, sin decir nada. Perdimos algunos minutos valiosos."* · *"Generalmente hay cambios en la ruta... esas paradas o desvíos no son planificados."* · *"Hay que ver contingencias un día antes, que haya derrumbes."*
- **Contraste que baja su prioridad:** la capacidad ya existía — `EventModel` soporta waypoints con label y `routeGeoJson`, y `meetingPoint` se deriva del primero. Falló que el dato no se llenó o no se mostró a tiempo, no que faltara. Y no existe ningún tipo de notificación de cambio de evento o ruta en `notification_dto.dart:44-88`.
- **Pregunta abierta:** en esa rodada, ¿el organizador puso el destino en la app y ustedes no lo vieron, o nunca lo puso? La respuesta cambia todo: si la app no lo exige, si no lo muestra cuando toca, o si la gente no lo llena.

## P-09 · La rodada transcurre sin seguimiento porque alguien olvidó pulsar "iniciar"

- **Segmento:** participante inscrito y organizador
- **Frecuencia:** falló 1 de 1 · **Severidad:** crítica · **Evidencia:** nivel 1
- **Evidencia:** *"No logré utilizarla, el organizador olvidó iniciar la rodada."* Se dieron cuenta **al final**, *"cuando nadie apareció en el mapa."* En código: la barra "Seguir rodada en vivo" solo se pinta si `event.state == inProgress`, y **no existe ningún tipo de notificación de inicio de evento** en el catálogo de `notification_dto.dart`.
- **Patrón:** el fallo fue **mudo** durante horas — el mismo patrón del SOS.
- **JTBD:** *cuando arranca la rodada, quiero que el grupo quede visible sin que dependa de que alguien se acuerde de pulsar un botón.*
- **Pregunta abierta:** si el organizador olvidó **iniciar**, ¿qué garantiza que se acuerde de **terminar**? Hoy el apagado del tracking depende de eso.

## P-10 · Perder el contacto con el grupo obliga a depender de que alguien conteste

- **Segmento:** participante en marcha
- **Frecuencia:** desconocida (un episodio) · **Severidad:** alta · **Evidencia:** nivel 1, irrepetido
- **Evidencia:** *"Quedamos en la iglesia del parque mientras los otros compañeros ya habían encontrado un parqueadero, pero no sabíamos nada de ellos. Tocó llamarlos y esperar que nos enviaran la ubicación. Nos toca esperar unos cinco minutos o diez."* La ubicación llegó **por WhatsApp**.
- **El costo no fue solo tiempo:** *"Había policía de tránsito en el pueblo, por lo que pensamos que habían tenido algún altercado con ellos."* La incertidumbre escaló a miedo — y el miedo real fue un retén, no un accidente.
- **Pregunta abierta:** ¿cuántas veces en las últimas cinco salidas —con app o sin ella— hubo que llamar a alguien para saber dónde estaba? ¿Y qué se hizo mientras tanto: esperar, seguir, o devolverse?

## P-11 · Los vencimientos de SOAT y RTM dependen de terceros con datos desactualizados

- **Segmento:** dueño de moto, especialmente de moto comprada de segunda sin traspaso
- **Frecuencia:** anual · **Severidad:** alta (multa, inmovilización) · **Evidencia:** nivel 2 (hecho legal)
- **Evidencia:** *"Muchas veces estos mensajes no llegan, porque tal vez la moto cambió de propietario pero no hicieron traspaso, o no actualizó bien el número de teléfono... No es una información del todo fiable."* SOAT y RTM son obligatorios en Colombia y vencen cada año.
- **Hueco verificado:** existen los tipos `SOAT_30D/7D/DAY_OF` pero **ningún tipo de notificación de RTM**, pese a que `docs/features/vehicle_documents.md` los declara delegados al backend. Y todos los programa el NestJS declarado muerto.
- **Pregunta abierta:** ¿alguna vez llegó al teléfono de alguien un recordatorio de SOAT enviado por la app? ¿Y uno de tecnomecánica? Necesitamos saber si esto funcionó de verdad o solo está escrito en la documentación.

## P-12 · El documento no está a la mano cuando se necesita

- **Segmento:** dueño de moto en un retén; dueño que presta la moto
- **Frecuencia:** desconocida · **Severidad:** alta cuando ocurre · **Evidencia:** nivel 4 + código
- **Evidencia:** *"Esos documentos son útiles para un retén de tránsito. Y hay personas que prestan su moto, entonces es más fácil que lo compartan desde allí."* Dolor real reportado: *"El SOAT a veces lo elimino por limpiar información de mi dispositivo y se me pierde."*
- **Ironía verificada en código:** `document_downloader.dart:52-57` cachea el archivo en el **directorio temporal del SO** — exactamente lo que borra el "limpiar el dispositivo" que él dice hacer. Y no existe ninguna función de compartir el documento.
- **Pregunta abierta:** en el último retén, ¿de dónde se sacó el documento — de la app, de la galería, del físico, del correo? Si no fue de la app teniéndola instalada, el problema no es guardarlo sino llegar a él en ese momento.

## P-13 · El dato de emergencia solo se captura inscribiéndose a una rodada

- **Segmento:** cualquier usuario con cuenta; organizador que necesita usarlo
- **Frecuencia:** desconocida · **Severidad:** alta · **Evidencia:** nivel 2 (solo código) — `[SUPUESTO]`: el usuario nunca lo mencionó
- **Evidencia:** `edit_profile_page.dart:33-36` — `_save()` valida el formulario y hace `context.pop()` **sin llamar ningún use case**; el botón de entrada se eliminó en el commit `6607bee`, así que la pantalla es inalcanzable. La única vía real de captura es `RegistrationFormCubit` con `saveToProfile`. Del lado del uso: el organizador ve nombre y teléfono como texto plano en `RegistrationDetailPage`, **sin botón de llamar** (el único `tel:` del repo está en `sos_banner.dart:30`) y con red obligatoria.
- **Que nadie notara la rotura en meses es señal débil pero real de que ese flujo no se usaba.**
- **Pregunta abierta:** ¿qué pasa si el participante no marcó el opt-in de contacto o de información médica? ¿Una rodada de marca acepta un registro de emergencia donde la mitad de las casillas pueden venir en blanco?

## P-14 · Los datos de emergencia de una rodada de marca viven en un Google Forms inaccesible

- **Segmento:** organizador de rodada oficial de marca o empresa
- **Frecuencia:** desconocida · **Severidad:** alta · **Evidencia:** nivel 5 — `[SUPUESTO]`, dolor atribuido, no observado
- **Evidencia:** *"Nunca he hablado con ninguna, pero he participado en rodadas y ellos envían un formulario de Google... si algo pasa en una ruta del domingo van a tener que llamar a esa persona, o con el correo corporativo buscar el formulario."* El usuario habla como **participante**, no como organizador ni tras hablar con una marca.
- **Por qué importa igual:** es el único segmento identificado que podría pagar.
- **Pregunta abierta:** ¿qué marca, qué rodada, quién la organiza? Una sola conversación con un organizador real convierte esto de inferencia en requerimiento.

## P-15 · El odómetro no tiene forma de mantenerse al día

- **Segmento:** dueño de moto que lleva mantenimiento
- **Frecuencia:** desconocida · **Severidad:** media · **Evidencia:** nivel 4 + código
- **Evidencia:** *"Aquí entramos en otro dilema: cuándo se actualiza el kilometraje, porque sí o sí no se puede conectar la aplicación con la moto... Lo que yo hago es que al registrar un mantenimiento nuevo actualizo el kilómetro actual."*
- **El defecto de fondo:** el estado `overdue/next/upToDate` se calcula contra el odómetro actual con umbrales de 500 km / 30 días — **el aviso depende de un dato que solo cambia cuando ya no hace falta el aviso.**
- **Pregunta abierta:** ¿cada cuánto miraría usted el odómetro real de la moto para actualizarlo, si la app se lo pidiera? Si la respuesta es "casi nunca", los avisos por kilometraje no se sostienen.

## P-16 · Rideglory compite por un manubrio que ya está ocupado

- **Segmento:** participante en marcha
- **Frecuencia:** cada rodada · **Severidad:** alta · **Evidencia:** nivel 4 (autoinforme)
- **Evidencia:** *"Cuando llevo el teléfono en el manubrio es porque prefiero ver el mapa de Maps o Waze, para el tema de las fotomultas, retenes, imprevistos en la vía... Solamente lo uso cuando me pierdo... Entonces cierro el mapa y vuelvo a abrir la aplicación. Generalmente solo lo hago parando."*
- **Consecuencia de alcance:** cualquier diseño que asuma la app abierta en el manubrio durante la rodada contradice el uso declarado. En código, el único enlace a navegación externa es `MapLauncherHelper.openSearchByAddress` desde el detalle del evento — no hay ninguna vía hacia la posición viva del líder.
- **Pregunta abierta:** ¿cuántas veces en una rodada estaría dispuesto a parar para consultar algo en la app? Si es una o ninguna, el mapa en vivo tiene que entregar su valor sin que nadie lo abra.

## P-17 · El rastro se descarta en silencio en zonas sin señal

- **Segmento:** participante en rutas offroad, de montaña y con túneles
- **Frecuencia:** desconocida · **Severidad:** alta · **Evidencia:** nivel 4 + código
- **Evidencia:** *"Hay grupos que hacen salidas offroad y entramos a montaña donde se pierde [la señal], o en algunos túneles."* En código: `tracking_ws_client.dart:86-92` hace `return` mudo si el canal es null, y la reconexión es un `Timer` fijo de 2 s sin backoff ni cola. `REQUIREMENTS.md §10.4-10.5` prometía ambos; ninguno existe.
- **Consecuencia:** no hay forma de distinguir "no hay nadie en el mapa" de "no tengo señal" — que es justo el momento en que importa.
- **Pregunta abierta:** ¿cuánto tiempo sin rastro de un compañero es normal en una ruta suya, y a partir de cuánto sí hay que preocuparse? Sin ese número no se puede diseñar el estado "sin señal".

## P-18 · La ubicación se comparte sin consentimiento informado ni parada visible

- **Segmento:** cualquier participante que comparte ubicación
- **Frecuencia:** cada rodada · **Severidad:** alta (riesgo legal) · **Evidencia:** nivel 2 (código) — `[SUPUESTO]`: el usuario no lo mencionó
- **Evidencia:** `splash_cubit.dart:25` dispara el diálogo del sistema en el **primer arranque**, sin pantalla de contexto; `location_permission_handler.dart:52-79` encadena hasta `locationAlways` sin aviso propio; 0 resultados de `stopSharing`; el apagado depende del broadcast WS `tracking.event.ended`, el mismo transporte que descarta mensajes en silencio. `LiveTrackingSessionHolder` es un `@lazySingleton` cuyo docstring declara que existe para mantener GPS y WS vivos **después** de salir del mapa.
- **Riesgo concreto:** el teléfono de un participante puede quedar transmitiendo indefinidamente si el organizador no cierra la rodada — que es exactamente lo que pasó 1 de 1 veces con "iniciar".
- **Pregunta abierta:** ¿el participante debe poder dejar de compartir su ubicación en cualquier momento aunque la rodada siga activa? (El contrato dice que sí; el código no lo permite.)

## P-19 · Pico y placa

- **Segmento:** dueño de moto en ciudad con restricción
- **Frecuencia:** desconocida · **Severidad:** baja · **Evidencia:** `[SUPUESTO]` — mención suelta
- **Evidencia:** dicho de pasada dentro de una respuesta sobre otra cosa: *"registren sus vehículos, su SOAT, cuándo tienen pico y placa, tengan todo eso centralizado."* 0 resultados de "pico" en `lib/`. **No hay historia detrás, ni frecuencia, ni costo declarado.**
- **Pregunta abierta:** ¿cuándo fue la última vez que sacó la moto un día de pico y placa sin darse cuenta, y qué le costó? Sin esa historia, esto no es un problema levantado y no debería entrar a diseño.

---

## Afirmaciones que hoy no se pueden probar ni refutar

No son problemas. Son creencias que sostienen decisiones caras, y conviene tenerlas a la vista:

| Afirmación | Por qué no es evaluable hoy |
|---|---|
| Las marcas adoptarían Rideglory para sus rodadas oficiales | Ni una conversación, ni un correo, ni el nombre de una empresa en todo el repo |
| El garaje funciona como gancho y la gente "por ahí derecho se antoja" de los eventos | Ningún embudo medido: 0 exports de GA4, 0 conteos de sesión, 0 retención |
| Con un botón siempre accesible el SOS "se volvería costumbre" | El propio usuario nombra la adopción como requisito, pero requiere muchas rodadas con muchos riders |
| Un impacto se puede detectar por acelerómetro | El usuario mismo duda. No hay paquete de sensores ni línea de detección de caída |
| Cinco falsas alarmas es el techo de tolerancia | Número producido en la entrevista, sin ninguna medición detrás. Podrían ser dos o quince |
| Si el grupo se hubiera enterado, se habría evitado el robo de la maleta | Contrafáctico sobre un incidente que ni siquiera ocurrió con la app |
| La foto de portada obligatoria hace que el evento "se venda" mejor | Ni una inscripción medida, ni comparación entre eventos con y sin foto |
| "La app solo tiene derecho a existir en marcha" | Límite declarado por el fundador desde `n=1`. Puede ser la mejor decisión del proyecto o un autolímite equivocado |
| Tener el SOAT en la app evita el dolor de cabeza en un retén | Nunca se ha mostrado desde Rideglory en un retén real, y el caché vive en el directorio temporal del SO |
| Los usuarios que se fueron lo hicieron por falta de valor | Indistinguible de abandono por app rota: 9 issues Flutter + 1 NestJS sin resolver en el mismo periodo |
| Otras personas llevan el mantenimiento en libreta o Excel y necesitarían cargarlo por foto | Un pedido de una sola persona, filtrado por el juicio del constructor, que además lo desestimó |
