# Plan de validación — el supuesto que gobierna el refactor

> Derivado del `/discovery` del 2026-08-18. Sirve a la sección 5 de [`PRODUCT-BRIEF.md`](./PRODUCT-BRIEF.md).
>
> Este documento **no valida nada por sí solo**: deja los instrumentos listos. Salir a usarlos es trabajo de campo, no de código.

## El supuesto

> **Que exista algún problema del rider *en marcha* que justifique abrir Rideglory en la vía.**

De él cuelgan eventos, tracking, SOS y el permiso de ubicación en segundo plano con su *prominent disclosure* ante ambas tiendas. Si es falso, sobrevive el garaje y el historial de mantenimiento — y poco más.

**Regla que hace útil este plan:** se define *antes* qué resultado cuenta como refutación. Un experimento cuyo resultado siempre se puede interpretar a favor no es un experimento.

---

## Experimento 1 · Tres rodadas con el tracking encendido

**Se puede correr con la app actual, crashes incluidos.** No hay que esperar a la v2: el objetivo no es que la experiencia sea buena, es observar si alguien la abre. El backend se mantiene encendido hasta el switch a producción, así que la ventana para correrlo está abierta.

> **Mida el problema, no solo el uso.** La app actual arrastra 9 issues Flutter y 1 NestJS sin resolver, así que "no la abrió" y "se le rompió" son indistinguibles — la misma ambigüedad que ya contamina a los usuarios inactivos. Por eso las filas de la tabla que **no** dependen de la app (cuántas veces alguien preguntó dónde iba el grupo, cuántas paradas normales hubo, si el destino estaba claro) son las más confiables del experimento: se recogen preguntando al final y no las puede romper un crash. Si solo se recoge una cosa, que sea esa.

**Precondición que ya falló una vez:** el organizador tiene que acordarse de pulsar "iniciar". Que lo haga alguien distinto del fundador, y que alguien más se lo recuerde 10 minutos antes.

### Qué observar, y quién

Nada de esto requiere instrumentación nueva: se anota a mano al terminar, en la gasolinera o en el almuerzo.

| Dato | Cómo se recoge | Qué decide |
|---|---|---|
| Cuántas veces cada rider abrió Rideglory durante la rodada | Preguntar al final, uno por uno | Es **la** medida. Si la mediana es 0, el supuesto está muerto |
| En cada apertura: ¿en marcha o parado? ¿qué buscaba? | Misma pregunta | Distingue "consulta parado" de "uso en marcha" — son dos productos |
| Cuántas veces se detuvo alguien más de un minuto por razones normales | Contarlas | Si son > 5, cualquier detección automática de "se quedó atrás" se apaga sola (ver P-07) |
| Cuántas veces alguien preguntó por WhatsApp o llamó para saber dónde iba el grupo | Revisar el grupo al final | Es el problema P-10 medido en su hábitat |
| ¿Alguien perdió el rastro y por cuánto tiempo? | Preguntar | Alimenta el estado "sin señal" (P-17) |
| ¿El organizador puso destino exacto, y los demás lo vieron? | Preguntar a ambos lados | Resuelve la pregunta abierta de P-08 |

### Criterios definidos de antemano

- **Refuta el supuesto:** en las tres rodadas, la mediana de aperturas por rider en marcha es **0**, y ninguna pregunta de "¿dónde van?" se resolvió con la app.
- **Lo confirma:** al menos un rider distinto del fundador abre la app en marcha en cada rodada **para resolver una pregunta concreta**, y lo cuenta sin que se lo sugieran.
- **Resultado intermedio, que es el más probable:** se abre parado, no en marcha. Eso **no** mata el producto, pero sí mata el mapa en vivo tal como está construido — y cambia el alcance hacia "consulta rápida al parar", no hacia telemetría continua.

---

## Experimento 2 · Preguntar a quien ya la probó

Son amigos cercanos que la instalaron por petición. **Van a decir cosas amables**, así que la pregunta tiene que hacer imposible la cortesía.

**Sirve:** *"¿qué estabas intentando hacer la última vez que la abriste?"* · *"¿qué hiciste después de cerrarla?"* · *"¿la volviste a abrir alguna vez sin que yo te dijera?"*

**No sirve:** *"¿te gustó?"* · *"¿qué le agregarías?"* · *"¿la usarías si tuviera X?"* — las tres producen respuestas que se sienten como datos y no lo son.

**Qué buscar:** una sola persona que la haya abierto por su cuenta, sin que se lo pidieran, y para qué. Eso vale más que diez opiniones favorables.

**Contaminación conocida:** en ese mismo periodo Sentry registró 9 issues Flutter + 1 NestJS sin resolver en 24 h (500 del gateway al cargar mantenimientos, crashes de Mapbox). Si alguien dice que "se le trababa", es dato de app rota, no de falta de valor — y hay que anotarlo aparte.

---

## Experimento 3 · Una conversación con un organizador de rodada de marca

El segmento que podría pagar hoy descansa en una inferencia hecha desde afuera: el fundador participó en esas rodadas, nunca habló con quien las organiza.

**Basta una conversación.** Qué preguntar: cómo recogen hoy las inscripciones, quién administra ese formulario, qué pasó la última vez que alguien tuvo un problema en la vía, y quién tuvo que buscar el teléfono del contacto de emergencia.

- **Refuta:** el organizador dice que nunca ha necesitado esos datos en la vía, o que el formulario le funciona bien.
- **Confirma:** cuenta un episodio concreto en que los necesitó y no los tuvo a la mano.

**Coste:** una llamada. Es la validación más barata de todo el plan y la que más alcance decide.

---

## Lo que este plan NO valida

Honestidad sobre los límites, para que nadie los lea como resueltos:

- **Que el SOS "se vuelva costumbre".** Requiere muchas rodadas con muchos riders; tres no alcanzan.
- **Que un impacto se detecte por acelerómetro.** Sin prototipo y sin datos de caídas reales, no es evaluable.
- **Que las cinco falsas alarmas sean el techo real.** El número salió de la entrevista, no de una medición. El experimento 1 lo aproxima contando paradas, pero no lo prueba.
- **Que el garaje funcione como gancho hacia los eventos.** Requiere un embudo medido y usuarios que no existen todavía.
