# PRD — Legal: Validación de edad en eventos y modelo de privacidad de datos

**Tipo:** Feature (seguridad + privacidad) + decisiones legales pendientes
**Prioridad:** Alta
**Issue:** #46
**Fecha de creación:** 2026-06-16
**Scope:** App Flutter (registro a eventos, perfil de inscripción) + backend `rideglory-api`

---

## 1. Problema

Hay tres riesgos activos:

1. **Sin validación de edad:** Un menor de cualquier edad puede inscribirse en un evento de motociclismo. Si hay un accidente, la responsabilidad del organizador —y de la plataforma— se amplifica significativamente.

2. **Sobreexposición de datos personales:** El creador de un evento ve todos los datos de cada inscrito (nombre, cédula, fecha de nacimiento, teléfono, correo, ciudad, EPS, seguro médico, tipo de sangre, contacto de emergencia). Un usuario que se inscribe con alguien que no conoce está exponiendo datos sensibles sin graduación de necesidad.

3. **Sin canal de comunicación formal:** El organizador necesita contactar a los inscritos para coordinar (punto de encuentro, cambios de ruta), pero hoy no hay forma integrada de hacerlo. Esto lleva a que el teléfono se exponga como proxy para comunicación, cuando debería tener un propósito más acotado.

---

## 2. Objetivos

- Bloquear el registro a **eventos** de usuarios menores del límite definido (no el registro a la app).
- Crear un **modelo de privacidad por capas** para los datos de los inscritos, diferenciando datos médicos (seguridad) de datos personales (privacidad).
- Dar al usuario **control** sobre si comparte su teléfono con el organizador para coordinación.

**No-objetivos:**
- No modificar el proceso de registro a la app.
- No eliminar ningún campo del `UserModel` (todos siguen siendo recolectados).
- No construir un canal de mensajería interno (no es el scope — se usa WhatsApp/llamada).

---

## 3. Validación de edad en eventos

### 3.1 Lógica

La validación ocurre en el momento en que el usuario intenta inscribirse a un evento:

```
edad_usuario = hoy - birthDate
si edad_usuario < edad_minima_evento → bloquear inscripción con mensaje claro
```

El campo `birthDate` ya existe en `UserModel`. Si el usuario no tiene `birthDate` registrado, se bloquea la inscripción hasta que lo complete en su perfil.

### 3.2 Edad mínima — recomendación

Colombia establece **16 años** como la edad mínima para obtener licencia de conducción de motocicleta (categoría A1). La mayoría de edad legal es **18 años**.

**Recomendación técnica:** el backend expone un campo `minAgeRequirement` por evento (entero, en años). El creador del evento lo configura. El sistema impone:

| Regla | Valor |
|---|---|
| Mínimo absoluto de la plataforma | 16 años (hard cap — no negociable) |
| Valor por defecto al crear un evento | 18 años |
| Rango configurable por el organizador | 16–99 años |

Razón del default en 18: reduce la responsabilidad de la plataforma ante menores sin requerir validación de consentimiento parental. Un organizador que quiera permitir 16–17 años lo hace explícitamente y asume esa responsabilidad.

### 3.3 Mensaje de bloqueo (l10n)

```arb
"event_registration_age_blocked_title": "No cumples con el requisito de edad",
"event_registration_age_blocked_body": "Este evento requiere tener al menos {minAge} años. Actualiza tu fecha de nacimiento en tu perfil si crees que hay un error.",
"event_registration_age_missing_title": "Completa tu perfil",
"event_registration_age_missing_body": "Necesitamos tu fecha de nacimiento para verificar que cumples con el requisito de edad de este evento."
```

### 3.4 Implementación

- **Backend:** agregar campo `minAgeRequirement: Int` al modelo de evento (default 18). Validar en el endpoint de inscripción (`POST /events/:id/registrations`) comparando `birthDate` del usuario con la fecha actual.
- **App:** antes de mostrar el formulario de inscripción, verificar localmente y mostrar el mensaje si no cumple. La validación real la hace el backend.
- **Formulario de creación de evento:** añadir campo de edad mínima (selector numérico, 16–99, default 18).

---

## 4. Modelo de privacidad por capas para inscripciones

### 4.1 Capas de visibilidad

El `EventRegistrationModel` expone hoy todos los campos sin distinción. Se propone dividirlos en tres capas:

#### Capa A — Siempre visible para el organizador (seguridad médica)
Datos que el organizador **necesita siempre** para responder ante una emergencia, aunque el rider esté inconsciente:

- Tipo de sangre
- EPS
- Seguro médico adicional
- Contacto de emergencia (nombre + teléfono)

> Justificación: el organizador que aprueba una inscripción asume corresponsabilidad de la seguridad del rider durante el evento. Sin estos datos, no puede coordinar con servicios de emergencia.

#### Capa B — Solo visible durante SOS activo del rider
Datos personales que no son necesarios para la gestión del evento, pero sí durante una emergencia grave:

- Número de cédula / identificación
- Correo electrónico
- Ciudad de residencia
- Fecha de nacimiento

El SOS activo ya tiene un mecanismo de propagación vía WebSocket. Se extiende para que, durante el SOS, la ficha del rider en la lista de inscritos del organizador muestre estos campos desbloqueados.

#### Capa C — Controlado por el usuario (opt-in de contacto)
El teléfono tiene doble propósito: coordinación logística y emergencia. Se delega la decisión al rider:

| Opción del rider | Visibilidad del teléfono para el organizador |
|---|---|
| **Compartir para coordinación** (opt-in activo) | Visible siempre en la ficha de inscripción, con botones de acción |
| **No compartir** (default) | Solo visible durante SOS activo del rider |

Los demás riders (no organizador) **nunca ven el teléfono**, excepto durante el SOS del rider (comportamiento actual del banner de SOS, sin cambio).

### 4.2 UI del opt-in de contacto (rider)

En el formulario de inscripción a un evento, se añade una sección:

```
┌────────────────────────────────────────────────────┐
│ Coordinación del evento                            │
│                                                    │
│ Permitir que el organizador me contacte            │
│ vía WhatsApp o llamada para coordinar el evento    │
│                                ┌─────────────────┐ │
│                                │  AppSwitchTile  │ │
│                                └─────────────────┘ │
│ Tu número solo se usa para este evento.            │
└────────────────────────────────────────────────────┘
```

Este valor se persiste en `EventRegistrationModel` como `allowOrganizerContact: bool` (default: false).

### 4.3 UI del organizador — ficha del inscrito

La `RegistrationDetailPage` se reorganiza en secciones con visibilidad condicional:

```
┌─────────────────────────────────────────────────┐
│ INFORMACIÓN MÉDICA              [siempre visible] │
│ Tipo de sangre: O+                               │
│ EPS: Sura                                        │
│ Seguro adicional: Mapfre                         │
│ Contacto de emergencia: Ana Torres · 3001234567  │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ CONTACTO                                         │
│ [Si allowOrganizerContact = true]                │
│ 📞 3009876543    [Llamar] [WhatsApp]             │
│                                                  │
│ [Si allowOrganizerContact = false]               │
│ El participante no ha compartido su contacto     │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ DATOS PERSONALES        [bloqueado sin SOS]      │
│ 🔒 Cédula, correo y ciudad solo se muestran     │
│    cuando el participante activa una alerta SOS  │
│                                                  │
│ [Durante SOS activo del rider]                   │
│ Cédula: 1234567890                               │
│ Correo: ejemplo@mail.com                         │
│ Ciudad: Medellín                                 │
└─────────────────────────────────────────────────┘
```

### 4.4 Botones de acción de contacto

Cuando `allowOrganizerContact = true`, los botones deben:
- **Llamar:** abrir `tel://+57XXXXXXXXXX` con el número del rider.
- **WhatsApp:** abrir `https://wa.me/57XXXXXXXXXX` (número sin el `+`).

Usar `url_launcher` (ya es dependencia del proyecto).

---

## 5. Marco legal colombiano — hallazgos verificados

> Análisis basado en investigación multi-fuente sobre legislación y jurisprudencia colombiana (junio 2026). **No reemplaza asesoría jurídica formal.**

### 5.1 Responsabilidad civil del organizador (Alta confianza)

**Arts. 2341 y 2356 del Código Civil** imponen responsabilidad extracontractual a quien ejecuta actos peligrosos. La **Corte Suprema de Justicia** (Sentencia EXP. 5012, 25 oct. 1999; CSJ-SC2111 de 2021) estableció que en actividades peligrosas la responsabilidad **se presume**: la víctima solo prueba la actividad, el daño y el nexo causal. El organizador **solo se exonera** demostrando *causa extraña* (fuerza mayor, hecho exclusivo de la víctima o de un tercero). **Demostrar diligencia no exonera.**

**Implicación:** Un organizador que crea un evento de motociclismo a través de Rideglory está expuesto a responsabilidad civil con presunción en su contra si ocurre un accidente.

### 5.2 Validez del waiver digital (Confianza media)

Un checkbox de aceptación de T&C tiene **valor probatorio limitado** en actividades peligrosas bajo el Art. 2356. Aporta evidencia de que el participante conocía los riesgos (elemento de defensa de *hecho exclusivo de la víctima*), pero **no elimina la presunción de responsabilidad** del organizador.

La **Ley 527 de 1999** y el **Decreto 2364 de 2012** reconocen la firma electrónica, pero para waivers de actividades peligrosas un tribunal podría exigir mayor formalidad.

**Conclusión práctica:** El waiver digital es útil como evidencia complementaria, nunca como única protección. Combinarlo con firma electrónica cualificada aumenta su peso probatorio.

### 5.3 Menores de 16-17 años (Alta confianza)

La **Ley 769 de 2002, Art. 19** establece edad mínima de 16 años para licencia de moto. Los menores de 18 que tramitan licencia **deben presentar autorización escrita y autenticada de los padres**, quienes asumen responsabilidad civil y penal.

La **Ley 1098 de 2006** (Código de Infancia y Adolescencia, Arts. 14 y 18) impone a los padres la obligación de cuidado. Un organizador que permite la participación de un menor sin verificar el consentimiento parental **asume responsabilidad potencial** ante un accidente.

**Conclusión práctica:** La plataforma debe exigir autorización parental verificable para inscritos de 16-17 años. La opción más simple y segura es mantener **18 años como límite mínimo por defecto**.

### 5.4 Tratamiento de datos sensibles — Ley 1581 de 2012 (Alta confianza)

Los datos de **EPS, tipo de sangre y seguro médico son datos sensibles** bajo el **Art. 5 de la Ley 1581**. Esto implica:

- Se requiere **autorización previa, expresa e informada** del titular — **incluirlos en la política de privacidad no es suficiente**.
- La autorización debe ser **separada y específica** para el tratamiento de datos sensibles.
- El propósito del tratamiento debe estar **declarado explícitamente** (ej. "seguridad en emergencias durante eventos de motociclismo").
- El organizador que accede a estos datos se convierte en **corresponsable del tratamiento** — debe quedar documentado.

**Acción técnica requerida:** Antes de que el usuario complete su perfil médico, mostrar una **pantalla de autorización separada** (no un checkbox en T&C generales) con declaración de datos, propósito, destinatarios y botón "Autorizar" explícito.

### 5.5 Responsabilidad plataforma vs. organizador (Incierto — requiere abogado)

La **Ley 1480 de 2011** (Estatuto del Consumidor) podría aplicar si Rideglory es vista como prestadora de servicios a los participantes. No hay jurisprudencia clara sobre plataformas de coordinación de eventos deportivos en Colombia.

**Preguntas que requieren respuesta jurídica formal:**
1. ¿Rideglory es intermediario neutral o co-organizador con responsabilidad solidaria?
2. ¿Los T&C pueden transferir toda la responsabilidad al organizador del evento?
3. ¿Se necesita una póliza de responsabilidad civil a nivel de plataforma?

### Acciones técnicas que mitigan riesgo sin asesoría legal previa

Estas se pueden implementar ahora como señales de buena fe:

| Acción | Justificación |
|---|---|
| Validación de edad mínima (16 años hard cap) | Reduce exposición ante menores |
| Mostrar aviso de riesgo al inscribirse | "Los eventos de motociclismo implican riesgos. Tu participación es voluntaria." |
| Guardar timestamp de aceptación de T&C | Evidencia de consentimiento informado |
| Anonimizar datos en analytics | Cumplimiento básico Ley 1581 |
| No compartir datos médicos con terceros | Limitación del propósito de tratamiento |

---

## 6. Mecanismos de exoneración de responsabilidad

Estos tres mecanismos, implementados en conjunto, construyen la defensa técnica de Rideglory como intermediario neutral y documentan la cadena de responsabilidad hacia el organizador.

### 6.1 Separación contractual en T&C (texto obligatorio)

Los Términos y Condiciones deben incluir una cláusula explícita que establezca:

- Rideglory es un **intermediario tecnológico** que provee herramientas de coordinación, no el organizador del evento.
- El organizador es el **único responsable** de la seguridad, logística y cumplimiento normativo del evento que crea.
- Rideglory no participa, no supervisa ni controla la ejecución de los eventos.

Esta separación construye el argumento de intermediario neutral frente a la Ley 1480 de 2011 y reduce la exposición a responsabilidad solidaria.

### 6.2 Aceptación de riesgos al inscribirse a un evento (waiver contextual)

Al confirmar la inscripción a un evento — **no en el registro inicial a la app** — mostrar una pantalla de aceptación explícita antes de enviar el formulario:

```
┌──────────────────────────────────────────────────┐
│ Antes de continuar                               │
│                                                  │
│ Las actividades de motociclismo implican riesgos │
│ inherentes. Este evento es organizado por        │
│ [nombre del organizador], no por Rideglory.      │
│ Al inscribirte, confirmas que participas         │
│ voluntariamente y bajo tu propia responsabilidad.│
│                                                  │
│ [Cancelar]          [Entiendo, inscribirme]      │
└──────────────────────────────────────────────────┘
```

**Implementación:**
- Guardar `riskAcceptedAt: DateTime` y `riskAcceptanceVersion: String` en `EventRegistrationModel`.
- La versión permite actualizar el texto del waiver y saber qué versión aceptó cada usuario.
- El botón "Entiendo, inscribirme" **reemplaza** el botón de submit actual — no es un paso adicional.

**Por qué importa:** Aporta evidencia de **asunción voluntaria del riesgo por la víctima**, que es una de las causales que puede destruir la presunción de responsabilidad del Art. 2356 CC.

### 6.3 Aceptación de responsabilidad por el organizador al crear un evento

Al publicar un evento, hacer que el organizador acepte explícitamente una declaración:

```
┌──────────────────────────────────────────────────┐
│ Responsabilidad del organizador                  │
│                                                  │
│ Al crear este evento confirmo que:               │
│ • Soy responsable de la seguridad y organización │
│ • Comunicaré los riesgos a los participantes     │
│ • Rideglory actúa como plataforma tecnológica,   │
│   no como co-organizador                         │
│                                                  │
│ [Cancelar]          [Publicar evento]            │
└──────────────────────────────────────────────────┘
```

**Implementación:**
- Guardar `organizerAcceptedResponsibilityAt: DateTime` en el modelo del evento.
- Mostrar esta pantalla solo al **publicar** (no al guardar como borrador).

### 6.4 Lo que estos mecanismos NO cubren

- Si un juez determina que Rideglory **co-organiza** el evento (por proveer inscripción, datos médicos y tracking en vivo), los mecanismos anteriores pueden ser insuficientes. Esa distinción requiere asesoría legal.
- Los waivers no exoneran de responsabilidad por **negligencia propia** de la plataforma (ej. bug que impidió una alerta SOS).
- No reemplazan una **póliza de responsabilidad civil** a nivel de plataforma, que sería la protección más sólida.

---

## 7. Nice-to-have futuro: Tarjeta de emergencia

Una pantalla en la app que genera una **tarjeta de emergencia** con:

- Foto del rider
- Nombre completo
- Tipo de sangre
- EPS
- Contacto de emergencia (nombre + teléfono)
- QR que abre la tarjeta web (sin login)

El rider la guarda como imagen en su galería, la imprime, o la pone como widget en la pantalla de bloqueo. Una ambulancia la puede leer sin necesitar la app.

**Por qué se deja para después:** requiere infraestructura de token público en backend (link sin autenticación con expiración), y no resuelve el problema si el rider no lleva el teléfono a mano o la pantalla está bloqueada. El modelo actual (organizador siempre ve datos médicos) cubre el 90% de los casos en rodadas grupales.

---

## 8. Resumen de cambios técnicos requeridos

### Backend (`rideglory-api`)
- [ ] Añadir `minAgeRequirement: Int` al modelo de evento (default: 18)
- [ ] Validar edad del usuario en `POST /events/:id/registrations`
- [ ] Añadir `allowOrganizerContact: Bool` al modelo de inscripción (default: false)
- [ ] Añadir `riskAcceptedAt: DateTime?` y `riskAcceptanceVersion: String?` al modelo de inscripción
- [ ] Añadir `organizerAcceptedResponsibilityAt: DateTime?` al modelo de evento
- [ ] Endpoint de inscripción recibe y persiste `allowOrganizerContact` y `riskAcceptedAt`/`riskAcceptanceVersion`
- [ ] Endpoint de creación de evento recibe y persiste `organizerAcceptedResponsibilityAt`

### App Flutter
- [ ] Formulario de creación de evento: campo de edad mínima (16–99)
- [ ] Formulario de creación de evento: pantalla de aceptación de responsabilidad del organizador (§6.3) antes de publicar
- [ ] Formulario de inscripción: pantalla de aceptación de riesgos (§6.2) antes del submit — reemplaza el botón actual
- [ ] Formulario de inscripción: bloque de opt-in de contacto con `AppSwitchTile`
- [ ] Pantalla de autorización de datos sensibles (§5.4) antes de completar perfil médico — separada de T&C
- [ ] `RegistrationDetailPage`: secciones por capa (Médica / Contacto / Datos personales)
- [ ] Botones de acción WhatsApp y llamada (usando `url_launcher`)
- [ ] Bloqueo de Capa B sin SOS activo (lógica en la UI del organizador durante tracking)
- [ ] Strings en `app_es.arb`

### Pendiente (requiere decisión legal antes de implementar)
- [ ] Redactar texto definitivo de T&C con cláusula de separación de responsabilidad (§6.1) — requiere abogado
- [ ] Redactar texto definitivo del waiver contextual (§6.2) — requiere abogado
- [ ] Definir `riskAcceptanceVersion` inicial y proceso de versionado al actualizar el texto
- [ ] Determinar si se requiere firma electrónica cualificada (Ley 527/1999) o si el timestamp de aceptación es suficiente
- [ ] Evaluar contratación de póliza de responsabilidad civil a nivel de plataforma
