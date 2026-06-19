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

### 3.2 Edad mínima — decisión

La plataforma establece **18 años** como límite mínimo absoluto y **no configurable**. No existe rango ajustable por evento ni por organizador.

| Regla | Valor |
|---|---|
| Mínimo de la plataforma | 18 años (hard cap — no negociable) |

Razón: la mayoría de edad legal en Colombia es 18 años. Los menores de 16–17 que tramitan licencia requieren autorización parental autenticada (Ley 769/2002, Art. 19), lo que añade complejidad verificable que la plataforma no está en capacidad de gestionar. Fijar el límite en 18 elimina esta carga y reduce la responsabilidad de la plataforma ante menores de forma simple y definitiva.

### 3.3 Mensaje de bloqueo (l10n)

```arb
"event_registration_age_blocked_title": "No cumples con el requisito de edad",
"event_registration_age_blocked_body": "Este evento requiere tener al menos {minAge} años. Actualiza tu fecha de nacimiento en tu perfil si crees que hay un error.",
"event_registration_age_missing_title": "Completa tu perfil",
"event_registration_age_missing_body": "Necesitamos tu fecha de nacimiento para verificar que cumples con el requisito de edad de este evento."
```

### 3.4 Implementación

- **Backend:** la edad mínima (18 años) está hardcodeada en la lógica de validación del endpoint de inscripción (`POST /events/:id/registrations`). No hay campo `minAgeRequirement` en el modelo de evento.
- **App:** antes de mostrar el formulario de inscripción, verificar localmente y mostrar el mensaje si no cumple. La validación real la hace el backend.
- **Formulario de creación de evento:** no se añade ningún campo de edad mínima (el límite es fijo y no configurable).

---

## 4. Modelo de privacidad por capas para inscripciones

### 4.1 Capas de visibilidad

El `EventRegistrationModel` expone hoy todos los campos sin distinción. Se propone dividirlos en tres capas:

#### Capa A — Visible para el organizador solo mientras el evento está en curso (seguridad médica)
Datos de emergencia que el organizador puede necesitar mientras el evento está activo:

- Tipo de sangre *(opcional — el rider elige si compartirlo)*
- EPS *(opcional — el rider elige si compartirlo)*
- Seguro médico adicional *(opcional — el rider elige si compartirlo)*
- Contacto de emergencia (nombre + teléfono) **[obligatorio — no se puede omitir]**

**Visibilidad:** estos campos solo son accesibles para el organizador **mientras el evento está en curso** (estado activo). Antes de iniciar el evento y después de finalizado, la información médica no es visible.

**Opt-in del rider:** en el formulario de inscripción, el rider puede marcar/desmarcar si desea compartir su información médica (tipo de sangre, EPS, seguro). El contacto de emergencia siempre se envía. Si el rider no comparte la información médica, el organizador solo ve el contacto de emergencia durante el evento.

> Justificación: el contacto de emergencia es el dato mínimo indispensable para actuar ante un accidente. La información médica (EPS, tipo de sangre, seguro) es sensible bajo la Ley 1581 y requiere consentimiento expreso; delegarle al rider esa decisión reduce la exposición de la plataforma y del organizador al tratamiento no autorizado de datos sensibles. La restricción de visibilidad al periodo del evento limita el tiempo de exposición al mínimo necesario.

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

### 4.2 UI del opt-in en el formulario de inscripción (rider)

En el formulario de inscripción se añaden dos bloques de switches:

**Bloque 1 — Información médica (opt-in)**
```
┌────────────────────────────────────────────────────┐
│ Información médica                                 │
│                                                    │
│ Compartir mi información médica con el             │
│ organizador durante el evento                      │
│                                ┌─────────────────┐ │
│                                │  AppSwitchTile  │ │
│                                └─────────────────┘ │
│ Tipo de sangre, EPS y seguro. Solo visible         │
│ mientras el evento esté en curso.                  │
└────────────────────────────────────────────────────┘
```

Este valor se persiste en `EventRegistrationModel` como `shareMedicalInfo: bool` (default: false). El contacto de emergencia siempre se envía independientemente de este switch.

**Bloque 2 — Coordinación del evento (opt-in)**
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

El organizador **siempre ve todos los campos** que el rider completó en su inscripción. La diferencia es que los valores sensibles se **ofuscan en el backend** (ej. `••••••••`) antes de enviarse a la app; la app simplemente renderiza lo que recibe. Las secciones nunca desaparecen; lo que cambia es si el valor llega legible o enmascarado.

**Regla de ofuscación por campo:**

| Campo | Condición para mostrar valor real |
|---|---|
| Tipo de sangre | Evento en curso + rider eligió compartir (`shareMedicalInfo = true`) |
| EPS | Evento en curso + `shareMedicalInfo = true` |
| Seguro médico adicional | Evento en curso + `shareMedicalInfo = true` |
| Contacto de emergencia (nombre + teléfono) | Evento en curso (obligatorio — siempre se desofusca si el evento está activo) |
| Teléfono del rider | `allowOrganizerContact = true` (independiente del estado del evento) |
| Cédula | SOS activo del rider |
| Correo electrónico | SOS activo del rider |
| Ciudad de residencia | SOS activo del rider |

La `RegistrationDetailPage` se reorganiza en secciones con ofuscación condicional:

```
┌─────────────────────────────────────────────────┐
│ INFORMACIÓN MÉDICA                               │
│                                                  │
│ Tipo de sangre:  O+          ← evento en curso  │
│ Tipo de sangre:  ••••        ← evento no activo │
│                                                  │
│ EPS:             Sura        ← evento en curso  │
│ EPS:             ••••        ← evento no activo │
│                                                  │
│ Seguro adicional: Mapfre     ← evento en curso  │
│ Seguro adicional: ••••       ← evento no activo │
│                                                  │
│ [Si !shareMedicalInfo, los tres campos anteriores│
│  muestran "No compartido" en lugar de ••••]      │
│                                                  │
│ Contacto emergencia:                             │
│   Ana Torres · 3001234567    ← evento en curso  │
│   ••••••••••••••••           ← evento no activo │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ CONTACTO                                         │
│                                                  │
│ Teléfono: 📞 3009876543 [Llamar] [WhatsApp]     │
│            ← allowOrganizerContact = true        │
│                                                  │
│ Teléfono: ••••••••••••                          │
│            ← allowOrganizerContact = false       │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ DATOS PERSONALES                                 │
│                                                  │
│ Cédula:  1234567890          ← SOS activo        │
│ Cédula:  ••••••••••          ← sin SOS           │
│                                                  │
│ Correo:  ejemplo@mail.com    ← SOS activo        │
│ Correo:  ••••••••••••        ← sin SOS           │
│                                                  │
│ Ciudad:  Medellín            ← SOS activo        │
│ Ciudad:  ••••••••            ← sin SOS           │
└─────────────────────────────────────────────────┘
```

**Estado del evento para desofuscación médica:** el evento está "en curso" cuando ha sido iniciado por el organizador y aún no ha finalizado, mismo criterio que el tracking en vivo.

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

**Conclusión práctica:** La plataforma exige **18 años como límite mínimo absoluto**, eliminando la necesidad de gestionar autorización parental para menores de 16–17 años.

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
| Validación de edad mínima (18 años hard cap, no configurable) | Reduce exposición ante menores sin gestionar consentimiento parental |
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
- [ ] Validar edad del usuario (≥ 18 años, hardcodeado) en `POST /events/:id/registrations`
- [ ] Añadir `shareMedicalInfo: Bool` al modelo de inscripción (default: false)
- [ ] Añadir `allowOrganizerContact: Bool` al modelo de inscripción (default: false)
- [ ] Añadir `riskAcceptedAt: DateTime?` y `riskAcceptanceVersion: String?` al modelo de inscripción
- [ ] Añadir `organizerAcceptedResponsibilityAt: DateTime?` al modelo de evento
- [ ] Endpoint de inscripción recibe y persiste `shareMedicalInfo`, `allowOrganizerContact` y `riskAcceptedAt`/`riskAcceptanceVersion`
- [ ] Endpoint de creación de evento recibe y persiste `organizerAcceptedResponsibilityAt`
- [ ] Endpoint de detalle de inscripción (vista organizador): aplica ofuscación de campos **en el backend** según estado del evento y flags del rider antes de retornar la respuesta; el contacto de emergencia se desofusca solo si el evento está en curso

### App Flutter
- [ ] Formulario de creación de evento: pantalla de aceptación de responsabilidad del organizador (§6.3) antes de publicar — **sin campo de edad mínima**
- [ ] Formulario de inscripción: pantalla de aceptación de riesgos (§6.2) antes del submit — reemplaza el botón actual
- [ ] Formulario de inscripción: bloque opt-in de información médica con `AppSwitchTile` (`shareMedicalInfo`)
- [ ] Formulario de inscripción: bloque opt-in de contacto con `AppSwitchTile` (`allowOrganizerContact`)
- [ ] Pantalla de autorización de datos sensibles (§5.4) antes de completar perfil médico — separada de T&C
- [ ] `RegistrationDetailPage`: siempre muestra todos los campos; renderiza el valor tal como lo retorna el backend (puede ser el valor real u ofuscado)
- [ ] Botones de acción WhatsApp y llamada (usando `url_launcher`) — solo activos cuando `allowOrganizerContact = true`
- [ ] Strings en `app_es.arb`

### Pendiente (requiere decisión legal antes de implementar)
- [ ] Redactar texto definitivo de T&C con cláusula de separación de responsabilidad (§6.1) — requiere abogado
- [ ] Redactar texto definitivo del waiver contextual (§6.2) — requiere abogado
- [ ] Definir `riskAcceptanceVersion` inicial y proceso de versionado al actualizar el texto
- [ ] Determinar si se requiere firma electrónica cualificada (Ley 527/1999) o si el timestamp de aceptación es suficiente
- [ ] Evaluar contratación de póliza de responsabilidad civil a nivel de plataforma
