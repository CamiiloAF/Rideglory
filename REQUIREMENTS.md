# Rideglory — Documento de Requerimientos (MVP)

> **Versión:** 1.0  
> **Fecha:** Mayo 2026  
> **Estado:** En desarrollo  
> **Plataformas:** Android + iOS  
> **Idioma inicial:** Español (colombiano)

---

## Índice

1. [Visión general](#1-visión-general)
2. [Stack tecnológico](#2-stack-tecnológico)
3. [Diseño y sistema visual](#3-diseño-y-sistema-visual)
4. [Navegación y estructura](#4-navegación-y-estructura)
5. [Módulo: Autenticación](#5-módulo-autenticación)
6. [Módulo: Splash](#6-módulo-splash)
7. [Módulo: Home Dashboard](#7-módulo-home-dashboard)
8. [Módulo: Eventos](#8-módulo-eventos)
9. [Módulo: Inscripciones](#9-módulo-inscripciones)
10. [Módulo: Rastreo en tiempo real](#10-módulo-rastreo-en-tiempo-real)
11. [Módulo: Garaje (vehículos)](#11-módulo-garaje-vehículos)
12. [Módulo: Mantenimiento](#12-módulo-mantenimiento)
13. [Módulo: SOAT](#13-módulo-soat)
14. [Módulo: Perfil](#14-módulo-perfil)
15. [Módulo: Notificaciones](#15-módulo-notificaciones)
16. [Deep links](#16-deep-links)
17. [Contratos de API a extender](#17-contratos-de-api-a-extender)
18. [Fuera de alcance del MVP](#18-fuera-de-alcance-del-mvp)

---

## 1. Visión general

**Rideglory** es una aplicación móvil para la comunidad motera de Colombia. Permite organizar y unirse a rodadas (eventos), gestionar el garaje personal de motos, llevar historial de mantenimiento, rastrear a los compañeros en tiempo real durante una rodada y gestionar el SOAT de cada vehículo.

### Usuarios

- **Cualquier usuario registrado** puede crear eventos, inscribirse a eventos, gestionar su garaje y ver perfiles de otros riders.
- No existen roles diferenciados en el MVP. El creador de un evento actúa como organizador de ese evento específico.

### Principios de diseño

- La app **requiere conexión a internet** en todo momento. No hay modo offline.
- Toda la UI está en **español colombiano**. El soporte para inglés es trabajo futuro.
- No hay flujo de pagos en el MVP. Los eventos pueden indicar un precio (informativo), pero el cobro se hace por fuera de la app.

---

## 2. Stack tecnológico

| Capa | Tecnología |
|------|-----------|
| Frontend | Flutter (Clean Architecture, BLoC/Cubit) |
| State management | `flutter_bloc` — `Cubit<ResultState<T>>` |
| DI | `get_it` + `injectable` |
| HTTP | Retrofit + Dio |
| Auth | Firebase Authentication |
| Storage | Firebase Storage (imágenes) |
| Base de datos | Backend REST API (`rideglory-api`) |
| Tiempo real | WebSocket (`web_socket_channel`) |
| Mapas | `google_maps_flutter` |
| Localización | `geolocator` |
| Notificaciones | Firebase Cloud Messaging (FCM) |
| Deep links | Firebase Dynamic Links |
| Generación de imágenes IA | API externa (definir: OpenAI / Stable Diffusion / similar) |
| Fuentes | Space Grotesk (`google_fonts`) |

### Estado del backend (`rideglory-api`)

El backend está **parcialmente construido**. Los módulos de Auth, Eventos, Inscripciones, Vehículos y Mantenimiento tienen endpoints base. Los módulos de **SOAT**, **Rastreo GPS** y **Generación de portada con IA** requieren endpoints nuevos (ver sección 17).

---

## 3. Diseño y sistema visual

### Paleta de colores — Asphalt (dark)

| Token | Valor | Uso |
|-------|-------|-----|
| `color-bg` | `#0A0A0A` | Fondo de pantalla |
| `color-surface` | `#161616` | Cards, bottom sheets |
| `color-surface-2` | `#1F1F1F` | Inputs, elementos elevados |
| `color-border` | `#2D2D2D` | Bordes de cards e inputs |
| `color-primary` | `#f98c1f` | Naranja — acción principal, active state |
| `color-primary-dim` | `#3D2A0A` | Fondo de badges naranja |
| `color-text-primary` | `#F4F4F5` | Texto principal |
| `color-text-secondary` | `#71717A` | Texto secundario, placeholders |
| `color-text-muted` | `#3F3F46` | Texto deshabilitado |
| `color-success` | `#22C55E` | Estados OK, aprobado |
| `color-error` | `#EF4444` | Errores, rechazado, SOAT vencido |
| `color-warning` | `#F59E0B` | Alertas, SOAT por vencer, mantenimiento urgente |

### Tipografía

- **Fuente:** Space Grotesk (Google Fonts)
- **Border radius estándar:** 8px (inputs, botones), 12px (cards), 16px (cards grandes), 24px (bottom sheets, modal corners)

### Navegación inferior — Pill Tab Bar

La app usa una barra de navegación inferior con forma de píldora flotante con 4 tabs:

| Tab | Ícono | Destino |
|-----|-------|---------|
| INICIO | `home` | Home Dashboard |
| EVENTOS | `event` | Lista de eventos |
| GARAJE | `two_wheeler` | Lista de vehículos |
| PERFIL | `person` | Mi perfil |

El tab activo tiene fondo naranja sólido (`color-primary`) con texto e ícono en negro. Los tabs inactivos tienen fondo transparente con ícono y texto en `color-text-secondary`.

### Referencia visual

Los diseños de todas las pantallas están en `rideglory.pen` (archivo Pencil en la raíz del proyecto). Este archivo es la única fuente de la verdad para el diseño.

---

## 4. Navegación y estructura

### Flujo general

```
Splash
  └─► Login / Registro
        └─► Home Dashboard (shell con Tab Bar)
              ├─► Tab: Home
              ├─► Tab: Eventos
              │     ├─► Detalle de evento
              │     │     └─► Rastreo en tiempo real (durante evento activo)
              │     └─► Crear evento
              ├─► Tab: Garaje
              │     ├─► Detalle de vehículo
              │     │     └─► SOAT del vehículo
              │     └─► Agregar / Editar vehículo
              └─► Tab: Perfil
                    ├─► Mis eventos (lista de eventos del usuario)
                    ├─► Editar información personal
```

### Rutas nombradas (go_router)

| Nombre | Path | Descripción |
|--------|------|-------------|
| `splash` | `/` | Splash screen |
| `login` | `/login` | Login |
| `register` | `/register` | Registro |
| `home` | `/home` | Home dashboard (shell) |
| `events` | `/home/events` | Lista de eventos |
| `eventDetail` | `/home/events/:eventId` | Detalle de evento |
| `createEvent` | `/home/events/create` | Formulario crear evento |
| `eventTracking` | `/home/events/:eventId/tracking` | Rastreo en tiempo real |
| `myRegistrations` | `/home/my-registrations` | Mis inscripciones |
| `registrationDetail` | `/home/my-registrations/:registrationId` | Detalle de inscripción |
| `manageAttendees` | `/home/events/:eventId/attendees` | Gestionar inscritos |
| `garage` | `/home/garage` | Lista de vehículos |
| `vehicleDetail` | `/home/garage/:vehicleId` | Detalle de vehículo |
| `addVehicle` | `/home/garage/add` | Agregar vehículo |
| `editVehicle` | `/home/garage/:vehicleId/edit` | Editar vehículo |
| `soat` | `/home/garage/:vehicleId/soat` | Flujo SOAT |
| `maintenance` | `/home/maintenance` | Lista de mantenimientos |
| `maintenanceDetail` | `/home/maintenance/:maintenanceId` | Detalle de mantenimiento |
| `addMaintenance` | `/home/maintenance/add` | Agregar mantenimiento |
| `editMaintenance` | `/home/maintenance/:maintenanceId/edit` | Editar mantenimiento |
| `myProfile` | `/home/profile` | Mi perfil |
| `riderProfile` | `/home/riders/:userId` | Perfil de otro rider |

### Convenciones de navegación

- `context.pushNamed()` para transiciones normales (back button activo).
- `context.goAndClearStack()` para cambios de estado de auth (logout, onboarding completado).
- Los tabs del shell usan `context.goNamed()` para no apilar.

---

## 5. Módulo: Autenticación

### Métodos soportados

- Email y contraseña
- Google Sign-In
- Apple Sign-In (requerido por App Store cuando hay opciones de login social)

### Pantallas

#### 5.1 Login

**Campos:**
- Correo electrónico (validación formato email)
- Contraseña (mínimo 8 caracteres, campo enmascarado con toggle de visibilidad)

**Acciones:**
- "Iniciar sesión" — autentica con email/password vía Firebase Auth
- "¿Olvidaste tu contraseña?" — navega a flujo de recuperación por email
- "Continuar con Google" — OAuth Google Sign-In
- "Continuar con Apple" — OAuth Apple Sign-In
- "Regístrate" — navega a pantalla de registro

**Estados de error:**
- Credenciales incorrectas: mostrar error en línea bajo el campo contraseña
- Cuenta no existe: sugerir registro
- Sin conexión: snackbar de error de red

#### 5.2 Registro

**Campos:**
- Nombre completo
- Correo electrónico
- Contraseña (mínimo 8 caracteres)
- Confirmar contraseña

**Acciones:**
- "Crear cuenta" — registra en Firebase Auth y crea perfil en el backend
- "Ya tengo cuenta" — regresa a login

**Validaciones:**
- Email formato válido y no duplicado
- Contraseñas coinciden
- Nombre mínimo 2 caracteres

#### 5.3 Recuperación de contraseña

- El usuario ingresa su email
- Firebase envía correo de recuperación
- Se muestra pantalla de confirmación: "Te enviamos un correo a {email}"

### Flujo post-autenticación

1. Firebase Auth retorna token
2. `FirebaseAuthInterceptor` inyecta el token en cada request HTTP
3. El backend crea o actualiza el perfil del usuario en el primer login
4. Redirect a Home Dashboard

### Guard de autenticación

- `go_router` implementa `redirect` que revisa `FirebaseAuth.instance.currentUser`
- Si no hay sesión activa → redirige a `/login`
- Si ya hay sesión → redirige a `/home`

---

## 6. Módulo: Splash

### Comportamiento

1. Muestra logo de Rideglory + tagline "Connect. Ride. Explore." sobre fondo oscuro
2. Inicializa Firebase, DI (`configureDependencies()`) y verifica estado de autenticación
3. Barra de progreso de carga (estética, no técnica)
4. Después de inicialización:
   - Si hay sesión activa → navega a `/home`
   - Si no → navega a `/login`

### Duración máxima

- Máximo 3 segundos, luego navega independientemente del estado de carga visual

---

## 7. Módulo: Home Dashboard

### Propósito

Pantalla de bienvenida personalizada que muestra un resumen del estado del usuario: su moto principal y las próximas rodadas a las que está inscrito.

### Secciones

#### 7.1 Header

- Barra superior con saludo: "Hola, {nombre}" + nombre completo del usuario
- Ícono de notificaciones (campana) con badge de conteo de no leídas
- Diseño en dos líneas: subtítulo motivacional bajo el saludo

#### 7.2 Mi Garaje

- Label "MI GARAJE" + link "VER TODAS" → navega a `garage`
- **Card del vehículo principal:**
  - Imagen de la moto (full-width con overlay oscuro)
  - Nombre: marca + modelo
  - Si hay un mantenimiento próximo → alerta inline en naranja (ej. "Próxima carga de aceite en fecha")
  - Stats en chips: odómetro actual (km), próximo servicio (km restantes), último servicio (fecha)
  - Accesos rápidos: botón "Mantenimiento" → `maintenance` | botón "Documentos" → documentos del vehículo
- Si no tiene vehículos → CTA "Agrega tu moto" → navega a `addVehicle`

#### 7.3 Próximas Rodadas

- Label "PRÓXIMAS RODADAS" + ícono de filtro
- Scroll horizontal de cards de eventos donde el usuario está inscrito y aprobado:
  - Badge de estado: "INSCRITO" (naranja) o "DISPONIBLE"
  - Imagen del evento
  - Nombre del evento (mayúsculas)
  - Fecha y ciudad
  - Botón "VER DETALLES →" → navega a `eventDetail`
- CTA "VER CATÁLOGO COMPLETO DE EVENTOS >" al final de la sección → navega a `events`
- Si no tiene inscripciones aprobadas → estado vacío con CTA "Explorar eventos"

#### 7.4 Estado general

| Condición | Comportamiento |
|-----------|---------------|
| Sin vehículos | Sección MI GARAJE muestra CTA "Agrega tu moto" |
| Sin inscripciones aprobadas | Sección Próximas Rodadas muestra estado vacío con CTA |
| SOAT vencido o por vencer | Alerta inline en la card del vehículo afectado |
| Mantenimiento próximo | Alerta inline en naranja en la card del vehículo |

---

## 8. Módulo: Eventos

### 8.1 Lista de eventos

#### Filtros y búsqueda

- Título de pantalla: "Explorar Eventos"
- Barra de búsqueda por nombre de evento
- Chips de filtro rápido: "Todos", "En Vivo", "Gratuito"
- Botón de filtros avanzados (ver sección 8.2):
  - Fecha (rango desde/hasta)
  - Ciudad / departamento
  - Tipo de evento (Naked, Sport, Cruiser, Turismo, Off-Road)
  - Precio (gratuito / de pago)
  - Dificultad

#### Tarjeta de evento

Cada card muestra:
- Imagen de portada (full-width, con overlay oscuro)
- Badge de estado: "INSCRITO" si el usuario ya está inscrito; badge de precio si no
- Nombre del evento
- Organizador (nombre + avatar pequeño)
- Fecha + ciudad
- Tipo de evento y dificultad (chips)
- Botón "Ver" → navega a `eventDetail`

#### Ordenamiento

Los eventos se ordenan por fecha ascendente (más próximos primero). Solo se muestran eventos futuros o con fecha de hoy.

#### CTA crear evento

- Botón flotante "+" o botón en el header "Crear" → navega a `createEvent`

### 8.2 Filtros avanzados

Bottom sheet o pantalla completa con los filtros mencionados. Al aplicar filtros:
- Regresa a la lista con los resultados filtrados
- Muestra un chip "X filtros activos" con opción de limpiar

### 8.3 Detalle de evento

#### Header

- Imagen de portada full-width con overlay oscuro
- Botón back + botón compartir (genera deep link)
- Nombre del evento como título superpuesto

#### Chips de métricas del evento

Chips horizontales bajo el hero con: duración (ej. "3 días"), distancia (ej. "1.200 km"), tipo de evento (ej. "TURISMO")

#### Secciones

**Sobre la rodada:**
- Descripción larga (rich text, solo lectura)

**Punto de Encuentro:**
- Mini-mapa de Google Maps con el punto de inicio marcado
- Dirección legible
- Botón "Ver mapa" → abre Google Maps nativo con la dirección

**Marcas Permitidas:**
- Chips de selección mostrando las marcas habilitadas para el evento (BMW, Ducati, KTM, Honda, Yamaha, etc.)
- Chip especial "Todas" si no hay restricción

**Inscritos:**
- Lista horizontal de avatares de riders ya inscritos y aprobados
- Contador de inscritos totales

**CTA Bar fija en la parte inferior:**
- Precio del evento (si aplica) en el lado izquierdo
- Botón principal en el lado derecho, según estado del usuario:

| Estado del usuario | Botón |
|--------------------|-------|
| No inscrito | "Inscribirte" → navega a formulario de inscripción |
| Inscripción pendiente | "Pendiente de aprobación" (deshabilitado) |
| Aprobado, evento futuro | "Inscrito ✓" (informativo) |
| Aprobado, evento activo | "Ver rastreo" → navega a `eventTracking` |
| Rechazado | "No aceptado" (informativo) |
| Es el organizador | "Gestionar inscritos" → navega a `manageAttendees` |

#### Estado del evento

| Estado | Descripción |
|--------|-------------|
| `upcoming` | El evento aún no ha comenzado |
| `active` | El evento está en curso (entre fecha de inicio y fin) |
| `finished` | El evento ya pasó |
| `cancelled` | El organizador canceló el evento |

### 8.4 Crear evento

#### Campos del formulario

| Campo | Tipo | Requerido | Notas |
|-------|------|-----------|-------|
| Portada | Imagen | No | Galería o cámara. Si no se sube, se puede generar con IA |
| Generar ilustración IA | Button | — | Ver sección 8.4.1 |
| Nombre del evento | Text | Sí | |
| Descripción | Text area | No | Máx 2000 caracteres |
| Fecha de inicio | Date + Time picker | Sí | Debe ser futura |
| Fecha de fin | Date + Time picker | Sí | Debe ser posterior a inicio |
| Número de acompañantes | Number | No | Cupo máximo de participantes |
| Nivel de dificultad | Selector visual (íconos de llama) | No | 3 niveles |
| Distancia estimada | Number (km) | No | Kilómetros estimados del recorrido |
| Motos permitidas | Chips multi-select | No | Todas, Naked, Sport, Cruiser, Turismo, Off-Road |
| ¿Requiere aprobación? | Switch | Sí | Default: activado. Si se desactiva, auto-aprobación |

#### 8.4.1 Generación de ilustración con IA

- Botón "Generar ilustración IA" junto al área de portada
- Se abre un bottom sheet con un campo de texto de prompt
- La app llama al endpoint del backend que invoca la API de generación de imágenes
- Se muestran hasta 4 opciones generadas en un grid
- El usuario selecciona una → se sube a Firebase Storage y se usa como portada
- Estado de carga con spinner durante la generación

#### Flujo de publicación

1. El usuario completa el formulario y toca "Publicar evento"
2. Si hay validaciones pendientes → se marcan en rojo y se hace scroll al primer error
3. Si todo está OK → se muestra diálogo de confirmación
4. Al confirmar → se crea el evento, se sube la imagen si aplica, y navega al detalle del evento creado

#### Editar evento

- La pantalla de edición usa el mismo formulario
- Solo el creador del evento puede editarlo
- No se puede editar la fecha si el evento ya tiene inscritos aprobados (mostrar advertencia)
- No se puede editar si el evento está en estado `active` o `finished`

---

## 9. Módulo: Inscripciones

### 9.1 Mis inscripciones

Lista de todos los eventos a los que el usuario se ha inscrito, agrupados por estado:
- **Próximos** (aprobados con fecha futura)
- **Pendientes** (esperando aprobación del organizador)
- **Pasados** (eventos ya realizados, aprobados)
- **Rechazados**

Por cada inscripción: nombre del evento, fecha, estado con chip de color.

### 9.2 Detalle de inscripción

- Header: nombre del evento, fecha, hora y ciudad
- Badge de estado de inscripción (Confirmada / Pendiente / Rechazada)
- **Datos de la inscripción:**
  - Moto registrada (marca + modelo + año)
  - Tipo de participación (Rider principal / Acompañante)
  - Número de acompañantes
  - Notas personales (lo que el rider añadió al inscribirse)
  - Contacto de emergencia (nombre + teléfono)
- **Código QR de acceso** (botón que muestra el QR en pantalla completa para presentar en el evento)
- Botón "Cancelar inscripción" (solo si está pendiente o si el evento aún no comenzó)
- Si está rechazada: mensaje del organizador (si lo dejó)

### 9.3 Flujo de inscripción

1. Desde el detalle del evento, el usuario toca "Inscribirte"
2. Navega a la **pantalla de formulario de inscripción** con:
   - Nombre del evento (encabezado, solo lectura)
   - **Información Personal:** nombre completo, correo electrónico, teléfono, número de documento
   - **Información Básica:** tipo de participación (Rider principal / Acompañante), número de acompañantes
   - **Información de tu moto:** selector de vehículo del garaje del usuario
   - **Contacto de emergencia:** nombre y teléfono
   - Precio total (si el evento es de pago)
   - Botón "Confirmar Inscripción"
3. Al confirmar → se crea la inscripción en estado `pending`
4. El organizador recibe una notificación push

### 9.4 Gestionar inscritos

Accesible solo para el creador del evento.

#### Secciones

**Nuevas solicitudes** (estado `pending`):
- Lista de usuarios con foto, nombre, moto con la que va
- Acciones por cada solicitud:
  - ✅ Aprobar → cambia a `approved`, se notifica al usuario
  - ❌ Rechazar → bottom sheet para ingresar motivo opcional → cambia a `rejected`, se notifica
  - 📞 Llamar → abre dialer nativo con el teléfono del inscrito (si lo tiene registrado en perfil)
  - 💬 WhatsApp → abre WhatsApp con el número del inscrito (si lo tiene)

**Ya procesados** (estado `approved` o `rejected`):
- Lista con el estado visible
- Permite revertir (cambiar de aprobado a rechazado o viceversa)

#### Búsqueda y filtro

- Barra de búsqueda por nombre
- Filtro por estado (Todos / Pendientes / Aprobados / Rechazados)

---

## 10. Módulo: Rastreo en tiempo real

### Condiciones de activación

- Solo disponible cuando el evento está en estado `active`
- El usuario debe estar aprobado en el evento
- Se activa la primera vez que el usuario entra a la pantalla de rastreo del evento
- Se **desactiva automáticamente** cuando el evento cambia a estado `finished`

### Pantalla de rastreo

#### Mapa

- Google Maps a pantalla completa
- Marcador propio: diferente color o ícono de moto
- Marcadores de otros riders: foto de perfil como pin, nombre bajo el marcador
- Centro automático en la posición propia al entrar
- Botones de zoom +/−
- Botón "Centrar en mi posición"

#### Panel inferior (lista del grupo)

Deslizable desde abajo (bottom sheet parcial), muestra:
- Nombre del rider
- Moto que usa
- Velocidad actual (km/h)
- Estado: "Rodando", "Detenido", "Sin señal"
- Botón de llamada nativa (si tiene teléfono en perfil)

#### Información superior

- Distancia al marcador del organizador (en km)
- Velocidad promedio del grupo

#### Botón "Terminar sesión de rastreo"

- Solo visible para el organizador del evento
- Al tocarlo: cambia el estado del evento a `finished` en el backend
- Todos los riders reciben una notificación "La rodada ha terminado"
- La pantalla de rastreo se cierra automáticamente para todos

### Comportamiento GPS en background

- Mientras la app está en segundo plano, sigue enviando la ubicación al WebSocket
- La frecuencia de envío es cada 5 segundos
- Se muestra una notificación persistente de sistema: "Rideglory — Rodada activa"

### WebSocket

- Se conecta a `GET /api/tracking/ws` con el `eventId` como parámetro
- Envía mensajes de ubicación: `{ lat, lng, speed, status }`
- Recibe mensajes de otros riders: lista de `{ userId, lat, lng, speed, status }`
- Auto-reconexión con backoff exponencial si se pierde la conexión

---

## 11. Módulo: Garaje (vehículos)

### 11.1 Lista de vehículos (Garaje)

- Título: "Mi Garaje" + botón "Agregar" (naranja, esquina superior derecha) → navega a `addVehicle`
- **Card del vehículo principal** (destacada):
  - Label "Moto principal" + menú "···" (opciones: editar, archivar)
  - Foto de la moto (full-width)
  - Nombre: marca + modelo
  - Año · CC · Placa
  - Stats en chips: odómetro (km), próximo servicio (km), último servicio (fecha)
  - Accesos rápidos: botón "Mantenimiento" → `maintenance` | botón "Documentos" → documentos del vehículo
- **Sección "Otras motos":** lista compacta con el resto de vehículos (nombre + año/CC/placa), cada ítem navega a `vehicleDetail`
- Tap en cualquier vehículo → navega a `vehicleDetail`

### 11.2 Detalle de vehículo

- Header: nombre del vehículo + botón back + botón editar (lápiz) → navega a `editVehicle`
- Foto del vehículo (full-width)
- Badge "Moto principal" (si aplica)
- Datos de identificación: año · CC · Placa · VIN
- **Especificaciones técnicas:**
  - Motor (CC + configuración, ej. "869cc, parallel-2 clt")
  - Potencia (hp)
  - Torque (Nm)
  - Peso (kg)
  - Color
- **Documentos del vehículo** (sección con estado de cada documento):
  - SOAT: badge Vigente / Por vencer / Vencido / Sin registro → tap → flujo SOAT
  - Revisión técnica: badge de estado → tap → flujo de documento
  - Tarjeta de propiedad: badge de estado
- Fechas del último y próximo servicio
- Botón "Ver historial de mantenimientos" → navega a `maintenance` filtrado por este vehículo
- Archivar → opción en menú "···" del header (desactiva el vehículo; no lo elimina)

### 11.3 Formulario de vehículo

**Campos:**

| Campo | Tipo | Requerido | Notas |
|-------|------|-----------|-------|
| Foto | Imagen | No | Galería o cámara |
| Generar descripción automática | Button IA | No | Genera nombre/descripción con IA a partir de la foto |
| Nombre / Alias | Text | Sí | Nombre personalizado de la moto |
| Transmisión | Dropdown | No | Manual / Automática |
| Marca | Autocomplete | Sí | Lista de marcas (`ColombiaMotosBrandsData`) |
| Modelo | Text | Sí | |
| Cilindraje (CC) | Number | Sí | |
| Año | Number / picker | Sí | Rango 1990–año actual |
| Placa | Text | Sí | Validación formato colombiano (ABC-123 o ABC12D) |
| Peso (kg) | Number | No | |
| ¿Es tu moto favorita / principal? | Switch | No | Solo puede haber una principal |
| Mantenimiento recomendado | Sección | No | Intervalo sugerido de servicio (km o meses) |

---

## 12. Módulo: Mantenimiento

### 12.1 Lista de mantenimientos

- Selector de vehículo en la parte superior (tabs o dropdown)
- Tarjetas resumen (odómetro, total de registros, pendientes/urgentes)
- Banner de alerta si hay un mantenimiento vencido u olvidado
- Lista de registros ordenada por fecha descendente
- Por cada registro: tipo de servicio, fecha, odómetro, costo
- Estado del registro: ✅ Realizado / ⚠️ Próximo / 🔴 Vencido

### 12.2 Detalle de mantenimiento

- Toda la información del registro
- Notas del técnico / usuario
- Fotos adjuntas (si se subieron)
- Próxima fecha o kilómetros para repetir el servicio
- Botones: "Editar" / "Eliminar"

### 12.3 Formulario de mantenimiento

**Campos:**

| Campo | Tipo | Requerido | Notas |
|-------|------|-----------|-------|
| Vehículo | Dropdown | Sí | Si se entra desde un vehículo, está pre-seleccionado |
| Tipo de servicio | Dropdown | Sí | Cambio de aceite, Llantas, Frenos, Cadena, Filtro, Suspensión, Otro |
| Fecha del servicio | Date picker | Sí | |
| Odómetro al momento del servicio | Number (km) | Sí | |
| Taller / lugar | Text | No | |
| Costo | Number (COP) | No | |
| Notas | Text area | No | Máx 500 caracteres |
| Fotos | Multi-imagen | No | Galería o cámara, máx 5 fotos |
| Próxima revisión | Date O kilómetros | No | Uno de los dos para generar recordatorio |

### Recordatorios de mantenimiento

Si el usuario especifica "próxima revisión":
- La app genera una notificación push 7 días antes de la fecha o 500 km antes del odómetro estimado
- El cálculo de kilómetros estimados es manual (el usuario actualiza su odómetro)

---

## 13. Módulo: SOAT

### Flujo completo (`21` → `22` → `23` → `24` ó `25`)

El SOAT se gestiona a nivel de vehículo. El estado se calcula automáticamente a partir de la fecha de vencimiento almacenada.

#### 13.1 Vista de estado SOAT por garaje

- Muestra todos los vehículos con su badge de estado SOAT
- Acceso rápido al botón "Subir SOAT" para el vehículo que lo necesita

#### 13.2 Entrada al flujo SOAT

Dos opciones:
1. **Subir documento** → Abre galería/cámara para seleccionar foto o PDF del SOAT
2. **Ingresar manualmente** → Navega a formulario manual (sección 13.5)

#### 13.3 Subida con progreso

- Barra de progreso de subida del archivo a Firebase Storage
- Al completarse → navega a la confirmación

#### 13.4 Confirmación y extracción de datos

Después de subir el documento:
- Se muestra la imagen subida
- Campos editables pre-llenados (si se pudo extraer con OCR o manualmente):
  - Número de póliza
  - Fecha de inicio
  - Fecha de vencimiento ⚠️ **obligatorio**
  - Aseguradora
- Botón "Confirmar" → guarda en el backend y actualiza el estado del vehículo

#### 13.5 Ingreso manual

Formulario simple:
- Número de póliza
- Fecha de inicio
- Fecha de vencimiento ⚠️ obligatorio
- Aseguradora

#### Lógica de estado

| Condición | Badge |
|-----------|-------|
| Sin SOAT registrado | ⚪ Sin SOAT |
| `fechaVencimiento` > hoy + 30 días | 🟢 SOAT vigente |
| `fechaVencimiento` entre hoy y hoy + 30 días | 🟡 Vence en X días |
| `fechaVencimiento` ≤ hoy | 🔴 SOAT vencido |

#### Notificaciones SOAT

- 30 días antes del vencimiento: "Tu SOAT de {moto} vence en 30 días"
- 7 días antes: "Tu SOAT de {moto} vence en 7 días"
- El día del vencimiento: "El SOAT de {moto} venció hoy"

---

## 14. Módulo: Perfil

### 14.1 Mi perfil

**Información visible:**
- Foto de perfil
- Nombre completo
- Número de eventos creados
- Número de rodadas asistidas
- Motos registradas
- Número de seguidores / siguiendo

**Acciones:**
- "Editar perfil" → abre formulario de edición
- "Mis inscripciones" → navega a `myRegistrations`
- Listado de eventos creados por el usuario

**Formulario de edición:**

| Campo | Notas |
|-------|-------|
| Foto de perfil | Galería o cámara del dispositivo |
| Nombre completo | |
| Número de teléfono | Usado para los botones de llamada/WhatsApp en la gestión de inscritos |
| Ciudad | Autocomplete ciudades Colombia |
| Bio corta | Máx 160 caracteres |

### 14.2 Perfil de otro rider

**Información visible:**
- Foto de perfil, nombre, ciudad, bio
- Número de seguidores / siguiendo
- Motos que tiene registradas (públicas)
- Eventos que ha organizado (públicos, futuros primero)

**Acciones:**
- "Seguir" / "Dejar de seguir" — sistema de seguidores
- Si el usuario tiene teléfono registrado y el visitante es organizador de un evento donde ese rider está inscrito → puede llamar o abrir WhatsApp

### 14.3 Sistema de seguidores

- Un usuario puede seguir a otro sin aprobación (no es mutuo obligatorio)
- La lista de seguidores y siguiendo es visible en el perfil
- No hay feed social en el MVP

---

## 15. Módulo: Notificaciones

### Tipos de notificación push (FCM)

| Evento | Destinatario | Mensaje |
|--------|-------------|---------|
| Nueva inscripción a mi evento | Organizador | "{nombre} quiere unirse a {evento}" |
| Inscripción aprobada | Rider inscrito | "¡Fuiste aceptado en {evento}! 🏍️" |
| Inscripción rechazada | Rider inscrito | "Tu solicitud para {evento} no fue aceptada" |
| Cambio de estado del evento | Todos los inscritos aprobados | "{evento} fue {cancelado / modificado}" |
| Recordatorio 24h antes del evento | Todos los inscritos aprobados | "Mañana es {evento}. ¿Listo pa' rodar?" |
| Rodada terminada (tracking) | Todos los participantes activos | "La rodada {evento} ha terminado" |
| SOAT por vencer (30 días) | Dueño del vehículo | "Tu SOAT de {moto} vence en 30 días" |
| SOAT por vencer (7 días) | Dueño del vehículo | "Tu SOAT de {moto} vence en 7 días" |
| SOAT vencido | Dueño del vehículo | "El SOAT de {moto} venció hoy" |
| Mantenimiento próximo | Dueño del vehículo | "Es hora de revisar {tipo servicio} en {moto}" |

### Centro de notificaciones

- Pantalla accesible desde el ícono de campana en el header del Home
- Lista de todas las notificaciones recibidas
- Estado leído/no leído (punto naranja)
- Tap en notificación → navega a la pantalla relevante (deep link interno)
- Badge en el ícono con conteo de no leídas

---

## 16. Deep links

La app usa Firebase Dynamic Links para compartir eventos externamente.

### Formato del link

```
https://rideglory.page.link/event/{eventId}
```

### Comportamiento

- Si la app está instalada → abre directamente el detalle del evento (`eventDetail`)
- Si la app NO está instalada → redirige a Play Store / App Store
- El evento debe ser público para ser compartible

### Generación del link

- Desde la pantalla de detalle del evento, botón de compartir (ícono share)
- Genera el Dynamic Link dinámicamente via Firebase
- Abre el share sheet nativo del dispositivo

---

## 17. Contratos de API a extender

El backend (`rideglory-api`) tiene los módulos base de Auth, Eventos, Inscripciones, Vehículos y Mantenimiento. Los siguientes endpoints son **nuevos** para el MVP:

### 17.1 SOAT

```
POST   /api/vehicles/:vehicleId/soat         — Crear/actualizar registro SOAT
GET    /api/vehicles/:vehicleId/soat         — Obtener SOAT actual del vehículo
```

**Body POST:**
```json
{
  "policyNumber": "string",
  "insurer": "string",
  "startDate": "ISO8601",
  "expiryDate": "ISO8601",
  "documentUrl": "string (Firebase Storage URL)"
}
```

### 17.2 Tracking GPS

```
GET    /api/tracking/ws?eventId={id}         — WebSocket de tracking (ya existe parcialmente)
POST   /api/events/:eventId/tracking/start   — El organizador inicia el rastreo
POST   /api/events/:eventId/tracking/end     — El organizador termina la rodada
GET    /api/events/:eventId/tracking/status  — Estado actual del rastreo
```

**Mensaje WebSocket (cliente → servidor):**
```json
{
  "type": "location",
  "lat": -4.7110,
  "lng": -74.0721,
  "speed": 65,
  "status": "riding" // "riding" | "stopped" | "offline"
}
```

**Mensaje WebSocket (servidor → cliente):**
```json
{
  "type": "riders_update",
  "riders": [
    {
      "userId": "string",
      "name": "string",
      "avatarUrl": "string",
      "lat": -4.7110,
      "lng": -74.0721,
      "speed": 65,
      "status": "riding"
    }
  ]
}
```

### 17.3 Generación de portada con IA

```
POST   /api/events/generate-cover            — Genera opciones de imagen con IA
```

**Body:**
```json
{
  "prompt": "string",
  "count": 4
}
```

**Response:**
```json
{
  "images": [
    { "url": "string", "thumbnailUrl": "string" }
  ]
}
```

El backend es responsable de llamar al proveedor de IA (OpenAI DALL-E, Stability AI u otro) y devolver las URLs.

### 17.4 Notificaciones programadas (SOAT y mantenimiento)

```
POST   /api/notifications/schedule           — Programa una notificación futura
DELETE /api/notifications/schedule/:id       — Cancela una notificación programada
```

El backend usa un job scheduler (cron) para enviar FCM a la fecha/hora indicada.

### 17.5 Sistema de seguidores

```
POST   /api/users/:userId/follow             — Seguir a un usuario
DELETE /api/users/:userId/follow             — Dejar de seguir
GET    /api/users/:userId/followers          — Lista de seguidores
GET    /api/users/:userId/following          — Lista de seguidos
```

### 17.6 Deep links — metadata de evento

```
GET    /api/events/:eventId/share-metadata   — Retorna nombre, imagen y descripción para el Dynamic Link preview
```

---

## 18. Fuera de alcance del MVP

Los siguientes features fueron identificados pero **no se implementan en el MVP**:

| Feature | Razón |
|---------|-------|
| Pagos en la app (Wompi, MercadoPago) | Complejidad legal y operativa; el pago es externo por ahora |
| Verificación automática de SOAT por placa (RUNT API) | API de RUNT no tiene acceso público; se hace manual |
| Checklist configurable por el organizador | Eliminado del MVP para reducir complejidad del formulario |
| Seguimiento de combustible | No existe demanda suficiente validada |
| Idioma inglés | Fase posterior |
| Modo offline / descarga de mapas | No requerido |
| Chat interno en la app | Solo se redirige a WhatsApp/llamada nativa |
| Marketplace de repuestos | Fase posterior |
| Integración con SOAT / seguros | Fase posterior |
| Feeds sociales (fotos de rodadas) | Fase posterior |
| Gamificación (logros, retos) | Fase posterior |

---

## Apéndice A — Pantallas del diseño (`rideglory.pen`)

| ID frame | Nombre en Pencil | Descripción |
|----------|-----------------|-------------|
| `dyWWs` | Home Dashboard | Dashboard principal |
| `Neipf` | Events List | Lista / explorador de eventos |
| `kAubW` | Event Detail | Detalle de evento |
| `PMuA4` | CTA State Variants | Variantes del botón de inscripción (referencia) |
| `zbCa0` | Crear Evento | Formulario de creación de evento |
| `pQCmS` | Registration Form V2 | Formulario de inscripción a evento |
| `oUv12` | Mi Inscripción | Detalle de inscripción del usuario |
| `dUc9h` | Editar Inscripción | Gestión de inscripción (organizador) |
| `KCf6W` | Garaje | Lista de vehículos del usuario |
| `P1GSzZ` | Detalle de Moto | Detalle de vehículo con specs y documentos |
| `EqnMm` | Agregar / Editar Moto | Formulario de vehículo |
| `aGqnv` | Documentos — Estado Lleno | Componente de documentos (referencia) |
| `SykjL` | Lista de Mantenimientos | Lista de mantenimientos (pendiente de diseño final) |
| `ulESU` | Mantenimientos — Var A (Timeline) | Variante timeline de mantenimientos |
| `WmD8t` | Mantenimientos — Var B (Cards + Filtros) | Variante cards de mantenimientos |
| `A7qDd` | Profile | Perfil del usuario (pendiente de diseño final) |
| `YCuIq` | Vehicle Bottom Sheet | Bottom sheet de selección de vehículo (componente) |
| `VMmN0` | Component/Tab Bar | Tab bar reutilizable (componente) |
| `zKkmE` | Component/Event Badge | Badge de evento (componente) |

---

*Documento generado con base en el diseño `rideglory.pen` y sesión de levantamiento de requerimientos — Mayo 2026.*
