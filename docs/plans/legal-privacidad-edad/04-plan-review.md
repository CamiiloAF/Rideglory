# 04 — Plan Review

**Slug:** `legal-privacidad-edad`
**Timestamp:** 2026-06-19T19:21:28Z
**Reviewer:** Plan Reviewer (UX móvil + Clean Architecture)
**Veredicto:** `ok_con_ajustes`

---

## UX por fase

### Fase 1 — Contratos y schema de backend

Sin pantallas. Fase puramente de datos. No aplica UX review.

**Gate de calidad:** los defaults seguros para inscripciones pre-migración (`shareMedicalInfo = false`, `allowOrganizerContact = false`, `riskAcceptedAt = null`) deben estar explícitamente documentados en la migración de Prisma para evitar que el organizador vea datos que el rider nunca autorizó.

---

### Fase 2 — Validación de edad y ofuscación condicional

Sin pantallas Flutter. La validación de edad es 100% backend. No aplica UX review.

**Gate de calidad:** el error que retorna el backend cuando la edad es menor de 18 debe ser un código de error semántico (no un HTTP 500 genérico) para que la fase 4 pueda presentar un mensaje l10n claro al usuario. El código recomendado es `UNDERAGE_RIDER` con HTTP 422.

**Riesgo de UX encadenado:** si el backend retorna un string literal `"No compartido"` (supuesto #5 del PO), este string viaja en el idioma del backend y llega a Flutter tal cual. Si en el futuro la app es multilenguaje, este acoplamiento rompe la localización. Recomendación: el backend retorna un centinela semántico (p. ej. `"__NOT_SHARED__"`) y Flutter lo interpreta y muestra el texto localizado. Este ajuste debe acordarse aquí antes de que Architect fije el contrato.

---

### Fase 3 — Modelos y DTOs Flutter

Sin pantallas. Fase de dominio y datos. No aplica UX review.

**Gate de calidad:**
- `EventRegistrationModel` debe declarar `shareMedicalInfo` y `allowOrganizerContact` con valores por defecto explícitos (`false`) para que el `RegistrationFormCubit` no falle en formularios pre-existentes cuando el backend no los retorna.
- `sosTriggeredAt` debe mapearse en `EventModel` aunque no se use en UI en esta fase; es prerrequisito de la Fase 7.
- Pattern B se aplica estrictamente: `EventRegistrationDto extends EventRegistrationModel`; todos los campos nuevos del modelo deben reflejarse en el DTO con la misma firma de tipo.

---

### Fase 4 — Waiver del rider en el flujo de inscripción

**Esta fase tiene la mayor superficie de UX. Es la más crítica del plan.**

#### Validación de edad — pantalla de bloqueo

El plan menciona "validación local de edad antes de mostrar el formulario". Se necesita una pantalla de bloqueo con estas características:
- Muestra cuándo ocurre: al intentar acceder al formulario de inscripción si `birthDate` en el perfil indica menor de 18, o si `birthDate` no está en el perfil.
- Dos casos distintos:
  - **Perfil sin `birthDate`:** mensaje "Debes tener tu fecha de nacimiento en tu perfil para inscribirte" + botón "Ir a mi perfil" → `context.pushNamed(AppRoutes.editProfile)`.
  - **Menor de 18:** mensaje "Debes ser mayor de 18 años para participar en eventos de Rideglory" + botón "Entendido" → cierra el bottom sheet/página. No hay recurso ni escalación.
- El bloqueo debe ser una pantalla/estado dentro del flujo, no un `showDialog` directo (usar `AppDialog` si es modal, o una pantalla de estado vacío si es página).
- Touch target mínimo: 44px en los botones de acción.

#### Paso médico — opt-ins de privacidad

Los dos `AppSwitchTile` (`shareMedicalInfo` y `allowOrganizerContact`) deben agregarse al paso médico existente (`registration_medical_step.dart`). Requerimientos UX:
- Cada `AppSwitchTile` debe tener un subtítulo explicativo corto (no solo el título del campo). Ejemplo:
  - `shareMedicalInfo` → título: "Compartir información médica", subtítulo: "El organizador podrá ver tu grupo sanguíneo y EPS durante el evento".
  - `allowOrganizerContact` → título: "Permitir contacto del organizador", subtítulo: "El organizador podrá llamarte o escribirte por WhatsApp".
- Los switches deben estar en estado `OFF` por defecto (privacidad por defecto).
- Valor OFF no bloquea el formulario; el rider puede inscribirse sin compartir nada.
- Los switches deben tener un separador visual (`FormSectionHeader`) que los agrupe bajo el título "Privacidad" para distinguirlos de los campos médicos de arriba.
- Deben ir al final del paso médico, después de tipo de sangre, antes del botón "Siguiente".

#### Pantalla de waiver (paso 5 del wizard)

El waiver debe ser el último paso antes del submit. Opciones de implementación:
- **Opción A (recomendada):** Nuevo paso en el wizard (`stepCount = 5`). Archivo nuevo `registration_waiver_step.dart`. El `RegistrationWizardController` se inicializa con `stepCount: 5`. El `RegistrationStepIndicator` debe mostrar el paso correctamente.
- **Opción B:** Modal pantalla-completa pre-submit (no agrega paso al indicador). Más simple de implementar pero menos coherente con el wizard existente; el usuario llega al paso 4 (vehículo), presiona "Siguiente" y aparece el waiver como modal fullscreen.

La Opción A es preferida por coherencia, pero requiere verificar que `RegistrationStepIndicator` no tenga el número de pasos hardcodeado.

**Contenido obligatorio del waiver (paso/pantalla):**
- Título: "Antes de inscribirte".
- Texto del waiver (placeholder v0 en ARB). Debe ser scrollable si excede la pantalla — usar `SingleChildScrollView` dentro del área de contenido.
- Nombre del organizador visible para contextualizar la responsabilidad.
- `AppButton` "Entiendo, inscribirme" al final. El botón llama a `cubit.submit()`.
- `AppTextButton` "Cancelar" secundario para abortar.
- El botón de submit debe estar visible sin scroll para 375px de altura. Si el texto es largo, el área de texto scrollea pero los botones quedan fijos al fondo (`Column` con `Expanded(child: SingleChildScrollView(...))` + botones fuera del scroll).
- Estado de carga: `AppButton(isLoading: true)` mientras el cubit está en `ResultState.loading()`.
- Estado de error: `AppDialog` con el mensaje de error; si el backend retorna `UNDERAGE_RIDER` (inconsistencia), mostrar el mensaje de bloqueo de edad.

#### Strings l10n requeridos (Fase 4)

Todos en `app_es.arb` con prefijo `registration_`:
- `registration_waiverTitle` — "Antes de inscribirte"
- `registration_waiverBodyV0` — texto placeholder del waiver (puede ser largo, multiline en ARB)
- `registration_waiverCtaButton` — "Entiendo, inscribirme"
- `registration_waiverCancelButton` — "Cancelar"
- `registration_privacySectionTitle` — "Privacidad"
- `registration_shareMedicalInfoTitle` — "Compartir información médica"
- `registration_shareMedicalInfoSubtitle` — texto explicativo
- `registration_allowContactTitle` — "Permitir contacto del organizador"
- `registration_allowContactSubtitle` — texto explicativo
- `registration_underageTitle` — "Edad mínima requerida"
- `registration_underageMessage` — mensaje de bloqueo
- `registration_missingBirthDateMessage` — "Debes completar tu fecha de nacimiento en tu perfil"
- `registration_goToProfile` — "Ir a mi perfil"

---

### Fase 5 — Aceptación de responsabilidad del organizador

#### Flujo de intercepción antes de publicar

El `PublishRow` actual llama directamente a `cubit.saveEvent()`. La intercepción debe ser:
1. El usuario presiona "Publicar evento" en `PublishRow`.
2. Se navega a una pantalla nueva (`OrganizerResponsibilityPage`) o se muestra un bottom sheet fullscreen.
3. El organizador lee y acepta.
4. Al aceptar, el cubit recibe `organizerAcceptedResponsibilityAt = DateTime.now()` y procede con `saveEvent()`.

**Recomendación de implementación:** pantalla completa (no bottom sheet), navegación con `context.pushNamed`. Motivo: el texto legal es largo y requiere scroll; los bottom sheets en pantallas con teclado o scroll largo son propensos a UX deficiente en 375px.

**Requerimientos UX de la pantalla:**
- Estado idle: título, texto scrollable de responsabilidad (placeholder v0), `AppButton` "Acepto y publico el evento" al fondo fijo.
- Estado loading: `AppButton(isLoading: true)` mientras el cubit guarda.
- Estado error: mostrar error inline (no reemplazar la pantalla) — un `Text` de error sobre el botón con `colorScheme.error`.
- Estado success: la pantalla se cierra y el wizard completa el flujo (pop de vuelta a EventFormPage que luego navega a detail o list).
- Si el organizador está en modo edición (`cubit.isEditing == true`), esta pantalla NO debe aparecer (el evento ya fue publicado con responsabilidad previa). El `PublishRow` ya maneja el caso de edición; solo interceptar en creación nueva.

**Touch targets:** botón de acción mínimo 52px de altura (igual al `AppButton` existente en `PublishRow`).

**Strings l10n requeridos (Fase 5):**
- `event_organizerResponsibilityTitle` — "Responsabilidad del organizador"
- `event_organizerResponsibilityBodyV0` — texto placeholder
- `event_organizerResponsibilityCtaButton` — "Acepto y publico el evento"
- `event_organizerResponsibilityBackButton` — "Revisar evento" (para volver)

---

### Fase 6 — Autorización Ley 1581 en perfil médico

#### Dónde vive esta pantalla

El plan propone que aparezca "la primera vez que el usuario intenta completar o editar su perfil médico". El scan menciona que no existe actualmente un flujo de "perfil médico" separado — el perfil es `EditProfilePage`. Se necesita claridad sobre dónde se sitúa la información médica en el perfil.

**Ajuste requerido:** antes de implementar esta fase, el arquitecto debe definir si los campos médicos (EPS, grupo sanguíneo, seguro médico) del formulario de inscripción son distintos a un "perfil médico" en el perfil de usuario, o si son lo mismo. Si son lo mismo, la fase 6 tiene dependencia en un flujo de perfil médico que no existe actualmente y puede ser subvalorada.

**Asumiendo que la fase 6 intercepta la primera vez que el rider intenta completar el paso médico del wizard de inscripción** (alternativa más simple y coherente con lo que existe):

- La pantalla de autorización aparece como pantalla completa antes de mostrar el paso médico del wizard.
- Se persiste el timestamp de autorización en `SharedPreferences` (clave: `medical_data_consent_at`).
- En sesiones subsiguientes, si ya existe el timestamp, no se muestra la pantalla.
- La pantalla tiene: título, texto de la declaración Ley 1581 (propósito, datos tratados, destinatarios), `AppButton` "Autorizar" y `AppTextButton` "No autorizar" (que regresa al paso anterior del wizard o bloquea el avance al paso médico).

**Requerimientos UX:**
- El texto de la declaración debe ser scrollable.
- Los botones fijos al fondo.
- Si el usuario no autoriza (`AppTextButton` "No autorizar"), puede continuar el wizard pero no puede rellenar los campos médicos de la inscripción (o bien se le muestra un mensaje de que sus datos médicos no estarán disponibles para el organizador y puede continuar).
- Mínimo touch target: 44px; `AppButton` principal al menos 52px de altura.

**Strings l10n requeridos (Fase 6):**
- `registration_law1581Title` — "Autorización de datos personales"
- `registration_law1581BodyV0` — texto declaración
- `registration_law1581AuthorizeButton` — "Autorizar"
- `registration_law1581DeclineButton` — "No autorizar"
- `registration_law1581DeclinedMessage` — mensaje informativo si el usuario no autoriza

---

### Fase 7 — Vista del organizador con ofuscación y contacto

#### Botones de contacto en `RegistrationDetailPage`

`RegistrationDetailPage` ya distingue rol (`isRegistrantViewer`). Los botones de contacto solo aparecen cuando `!isRegistrantViewer` (el viewer es el organizador) Y `registration.allowOrganizerContact == true`.

**Requerimientos UX:**
- Los botones "Llamar" y "WhatsApp" deben estar en `RegistrationDetailBottomBar` (ya existe), no flotantes ni en el cuerpo. Así no compiten con las acciones de aprobación/rechazo.
- Si `allowOrganizerContact == false`: los botones de contacto no aparecen. No se muestra mensaje alternativo ("El rider no autorizó contacto") en la bottom bar — esa información está implícita en el campo de teléfono que aparecerá ofuscado en el cuerpo.
- Si `allowOrganizerContact == true`: dos botones secundarios (variante `outline` o `ghost`) en la bottom bar — "Llamar" con icono `Icons.call_rounded` y "WhatsApp" con icono o logo de WhatsApp.
- Ambos botones llaman a `UrlLauncherHelper.openPhone(phone)` y `UrlLauncherHelper.openWhatsApp(phone)` respectivamente. Ya están implementados.
- El teléfono a usar es `registration.phone` (del rider). Cuando `allowOrganizerContact == false` el backend retornará el teléfono ofuscado; el botón no aparecerá de todas formas.

**Estados de datos ofuscados:**
- `RegistrationDetailDataRow` recibe el valor como string y lo muestra tal cual. Si el backend envía `"••••"` o `"No compartido"` (o el centinela `"__NOT_SHARED__"` si se adopta el ajuste recomendado en Fase 2), se renderiza sin lógica especial en Flutter. El diseño del `RegistrationDetailDataRow` debe manejar visualmente estos valores sin romperse (truncado, overflow).

**Archivo nuevo requerido:** `registration_contact_actions.dart` — widget que encapsula los dos botones de contacto. Este widget se incluye en `RegistrationDetailBottomBar`. No definirlo como método `Widget _buildContactActions()` dentro de `RegistrationDetailBottomBar` — viola la regla de un widget por archivo.

**Strings l10n requeridos (Fase 7):**
- `registration_callButton` — "Llamar"
- `registration_whatsappButton` — "WhatsApp"

---

## Gates de calidad por fase

| Fase | Gate de arquitectura | Gate de UX | Herramienta de verificación |
|------|---------------------|------------|----------------------------|
| 1 | Migración Prisma con defaults seguros documentados; contratos compilados en todos los MS | N/A | `pnpm build` en contracts; `npx prisma migrate deploy` |
| 2 | Error `UNDERAGE_RIDER` semántico (422); ofuscación en backend, no en Flutter | N/A | Tests unitarios backend; curl manual con `birthDate` de menor |
| 3 | Pattern B en DTOs; `dart analyze` sin errores; `build_runner` sin conflictos | N/A | `dart analyze`, `dart run build_runner build` |
| 4 | Un widget por archivo; strings en ARB; `AppSwitchTile` para opt-ins; `ResultState` en cubit; no `FormBuilderSwitch` | Waiver scrollable con botones fijos; bloqueo de edad claro; subtítulos en switches | `dart analyze`; review manual en simulador 375px |
| 5 | Pantalla nueva en `events/presentation/form/`; `organizerAcceptedResponsibilityAt` en payload; solo en creación (no edición) | Texto scrollable; botones fijos; error inline | `dart analyze`; prueba manual creación de evento |
| 6 | Consentimiento en `SharedPreferences` con timestamp; un disparo de pantalla por lifetime | Texto scrollable; botones fijos; flujo de "no autorizar" no bloquea sin mensaje claro | `dart analyze`; prueba en instalación limpia y segunda sesión |
| 7 | `RegistrationContactActions` como widget separado; no método `_buildContactActions()`; `UrlLauncherHelper` inyectado | Botones solo cuando `allowOrganizerContact == true`; en bottom bar, no flotantes | `dart analyze`; prueba con registro con y sin `allowOrganizerContact` |

---

## Riesgos de scope

### Riesgo 1 — String `"No compartido"` acoplado al idioma del backend (MEDIO)
El supuesto #5 (backend retorna `"No compartido"` literal) acopla el idioma del servidor al cliente. Si el backend es multilenguaje en el futuro (o si el texto cambia), Flutter recibe un string que no puede relocalizar. **Mitigación:** acordar un centinela semántico (`"__NOT_SHARED__"` o `null` con semántica distinta a campo vacío) y Flutter muestra el texto localizado. Este ajuste debe acordarse antes de finalizar el contrato de API en Fase 1.

### Riesgo 2 — Pantalla de Ley 1581 sin flujo de "perfil médico" definido (ALTO)
El scan no identifica un flujo de "perfil médico" existente en `lib/features/profile/`. Los campos médicos existen en el wizard de inscripción, no en el perfil de usuario. La Fase 6 puede referir a una pantalla que intercepta el paso médico del wizard, o puede requerir crear un nuevo flujo de "perfil médico" en el feature de profile — lo que ampliaría significativamente el scope. **Mitigación:** el Architect debe aclarar el punto de intercepción antes de que comience la implementación de la Fase 6. Si el consenso es interceptar solo en el wizard de inscripción, la fase es simple; si requiere un flujo de perfil médico nuevo, es una fase adicional.

### Riesgo 3 — `RegistrationStepIndicator` con pasos hardcodeados (BAJO)
Si `registration_step_indicator.dart` tiene el número de pasos (4) hardcodeado en lugar de leerlo de `RegistrationWizardController.stepCount`, agregar el paso de waiver (stepCount = 5) romperá visualmente el indicador. **Mitigación:** verificar el widget antes de incrementar `stepCount`. El scan no lo inspeccionó; el implementador de Fase 4 debe verificarlo como primer paso.

### Riesgo 4 — `rideglory-contracts` como submódulo (ALTO)
Ya identificado en el PO Proposal como Riesgo 4. Se mantiene sin mitigación adicional desde el Plan Reviewer. El implementador de Fase 1 debe seguir el gotcha documentado en `project_contracts_rebuild_gotcha.md`: `npm run build` + `pnpm install` en cada MS después de cambiar los contratos.

### Riesgo 5 — `RegistrationDetailPage` tiene un método `_vehicleLabel` que retorna String, no Widget (ACEPTABLE)
`_vehicleLabel()` retorna `String`, no `Widget`. No viola la regla de "prohibido métodos que retornan widgets". No es un issue.

### Riesgo 6 — Doble validación de edad sin sincronización (BAJO)
La app valida edad localmente (Fase 4) y el backend la valida también (Fase 2). Si el usuario tiene `birthDate` en su perfil pero el formulario de inscripción permite editar `birthDate`, puede ingresar una fecha falsa y pasar la validación local. El backend la capturará. La UX de error del backend (`UNDERAGE_RIDER`) en este caso debe estar mapeada en el cubit de inscripción, no solo la validación local.

---

## Ajustes al plan

### Ajuste A1 — Centinela semántico para datos ofuscados (Fases 1 + 2 + 7)
**Obligatorio.** Antes de cerrar la Fase 1, el Architect debe decidir el contrato de API para campos no compartidos. Recomendación: el backend retorna `null` para "campo no compartido" (en lugar de string `"No compartido"`) y un campo booleano de bandera en el response (`medicalInfoShared: boolean`) para que Flutter sepa si mostrar "No compartido" localizado o el valor real. Alternativamente: centinela `"__NOT_SHARED__"`. El string literal en el idioma del backend es la opción menos recomendable.

### Ajuste A2 — Aclarar punto de intercepción de Ley 1581 antes de planear Fase 6 (Fase 6)
**Obligatorio.** El Architect debe definir en su artefacto de Fase 6 si la autorización Ley 1581 intercepta:
- (a) el paso médico del wizard de inscripción (scope acotado, cero nuevas pantallas de perfil), o
- (b) el flujo de perfil del usuario (scope ampliado, requiere nueva sección en `EditProfilePage` o nueva página).

### Ajuste A3 — Subtítulos obligatorios en `AppSwitchTile` de privacidad (Fase 4)
Los dos switches de opt-in DEBEN tener subtítulo explicativo. Sin subtítulo, el usuario no sabe qué implica activar el toggle. Esto es un requisito WCAG 2.1 (información suficiente en el punto de decisión) y de UX básica para consentimientos.

### Ajuste A4 — Waiver como paso 5 del wizard, verificar `RegistrationStepIndicator` (Fase 4)
El implementador debe leer `registration_step_indicator.dart` antes de modificar `stepCount`. Si el indicador tiene hardcodeado el número 4 de pasos, debe generalizarlo para leer `controller.stepCount`. Documentar este hallazgo en el handoff de la fase.

### Ajuste A5 — Error `UNDERAGE_RIDER` mapeado en el cubit de Fase 4 (Fases 2 + 4)
El `RegistrationFormCubit` debe manejar explícitamente el código de error `UNDERAGE_RIDER` del backend y convertirlo en el mensaje l10n de bloqueo de edad (`registration_underageMessage`), no en el mensaje genérico de error. Esto requiere coordinación entre Fase 2 (backend define el código) y Fase 4 (Flutter mapea el código).

### Ajuste A6 — `OrganizerResponsibilityPage` es pantalla completa, no bottom sheet (Fase 5)
Cambiar la especificación de implementación a pantalla completa navegada con `context.pushNamed`. Motivo: el texto legal es potencialmente largo; bottom sheets de scroll largo tienen comportamiento inconsistente en iOS con teclado. El nombre del archivo sugerido: `event_organizer_responsibility_page.dart` bajo `lib/features/events/presentation/form/`.

### Ajuste A7 — `RegistrationContactActions` como widget separado obligatorio (Fase 7)
El widget de botones de contacto (Llamar / WhatsApp) debe ser su propio archivo `registration_contact_actions.dart` incluido en `RegistrationDetailBottomBar`. No implementarlo como método `Widget _buildContactActions()` — viola el estándar de cero tolerancia.
