---
trigger: always_on
---

# Estándares de Código — Rideglory

## 📝 Strings

- **Todos los strings** visibles al usuario deben definirse en una clase estática dentro de
  `lib/features/<feature>/constants/<feature>_strings.dart`. Deben predominar los Strings ya existentes en AppStrings.
  - Ejemplo: `AuthStrings` en `lib/features/authentication/constants/auth_strings.dart`
  - Ejemplo: `SplashStrings` en `lib/features/splash/constants/splash_strings.dart`
- La clase debe ser clases abstractas.
- **Nunca** hardcodear strings directamente en widgets (`Text('Bienvenido')` está prohibido).
- Los strings de validación de formularios también van en la clase del feature correspondiente.
- Los strings globales y de error genérico van en `lib/core/constants/app_strings.dart`.

## 🎨 Colores

- **Prioridad 1 — Theme:** Usar siempre `Theme.of(context).colorScheme.<propiedad>` para
  colores que dependen del modo claro/oscuro o del tema activo.
  - `colorScheme.primary` → color primario (naranja `#f98c1f`)
  - `colorScheme.onPrimary` → texto/iconos sobre el color primario
  - `colorScheme.surface` / `colorScheme.onSurface` → fondos de tarjetas y texto principal
  - `colorScheme.onSurfaceVariant` → texto secundario / labels / hints
  - `colorScheme.error` → errores y estados de peligro
  - `colorScheme.outline` → bordes genéricos

- **Prioridad 2 — AppColors:** Cuando el color no tiene un equivalente semántico en el
  `ColorScheme`, usar la constante correspondiente en `lib/core/theme/app_colors.dart`.
  - `AppColors.darkBackground` → fondo principal oscuro (`#111111`)
  - `AppColors.darkSurface` → superficie elevada (`#1C1209`)
  - `AppColors.darkSurfaceHighest` → superficie más alta (`#261A0E`)
  - `AppColors.darkBorder` → bordes en modo oscuro (`#3D2810`)
  - `AppColors.primary` → naranja (`#f98c1f`) — usar solo fuera de un contexto de `BuildContext`
  - En lugar de usar Theme.of(context).colorScheme usa la extensión context.colorScheme

- **Prohibido:** Usar `Color(0xFF...)` directamente dentro de métodos `build()` o en widgets.
  Si necesitas un color nuevo, primero agrégalo a `AppColors` o verifica si ya existe en
  `colorScheme`.

## 🏗️ Estructura general

- No está permitido crear métodos para construir widgets (_buildXWidget())
- Cada Widget debe vivir en un archivo y cada archivo solo tendrá máximo 1 widget no importa si es público o privado
- Debe seguir una arquitectura limpia separada por capas: presentation, data, domain
- Constantes de campos de formulario → `lib/features/<feature>/constants/<feature>_form_fields.dart`
- Evita agregar comentarios muy obvios, por ejemplo evita "Outlined social login button (Google / Apple style)" en la clase LoginSocialButton. Se sobrentiende por el nombre de la clase par qué es el botón.
- **Textos de botones:** siempre en sentence case — primera letra mayúscula, el resto en minúscula.
  - ✅ `'Iniciar sesión'` `'Crear cuenta'` `'Regístrate gratis'`
  - ❌ `'INICIAR SESIÓN'` `'Crear Cuenta'` `'REGÍSTRATE GRATIS'`

## 📦 Componentes compartidos

- **Siempre** usar los componentes de `lib/shared/widgets/` en lugar de construir widgets primitivos
  propios cuando existe un equivalente:
  - **Botones** → `AppButton` (`shared/widgets/form/app_button.dart`)
    - Soporta `isLoading`, variantes (`primary`, `outline`, `danger`, etc.), `icon`, `isFullWidth`
    - **Prohibido** usar `ElevatedButton`, `OutlinedButton` o `TextButton` directamente en features
  - **Links / botones de texto** → `AppTextButton` (`shared/widgets/form/app_text_button.dart`)
    - Soporta variantes `primary`, `muted`, `danger`
  - **Campos de texto** → `AppTextField` (`shared/widgets/form/app_text_field.dart`)
    - Maneja label, hint, validación, prefixIcon, suffixIcon
  - **Campos de contraseña** → `AppPasswordTextField` (`shared/widgets/form/app_password_text_field.dart`)
    - Ya incluye toggle de visibilidad — no reimplementar
  - **Modales / diálogos** → `AppDialog` / `ConfirmationDialog` (`shared/widgets/modals/`)
    - **Prohibido** llamar `showDialog(...)` directamente; usar los wrappers existentes
- Si el componente shared no cubre un caso de uso específico del diseño (e.g. botones sociales
  con ícono de proveedor), se puede crear un widget propio en la carpeta del feature —
  pero debe documentarse la razón en un comentario junto al widget.

## 🖌️ Tema visual (Stitch Orange Dark)

- Color primario: `#f98c1f`
- Modo: **Dark**
- Fuente: **Space Grotesk** (`google_fonts`)
- Border radius estándar: **8 px** (`ROUND_EIGHT`)