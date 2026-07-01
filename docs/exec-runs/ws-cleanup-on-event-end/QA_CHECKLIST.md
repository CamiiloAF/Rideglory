# Checklist de QA — Cierre limpio de WebSocket y GPS al terminar un evento

**Feature:** WS Cleanup on Event End — cierre de GPS y WebSocket cuando el backend emite `tracking.event.ended`
**Fases cubiertas:** Fase 1 (Flutter — cubit + tests)
**Estado:** Pendiente de aprobacion PO

---

## Pre-condiciones

Antes de empezar, asegurate de tener en la cuenta de prueba:

- [ ] Dos dispositivos (o simuladores) disponibles: uno con cuenta de **organizador** y otro con cuenta de **rider participante**
- [ ] Un evento activo (estado `IN_PROGRESS`) en el que el rider ya se unió al tracking en vivo
- [ ] El rider tiene permisos de GPS concedidos a la app en primer plano
- [ ] Acceso a los logs del backend (o Sentry en entorno de staging) para las verificaciones técnicas
- [ ] Build reciente de la app instalado en ambos dispositivos (la build debe incluir el commit de esta fase)

---

## 1. Flujo principal — Rider activo recibe fin de evento

> Abre la pantalla de tracking en vivo en el dispositivo del **rider**. El mapa debe mostrar su posición y las de los demás participantes. El estado es "en rodada".

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 1.1 | Desde el dispositivo del **organizador**, pulsa el botón "Terminar rodada" en la pantalla de tracking | El organizador ve una confirmación de que el evento fue finalizado | |
| 1.2 | Observa el dispositivo del **rider** inmediatamente después | La pantalla de tracking muestra el estado de fin de sesión (pantalla de resumen o mensaje "La rodada ha terminado") sin que el rider haya hecho nada | |
| 1.3 | Verifica que la pantalla del rider ya no muestra el indicador de tracking activo (ej. punto pulsante, botón de salir de sesión) | El indicador de sesión activa desaparece; la UI refleja `isFinished = true` | |
| 1.4 | Espera 30 segundos sin cerrar la app en el rider | No aparecen errores en pantalla ni la app se congela | |
| 1.5 | Abre la app en el rider y navega a la lista de eventos | El evento aparece con estado "Finalizado" (no "En curso") | |

---

## 2. Flujo del organizador — Terminar evento no afecta su propia UI

> Sigue en el dispositivo del **organizador** después de terminar el evento.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 2.1 | Después de confirmar el fin del evento, observa la pantalla del organizador | La pantalla de tracking del organizador también muestra fin de sesión o navega al resumen | |
| 2.2 | Verifica que el botón "Terminar rodada" ya no está disponible | El botón desaparece o está deshabilitado | |
| 2.3 | Navega hacia atrás o cierra la pantalla de tracking | La navegación funciona con normalidad; no hay pantallas bloqueadas | |

---

## 3. Casos de borde

### 3A. Rider que estaba solo como espectador (sin tracking activo)

> Usa un tercer dispositivo (o simula el escenario) con una cuenta que esté en la pantalla del evento pero **no** haya activado el tracking de ubicación.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 3A.1 | El organizador termina el evento mientras el espectador ve la pantalla | La pantalla del espectador también actualiza el estado a "finalizado" | |
| 3A.2 | Verifica que no aparece ningún error o pop-up inesperado en el dispositivo del espectador | La UI responde limpiamente al fin del evento sin mostrar errores | |

### 3B. Rider que pierde conexión justo al momento del fin

> Pon el dispositivo del rider en modo avión un segundo antes de que el organizador termine el evento, luego restaura la conexión.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 3B.1 | Activa el modo avión en el rider | La app muestra algún indicador de sin conexión o simplemente deja de actualizar el mapa | |
| 3B.2 | Desde el organizador, termina el evento | El organizador ve la confirmación de fin | |
| 3B.3 | Restaura la conexión en el dispositivo del rider | La app del rider eventualmente recibe el evento de fin y muestra la pantalla de sesión terminada (puede tardar unos segundos en reconectar el WS) | |
| 3B.4 | Verifica que el rider no queda en un estado de "en rodada" indefinido | Después de restaurar la conexión, el estado es "finalizado" o el rider puede navegar normalmente | |

### 3C. El organizador termina el evento dos veces (doble tap accidental)

> En el dispositivo del organizador, intenta pulsar el botón "Terminar rodada" dos veces muy rápido (si la UI lo permite).

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 3C.1 | Pulsa "Terminar rodada" dos veces seguidas en el organizador | El sistema procesa el fin del evento una sola vez; no aparecen errores duplicados ni estados inconsistentes | |
| 3C.2 | Verifica en el dispositivo del rider | La pantalla de "finalizado" aparece una sola vez; no parpadea ni se duplica la navegación | |

### 3D. Rider cierra la app y la vuelve a abrir después de que el evento terminó

> El rider no estaba en la pantalla de tracking cuando el organizador terminó el evento.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 3D.1 | Cierra la app del rider completamente (kill) antes de que el organizador termine el evento | La app se cierra sin errores | |
| 3D.2 | El organizador termina el evento | El organizador ve confirmación | |
| 3D.3 | Vuelve a abrir la app en el dispositivo del rider y navega al evento | El evento aparece como "Finalizado"; no hay opción de "unirse al tracking" ni botón de sesión activa | |

---

## 4. Verificaciones tecnicas (equipo de desarrollo)

> Estas verificaciones requieren acceso a los logs del backend, base de datos o herramientas de observabilidad (Sentry / logs del servidor).

| # | Verificacion | Resultado esperado | ✅/❌ |
|---|-------------|--------------------|-------|
| 4.1 | Después de que el rider recibe `tracking.event.ended`, revisar logs del backend durante 60 segundos | No llegan nuevos pings de ubicación (`POST /tracking/location` o WS `location.update`) del rider para ese evento | |
| 4.2 | Verificar en los logs que el WS del rider se cerró (`leaveSession` fue procesado por el servidor) | El servidor registra el cierre limpio de la sesión WS del rider | |
| 4.3 | Correr `flutter test test/features/events/presentation/tracking/` en el repositorio local | 9 tests pasan (4 nuevos + 5 existentes); 0 fallos | |
| 4.4 | Correr `dart analyze` sobre el proyecto | `No issues found!` — cero violaciones nuevas | |
| 4.5 | Verificar en Sentry (si está habilitado en staging) que no hay errores nuevos relacionados con `LiveTrackingCubit` después del evento | No aparecen excepciones no manejadas del cubit en la consola de Sentry | |
| 4.6 | Revisar en logs que el evento de analytics `trackingSessionEnded` fue registrado exactamente una vez por rider al fin del evento | Exactamente 1 evento de analytics por rider; no hay duplicados | |

---

## Resultado final

| Estado | Criterio |
|--------|----------|
| ✅ Aprobado | Todos los casos de las secciones 1, 2 y 4 marcados como ✅, y maximo 1 caso de borde (seccion 3) con observacion menor |
| ⚠️ Aprobado con observaciones | Maximo 2 casos fallidos de baja severidad fuera de las secciones 1 y 4, con ticket creado para seguimiento |
| ❌ Rechazado | Cualquier caso de las secciones **1** (flujo principal) o **4** (verificaciones tecnicas 4.1–4.4) marcado como ❌ |

**Revisado por:** ___________________
**Fecha:** ___________________
**Resultado:** ___________________
**Observaciones:** ___________________
