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
| Mapas | `mapbox_maps_flutter` |
| Localización | `geolocator` |
| Notificaciones | Firebase Cloud Messaging (FCM) |
| Deep links | Firebase Dynamic Links |
| Generación de imágenes IA | Google Vertex AI — Imagen 3 (vía `rideglory-api`) |
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

### 6.1 Comportamiento

1. Muestra logo de Rideglory + tagline "Connect. Ride. Explore." sobre fondo oscuro
2. Inicializa Firebase, DI (`configureDependencies()`) y verifica estado de autenticación
3. Descarga catálogos estáticos del backend **en paralelo** (ver sección 6.2)
4. Barra de progreso de carga (estética, no técnica)
5. Después de inicialización:
   - Si hay sesión activa → navega a `/home`
   - Si no → navega a `/login`

### 6.2 Catálogos estáticos

Endpoints **públicos (sin token)** cargados al inicio y cacheados en `SharedPreferences` con TTL de 24 horas. Si la red no está disponible y no hay caché, se usan valores embebidos de respaldo.

| Catálogo | Dónde se usa |
|----------|-------------|
| Marcas de moto | Formulario de vehículo · filtro "Marcas permitidas" en eventos |
| Ciudades de Colombia | Perfil de usuario · formulario de inscripción |
| Tipos de evento | Chips de "Tipo de evento" en Crear Evento |
| Tipos de servicio de mantenimiento | Dropdown en formulario de mantenimiento |

Ver contratos de API en sección 17.7.

### 6.3 Duración máxima

- Máximo 3 segundos, luego navega independientemente del estado de carga visual

---

## 7. Módulo: Home Dashboard

### Propósito

Pantalla de bienvenida personalizada que muestra un resumen del estado del usuario: su moto principal y las próximas rodadas a las que está inscrito o a las que se puede inscribir. Se mostrarán máximo 5 eventos

### Secciones

#### 7.1 Header

- Barra superior con saludo: "Hola, {nombre}"
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
Mantenimiento vencido | Alerta inline en rojo en la card del vehículo |

---

## 8. Módulo: Eventos

### 8.1 Lista de eventos

### Reglas de negocio

- Un usuario solo podrá crear un evento si tiene al menos un vehiculo creado
- Los eventos en estado cancelled solo serán visibles para los inscritos a ese evento


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
- Mini-mapa de Mapbox con el punto de inicio marcado (estilo dark)
- Dirección legible
- Botón "Ver mapa" → deep-link a Google Maps / Apple Maps nativo

**Marcas Permitidas:**
- Chips de selección mostrando las marcas habilitadas para el evento (BMW, Ducati, KTM, Honda, Yamaha, etc.)
- Chip especial "Todas" si no hay restricción

**Inscritos: (solo es visible para el owner del evento)**
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
| El evento ya tiene el maximo de inscritos | Botón de inscribirse deshabilitado y texto que indique que no hay cupo |

#### Estado del evento

| Estado | Descripción |
|--------|-------------|
| `scheduled` | El evento aún no ha comenzado |
| `in_progress` | El evento está en curso (Lo inicia el owner) |
| `finished` | El evento ya pasó |
| `cancelled` | El organizador canceló el evento |

### 8.4 Crear evento

#### Campos del formulario

| Campo | Tipo | Requerido | Notas |
|-------|------|-----------|-------|
| Portada | Imagen | Si | "Subir imagen" (galería/cámara) o "Generar con IA" (ver sección 8.4.1) |
| Nombre del evento | Text | Sí | |
| Descripción | Text area | Si | Máx 2000 caracteres |
| Fecha de inicio | Date picker | Sí | Formato DD/MM/YYYY |
| Fecha de fin | Date picker | No | Debe ser igual o posterior a inicio |
| Hora de encuentro | Time picker | Sí | Hora de partida del grupo |
| Punto de encuentro / Partida | Mapbox Geocoding (search box) | Sí | Origen de la ruta; al seleccionarlo, el mini-mapa preview se centra en ese punto |
| Punto de llegada / destino | Mapbox Geocoding (search box) | No | Destino final; al completar origen + destino, el mini-mapa dibuja la ruta calculada (Mapbox Directions API, llamada desde el backend) con una línea naranja. Esta ruta queda guardada como polyline y será visible para todos los riders durante el rastreo en vivo |
| Dificultad | Selector de llamas (1–5) | No | 5 niveles; muestra descripción textual del nivel seleccionado |
| Tipo de evento | Chips multi-select | No | On-Road, Off-road, Urbana, Competición, Solidaria |
| Marcas permitidas | Multi-select | No | Marcas de moto habilitadas para el evento |
| Máximo de participantes | Number | No | Sin límite si se deja vacío |
| Precio de inscripción | Number (COP) | No | Toggle "Gratuito" para fijar en $0; si hay precio es informativo, el cobro se coordina fuera de la app |

#### 8.4.1 Generación de ilustración con IA

**Tecnología:** Google Vertex AI — Imagen 3, invocado desde `rideglory-api` (la API key nunca sale del backend).

**Flujo:**
1. El usuario toca "Generar ilustración IA"
2. Se abre un bottom sheet con un campo de texto: "Describe la portada que quieres" (ej. "Amanecer en carretera montañosa de los Andes con una KTM naranja")
3. La app llama a `POST /api/events/generate-cover` con el prompt
4. El backend valida el cupo diario del usuario (máximo **2 generaciones/día** en plan gratuito)
5. Si hay cupo → invoca Imagen 3 en Vertex AI, recibe hasta 4 imágenes
6. Se muestran las opciones generadas en un grid 2×2 dentro del bottom sheet
7. Cada imagen tiene dos acciones:
   - **Seleccionar** → se sube a Firebase Storage y se usa como portada del evento
   - **Descargar** (ícono de descarga) → guarda la imagen en la galería del dispositivo
8. El usuario puede descargar cualquier imagen independientemente de si la selecciona como portada
9. Estado de carga con spinner y mensaje "Generando ilustración…" durante la espera

**Límite de generaciones:**

| Plan | Generaciones por día |
|------|----------------------|
| Gratuito | 2 |
| (futuro) Pro | Sin límite |

Si el usuario agota su cupo, el botón se deshabilita y muestra "Límite diario alcanzado (2/2)". El contador se reinicia a las 00:00 UTC.

#### Flujo de publicación

1. El usuario completa el formulario
2. **Publicar evento** (botón primario naranja): valida el formulario → si hay errores, marca en rojo y hace scroll al primero → si todo está OK, crea el evento y navega a su detalle
3. **Guardar como borrador** (enlace secundario bajo el botón): guarda sin publicar; el evento queda en estado `draft` y no es visible para otros usuarios

#### Editar evento

- La pantalla de edición usa el mismo formulario
- Solo el creador del evento puede editarlo
- No se puede editar la fecha si el evento ya tiene inscritos aprobados (mostrar advertencia)
- No se puede editar si el evento está en estado `in_progress` o `finished` o `cancelled`

---

## 9. Módulo: Inscripciones

### 9.1 Mis inscripciones

Lista de todos los eventos a los que el usuario se ha inscrito, agrupados por estado:
- **Próximos** (aprobados con fecha futura)
- **Pendientes** (esperando aprobación del organizador)
- **Pasados** (eventos ya realizados, en los que se solicitó la inscripción)
- **Rechazados**

Por cada inscripción: nombre del evento, fecha, estado con chip de color.

### 9.2 Detalle de inscripción

- Header "Mi Inscripción" con botón back
- **Card del evento:** nombre, fecha y ciudad + badge de estado (Confirmada / Pendiente / Rechazada)
- **Card de datos de participación:**
  - Moto registrada (marca + modelo + año)
  - Tipo de participación (Rider principal / Acompañante)
  - Número de acompañantes
- **Card de contacto de emergencia:** nombre + teléfono
- **Card "Código QR de acceso"** (borde naranja): tap → QR en pantalla completa para presentar en el punto de encuentro
- Botón **"Editar Inscripción"** (naranja) → permite modificar los datos antes de que el evento comience. Muestra mensaje del organizador
- Botón **"Cancelar inscripción"** (rojo, fondo tenue) → solo si está pendiente o el evento aún no comenzó
- Si está rechazada: muestra mensaje del organizador (si lo dejó)

### 9.3 Flujo de inscripción

1. Desde el detalle del evento, el usuario toca "Inscribirte"
2. Navega a la pantalla de formulario con un **stepper de 4 secciones** en un page viewer:

**Sección 1 — Información Personal**

| Campo | Tipo |
|-------|------|
| Nombre completo | Text |
| Número de identificación | Text (cédula u otro doc) |
| Fecha de nacimiento | Date picker |
| Teléfono | Phone |
| Correo electrónico | Email |
| Ciudad de residencia | Autocomplete |

**Sección 2 — Información Médica**

| Campo | Tipo |
|-------|------|
| EPS | Text |
| Seguro médico | Text (opcional) |
| Tipo de sangre | Chips selector (A+, A−, B+, B−, AB+, AB−, O+, O−) |

**Sección 3 — Contacto de Emergencia**

| Campo | Tipo |
|-------|------|
| Nombre del contacto | Text |
| Teléfono del contacto | Phone |

**Sección 4 — Vehículo de Inscripción**
- Selector de moto del garaje del usuario con botón "Cambiar"

3. Botón **"Confirmar Inscripción"** fijo en la parte inferior → crea la inscripción en estado `pending`
4. El organizador recibe una notificación push

### 9.4 Gestionar inscritos

Accesible solo para el creador del evento.

#### Secciones

**Nuevas solicitudes** (estado `pending`):
- Lista de usuarios con foto, nombre, moto con la que va
- Acciones por cada solicitud:
  - ✅ Aprobar → cambia a `approved`, se notifica al usuario
  - ❌ Rechazar → bottom sheet para ingresar motivo opcional → cambia a `rejected`, se notifica
  - Solicitar edición → bottom sheet para ingresar motivo obligatorio → cambia a `ready_for_edit`, se notifica al usuario
  - 📞 Llamar → abre dialer nativo con el teléfono del inscrito (si lo tiene registrado en perfil)
  - 💬 WhatsApp → abre WhatsApp con el número del inscrito (si lo tiene)

**Ya procesados** (TODOS LOS ESTADOS):
- Lista con el estado visible
- Permite revertir (cambiar de aprobado a rechazado o viceversa)

#### Búsqueda y filtro

- Barra de búsqueda por nombre
- Filtro por estado (Todos / Pendientes / Aprobados / Rechazados / Editando)

---

## 10. Módulo: Rastreo en tiempo real

### Condiciones de activación

- Solo disponible cuando el evento está en estado `active`
- El usuario debe estar aprobado en el evento
- Se activa la primera vez que el usuario entra a la pantalla de rastreo del evento
- Se **desactiva automáticamente** cuando el evento cambia a estado `finished`

---

### 10.1 Pantalla principal de rastreo

#### Mapa (capa base)

- Mapbox a pantalla completa (estilo dark personalizado, compatible con la paleta de Rideglory)
- **Ruta del evento** trazada sobre el mapa (polilínea naranja) si el organizador la definió al crear el evento
- Marcador de origen (punto de encuentro) y destino de la ruta
- Marcador propio: ícono de moto en color diferenciado (naranja)
- Marcadores de otros riders: foto de perfil como pin; al estar en SOS → pin rojo pulsante
- Centro automático en la posición propia al entrar; luego el usuario puede mover el mapa libremente
- Botón "Centrar en mi posición"
- Indicador de adherencia a la ruta (chip discreto): "En ruta ✓" / "Fuera de ruta ⚠" — solo visible si el organizador definió una ruta

#### Overlay de información superior (no invasivo)

Barra compacta en la parte superior del mapa:
- Velocidad promedio del grupo (km/h)
- Número de riders activos / total
- Distancia al líder (organizador) en km

#### Lista de participantes (overlay lateral o bottom sheet mini)

Panel no invasivo, siempre visible en la esquina inferior o como bottom sheet parcial colapsado. Por cada rider muestra en formato compacto:
- Avatar + nombre
- Velocidad actual (km/h)
- Estado: `Rodando` / `Detenido` / `Sin señal`
- Moto
- Badge **"Líder"** si es el organizador, badge **"Tú"** si es el usuario actual
- Nivel de batería del dispositivo (ícono)

Tap en un rider → abre **pantalla de detalle del participante** (ver sección 10.2)

#### Botón SOS

- Botón prominente y siempre visible en el mapa (esquina inferior derecha, color rojo)
- Al presionar: pide confirmación ("¿Enviar alerta de emergencia?")
- Al confirmar:
  - El marcador del usuario cambia a **rojo pulsante** en el mapa de todos los participantes
  - Se envía una **notificación push de emergencia** a todos los riders del evento: "🆘 {nombre} necesita ayuda — {ubicación}"
  - El estado del rider cambia a `sos` en el WebSocket
  - En el mapa de los demás aparece un banner rojo: "{nombre} emitió una alerta SOS"
  - Cada participante ve dos acciones sobre el rider en SOS:
    - 📞 **Llamar** → abre el dialer nativo con su teléfono
    - 📍 **Localizar** → deep-link a Google Maps / Apple Maps con navegación hasta su posición

#### Botón "Terminar rodada"

- Solo visible para el organizador del evento
- Al tocarlo → diálogo de confirmación
- Al confirmar: cambia el estado del evento a `finished` en el backend; todos los riders reciben push "La rodada ha terminado" y la pantalla se cierra automáticamente para todos

---

### 10.2 Pantalla de detalle de participantes

Pantalla completa accesible desde la lista compacta del mapa.

#### Header y filtros

- Título "Participantes ({n})"
- Buscador por nombre (filtra en tiempo real)
- Chips de filtro por estado: Todos / Rodando / Detenido / Sin señal / SOS

#### Lista de participantes (detallada)

Por cada rider:
- Avatar + nombre + badge Líder/Tú
- Moto (marca + modelo)
- Velocidad actual (km/h)
- Estado con color semántico
- Distancia a la que está de mí (en km, actualizada en tiempo real)
- Nivel de batería del dispositivo
- Botones de contacto (visibles si el rider tiene teléfono registrado y si soy el owner del evento):
  - 📞 Llamar → dialer nativo
  - 💬 WhatsApp → enlace `wa.me/{phone}`
- Si el rider está en SOS: banner rojo + botón 📍 Localizar + llamada de emergencia (cualquier persona lo puede llamar o localizar)

#### Tap en un rider

Abre el perfil publico del Rider

---

### 10.3 Ruta del evento en el mapa

La ruta personalizada la define el organizador en el formulario de creación/edición del evento (ver sección 8.4). El módulo de rastreo la consume así:

- Si el evento tiene ruta definida: se dibuja como polilínea naranja sobre el mapa Mapbox al iniciar la rodada
- El backend expone la polyline encoded vía `GET /api/events/:eventId/route`

#### Indicador de adherencia (opcional para el rider)

- El rider puede activar/desactivar "Seguir ruta" desde el mapa
- Cuando está activo: el app calcula si el rider está dentro de un radio de 200 m de la polilínea
  - **En ruta:** chip verde discreto "En ruta ✓"
  - **Fuera de ruta:** chip naranja "Fuera de ruta ⚠" + vibración suave

---

### 10.4 Comportamiento GPS en background

- Mientras la app está en segundo plano, sigue enviando la ubicación al WebSocket cada **5 segundos**
- Se muestra una notificación persistente del sistema: "Rideglory — Rodada activa"
- Si el usuario no tiene conexión → los mensajes se encolan y se reenvían al reconectar

---

### 10.5 WebSocket

- Se conecta a `GET /api/tracking/ws?eventId={id}`
- Auto-reconexión con backoff exponencial si se pierde la conexión

**Cliente → servidor (ubicación):**
```json
{
  "type": "location",
  "lat": -4.7110,
  "lng": -74.0721,
  "speed": 65,
  "heading": 270,
  "batteryLevel": 82,
  "status": "riding"
}
```
`status`: `"riding"` | `"stopped"` | `"offline"` | `"sos"`

**Cliente → servidor (SOS):**
```json
{
  "type": "sos",
  "lat": -4.7110,
  "lng": -74.0721
}
```

**Servidor → cliente (actualización de riders):**
```json
{
  "type": "riders_update",
  "riders": [
    {
      "userId": "string",
      "name": "string",
      "avatarUrl": "string",
      "vehicleName": "string",
      "isOrganizer": true,
      "lat": -4.7110,
      "lng": -74.0721,
      "speed": 65,
      "heading": 270,
      "batteryLevel": 82,
      "status": "riding",
      "distanceToMe": 1.4
    }
  ]
}
```

**Servidor → cliente (alerta SOS):**
```json
{
  "type": "sos_alert",
  "userId": "string",
  "name": "string",
  "phone": "string",
  "lat": -4.7110,
  "lng": -74.0721
}
```

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
- **Sección "Otras motos":** lista compacta con foto thumbnail + nombre (Marca + Modelo), año · CC · odómetro actual; cada ítem navega a `vehicleDetail`
- Tap en cualquier vehículo → navega a `vehicleDetail`

### 11.2 Detalle de vehículo

- Header: nombre del vehículo + botón back + botón editar (lápiz) → navega a `editVehicle`
- Foto del vehículo (full-width)
- Badge "Moto principal" (si aplica)
- Datos de identificación: Placa · año · CC
- **Especificaciones técnicas:**
  - Motor (CC + configuración, ej. "869cc, parallel-2 clt")
  - Potencia (hp)
  - Torque (Nm)
  - Peso (kg)
  - Color
- **Documentos del vehículo:**
  - SOAT: badge Vigente / Por vencer / Vencido / Sin registro → tap → flujo SOAT
  - Revisión técnica: badge de estado → tap → flujo de documento
- Chips de fechas: último servicio · próximo servicio
- Botón "Ver historial de mantenimientos" → navega a `maintenance` filtrado por este vehículo
- Archivar → opción en menú "···" del header (desactiva el vehículo; no lo elimina)

### 11.3 Formulario de vehículo

**Escanear tarjeta de propiedad:** Banner con borde naranja en la parte superior del formulario. Al tappear → abre cámara para escanear la tarjeta de propiedad del vehículo; si el escaneo es exitoso, auto-rellena Marca, Modelo, Año, CC y Placa.

**Campos:**

| Campo | Tipo | Requerido | Notas |
|-------|------|-----------|-------|
| Foto | Imagen | No | Galería o cámara |
| Marca | Autocomplete | Sí | Catálogo del backend cargado en splash (ver sección 6.2) |
| Modelo | Text | Sí | El nombre del vehículo se compone automáticamente como "Marca Modelo" |
| Año | Number / picker | Sí | Rango 1990–año actual |
| Cilindraje (CC) | Number | Sí | |
| Color | Text | No | |
| Placa | Text | Sí | Validación formato colombiano (ABC-123 o ABC12D) |
| Transmisión | Chips | No | Manual / Automática |
| Peso (kg) | Number | No | |
| ¿Es tu moto principal? | Switch | No | Solo puede haber una principal |
| Mantenimiento recomendado | Toggle + Sección | No | Si activo: muestra campos de intervalo (km y/o meses) |

**Documentos del vehículo** (sección al final del formulario):
- Slot SOAT: estado actual + acceso rápido al flujo de carga (ver sección 13)
- Slot Revisión técnica: ídem
- Permiten iniciar la gestión de documentos sin salir del formulario

---

## 12. Módulo: Mantenimiento

### 12.1 Dashboard de mantenimiento

Pantalla principal del módulo. Acceso desde el tab Garaje → vehículo seleccionado o desde el botón de acceso rápido "Mantenimiento" en la card principal del garaje.

**Header:**
- Título "Mantenimientos" + ícono de filtros (≡) + botón "+" (naranja) → inicia flujo de registro

**Estado del vehículo:**
- Donut chart con porcentaje de salud general del vehículo (basado en servicios al día vs atrasados)
- Texto: "X de Y servicios al día" + indicador del servicio más urgente vencido

**Secciones por urgencia:**

| Sección | Color | Criterio |
|---------|-------|---------|
| ATRASADO | Rojo | El km programado ya fue superado o la fecha pasó |
| PRÓXIMAMENTE | Amarillo | Faltan ≤ 1,500 km o ≤ 30 días |
| AL DÍA | Verde | Dentro del margen seguro |

Cada ítem muestra: ícono de tipo · nombre del servicio · km restantes al próximo · badge de estado.

### 12.2 Historial de mantenimientos

Vista cronológica de todos los registros. Accesible desde botón "Ver historial" en el detalle del vehículo (sección 11.2).

- **Resumen:** total de servicios realizados + total gastado (COP)
- Registros **agrupados por año** en orden descendente
- Por cada registro: ícono de tipo · nombre · costo · fecha · odómetro · badge Completado / Pendiente

### 12.3 Filtros (bottom sheet)

Deslizable desde la lista. Secciones:
- **Tipo de mantenimiento** (chips multi-select): Aceite, Frenos, Llantas, Revisión, Filtro de aire, Cadena, Electricidad, Otro
- **Estado** (chips single-select): Todos / Atrasado / Próximo / Al día
- **Rango de fecha**: Este mes · Últimos 3 meses · Último año · Personalizado (date range picker)
- Botón "Aplicar" (naranja) + "Limpiar todo"

### 12.4 Flujo de registro — Nuevo Mantenimiento (3 pasos)

#### Paso 1 — Tipo de servicio

Grid 2×4 de tarjetas con ícono y nombre. Tipos disponibles (catálogo del backend, ver sección 6.2):

Cambio de aceite · Revisión de frenos · Cambio de llantas · Revisión general · Filtro de aire · Cadena y piñones · Electricidad · Otro

Al seleccionar uno → "Continuar".

#### Paso 2 — Detalles

Dos modos seleccionables con tabs al inicio del formulario:

**Tab "Completado"** — servicio ya realizado:

| Campo | Tipo | Requerido | Notas |
|-------|------|-----------|-------|
| Fecha del servicio | Date picker | Sí | |
| Kilómetros al momento | Number (km) | Sí | Odómetro en el momento del servicio |
| Gasto total | Number (COP) | No | |
| Taller / Mecánico | Text | No | |
| Notas / Observaciones | Text area | No | Insumos usados, observaciones técnicas |
| Próximo servicio en | Number (km) | No | Intervalo en km para el siguiente servicio |
| Fecha programada próximo | Date picker | No | Alternativa o complemento al intervalo en km |

**Tab "Programado"** — servicio futuro planificado:

| Campo | Tipo | Requerido | Notas |
|-------|------|-----------|-------|
| Notas / Observaciones | Text area | No | |
| Próximo servicio en | Number (km) | Sí | Km objetivo del próximo servicio |
| Fecha programada | Date picker | No | |

El app calcula y muestra automáticamente: días que faltan y km estimados al próximo servicio (basado en odómetro actual del vehículo).

#### Paso 3 — Vehículo

Selector del vehículo al que aplica el servicio. Si se entró desde un vehículo específico, viene pre-seleccionado.

**CTA final:** "Guardar mantenimiento" (naranja) · "Descartar" (link rojo)

### 12.5 Recordatorios de mantenimiento

Si el usuario define "próximo servicio":
- Push 30 días antes de la fecha programada: "Tu {tipo} está próximo — {X} días"
- Push cuando el odómetro estimado se acerca a 500 km del objetivo: "Tu {tipo} se acerca — faltan ~500 km"
- El odómetro del vehículo se actualiza manualmente por el usuario

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
- Motos que tiene registradas (públicas y solo información no sensible)
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
GET    /api/tracking/ws?eventId={id}         — WebSocket de tracking
POST   /api/events/:eventId/tracking/start   — El organizador inicia el rastreo
POST   /api/events/:eventId/tracking/end     — El organizador termina la rodada
GET    /api/events/:eventId/tracking/status  — Estado actual del rastreo
GET    /api/events/:eventId/route            — Obtiene la polilínea de la ruta del evento (si existe)
```

Ver contratos completos de mensajes WebSocket en la sección 10.5.

**Ruta del evento — body al crear/editar evento:**
```json
{
  "route": {
    "origin": { "lat": -4.7110, "lng": -74.0721, "address": "string" },
    "destination": { "lat": -4.8000, "lng": -74.1000, "address": "string" },
    "polyline": "encoded_polyline_string"
  }
}
```

**Notificación SOS** — el backend recibe el mensaje `sos` por WebSocket y:
1. Emite `sos_alert` a todos los demás riders del evento via WebSocket
2. Envía push FCM de emergencia a todos los participantes aprobados

### 17.3 Generación de portada con IA

**Tecnología:** Google Vertex AI — Imagen 3. La service account del proyecto GCP autentica la llamada; la API key nunca llega al cliente.

```
POST   /api/events/generate-cover            — Genera opciones de imagen con IA
GET    /api/events/generate-cover/quota      — Consulta cupo diario restante del usuario
```

**Body POST:**
```json
{
  "prompt": "string"
}
```

**Response POST (éxito):**
```json
{
  "images": [
    { "url": "string" }
  ],
  "quotaUsed": 1,
  "quotaRemaining": 1
}
```

**Response POST (cupo agotado — HTTP 429):**
```json
{
  "error": "daily_quota_exceeded",
  "quotaUsed": 2,
  "quotaRemaining": 0,
  "resetsAt": "2026-05-14T00:00:00Z"
}
```

**Lógica de cuota (backend):**
- El backend lleva un contador por `userId` y fecha UTC en base de datos
- Plan gratuito: máximo **2 generaciones por día** (00:00–23:59 UTC)
- Si se supera el límite → HTTP 429 sin invocar Vertex AI
- El backend genera 4 variantes por llamada (parámetro fijo `sampleCount: 4` en Vertex AI)
- Las imágenes se retornan como data URLs o se suben a Firebase Storage temporal

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

### 17.7 Catálogos estáticos

Endpoints públicos, sin token de autenticación. Cargados en splash (ver sección 6.2). El backend debe incluir `Cache-Control: public, max-age=86400`.

```
GET    /api/catalogs/brands          — Marcas de moto
GET    /api/catalogs/cities          — Ciudades de Colombia
GET    /api/catalogs/event-types     — Tipos de evento
GET    /api/catalogs/service-types   — Tipos de servicio de mantenimiento
```

**Response (todas igual):**
```json
[
  { "id": "string", "name": "string" }
]
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
| `qonbS` | Event Tracking — Map | Mapa de rastreo en tiempo real (ruta, riders, SOS) |
| `OEqDE` | Event Tracking — Riders Panel | Panel detallado de participantes en rastreo |
| `pQCmS` | Registration Form V2 | Formulario de inscripción a evento |
| `oUv12` | Mi Inscripción | Detalle de inscripción del usuario |
| `dUc9h` | Editar Inscripción | Gestión de inscripción (organizador) |
| `KCf6W` | Garaje | Lista de vehículos del usuario |
| `P1GSzZ` | Detalle de Moto | Detalle de vehículo con specs y documentos |
| `EqnMm` | Agregar / Editar Moto | Formulario de vehículo |
| `aGqnv` | Documentos — Estado Lleno | Componente de documentos (referencia) |
| `Ako7u` | Mantenimientos — Dashboard | Vista principal con salud del vehículo y servicios por urgencia |
| `SykjL` | Mantenimientos — Historial | Lista cronológica agrupada por año con resumen de gasto |
| `v6RqaX` | Mantenimientos — Filtros | Bottom sheet de filtros (tipo, estado, rango de fecha) |
| `J5h6P` | Nuevo Mantenimiento — Paso 1 | Selección de tipo de servicio (grid 2×4) |
| `eK2WW` | Nuevo Mantenimiento — Paso 2 (Completado) | Detalles de servicio ya realizado |
| `ELB5u` | Nuevo Mantenimiento — Paso 2 (Programado) | Detalles de servicio futuro planificado |
| `nxTub` | Event Tracking — Estado SOS | Mapa de rastreo con alerta SOS activa (banner + llamar/localizar) |
| `ulESU` | Mantenimientos — Var A (Timeline) | Variante timeline de mantenimientos |
| `WmD8t` | Mantenimientos — Var B (Cards + Filtros) | Variante cards de mantenimientos |
| `A7qDd` | Profile | Perfil del usuario (pendiente de diseño final) |
| `YCuIq` | Vehicle Bottom Sheet | Bottom sheet de selección de vehículo (componente) |
| `VMmN0` | Component/Tab Bar | Tab bar reutilizable (componente) |
| `zKkmE` | Component/Event Badge | Badge de evento (componente) |

---

*Documento generado con base en el diseño `rideglory.pen` y sesión de levantamiento de requerimientos — Mayo 2026.*
