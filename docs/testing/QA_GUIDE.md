# Guía de QA — Rideglory

**Versión:** Junio 2026  
**App:** Rideglory (iOS / Android)  
**Ambiente:** Desarrollo (flavor `dev`)

---

## Cómo leer este documento

Cada sección es un flujo independiente. Para cada paso se indica:
- Lo que hay que hacer
- Lo que debería ocurrir (**Esperado**)
- Si hay algo crítico que verificar (🔴 Crítico / 🟡 Importante / 🟢 Menor)

Cuando algo **no** coincida con el resultado esperado, anota:
1. El flujo y el número de paso
2. Una descripción breve de lo que pasó
3. Captura de pantalla o video si es posible

---

## Configuración previa

| Requisito | Detalle |
|-----------|---------|
| Dispositivo | iOS 16+ o Android 12+ (físico o simulador) |
| Conexión | WiFi activo durante toda la sesión |
| Cuenta de prueba | Crear una cuenta nueva con correo de prueba **antes** de empezar |
| Cámara / Fotos | El dispositivo debe tener fotos de ejemplo en la galería |
| Ubicación | Activar permisos de ubicación para la app |

---

## MÓDULO 1 — Autenticación

### F1.1 · Registro de cuenta nueva

1. Abrir la app → pantalla de bienvenida/splash
2. Tocar **"Crear cuenta"**
3. Ingresar nombre, correo y contraseña válidos
4. Tocar **"Registrarse"**

**Esperado:** Redirige a la pantalla principal (Home). El usuario queda autenticado.  
🔴 Si la app se cuelga o muestra error genérico al registrar, es crítico.

---

### F1.2 · Inicio de sesión con correo

1. Cerrar sesión (si aplica) o desinstalar/limpiar datos
2. Ingresar correo y contraseña correctos
3. Tocar **"Iniciar sesión"**

**Esperado:** Redirige a Home.  
🔴 Verificar que con credenciales incorrectas aparezca un mensaje de error legible (no un código técnico).

---

### F1.3 · Recuperar contraseña

1. Pantalla de login → **"¿Olvidaste tu contraseña?"**
2. Ingresar correo registrado
3. Tocar **"Enviar enlace"**

**Esperado:** Mensaje de confirmación en pantalla. Llega correo de recuperación.  
🟡 Verificar que con un correo no registrado también aparezca mensaje (sin revelar si existe o no).

---

### F1.4 · Cerrar sesión

1. Ir a Perfil (ícono inferior derecho)
2. Buscar opción **"Cerrar sesión"**
3. Confirmar en el diálogo

**Esperado:** Redirige a la pantalla de login. No quedan datos del usuario en pantalla.

---

## MÓDULO 2 — Garage (Mis vehículos)

### F2.1 · Agregar un vehículo

1. Ir a pestaña **Garage** (ícono de moto en la barra inferior)
2. Tocar el botón para agregar vehículo
3. Completar el formulario: marca, referencia, año, placa, kilometraje
4. (Opcional) Agregar foto del vehículo desde galería o cámara
5. Guardar

**Esperado:** El vehículo aparece en la lista del garage. Si es el primero, queda marcado como principal.  
🔴 Verificar que la placa con formato inválido muestre error de validación antes de guardar.

---

### F2.2 · Ver detalle de un vehículo

1. Desde el Garage, tocar cualquier vehículo
2. Explorar la pantalla de detalle

**Esperado:** Se muestra marca, referencia, año, placa, kilometraje y foto (si se subió). Hay opciones para editar y ver documentos.

---

### F2.3 · Editar un vehículo

1. Desde el detalle del vehículo → opción **Editar**
2. Cambiar el kilometraje
3. Guardar

**Esperado:** Los cambios se reflejan al volver al detalle.  
🟡 Verificar que al tocar Atrás sin guardar los cambios no se persistan.

---

### F2.4 · SOAT del vehículo

1. Desde el detalle del vehículo → sección **SOAT**
2. Tocar para ver estado

**Esperado:** Muestra estado actual del SOAT (vigente / próximo a vencer / vencido / sin registrar).

3. Si no hay SOAT registrado → tocar **"Registrar manualmente"**
4. Completar datos: fecha de vencimiento, número de póliza
5. (Opcional) Adjuntar foto del documento
6. Guardar

**Esperado:** El estado del SOAT se actualiza en la pantalla.  
🟡 Verificar que con una fecha de vencimiento pasada el estado sea "Vencido".

---

### F2.5 · Tecnomecánica (RTM) del vehículo

(Mismo flujo que F2.4 pero para la Tecnomecánica)

1. Desde el detalle del vehículo → sección **Tecnomecánica**
2. Ver estado actual o registrar manualmente con fecha de vencimiento
3. Guardar

**Esperado:** Estado actualizado y visible en el detalle del vehículo.

---

### F2.6 · Mantenimientos del vehículo

1. Desde el detalle del vehículo → sección **Mantenimientos**
2. Tocar **"Agregar mantenimiento"**
3. Completar: tipo de mantenimiento, fecha, kilometraje, descripción
4. Guardar

**Esperado:** El mantenimiento aparece en la lista del vehículo.

5. Tocar el mantenimiento recién creado → ver detalle

**Esperado:** Muestra todos los campos ingresados.

6. Editar el mantenimiento → cambiar la descripción → guardar

**Esperado:** Cambios reflejados en el detalle.

---

## MÓDULO 3 — Eventos

### F3.1 · Explorar eventos

1. Ir a pestaña **Eventos** (ícono central en la barra inferior)
2. Desplazarse por la lista de eventos disponibles

**Esperado:** Lista cargada con tarjetas de eventos (imagen, nombre, fecha, ciudad).  
🟡 Verificar que el estado de carga (loading) sea visible mientras se obtienen los eventos.  
🟢 Con lista vacía debe aparecer un mensaje de estado vacío, no una pantalla en blanco.

---

### F3.2 · Filtrar eventos

1. Desde la lista de eventos → buscar ícono o botón de **Filtros**
2. Aplicar filtro por ciudad o fecha
3. Tocar **"Aplicar"**

**Esperado:** La lista se actualiza mostrando solo eventos que cumplen el filtro.  
🟡 Verificar que al limpiar filtros vuelvan todos los eventos.

---

### F3.3 · Ver detalle de un evento

1. Tocar cualquier evento en la lista

**Esperado:** Pantalla de detalle con: imagen de portada, nombre, descripción, fecha, lugar, ruta en mapa (si tiene), cantidad de asistentes.

---

### F3.4 · Mis eventos

1. Desde la pestaña Eventos → cambiar a pestaña **"Mis eventos"**

**Esperado:** Lista de eventos que el usuario organizó o en los que está registrado.

---

### F3.5 · Crear un evento (sin IA)

1. Ir a **Mis eventos** o buscar el botón de crear evento (+)
2. Completar los campos obligatorios:
   - Nombre del evento
   - Descripción (texto libre)
   - Fecha de inicio y fin
   - Ciudad / Lugar de encuentro
3. Subir una portada desde la galería
4. Tocar **"Guardar borrador"** o **"Publicar"**

**Esperado:** El evento aparece en "Mis eventos". Si se publicó, también en la lista general.  
🔴 Verificar que al intentar publicar sin campos obligatorios aparezcan mensajes de validación por campo.

---

### F3.6 · Crear un evento — Descripción con IA

1. Crear un evento nuevo (como en F3.5)
2. En la sección de **Descripción** → tocar el botón **"Generar con IA"**
3. En el chat que aparece, escribir un mensaje como:  
   *"Evento de touring por la Sierra Nevada, 2 días, perfil familiar"*
4. Enviar el mensaje

**Esperado:** La IA responde con una propuesta de descripción en el chat.

5. Si la respuesta es buena → tocar **"Insertar"**

**Esperado:** La descripción se inserta automáticamente en el editor del formulario.  
🟡 Verificar que el indicador de cuota baje después de cada generación.  
🟡 Con cuota agotada debe aparecer un banner informando que no hay más generaciones disponibles.

---

### F3.7 · Crear un evento — Portada con IA

1. Crear un evento nuevo o editar uno existente
2. En la sección de **Portada** → tocar **"Generar con IA"**
3. Escribir un prompt descriptivo:  
   *"Motociclistas en carretera destapada al amanecer, montañas de fondo"*
4. Enviar

**Esperado:** Aparece una imagen generada por IA en el chat.

5. Tocar la imagen para previsualizarla en pantalla completa

**Esperado:** La imagen ocupa toda la pantalla con opciones de usar o descartar.

6. Seleccionar la imagen → **"Usar esta portada"**

**Esperado:** La imagen queda como portada del evento en el formulario.  
🟡 Verificar que durante la generación haya un estado de carga visible (shimmer o spinner).  
🟡 Si la generación falla, debe aparecer un mensaje de error claro con opción de reintentar.

---

### F3.8 · Editar un evento propio

1. Desde **Mis eventos** → tocar un evento propio
2. Buscar opción **Editar**
3. Cambiar el nombre del evento
4. Guardar

**Esperado:** El nombre actualizado aparece en el detalle y en la lista.

---

### F3.9 · Borradores de eventos

1. Crear un evento y guardar como borrador (sin publicar)
2. Ir a **Mis borradores** (buscar en el menú o en Mis eventos)

**Esperado:** El borrador aparece en la lista. Se puede reanudar la edición.

---

### F3.10 · Registrarse en un evento

1. Desde el detalle de un evento → tocar **"Registrarme"**
2. Completar el formulario de registro (selección de vehículo, datos adicionales si aplica)
3. Confirmar

**Esperado:** Aparece confirmación de solicitud enviada. El estado en el detalle cambia a "Pendiente de aprobación" o "Registrado" según la configuración del evento.  
🔴 Verificar que solo se pueda registrar con un vehículo previamente agregado al garage. Si no tiene vehículo, el flujo debe guiarlo a crearlo.

---

### F3.11 · Mis registraciones

1. Ir a **Mis registraciones** (desde Eventos o el menú)
2. Explorar la lista

**Esperado:** Lista con todos los eventos donde el usuario se ha registrado, con estado visible (pendiente / aprobado / rechazado).

3. Tocar una registración → ver detalle

**Esperado:** Detalle con información del evento, estado actual y datos del registro.

---

### F3.12 · Gestionar asistentes (como organizador)

1. Ir al detalle de un evento **propio**
2. Tocar **"Ver asistentes"**

**Esperado:** Lista de usuarios que se han registrado, con su estado.

3. Tocar un asistente pendiente → opciones de **Aprobar** o **Rechazar**
4. Aprobar uno y rechazar otro

**Esperado:** El estado cambia inmediatamente en la lista.  
🟡 Verificar que al tocar el nombre del asistente se muestre su perfil de rider.

---

### F3.13 · Seguimiento en vivo (Live Tracking)

> ⚠️ Este flujo requiere que el evento esté **activo/en curso** y que haya otros participantes conectados.

1. Desde el detalle de un evento activo → tocar **"Mapa en vivo"**

**Esperado:** Se abre un mapa con puntos de ubicación de los participantes en tiempo real.

2. Explorar el mapa (zoom, desplazamiento)
3. Tocar **"Ver participantes"**

**Esperado:** Lista de participantes conectados actualmente.  
🟡 Verificar que la ubicación propia aparezca diferenciada en el mapa.

---

## MÓDULO 4 — Perfil

### F4.1 · Ver perfil propio

1. Ir a pestaña **Perfil** (ícono inferior derecho)

**Esperado:** Foto de perfil, nombre, correo, estadísticas básicas del usuario.

---

### F4.2 · Editar perfil

1. Desde Perfil → tocar **"Editar perfil"**
2. Cambiar la foto de perfil (desde galería)
3. Cambiar el nombre o algún dato
4. Guardar

**Esperado:** El perfil actualizado se refleja inmediatamente al volver.  
🟡 Verificar que fotos muy pesadas (>5MB) no cierren la app.

---

### F4.3 · Ver notificaciones

1. Desde Perfil → tocar **"Notificaciones"**

**Esperado:** Lista de notificaciones recientes. Si no hay, muestra estado vacío con mensaje apropiado.

---

## MÓDULO 5 — Perfil de otros riders

### F5.1 · Ver perfil de un rider desde un evento

1. Ir al detalle de un evento → **Asistentes**
2. Tocar el nombre de cualquier asistente

**Esperado:** Se abre el perfil público del rider con su foto, nombre y vehículos.

---

## CASOS BORDE GENERALES

### E1 · Sin conexión a internet

1. Activar modo avión en el dispositivo
2. Intentar cargar la lista de eventos

**Esperado:** Mensaje de error por falta de conexión. La app **no** debe cerrarse.

3. Restaurar conexión
4. Hacer pull-to-refresh (deslizar hacia abajo en la lista)

**Esperado:** La lista carga correctamente.

---

### E2 · Campos vacíos en formularios

Para cada formulario (vehículo, evento, mantenimiento):

1. Intentar guardar sin completar ningún campo obligatorio

**Esperado:** Mensajes de validación debajo de cada campo obligatorio vacío. El formulario no se envía.

---

### E3 · Fotos y cámara

1. En cualquier campo de imagen → tocar y seleccionar **"Cámara"**
2. Tomar una foto
3. Confirmar

**Esperado:** La foto aparece en el campo correspondiente.  
🟡 Si el usuario niega el permiso de cámara, debe aparecer un mensaje explicando cómo habilitarlo en ajustes.

---

### E4 · Pull-to-refresh

En cualquier listado (eventos, vehículos, mantenimientos, notificaciones):

1. Deslizar hacia abajo desde la parte superior de la lista

**Esperado:** Indicador de carga visible. La lista se actualiza con datos frescos.

---

### E5 · Flujo de vehículo requerido

1. Crear una cuenta nueva sin agregar vehículos
2. Intentar registrarse en un evento

**Esperado:** La app informa que es necesario agregar un vehículo primero y ofrece ir al formulario de vehículo directamente.

---

## CHECKLIST RÁPIDO DE REGRESIÓN

Usar este checklist para verificar que nada se rompió después de una actualización:

- [ ] Login con credenciales válidas funciona
- [ ] La app llega a Home después de autenticarse
- [ ] La lista de eventos carga
- [ ] El detalle de un evento abre
- [ ] El Garage muestra los vehículos existentes
- [ ] Crear un vehículo simple (sin foto) funciona
- [ ] El perfil carga correctamente
- [ ] Cerrar sesión y volver a la pantalla de login funciona
- [ ] No hay pantallas completamente en blanco en ningún flujo principal

---

## Cómo reportar un bug

Incluir en el reporte:

1. **Flujo afectado** (ej: F3.6 — Descripción con IA)
2. **Paso donde falló** (ej: Paso 4 — al enviar el mensaje)
3. **Qué pasó** (descripción corta y clara)
4. **Qué esperabas que pasara**
5. **Captura / video** adjunto
6. **Dispositivo y sistema operativo** (ej: iPhone 14 — iOS 17.2)
7. **Reproducible?** Sí / No / A veces

---

*Documento generado por el equipo de Rideglory. Contacto: camiiloagudelo92@gmail.com*
