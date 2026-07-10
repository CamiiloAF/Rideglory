# Checklist de QA — Borrado en cascada de vehículos, documentos y mantenimientos al eliminar cuenta

**Feature:** Eliminación de cuenta — cascada de datos de dominio (vehículos, SOAT, RTM, mantenimientos, imágenes en Storage)
**Fases cubiertas:** Fase 1 (núcleo de identidad, ya entregada) + Fase 2 (esta fase — 100% backend en `rideglory-api`; en Rideglory Flutter solo se tocó documentación, sin código ni copy nuevo)
**Estado:** Pendiente de aprobación PO

---

## Pre-condiciones

Esta fase no toca la UI: la pantalla y el copy de confirmación de borrado de cuenta ya existen desde fase 1 y no deben verse distintos. Antes de empezar, prepara varias cuentas de prueba **desechables** (NUNCA uses una cuenta real de producción — el borrado es irreversible). No uses `qa1@gmail.com` ni `qa2@gmail.com` si las necesitas para otras pruebas en curso, porque quedarán eliminadas al final de este checklist.

- [ ] Cuenta A (datos completos): 2-3 vehículos, cada uno con SOAT vigente (con foto), RTM vigente (con foto) y al menos 2 registros de mantenimiento por vehículo.
- [ ] Cuenta B (documentos sin foto): al menos 1 vehículo con SOAT o RTM capturado **sin** foto/documento adjunto.
- [ ] Cuenta C (imagen huérfana): 1 vehículo cuya foto se borró manualmente del bucket de Firebase Storage (o cuya URL está corrupta) mientras el registro en la app sigue apuntando a ella.
- [ ] Cuenta D (garage vacío): cuenta nueva sin ningún vehículo registrado.
- [ ] Acceso de lectura a Postgres de `vehicles-ms` y `maintenances-ms` (o a quien pueda correr las queries por ti).
- [ ] Acceso a la consola de Firebase Storage del proyecto (o a `bucket.file(path).exists()`).
- [ ] Acceso a los logs de `api-gateway` (para verificar que los fallos de Storage se loguean sin abortar el flujo).
- [ ] Anota de antemano los IDs/matrículas de los vehículos de cada cuenta y las URLs de sus imágenes/documentos, para poder verificarlos después de borrados.

---

## 1. Eliminar cuenta con datos completos (vehículos, SOAT, RTM y mantenimientos)

> Inicia sesión con la Cuenta A. Ve a Perfil → Eliminar cuenta (o la ruta equivalente ya existente desde fase 1).

| # | Acción | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 1.1 | Abre la pantalla de confirmación de eliminación de cuenta. | La pantalla y el copy se ven exactamente igual que antes de esta fase (menciona que se borrarán motos, documentos e historial). | |
| 1.2 | Confirma la eliminación de la Cuenta A. | La app muestra que la cuenta fue eliminada, sin errores ni pantallas de carga colgadas; te redirige al flujo de login/onboarding. | |
| 1.3 | Intenta iniciar sesión de nuevo con la Cuenta A. | El inicio de sesión falla (la cuenta ya no existe). | |

---

## 2. Eliminar cuenta con documentos sin foto

> Inicia sesión con la Cuenta B (tiene SOAT o RTM sin foto adjunta).

| # | Acción | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 2.1 | Verifica antes de borrar que el vehículo con SOAT/RTM sin foto sigue visible normalmente en el garage. | El vehículo y su documento aparecen en la app sin foto, sin errores visuales. | |
| 2.2 | Confirma la eliminación de la Cuenta B. | El borrado se completa sin error ni mensaje de falla; no se queda cargando indefinidamente. | |
| 2.3 | Intenta iniciar sesión de nuevo con la Cuenta B. | El inicio de sesión falla (la cuenta ya no existe). | |

---

## 3. Eliminar cuenta con imagen huérfana o URL corrupta en Storage

> Inicia sesión con la Cuenta C (tiene una imagen de vehículo borrada manualmente del bucket o con URL corrupta).

| # | Acción | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 3.1 | Confirma la eliminación de la Cuenta C. | El borrado se completa sin error 500 ni mensaje de falla visible para el usuario, a pesar de que una de las imágenes ya no existe en el bucket. | |
| 3.2 | Intenta iniciar sesión de nuevo con la Cuenta C. | El inicio de sesión falla (la cuenta ya no existe): el fallo de borrar una sola imagen no bloqueó el resto del proceso. | |

---

## 4. Eliminar cuenta con garage vacío

> Inicia sesión con la Cuenta D (sin ningún vehículo registrado).

| # | Acción | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 4.1 | Confirma la eliminación de la Cuenta D. | El borrado se completa sin error, de forma tan rápida y fluida como con cualquier otra cuenta. | |
| 4.2 | Intenta iniciar sesión de nuevo con la Cuenta D. | El inicio de sesión falla (la cuenta ya no existe). | |

---

## 5. Regresión visual — pantalla de confirmación sin cambios

> Esta fase es 100% backend; la pantalla de confirmación no debió tocarse. Usa cualquier cuenta de prueba adicional que NO vayas a eliminar (o cancela antes del paso final).

| # | Acción | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 5.1 | Abre Perfil → Eliminar cuenta y compara el texto y diseño con capturas previas a esta fase (si las tienes) o con tu recuerdo del flujo de fase 1. | El copy, los botones y el diseño de la pantalla son idénticos a los de fase 1 — no hay textos, botones ni pasos nuevos. | |
| 5.2 | Cancela el flujo antes de confirmar el borrado. | La cuenta permanece intacta, puedes seguir usando la app con normalidad. | |

---

## 6. Casos de borde

### 6A. Fallo de red durante el borrado

> Con una cuenta de prueba desechable, provoca una desconexión de red justo después de tocar "Confirmar eliminación" (por ejemplo activando modo avión a mitad del proceso, si es posible reproducirlo).

| # | Acción | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 6A.1 | Corta la conexión a internet justo al confirmar el borrado. | La app muestra un error de red claro (no un crash ni una pantalla en blanco); no queda en un estado intermedio confuso para el usuario. | |
| 6A.2 | Restablece la conexión y vuelve a intentar el borrado con la misma cuenta. | El reintento completa el borrado correctamente (o indica claramente que ya no puede continuar). | |

### 6B. Documento sin foto combinado con vehículo con foto en la misma cuenta

> Usa una cuenta con al menos un vehículo con foto normal y otro documento (SOAT o RTM) sin foto, en la misma cuenta.

| # | Acción | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 6B.1 | Confirma la eliminación de esa cuenta mixta. | El borrado se completa sin error; tanto la imagen del vehículo con foto como los registros sin foto se eliminan correctamente (ver verificación técnica 7.3). | |

---

## 7. Verificaciones técnicas (equipo de desarrollo)

> Estas verificaciones requieren acceso a la base de datos, a la consola de Firebase Storage o a los logs del backend. Ejecútalas inmediatamente después de cada borrado de las secciones 1 a 4, usando los IDs anotados en las pre-condiciones.

| # | Verificación | Resultado esperado | ✅/❌ |
|---|-------------|--------------------|-------|
| 7.1 | Query directa a Postgres de `vehicles-ms`: buscar filas de `Vehicle`, `Soat` y `Tecnomecanica` con el `ownerId`/`vehicleId` de la Cuenta A (o cualquier cuenta borrada con vehículos). | No existe ninguna fila para ese `ownerId`/`vehicleId` en ninguna de las 3 tablas. | |
| 7.2 | Query directa a Postgres de `maintenances-ms`: buscar registros de `Maintenance` con el `userId` de la Cuenta A. | Todos los registros de ese `userId` tienen `isDeleted: true` (soft delete, no borrado físico). | |
| 7.3 | En la consola de Firebase Storage (o `bucket.file(path).exists()`), verificar las URLs anotadas de fotos de vehículo, SOAT y RTM de la Cuenta A. | Ninguno de esos objetos existe ya en el bucket. | |
| 7.4 | Revisar los logs de `api-gateway` durante el borrado de la Cuenta C (imagen huérfana). | Se ve un log de advertencia (`warn`) indicando que un archivo individual no se pudo borrar, sin ningún error 500 propagado al cliente ni excepción sin capturar. | |
| 7.5 | Query a Postgres de `vehicles-ms` para la Cuenta D (garage vacío) tras el borrado. | No hay filas huérfanas ni errores en el proceso; el resultado interno reporta 0 vehículos borrados sin haber lanzado excepción. | |
| 7.6 | Confirmar en el schema de Prisma de `vehicles-ms`/`maintenances-ms` que no se agregó `onDelete: Cascade`. | El schema sigue sin `onDelete: Cascade` para estas relaciones (decisión explícita del Architect: borrado explícito en la capa de servicio). | |
| 7.7 | Confirmar que `DELETE /users/me` no cambió de firma ni de respuesta HTTP respecto a fase 1. | El contrato del endpoint público es idéntico; los pasos nuevos son internos vía `MessagePattern` (`hardDeleteAllByOwner`, `softDeleteMaintenancesByUserId`), sin endpoints HTTP nuevos. | |

---

## Resultado final

| Estado | Criterio |
|--------|----------|
| ✅ Aprobado | Todos los casos de las secciones 1–7 marcados como ✅ |
| ⚠️ Aprobado con observaciones | Máximo 2 casos fallidos de baja severidad (por ejemplo, mensajería de error poco clara en 6A), con ticket creado |
| ❌ Rechazado | Cualquier caso de las secciones 1, 2, 3, 4 o 7 (borrado incompleto, error 500, filas/imágenes huérfanas, o cambios no autorizados de copy/UI en la sección 5) marcado como ❌ |

**Revisado por:** ___________________
**Fecha:** ___________________
**Resultado:** ___________________
**Observaciones:** ___________________
