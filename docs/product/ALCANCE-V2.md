# Alcance de la v2

> Derivado del `/discovery` del 2026-08-18. Convierte los 19 problemas de [`backlog.md`](./backlog.md) y los 21 veredictos de [`PRODUCT-BRIEF.md`](./PRODUCT-BRIEF.md) en un orden de construcción.
>
> **Esto no diseña ninguna pantalla.** Fija qué se construye, en qué orden y bajo qué condición. El diseño viene después, en `/pencil-screen`, y solo para lo que esté aquí aprobado.

## El principio que ordena todo

El refactor no puede empezar por lo más caro, porque lo más caro es también lo que menos evidencia tiene. El orden se deriva de una sola regla:

> **Se construye primero lo que tiene evidencia, y se pone detrás de una validación lo que descansa sobre un supuesto.**

Aplicada a Rideglory eso significa algo incómodo pero defendible: **el garaje y el mantenimiento van primero, y el bloque en marcha —eventos, tracking, SOS— espera al experimento 1** de [`validacion.md`](./validacion.md).

No es una degradación del SOS ni de los eventos. Es reconocer que hoy no sabemos qué mapa construir, y que el experimento que lo dice cuesta tres rodadas y ninguna línea de código.

---

## Bloque 0 · Cimientos (sin decisión de producto pendiente)

Nada de esto está en discusión: es infraestructura o requisito legal. Se hace primero porque todo lo demás se apoya encima.

| Qué | Por qué ahora | Referencia |
|---|---|---|
| Auth de Supabase (Google y Apple) | Decide si los usuarios existentes se recuperan o hay que pedirles crear cuenta. Bloquea la migración | veredicto `redesign` |
| Esquema Postgres con RLS desde el día uno | El enmascarado de datos sensibles **ocurre en la base**. Hoy depende del NestJS que se apaga | `CLAUDE.md` |
| Borrado de cuenta in-app | Requisito de ambas tiendas y de la Ley 1581. Su forma actual ya es correcta — **el modelo de datos debería partir de sus reglas**, no al revés | veredicto `keep` |
| Estados obligatorios de pantalla | Hoy **no existen**: `shared/widgets/states/` tiene 2 archivos y no hay paquete de connectivity. Sin ellos, montaña y túnel terminan en spinner infinito | veredicto `keep` |
| Analítica y observabilidad | Es lo que va a responder qué hace la gente **cuando por fin haya gente**. Instalarlo después es perder los primeros datos, que son los únicos irrepetibles | veredicto `keep` |

**Ventana de corte (decidida el 2026-08-18):** la EC2 con el backend NestJS **se mantiene encendida hasta que la v2 entre a producción**. Ese día se hace el switch: migrar los datos a Supabase, despublicar o actualizar la app en tiendas, y apagar la instancia.

Consecuencias para este bloque:

- **La migración es posible y hay tiempo para prepararla.** El esquema de Supabase puede diseñarse sabiendo qué datos reales tiene que recibir, en vez de a ciegas.
- **Sigue haciendo falta un `pg_dump` ahora, no el día del corte.** Una instancia encendida no es un respaldo: un disco que falla, una factura impaga o un `terminate` accidental pierden la misma data. El dump hay que restaurarlo una vez en local para comprobar que sirve.
- **Rescatar ya los `.env` de cada microservicio y del gateway**, y lo configurado a mano en el servidor (`crontab`, systemd, nginx, certificados). El código está en GitHub — los 8 submódulos existen todos en la org `Rideglory-Backend` — pero los secrets no se commitean.
- **El día del corte hay trabajo de tiendas, no solo de servidor:** una app publicada contra un backend apagado es una app muerta en la ficha, con riesgo de reseñas de una estrella y de remoción en Play.

---

## Bloque 1 · Garaje y mantenimiento (evidencia real)

Es lo único con uso voluntario y recurrente, y el motivo declarado de existencia del producto. Va primero.

| Qué | Problemas que sirve |
|---|---|
| Garaje: motos, odómetro, placa, foto, principal, archivar | P-02 |
| Historial de mantenimiento: servicio, fecha, odómetro, costo, taller, notas | **P-02** — el mejor problema del set |
| SOAT y RTM como documentos: captura, vigencia, y llegar a ellos **sin señal** | P-11, P-12 |
| Recordatorios de vencimiento **que el usuario controla** — incluida la RTM, que hoy no tiene ni un tipo de notificación | P-11 |
| Contacto de emergencia editable **fuera del flujo de inscripción** | P-13 |

**Dos problemas abiertos que hay que resolver dentro de este bloque, no después:**

- **El odómetro (P-15).** El estado "próximo servicio" se calcula contra un número que solo cambia cuando se registra un mantenimiento: el aviso depende de un dato que solo se actualiza cuando ya no hace falta el aviso. Hay que decidir cómo se mantiene al día antes de construir los avisos por kilometraje.
- **El caché de documentos (P-12).** Hoy vive en el directorio temporal del SO — exactamente lo que borra el "limpiar el dispositivo" que el usuario dice hacer. Guardarlo ahí es no resolver el problema.

**Fuera de alcance en este bloque:** escaneo de tarjeta de propiedad (`kill`), carga de mantenimientos por foto (pedido de una sola persona, desestimado por el propio fundador).

---

## Bloque 2 · La rodada, sin el mapa

Se puede construir sin esperar el experimento, porque **no depende del supuesto en marcha**: es coordinación previa, que ocurre parado y con señal.

| Qué | Problemas que sirve |
|---|---|
| Crear y publicar rodada con el mínimo real: **nombre, ruta, fecha, dificultad, destino, foto, gratis por defecto** | P-08 |
| **Destino con punto exacto, no solo ciudad** — el fallo textual de la única rodada real | **P-08** |
| Inscripción con capa legal: opt-in médico y de contacto, sellos de consentimiento, **edad validada en el servidor** | requisito legal |
| Cambio de ruta con aviso a los inscritos (contingencias del día antes) | P-08 |
| **Aviso de inicio de rodada** — que nadie descubra al final que el mapa nunca arrancó | **P-09** |
| Datos de emergencia del participante accesibles al organizador **en la vía, con un botón de llamar** | P-13, P-14 |

**La lección de P-09 aplicada:** el ciclo de vida del evento no puede depender de que una persona se acuerde de pulsar algo sin que nadie se entere si no lo hace. Si sigue habiendo un botón "iniciar", tiene que haber un aviso cuando no se pulsa.

---

## Bloque 3 · En marcha — **bloqueado por el experimento 1**

Mapa en vivo, tracking, SOS y detección de rezagados. **No se diseña ni se implementa hasta que las tres rodadas digan qué se abre y cuándo.**

Lo que ya sabemos que tiene que ser cierto *si* el bloque procede:

- **El SOS es de rescate entre pares**, no médico. Persistencia local antes de la red, cola con reintento al recuperar señal, y la UI nunca dice "enviado" sin confirmación del servidor.
- **La cadena completa se verifica con dos teléfonos** — un rider pulsa, otro lo ve — antes de prometer nada. Nunca se ha hecho ni una vez.
- **La parada de compartir ubicación es accesible siempre**, y el fin del tracking no depende del mismo transporte que puede estar caído.
- **Aviso propio antes del diálogo del sistema**, y el permiso no se pide en el splash.
- **El manubrio está ocupado por Waze.** Cualquier diseño que asuma la app abierta en marcha contradice el uso declarado (P-16).
- **La detección automática de rezagados choca con la tasa base** (P-07). No se construye sin el conteo de paradas normales del experimento 1.

**Condición de entrada al bloque:** resultado del experimento 1 y decisión explícita sobre la pregunta abierta de P-05 — ¿Rideglory llama al 123 o explícitamente no?

---

## Decisiones tomadas durante el diseño (2026-08-19)

| Decisión | Qué se decidió | Por qué |
|---|---|---|
| **Identidad visual** | Se descarta la paleta Asphalt y Space Grotesk. Nueva dirección: **amarillo de señalización en dosis baja** (reservado a la acción principal), **Outfit**, radios grandes, bloques planos. Tema **claro y oscuro** | El fundador rechazó la identidad anterior: *"estos diseños no me dan ganas de usar la aplicación"*. La deseabilidad no es un extra |
| **Barra de navegación** | **MANTENIMIENTO · EVENTOS · GARAJE · PERFIL**. El Home desaparece | El Home estaba en `kill` y el mantenimiento es lo único con uso real. Consultar el historial baja a 1 toque y registrar a 2 |
| **Garaje** | **Galería en dos columnas** (arquetipo D) | Escala a 6-8 motos, no compite con el hero del detalle, y es la que menos se degrada con fotos reales o sin foto |
| **Detalle de moto** | Aprobado por el fundador, con **Documentos en fila ancha** | Mantiene la fecha de vencimiento visible —que es lo que se mira antes de salir o en un retén— y menciona la promesa offline una sola vez |
| **Odómetro** | Se **deriva del kilometraje que ya se pide al registrar un mantenimiento**; corregirlo a mano es la excepción | Un recordatorio cada 15 días le traslada al usuario una tarea que va a ignorar (P-15) |
| **Orientación social** | **Pospuesta**, no descartada | Ver abajo |

### Sobre la orientación social

El 2026-08-19 el fundador planteó reorientar la app como red social para motociclistas y poner Eventos como pantalla inicial. Se **pospuso** por dos razones, y conviene tenerlas escritas para no rediscutirlas desde cero:

1. **Eventos como pantalla de entrada depende de que haya eventos.** Hoy hay una rodada en toda la historia de la app y ningún usuario activo (P-01). Una pantalla inicial que dice "no hay rodadas cerca" es la peor primera impresión posible. El orden de pestañas es reversible: se cambia el día que haya vida social.
2. **La evidencia en contra es del propio fundador**, dicha en el descubrimiento del día anterior: *"todo se hace directamente por WhatsApp... no hay ningún lío"*, *"es como replicarle a WhatsApp, por eso no le hago mucha fuerza"*, y el límite que él mismo fijó — la coordinación se queda en WhatsApp y la app solo vale en marcha.

**Qué destrabaría la decisión:** responder la pregunta abierta de P-04 — *¿qué hace un evento en Rideglory que un mensaje de WhatsApp con hora, punto y link no haga ya?* — y el experimento 3 de [`validacion.md`](./validacion.md): **una** conversación con un organizador de rodadas de marca. Cuesta una llamada y decide si la app se orienta a eventos con fundamento o si se ahorra el trimestre.

## Fuera de la v2

| Qué | Por qué |
|---|---|
| Chat in-app | Descartado por el fundador: *"es más cómodo WhatsApp"* |
| Grupos / comunidad / perfil público / "Seguir" | Sin problema asociado. Él mismo marcó la idea como débil. **Cuidado:** no arrastrar el camino asistentes → detalle de inscripción, que sí es carga útil |
| Home / dashboard | 36 archivos que repiten lo que ya vive en sus pestañas. **Rescatar** el botón de notificaciones y el badge de SOAT antes de borrar, y decidir a qué pestaña cae la app al abrir |
| Escaneo de tarjeta de propiedad | `// TODO` y un PRD. El OCR on-device **no se toca**: lo usa SOAT |
| Pico y placa | Mención suelta, sin historia detrás. Devolverle la pregunta antes de tratarlo como requerimiento |

---

## Lo que este documento asume y podría estar mal

- **Que el garaje merece ir primero por tener la mejor evidencia.** Esa evidencia es `n=1` y ese 1 construyó la app. Es la mejor que hay, no una buena.
- **Que el bloque 2 no depende del supuesto en marcha.** Si el experimento 1 refuta que alguien abra la app en la vía, hay que volver a preguntarse si una rodada en Rideglory aporta algo sobre un mensaje de WhatsApp con hora, punto y link (P-04).
- **Que se puede construir el bloque 1 sin usuarios.** Se puede, pero no se puede *validar*. Mientras no haya distribución (P-01), cada decisión de este documento se toma sobre una sola persona.
