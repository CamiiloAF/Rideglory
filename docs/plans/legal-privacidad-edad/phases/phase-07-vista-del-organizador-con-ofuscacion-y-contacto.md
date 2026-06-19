# Fase 7 — Vista del organizador con ofuscación y contacto

**Slug:** `legal-privacidad-edad`
**Timestamp:** 2026-06-19T19:51:37Z
**Nivel rg-exec:** normal
**dependsOn:** [2, 3]

---

## Objetivo

Adaptar `RegistrationDetailPage` para que el organizador vea los datos de cada inscrito tal como los retorna el backend (reales u ofuscados según las reglas de privacidad establecidas en Fase 2), y pueda contactar directamente al rider con un tap cuando `allowOrganizerContact == true`. La distinción organizador/piloto se hace mediante un campo explícito `isOrganizerView: bool` en `RegistrationDetailExtra`, eliminando la ambigüedad del patrón actual basado en comparación de `userId`.

---

## Alcance

### Entra
- Extensión de `RegistrationDetailExtra` con tres campos nuevos: `isOrganizerView: bool`, `eventState: EventState?`, `eventSosTriggeredAt: DateTime?`.
- Actualización de todos los puntos de navegación que abren el detalle desde la lista de inscriptos del evento para pasar `isOrganizerView: true` y el estado actual del evento (`event.state`, `event.sosTriggeredAt`).
- Refactor de `RegistrationDetailPage` para usar `extra.isOrganizerView` (en lugar de `registration.userId == currentUserId`) como palanca de vista.
- Refactor de `RegistrationDetailBottomBar`: independizar `RegistrationContactActions` del early-return existente en la línea 48 (`if (actions.isEmpty) return const SizedBox.shrink()`).
- Nuevo widget `RegistrationContactActions` en archivo independiente `registration_contact_actions.dart` con botones Llamar y WhatsApp.
- Corrección del acceso a `bloodType` en `RegistrationDetailPage`: la Fase 3 cambia `bloodType` a `BloodType?` con getter de parse seguro; la UI usa `registration.bloodType?.label ?? registration.bloodTypeRaw ?? context.l10n.notAvailable` (el campo `bloodTypeRaw` es la propiedad que Fase 3 expondrá con el string crudo del backend). El fallback final es `context.l10n.notAvailable` (valor en ARB: `"N/A"`).
- Dos strings l10n nuevos: `registration_callButton` y `registration_whatsappButton`.

### No entra
- Localización de los centinelas `"••••"` o `"__NOT_SHARED__"` a texto descriptivo en español — eso es trabajo de UX futuro, no bloqueante de esta fase. La UI muestra el string crudo.
- Ningún cambio de backend, contrato o migración.
- Ninguna pantalla nueva; toda la UI se modifica sobre páginas/widgets existentes.
- Cambios en `MyRegistrationsDataView` (vista del piloto sobre sus propias inscripciones) — esos puntos de navegación NO pasan `isOrganizerView: true`.

---

## Que se debe hacer (pasos concretos y ordenados)

### Paso 1 — Pre-flight: confirmar campos disponibles en `EventModel` y `EventRegistrationModel` tras Fase 3

Verificar que `EventModel` y `EventDto` ya tienen `sosTriggeredAt: DateTime?` y `organizerAcceptedResponsibilityAt: DateTime?` mapeados por la Fase 3. Si la Fase 3 no ha cerrado, esta fase queda bloqueada.

Verificar también:
- `EventRegistrationModel.allowOrganizerContact: bool` (Fase 3). Sin este campo el widget `RegistrationContactActions` no puede evaluar la condición de renderizado.
- El nombre exacto de la propiedad que Fase 3 expone para el string crudo de `bloodType`. El plan de Fase 3 establece que `bloodType` pasa a `BloodType?` con getter de parse seguro; el string crudo debe estar accesible como `bloodTypeRaw` (nombre que este plan usa). Si Fase 3 usa otro nombre, ajustar el Paso 4 antes de escribir código.

### Paso 2 — Extender `RegistrationDetailExtra`

Archivo: `lib/features/event_registration/presentation/registration_detail_extra.dart`

Agregar tres campos al constructor:

```dart
import 'package:flutter/material.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart'; // nuevo import

class RegistrationDetailExtra {
  const RegistrationDetailExtra({
    required this.registration,
    this.eventOwnerId,
    this.isOrganizerView = false,   // nuevo — default false: no rompe puntos de navegación del piloto
    this.eventState,                 // nuevo
    this.eventSosTriggeredAt,        // nuevo
    this.onCancelRegistration,
    this.onApprove,
    this.onReject,
    this.onRequestEdit,
    this.onEditRegistration,
  });

  final EventRegistrationModel registration;
  final String? eventOwnerId;
  final bool isOrganizerView;
  final EventState? eventState;
  final DateTime? eventSosTriggeredAt;
  final Future<bool> Function()? onCancelRegistration;
  final void Function(BuildContext context)? onApprove;
  final void Function(BuildContext context)? onReject;

  /// Organizador: habilita la edición de la inscripción del piloto
  /// (estado READY_FOR_EDIT).
  final void Function(BuildContext context)? onRequestEdit;

  /// Piloto: abre el formulario para editar su propia inscripción.
  final void Function(BuildContext context)? onEditRegistration;
}
```

El valor por defecto `isOrganizerView = false` garantiza que los puntos de navegación existentes del piloto (`MyRegistrationsDataView`) no rompen sin cambios de código.

### Paso 3 — Actualizar puntos de navegación del organizador

Los tres archivos que abren el detalle desde la perspectiva del organizador deben pasar `isOrganizerView: true` más el estado del evento.

**`lib/features/events/presentation/attendees/widgets/attendees_list.dart`**

Dos bloques de construcción de `RegistrationDetailExtra` (líneas reales en el archivo):
- Rama `pending` → línea 69: la construcción del `RegistrationDetailExtra` dentro del `onTap` de `AttendeePendingRequestCard`.
- Rama `processed` → línea 143: la construcción del `RegistrationDetailExtra` dentro del `onTap` de `AttendeeProcessedItem`.

Agregar en ambas construcciones:
```dart
isOrganizerView: true,
eventState: event.state,
eventSosTriggeredAt: event.sosTriggeredAt,
```

El `EventModel event` ya está disponible como campo de `AttendeesList` (declarado en la línea 18 del archivo actual).

**`lib/features/events/presentation/detail/widgets/event_detail_participants_section.dart`**

Método `_openRegistrationDetail` — línea 32 del archivo actual. El `RegistrationDetailExtra` se construye en la línea 40.

Agregar los tres campos al `RegistrationDetailExtra`:
```dart
isOrganizerView: true,
eventState: event.state,
eventSosTriggeredAt: event.sosTriggeredAt,
```

El `EventModel event` ya está disponible como campo de `EventDetailParticipantsSection`.

**`lib/features/events/presentation/detail/event_detail_view.dart`**

Localizar el bloque `pushNamed(AppRoutes.registrationDetail, extra: RegistrationDetailExtra(...))`. Verificar que el `EventModel` esté accesible en ese contexto (viene del cubit o de `widget.event` según la estructura actual) y que `sosTriggeredAt` esté mapeado tras Fase 3. Agregar los tres campos. Documentar en el handoff de la fase de dónde viene el `EventModel` en ese punto.

### Paso 4 — Refactorizar `RegistrationDetailPage`

Archivo: `lib/features/event_registration/presentation/registration_detail_page.dart`

**4a — Cambiar la lógica de vista:**

```dart
// Antes:
final currentUserId = context.watch<AuthCubit>().state.currentUser?.id;
final isRegistrantViewer = registration.userId == currentUserId;

// Después:
final isOrganizerView = params.isOrganizerView;
final isRegistrantViewer = !isOrganizerView;
```

Verificar si `context.watch<AuthCubit>()` se usa para algo más en la página antes de eliminar el import y la llamada. Si ya no se usa, eliminar para no acumular escuchas innecesarias.

**4b — Corregir el acceso a `bloodType` en la sección médica:**

La línea actual es la 128 del archivo:
```dart
value: registration.bloodType.label,  // línea 128 actual — falla con Null check si bloodType es null
```

Cambiar a:
```dart
value: registration.bloodType?.label
    ?? registration.bloodTypeRaw
    ?? context.l10n.notAvailable,
```

Justificación: Fase 3 cambia `bloodType` de `BloodType` a `BloodType?`. El getter de parse seguro retorna `null` cuando el valor recibido del backend no es un enum válido (por ejemplo, `"__NOT_SHARED__"` o `"••••"`). En ese caso la UI muestra el string crudo via `bloodTypeRaw`, o si este también es nulo, muestra `"N/A"` (valor de `context.l10n.notAvailable` en `app_es.arb`). El criterio de aceptación 10 usa `"N/A"` como fallback final (no `"N/D"`) porque esa es la clave `notAvailable` ya existente en el ARB (línea 31: `"notAvailable": "N/A"`). No se agrega una clave nueva.

**Coordinación con Fase 3:** el nombre del getter del string crudo se fija como `bloodTypeRaw`. Si Fase 3 usa otro nombre, el implementador de Fase 7 lo ajusta al nombre real antes de escribir código.

### Paso 5 — Crear `RegistrationContactActions` (archivo independiente — obligatorio)

Crear `lib/features/event_registration/presentation/widgets/registration_contact_actions.dart`.

Este archivo es obligatorio por la regla de cero tolerancia: un widget por archivo. Prohibido como método `_buildContactActions()` dentro de `RegistrationDetailBottomBar`.

**Imports requeridos (copy-paste ejecutable):**
```dart
import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';       // AppButton, AppButtonVariant, AppButtonStyle, AppSpacing, AppColors
import 'package:rideglory/features/event_registration/presentation/registration_detail_extra.dart';
import 'package:rideglory/shared/helpers/url_launcher_helper.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
```

**Implementación:**

```dart
class RegistrationContactActions extends StatelessWidget {
  const RegistrationContactActions({
    super.key,
    required this.extra,
  });

  final RegistrationDetailExtra extra;

  @override
  Widget build(BuildContext context) {
    if (!extra.isOrganizerView) return const SizedBox.shrink();
    if (!extra.registration.allowOrganizerContact) return const SizedBox.shrink();

    final phone = extra.registration.phone;

    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: context.l10n.registration_callButton,
            icon: Icons.call_rounded,
            variant: AppButtonVariant.ghost,
            style: AppButtonStyle.outlined,
            onPressed: () => UrlLauncherHelper.openPhone(phone),
            isFullWidth: true,
          ),
        ),
        AppSpacing.hGapMd,
        Expanded(
          child: AppButton(
            label: context.l10n.registration_whatsappButton,
            variant: AppButtonVariant.ghost,
            style: AppButtonStyle.outlined,
            onPressed: () => UrlLauncherHelper.openWhatsApp(phone),
            isFullWidth: true,
          ),
        ),
      ],
    );
  }
}
```

**Decisión de variante — determinista y sin ambigüedad:**

Se usa `AppButtonVariant.ghost` + `AppButtonStyle.outlined`. Esta combinación es la correcta para acciones secundarias sobre fondo oscuro:
- `ghost` (relleno base `#242429`) con `outlined` añade el borde, produciendo el aspecto de botón secundario sobre `AppColors.darkBgPrimary` sin competir visualmente con los botones de acción principal.
- Las variantes del enum verificadas en `lib/shared/widgets/form/app_button.dart` línea 6 son: `{primary, secondary, danger, success, ghost, ghostSubtle}`. No existe `outline` — usar `ghost` + `AppButtonStyle.outlined` (línea 8: `{filled, outlined, tonal, text}`).
- No usar `secondary` solo, que produce relleno sólido y visual más prominente que el deseado para contacto.

**Nota sobre el guard de teléfono vacío (R5):** `RegistrationContactActions` solo se renderiza cuando `allowOrganizerContact == true`, condición que garantiza que el backend retorna el teléfono real (no `"••••"`). `UrlLauncherHelper.openPhone` y `openWhatsApp` ya usan `canLaunchUrl` internamente antes de abrir, de modo que una URL malformada no crashea — simplemente no abre nada. No se agrega guard adicional en el widget; si en el futuro el backend cambia el contrato, agregar `phone.isNotEmpty && phone != '••••'` como condición extra antes de renderizar.

### Paso 6 — Refactorizar `RegistrationDetailBottomBar`

Archivo: `lib/features/event_registration/presentation/widgets/registration_detail_bottom_bar.dart`

El problema actual: el early-return en línea 48 (`if (actions.isEmpty) return const SizedBox.shrink()`) impide que `RegistrationContactActions` se muestre para inscripciones aprobadas que no tienen acciones de organizador (la inscripción aprobada no tiene aprobar/rechazar pendientes).

Solución: evaluar la visibilidad de `RegistrationContactActions` **antes** del early-return, y retornar `SizedBox.shrink()` solo si ambas secciones (acciones + contacto) están vacías.

Estructura del nuevo `build()`:

```dart
@override
Widget build(BuildContext context) {
  final registration = params.registration;
  final ownerSuppressed =
      params.eventOwnerId != null &&
      params.eventOwnerId == registration.userId;
  final showCancel = params.onCancelRegistration != null && !ownerSuppressed;

  final isPending = registration.status == RegistrationStatus.pending;
  final isReadyForEdit =
      registration.status == RegistrationStatus.readyForEdit;
  final ownerCanAct = isPending || isReadyForEdit;
  final showOwnerActions =
      ownerCanAct && (params.onApprove != null || params.onReject != null);
  final showApprove = isPending && params.onApprove != null;
  final showRequestEdit = isPending && params.onRequestEdit != null;

  final actions = _buildActions(
    context,
    showOwnerActions: showOwnerActions,
    showApprove: showApprove,
    showRequestEdit: showRequestEdit,
    showCancel: showCancel,
  );

  // Evaluar contacto de forma independiente del early-return de acciones:
  // una inscripción aprobada con allowOrganizerContact == true muestra
  // botones de contacto aunque actions esté vacío.
  final showContact = params.isOrganizerView &&
      registration.allowOrganizerContact;

  if (actions.isEmpty && !showContact) return const SizedBox.shrink();

  final bottomPadding = MediaQuery.of(context).padding.bottom;

  return Container(
    decoration: const BoxDecoration(
      color: AppColors.darkBgPrimary,
      border: Border(top: BorderSide(color: AppColors.darkBorderPrimary)),
    ),
    padding: EdgeInsets.fromLTRB(20, 16, 20, math.max(16, bottomPadding)),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...actions,
          if (actions.isNotEmpty && showContact) AppSpacing.gapMd,
          if (showContact) RegistrationContactActions(extra: params),
        ],
      ),
    ),
  );
}
```

Agregar import de `RegistrationContactActions` al inicio del archivo:
```dart
import 'package:rideglory/features/event_registration/presentation/widgets/registration_contact_actions.dart';
```

### Paso 7 — Agregar strings l10n

En `lib/l10n/app_es.arb`, agregar al final del bloque `registration_*`:

```json
"registration_callButton": "Llamar",
"registration_whatsappButton": "WhatsApp"
```

Ejecutar `flutter gen-l10n` o `dart run build_runner build --delete-conflicting-outputs` para regenerar `app_localizations_es.dart`.

### Paso 8 — Verificar `dart analyze`

Ejecutar `dart analyze` y resolver todos los errores antes de considerar la fase cerrada. Prestar atención especial a:
- El acceso nullable `registration.bloodType?.label ?? registration.bloodTypeRaw ?? context.l10n.notAvailable` en `RegistrationDetailPage`.
- Los imports nuevos en `registration_detail_bottom_bar.dart` y `registration_detail_extra.dart`.
- Que `EventState` esté importado en `registration_detail_extra.dart` (`package:rideglory/features/events/domain/model/event_model.dart`).
- Que `RegistrationContactActions` sea importado en `registration_detail_bottom_bar.dart`.

---

## Archivos a crear/modificar (rutas reales)

| Ruta | Operación | Qué cambia |
|------|-----------|------------|
| `lib/features/event_registration/presentation/registration_detail_extra.dart` | Modificar | Agregar `isOrganizerView: bool = false`, `eventState: EventState?`, `eventSosTriggeredAt: DateTime?`; nuevo import de `event_model.dart`. |
| `lib/features/event_registration/presentation/registration_detail_page.dart` | Modificar | Usar `params.isOrganizerView` en lugar de `userId == currentUserId`; corregir acceso a `bloodType` nullable (línea 128) con fallback `bloodTypeRaw ?? context.l10n.notAvailable`. |
| `lib/features/event_registration/presentation/widgets/registration_detail_bottom_bar.dart` | Modificar | Independizar early-return de `RegistrationContactActions`; importar y usar el nuevo widget. |
| `lib/features/event_registration/presentation/widgets/registration_contact_actions.dart` | **Crear** | Nuevo widget `RegistrationContactActions` con botones Llamar y WhatsApp condicionales; variante `ghost` + `outlined`. |
| `lib/features/events/presentation/attendees/widgets/attendees_list.dart` | Modificar | Pasar `isOrganizerView: true`, `eventState`, `eventSosTriggeredAt` en rama pending (línea 69) y rama processed (línea 143). |
| `lib/features/events/presentation/detail/widgets/event_detail_participants_section.dart` | Modificar | Pasar los tres campos nuevos en `_openRegistrationDetail` (línea 32), en la construcción de `RegistrationDetailExtra` (línea 40). |
| `lib/features/events/presentation/detail/event_detail_view.dart` | Modificar | Pasar los tres campos nuevos en el bloque de navegación a `AppRoutes.registrationDetail`. |
| `lib/l10n/app_es.arb` | Modificar | Agregar `registration_callButton` y `registration_whatsappButton`. |
| `lib/l10n/app_localizations_es.dart` | Auto-generado | Regenerado por `flutter gen-l10n`. No editar a mano. |

---

## Contratos / API rideglory-api

**Ninguno.** Esta fase es exclusivamente de presentación Flutter. No modifica endpoints, DTOs de contratos, ni lógica de backend. El backend ya retorna los datos ofuscados o reales según las reglas implementadas en Fase 2; Flutter los renderiza tal como llegan.

---

## Cambios de datos / migraciones

**Ninguno.** No hay migraciones de Prisma ni cambios en el schema de base de datos.

---

## Criterios de aceptación (numerados, observables, testeables)

1. **isOrganizerView explícito:** Abrir el detalle de la inscripción de un rider desde `AttendeesList` (sección pending o processed) muestra el título "Detalles de solicitud" y **no** "Mi inscripción". El título correcto proviene de `isRegistrantViewer = false` derivado de `params.isOrganizerView = true`.

2. **isOrganizerView en detalle de evento:** Abrir el detalle de inscripción desde `EventDetailParticipantsSection` también pasa `isOrganizerView: true` y produce la misma vista organizador.

3. **Vista del piloto no afectada:** Abrir el detalle de una inscripción propia desde `MyRegistrationsDataView` sigue mostrando "Mi inscripción", el banner de estado y los botones de editar/cancelar. El campo `isOrganizerView` por defecto es `false` en esos puntos de navegación.

4. **Organizador-participante:** Si el organizador también está inscrito en su propio evento, abrir el detalle de la inscripción de OTRO rider desde `AttendeesList` muestra la vista organizador (no la vista piloto). El comportamiento ya no depende de comparar `userId`.

5. **Botones de contacto visibles:** En la vista organizador de una inscripción con `status == approved` y `allowOrganizerContact == true`, la bottom bar muestra los botones "Llamar" y "WhatsApp" en una fila de dos columnas. Los botones aparecen aunque no haya acciones de aprobar/rechazar (inscripción ya aprobada).

6. **Botones de contacto ocultos:** En la vista organizador de una inscripción con `allowOrganizerContact == false`, la bottom bar no muestra los botones de contacto. Si tampoco hay acciones de organizador, la bottom bar es `SizedBox.shrink()` (no se renderiza).

7. **Tap en Llamar:** Tocar el botón "Llamar" invoca `UrlLauncherHelper.openPhone(phone)`, que construye la URL `tel:<phone>` y la lanza vía `url_launcher`. Verificable manualmente en dispositivo o simulador. El teléfono está garantizado como real (no `"••••"`) porque `allowOrganizerContact == true` es condición de render del widget.

8. **Tap en WhatsApp:** Tocar el botón "WhatsApp" invoca `UrlLauncherHelper.openWhatsApp(phone)`, que construye `https://wa.me/<sanitized_phone>` y la lanza. Verificable manualmente.

9. **Datos ofuscados renderizados:** Si el backend retorna `"••••"` en el campo `phone`, la fila de teléfono en `RegistrationDetailDataRow` muestra literalmente `"••••"`. No lanza excepción ni muestra vacío.

10. **bloodType nullable:** Si `registration.bloodType` es `null` (porque el backend retornó `"__NOT_SHARED__"` y Fase 3 lo parseó como `null`), la fila de grupo sanguíneo muestra el string crudo del backend via `bloodTypeRaw`, o en su defecto `"N/A"` (valor de `context.l10n.notAvailable`, clave ya existente en `app_es.arb` línea 31). No lanza `Null check operator used on a null value`. No se agrega ninguna clave nueva al ARB.

11. **l10n verificado:** Los textos "Llamar" y "WhatsApp" provienen de `context.l10n.registration_callButton` / `context.l10n.registration_whatsappButton`. No hay strings hardcodeados en los widgets.

12. **dart analyze limpio:** `dart analyze` termina sin errores en todos los archivos modificados o creados.

---

## Pruebas

### Widget tests

**`RegistrationContactActions` — `registration_contact_actions_test.dart`**

| Caso | Expectativa |
|------|-------------|
| `isOrganizerView: false` | Widget retorna `SizedBox.shrink()`; no hay botones. |
| `isOrganizerView: true`, `allowOrganizerContact: false` | Widget retorna `SizedBox.shrink()`; no hay botones. |
| `isOrganizerView: true`, `allowOrganizerContact: true` | Widget renderiza dos botones con textos `registration_callButton` y `registration_whatsappButton`. |
| Tap en botón Llamar | `UrlLauncherHelper.openPhone` es invocado con el teléfono correcto. (Mockear `url_launcher` con `MethodChannelMock` o `mockito` sobre el canal de plataforma.) |
| Tap en botón WhatsApp | `UrlLauncherHelper.openWhatsApp` es invocado con el teléfono correcto. |

**`RegistrationDetailBottomBar` — test de early-return refactorizado**

| Caso | Expectativa |
|------|-------------|
| Inscripción aprobada, `allowOrganizerContact: true`, `isOrganizerView: true` | La bottom bar **no** es `SizedBox.shrink()`; contiene `RegistrationContactActions`. |
| Inscripción aprobada, `allowOrganizerContact: false`, `isOrganizerView: true` | La bottom bar es `SizedBox.shrink()` (sin acciones ni contacto). |
| Inscripción pending, `isOrganizerView: true`, callbacks de aprobar/rechazar presentes | Bottom bar muestra botones de aprobar/rechazar; `RegistrationContactActions` oculto (`allowOrganizerContact` es `false` en la fixture de test pending). |
| Vista piloto con `onEditRegistration` y `onCancelRegistration` | Bottom bar muestra editar + cancelar; sin botones de contacto (isOrganizerView es `false`). |

### Tests de integración (manual / golden)

- Flujo completo organizador: crear evento → inscribir rider con `allowOrganizerContact: true` → aprobar inscripción → abrir detalle desde lista de inscriptos → verificar botones de contacto visibles y funcionales.
- Flujo piloto: abrir inscripción propia desde "Mis inscripciones" → verificar que **no** aparecen botones de contacto ni se usa `isOrganizerView`.

### Tests unitarios

No hay lógica de negocio nueva en esta fase (la ofuscación es del backend). Los tests de widget cubren los casos relevantes.

---

## Riesgos y mitigaciones

| # | Riesgo | Probabilidad | Impacto | Mitigación |
|---|--------|-------------|---------|------------|
| R1 | El acceso a `bloodType.label` en `RegistrationDetailPage` (línea 128 del archivo actual) lanza `Null check operator` si `bloodType` es `null` tras el cambio de tipo en Fase 3. | Alta (el tipo cambia) | Crasheo en la vista de inscripción. | En el Paso 4b cambiar el acceso a nullable con fallback `bloodTypeRaw ?? context.l10n.notAvailable`. El implementador confirma el nombre de `bloodTypeRaw` con el modelo resultante de Fase 3 antes de escribir código. |
| R2 | `event.sosTriggeredAt` no está mapeado en `EventModel` Flutter si Fase 3 no cerró o lo omitió. | Media | El campo llega como `null` siempre; la UI no refleja el estado SOS pero no crashea (el campo es nullable). | Verificar pre-flight (Paso 1). Si Fase 3 está incompleta, esta fase no puede avanzar. |
| R3 | `AttendeesList` rama `processed` actualmente no pasa callbacks de acción (solo `registration` y `eventOwnerId`). Al agregar `isOrganizerView: true`, una inscripción aprobada con `allowOrganizerContact: true` mostrará los botones de contacto — que es el comportamiento deseado. El QA debe verificar que no aparezcan botones de aprobar/rechazar en inscripciones ya procesadas. | Baja | Confusión de UX. | Los flags `showApprove`, `showOwnerActions` ya están condicionados al `status`; la lógica existente es correcta y no cambia. |
| R4 | `event_detail_view.dart` puede no tener acceso directo al `EventModel` con `sosTriggeredAt` si el campo llega de un cubit con estado parcial. | Media | `eventSosTriggeredAt` llega `null` desde ese punto de navegación aunque exista en backend. | El implementador verifica de dónde viene el `EventModel` en ese widget y si incluye `sosTriggeredAt` tras Fase 3. Documentar la fuente en el handoff de la fase. |
| R5 | El teléfono del rider podría ser `"••••"` si `allowOrganizerContact == false` (el backend ofusca el campo). | Baja | Tap no abre nada o construye URL malformada (`tel:••••`). | `RegistrationContactActions` solo se renderiza cuando `allowOrganizerContact == true`, que es la condición exacta que garantiza que el backend retorna el teléfono real (no `"••••"`). Además, `UrlLauncherHelper.openPhone` usa `canLaunchUrl` internamente y no crashea ante URLs no lanzables. No se necesita guard adicional en el widget. Si el contrato del backend cambia en el futuro, agregar `phone.isNotEmpty` como condición extra antes de renderizar. |

---

## Dependencias (fases prerequisito y por que)

**Fase 2 — Validación de edad y ofuscación condicional en backend**
El backend debe retornar los campos ofuscados (`"••••"`, `"__NOT_SHARED__"`) o reales según las reglas de privacidad. Sin Fase 2, todos los campos llegan siempre con el valor real y la UI de ofuscación no tiene efecto observable. Además, `allowOrganizerContact` solo viaja desde el backend si los contratos y la lógica de persistencia de Fase 2 (y Fase 1) están implementados.

**Fase 3 — Modelos y DTOs Flutter**
`EventRegistrationModel` necesita `allowOrganizerContact: bool` para que `RegistrationContactActions` pueda evaluar la condición de renderizado. `EventModel` necesita `sosTriggeredAt: DateTime?` (mapeado en Fase 3) para que los puntos de navegación puedan pasar `eventSosTriggeredAt` al extra. El cambio de `bloodType: BloodType` a `BloodType?` con getter de parse seguro más el campo `bloodTypeRaw` son prerequisitos de la corrección del acceso en `RegistrationDetailPage`.

---

## Ejecucion recomendada (nivel rg-exec: normal)

**Por que normal:** Feature de UI acotada sobre una página existente. Incluye refactor de `RegistrationDetailBottomBar` para independizar el early-return, widget nuevo obligatorio (`registration_contact_actions.dart`), y extensión de `RegistrationDetailExtra`. Sin migraciones ni contratos nuevos. Riesgo medio por el refactor del early-return que puede afectar estados existentes de la bottom bar, y por la corrección del acceso a `bloodType` nullable que depende del modelo resultante de Fase 3. El nivel normal cubre: implementador con auditor Opus iterativo hasta aprobar, sin necesidad del ciclo full que aplica a cambios de backend/migraciones.

**Pre-flight obligatorio antes de ejecutar:**
1. Confirmar que Fase 2 (backend) y Fase 3 (modelos Flutter) están cerradas y mergeadas.
2. Verificar que `EventRegistrationModel.allowOrganizerContact` existe y es `bool`.
3. Verificar que `EventModel.sosTriggeredAt` existe y es `DateTime?`.
4. Confirmar el nombre exacto del getter/campo de string crudo de `bloodType` que Fase 3 expone (este plan lo llama `bloodTypeRaw`). Actualizar el Paso 4b si el nombre difiere antes de escribir código.
