# PRD — Analytics: Segmentación demográfica y mejora de cobertura de eventos

**Tipo:** Mejora de infraestructura + feature de perfil + cambio de modelo
**Prioridad:** Media
**Issue:** #47
**Fecha de creación:** 2026-06-16
**Scope:** App Flutter (perfil + inscripción a eventos) + backend `rideglory-api` + Firebase Analytics

---

## 1. Problema

La infraestructura de analytics ya existe (`AnalyticsService`, 67 eventos definidos, política no-PII) pero carece de segmentación demográfica útil para decisiones de publicidad y producto:

- No hay **género/sexo** como dimensión de segmentación ni como campo del perfil.
- No hay **rango etario** reportado como user property (aunque `birthDate` existe en `UserModel`).
- No hay **tipo de vehículo** como dimensión (marca/tipo de moto del vehículo principal).

Sin estas dimensiones, Firebase Analytics agrupa todos los usuarios sin distinción, haciendo inútil la segmentación de audiencias para campañas.

---

## 2. Objetivo

Añadir **género/sexo** como campo persistido en el perfil del usuario (base de datos + app), recolectarlo en dos puntos del flujo, y reportarlo a Firebase Analytics como user property. Complementar con otras user properties derivadas de datos existentes.

**No-objetivos:**
- No recolectar campos de alta cardinalidad (nombre, correo, teléfono, ID) en Analytics.
- No cambiar la política no-PII existente de Analytics.
- No hacer el campo obligatorio (siempre opcional).

---

## 3. Campo género/sexo — fuente de verdad en base de datos

A diferencia de las demás user properties (derivadas en runtime), el género/sexo **se persiste en la base de datos** porque:
- Es un dato de perfil propio del usuario, no solo una métrica.
- Permite tenerlo disponible en cualquier sesión sin depender de que el usuario lo vuelva a declarar.
- Facilita reportarlo a Analytics en cada login automáticamente.

### 3.1 Cambios de modelo

**Backend (`rideglory-api`):**
- Añadir campo `gender: String?` al modelo de usuario (nullable — opcional).
- Valores permitidos: `male` / `female` / `non_binary` / `prefer_not_to_say`.
- Endpoint de actualización de perfil (`PATCH /users/me`) debe aceptar y persistir este campo.

**App Flutter:**
- Añadir campo `gender: String?` a `UserModel` y su `UserDto`.
- Regenerar código con `dart run build_runner build --delete-conflicting-outputs`.

### 3.2 Dónde recolectarlo

El campo se solicita en **dos puntos**:

| Punto | Contexto | Comportamiento |
|---|---|---|
| **Perfil (`ProfilePage`)** | Edición de datos personales | Campo editable en cualquier momento |
| **Formulario de inscripción a eventos** | Previo a registrarse en un evento | Se pre-llena si ya existe en el perfil; si el usuario lo cambia, actualiza el perfil también |

El campo es siempre **opcional** en ambos puntos. El usuario puede omitirlo sin bloquearse.

### 3.3 Texto y valores (l10n)

```arb
"profile_gender": "Género",
"profile_gender_hint": "Selecciona una opción",
"profile_gender_male": "Hombre",
"profile_gender_female": "Mujer",
"profile_gender_non_binary": "No binario",
"profile_gender_prefer_not_to_say": "Prefiero no decir"
```

### 3.4 Consideraciones Ley 1581 de 2012

El género/sexo es **dato sensible** según el artículo 5 de la Ley 1581. Al persistirlo en base de datos se requiere:

- **Consentimiento explícito e informado** en el momento de recolección. Implementar con texto breve junto al campo: *"Este dato se usa para mostrarte contenido relevante y mejorar la app. Puedes omitirlo o cambiarlo en cualquier momento."*
- El campo debe ser **completamente opcional** (nunca requerido para completar el flujo).
- Incluir en los Términos y Condiciones y Política de Privacidad con propósito declarado explícitamente.

> **Acción pendiente (legal):** Actualizar la Política de Privacidad para incluir el tratamiento del género con base legal (consentimiento — art. 9 Ley 1581). Sin esto, la recolección no cumple con la norma aunque el campo sea opcional.

---

## 4. User properties de Analytics

Todas se registran vía `analyticsService.setUserProperty(name, value)`.

| Propiedad | Clave Firebase | Valores permitidos | Fuente | Cuándo reportar |
|---|---|---|---|---|
| Género | `user_gender` | `male` / `female` / `non_binary` / `prefer_not_to_say` | `UserModel.gender` (DB) | Post-login y al guardar perfil |
| Rango etario | `age_range` | `16_17` / `18_24` / `25_34` / `35_44` / `45_plus` | Derivado de `birthDate` | Post-login y al guardar perfil |
| Ciudad de residencia | `residence_city` | Valor normalizado (minúsculas, sin tildes, máx 100 chars) | `UserModel.residenceCity` (ya existe) | Post-login y al guardar perfil |
| Tipo de vehículo principal | `main_vehicle_type` | `honda` / `yamaha` / `kawasaki` / `suzuki` / `bmw` / `harley` / `other` | Vehículo marcado como principal | Al cambiar vehículo principal |

> La ciudad de residencia **ya existe** en `UserModel.residenceCity` — no requiere nuevo campo, solo reportarla como user property.

Todas se actualizan en `AuthCubit` post-login y en el cubit de perfil al guardar.

---

## 5. Oportunidades adicionales de analytics (backlog)

Los siguientes eventos ya están definidos en `analytics_events.dart` pero tienen oportunidades de mejora en sus parámetros:

| Área | Oportunidad |
|---|---|
| Eventos | Agregar `param_event_route_type` (urbana / montaña / carretera) al crear el evento |
| Registro | Agregar `param_registration_vehicle_type` (tipo de moto) al registrarse en un evento |
| Mantenimiento | Agregar `param_maintenance_mileage_range` (agrupado, no exacto) al crear registro |
| Embudo de evento | Funnel: `event_detail_viewed` → `registration_started` → `registration_submitted` → `registration_approved` |

Estos requieren coordinación con backend si los parámetros vienen del servidor.

---

## 6. Implementación — pasos

### Backend
1. Añadir `gender: String?` al modelo de usuario en Prisma (migración).
2. Actualizar endpoint `PATCH /users/me` para aceptar y devolver `gender`.
3. Incluir `gender` en el DTO de respuesta del usuario.

### App Flutter
1. Añadir `gender: String?` a `UserModel` y `UserDto` → regenerar con `build_runner`.
2. **`ProfilePage`**: añadir selector de género (4 opciones + texto de consentimiento) con `AppTextField` o dropdown estilizado. Al guardar, persiste en backend y llama a `analyticsService.setUserProperty('user_gender', value)`.
3. **Formulario de inscripción a eventos**: añadir el mismo selector, pre-llenado con el valor del perfil. Si el usuario lo cambia aquí, actualiza el perfil también vía `PATCH /users/me`.
4. **`AuthCubit` post-login**: derivar `age_range` de `birthDate` y reportar todas las user properties disponibles (`user_gender`, `age_range`, `residence_city`).
5. **`VehicleCubit`**: al cambiar vehículo principal, reportar `main_vehicle_type`.
6. Añadir strings a `app_es.arb` → `flutter gen-l10n`.
7. **Actualizar Política de Privacidad** (acción legal, fuera del scope técnico).

---

## 7. Qué NO se hace

- **El género/sexo es exclusivo del usuario.** No se expone al organizador del evento, a otros riders, ni a ningún tercero dentro de la app. Solo el propio usuario lo ve en su perfil y en el formulario de inscripción.
- El género/sexo **no aparece** en `EventRegistrationModel`, `RegistrationDetailPage`, `RiderProfileModel` ni en ninguna vista accesible por otros usuarios.
- No se envían coordenadas, nombres, correos ni IDs a Analytics.
- No se rompe la política no-PII existente.
- No se hace el campo de género obligatorio en ningún flujo.
