# Intake — Eliminación de cuenta (App Store Guideline 5.1.1(v))

_Generado: 2026-07-07T15:49:18Z_

## Fuente

Objetivo entregado directamente en el prompt de la sesión (no es una ruta de archivo existente,
salvo la referencia de contexto `docs/web/delete-account.html`, que sí fue leída completa — ver
abajo). Motivo: Apple rechazó la build 0.0.7 (14) de Rideglory en revisión de App Store citando la
Guideline 5.1.1(v): la app permite crear cuentas pero no ofrece un mecanismo de eliminación de
cuenta **dentro de la app**. El flujo actual (`docs/web/delete-account.html`, solicitud por email
con SLA de 10 días hábiles) no es suficiente porque Rideglory no es una app de una industria
regulada que califique para la excepción de "customer service required" del guideline.

### Contenido relevante de `docs/web/delete-account.html` (leído completo)

Define el compromiso público ya existente con los usuarios sobre qué pasa al eliminar la cuenta —
esto es el contrato que el flujo in-app debe cumplir:

| Dato | Acción prometida | Plazo prometido |
|---|---|---|
| Perfil (nombre, email, foto, datos médicos) | Eliminado | Inmediato |
| Vehículos y fotos asociadas | Eliminado | Inmediato |
| Historial de mantenimientos | Eliminado | Inmediato |
| Documentos SOAT (y por extensión RTM) | Eliminado | Inmediato |
| Token FCM | Eliminado | Inmediato |
| Registros de participación en eventos (histórico) | **Anonimizado** (no borrado) | Se conserva hasta 3 años, sin datos identificables |
| Logs técnicos del sistema | Conservado temporalmente | Auto-eliminados a los 30 días |

FAQ notables del documento que el flujo in-app y sus copies deben respetar o al menos no
contradecir:
- Se puede crear una cuenta nueva con el mismo correo después de eliminar (no hay blacklist de
  email).
- Organizador con eventos activos: la página actual solo "recomienda" cancelar/transferir antes de
  eliminar — no hay bloqueo duro documentado. El flujo in-app debe decidir explícitamente qué hacer
  aquí (bloquear vs. avisar vs. cancelar automático) — ver Preguntas abiertas.
- La página web se conserva tal cual para cumplir el requisito equivalente de Google Play (Data
  Safety / Account Deletion); no se toca en esta planeación salvo que el flujo in-app cambie las
  promesas de retención/anonimización, en cuyo caso el texto debe quedar consistente.

## Objetivo

Diseñar el flujo completo de **eliminación de cuenta dentro de la app** (in-app account deletion)
para cumplir App Store Guideline 5.1.1(v): un endpoint de borrado/anonimización en `rideglory-api`
que limpie los datos del usuario en todos los microservicios y elimine la cuenta de Firebase Auth
vía Admin SDK, más la UI en Flutter (`ProfileActionsList` + confirmación + llamada + logout) que lo
dispare, de forma demostrable en un video para la revisión de Apple.

## Alcance percibido

### Backend (`rideglory-api`, super-repo de 7 submódulos + contracts + common-lib)
- Nuevo endpoint `DELETE /users/me` en `api-gateway`, autenticado con el token Firebase del usuario
  actual (mismo patrón de auth interceptor que ya usa el resto de la API).
- `users-ms`: recibe la orden de borrado, coordina (síncrono u orquestado) la limpieza en los demás
  microservicios y al final invoca Firebase Admin SDK para borrar el usuario de Firebase Auth
  (evita el problema conocido de "requiere reautenticación reciente" del SDK cliente).
- Microservicios/datos afectados, alineado con la tabla de `delete-account.html`:
  - `users-ms`: perfil (nombre, email, foto, datos médicos), preferencias, opt-out de analytics.
  - `vehicles-ms`: vehículos y fotos asociadas (incluye limpieza en Firebase Storage).
  - `maintenances-ms`: historial de mantenimientos.
  - Documentos SOAT/RTM (confirmar en qué MS viven — `vehicles-ms` u otro) y sus imágenes en
    Storage.
  - `notifications-ms`: tokens FCM del usuario.
  - `events-ms`: registros de participación en eventos — **anonimizar**, no borrar (según promesa
    ya publicada), preservando métricas agregadas; decidir manejo de eventos donde el usuario es
    organizador activo.
  - Firebase Storage: barrido de todas las imágenes del usuario (fotos de perfil, vehículos, SOAT,
    RTM).
  - Firebase Auth: borrado del usuario vía Admin SDK.
- Dado que no hay usuarios reales en producción, hard-delete simple es aceptable donde el documento
  público no exige anonimización explícita (perfil, vehículos, mantenimientos, documentos, tokens);
  solo eventos/registros históricos requieren anonimización según lo ya prometido.
- Posible necesidad de una API/mecanismo interno cross-MS (contracts compartidos vía
  `rideglory-contracts`, o llamadas orquestadas desde `api-gateway`/`users-ms`) — a definir por la
  fase de arquitectura/backend, no en este intake.

### App Flutter
- Ítem "Eliminar cuenta" nuevo en `ProfileActionsList`
  (`lib/features/profile/presentation/widgets/profile_actions_list.dart`), siguiendo el patrón ya
  existente de "Cerrar sesión" en el mismo archivo (`ConfirmationDialog` tipo `danger`,
  `ProfileMenuItem` con color de error).
- Confirmación explícita (posiblemente doble: advertencia de irreversibilidad + confirmación final,
  dado que es una acción destructiva de mayor peso que logout) antes de ejecutar el borrado.
- Llamada al nuevo endpoint `DELETE /users/me` vía el repositorio/cubit correspondiente del feature
  `profile` (o `authentication`), manejada con `ResultState<T>` (loading/error/success), sin
  banderas booleanas.
- Al éxito: `signOut` local (mismo patrón que `_logout`: `AuthCubit.signOut()`,
  `VehicleCubit.clearVehicles()`, `ProfileCubit.reset()`) + `context.goAndClearStack(AppRoutes.login)`.
- Manejo de error visible al usuario si el borrado falla (reintentar, o al menos no dejar la cuenta
  en estado inconsistente).
- Strings nuevos en `lib/l10n/app_es.arb` con prefijo `profile_` o `account_` (confirmación de
  título/mensaje, botón, mensajes de error, posible aviso especial para organizadores con eventos
  activos).

### Fuera de alcance explícito (por ahora, salvo que el plan decida lo contrario)
- No se toca `docs/web/delete-account.html` salvo actualización de copy si las políticas de
  retención cambian como resultado de esta fase.
- No se resuelve aquí el mecanismo exacto de orquestación cross-microservicio (saga, llamadas
  síncronas encadenadas, cola de eventos) — queda para la fase de arquitectura/backend dentro del
  plan.
- No se planea en este intake el video de demostración para Apple (es un entregable operativo
  posterior a la implementación, no una fase de código), pero el flujo debe quedar diseñado para
  ser grabable end-to-end en dispositivo físico (crear cuenta → eliminar → confirmación de
  eliminación exitosa).

## Preguntas abiertas

1. **Organizador con eventos activos**: ¿bloquear la eliminación de cuenta hasta que
   cancele/transfiera sus eventos activos, avisar y dejar continuar, o cancelar automáticamente los
   eventos como parte del flujo de borrado? La página web actual solo "recomienda" — el flujo in-app
   necesita una decisión explícita y determinista.
2. **Ubicación de SOAT/RTM en el backend**: ¿viven en `vehicles-ms` como sub-recurso de vehículo, o
   en un microservicio propio? Afecta qué servicio debe limpiar esos documentos e imágenes.
3. **Orquestación cross-microservicio**: ¿el borrado se coordina síncronamente desde `users-ms`
   llamando a los demás MS (riesgo de fallos parciales), o se emite un evento
   (`user.deletion.requested`) que cada MS consume de forma idempotente? Dado que no hay usuarios
   reales, ¿es aceptable un enfoque síncrono simple para v1, o el plan debe invertir en idempotencia
   desde ya?
4. **Fallos parciales**: si el borrado en un microservicio falla a mitad de camino, ¿qué pasa con la
   cuenta de Firebase Auth? ¿Se aborta todo, se reintenta, o se deja la cuenta de Auth borrada igual
   (dado que ya no hay usuarios reales, el riesgo de datos huérfanos es tolerable para v1)?
5. **Confirmación de identidad**: ¿basta con la sesión activa + confirmación en diálogo, o Apple/el
   equipo quiere un paso adicional (reingresar contraseña, código) antes de un borrado irreversible?
   Dado el problema conocido de reautenticación reciente de Firebase Auth client SDK, se asume que
   el borrado de Firebase Auth se hace vía Admin SDK en backend (no requiere reauth del cliente) —
   confirmar que esto es aceptable como único gate de seguridad.
6. **Analytics/eventos de auditoría**: ¿se debe emitir un evento de analytics (`account_deleted`) o
   un registro de auditoría técnico antes de borrar al usuario, dado que después ya no habrá
   `userId` para correlacionar?
7. **Retención de logs técnicos (30 días)** mencionada en la web: ¿es un mecanismo real ya
   implementado, o solo una promesa de copy sin backend correspondiente? Si es lo segundo, ¿debe
   esta fase implementarlo o se documenta como deuda/fuera de alcance?
8. **Reintentos y estado inconsistente en la app**: si el usuario cierra la app durante un borrado en
   progreso (llamada HTTP larga por la orquestación multi-MS), ¿qué UX se ofrece al reabrir (sesión
   ya inválida, cuenta a medio borrar)?
