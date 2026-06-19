# Checklist de QA — Garaje en Home siempre coherente con VehicleCubit

**Feature:** Coherencia del garaje en Home — VehicleCubit como única fuente de verdad
**Fases cubiertas:** Fase única (Flutter presentation layer)
**Estado:** Pendiente de aprobacion PO

---

## Pre-condiciones

Antes de empezar, asegurate de tener en la cuenta de prueba:

- [ ] Al menos **un vehículo registrado** en el garaje de la cuenta de prueba (con modelo, placa y foto).
- [ ] Al menos **un segundo vehículo** registrado en el garaje (para poder cambiar el principal).
- [ ] La app instalada desde el árbol de trabajo actual (no desde Play Store / TestFlight).
- [ ] Acceso al emulador/simulador o dispositivo físico con sesión iniciada.
- [ ] Conexión a internet activa para que el backend responda normalmente.

---

## 1. Pantalla Home — carga normal con vehículo principal

> Abre la app con sesión iniciada. Espera a que la pantalla Home termine de cargar.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 1.1 | Abre la app desde cero (estado frío). Observa la sección de garaje mientras carga. | Aparece un bloque gris de aproximadamente 200 px de alto en lugar del card del vehículo, sin texto ni crash. | |
| 1.2 | Espera a que la carga termine (1–3 s). | El card del vehículo principal aparece con su nombre, modelo y foto; el bloque gris desaparece. | |
| 1.3 | Verifica que la pantalla Home no muestra errores de tipo "Null check operator used on null value" ni pantalla roja de error. | La pantalla Home se muestra completa sin errores en pantalla. | |

---

## 2. Pantalla Home — garaje vacío

> Inicia sesión con una cuenta que no tenga vehículos registrados, o archiva temporalmente todos los vehículos de la cuenta de prueba.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 2.1 | Abre la app con la cuenta sin vehículos. Espera a que Home cargue. | La sección de garaje muestra el card de estado vacío ("Aún no tienes vehículos" o equivalente), sin crash. | |
| 2.2 | Toca el botón de acción dentro del card vacío (ej. "Agregar vehículo"). | Navega a la pantalla de creación de vehículo sin error. | |

---

## 3. Cambio de vehículo principal — reactividad inmediata

> Tener al menos dos vehículos en el garaje. El vehículo A es el principal actual.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 3.1 | Desde la pantalla Home, anota el nombre del vehículo principal que aparece en la sección de garaje. | El card muestra el vehículo A como principal. | |
| 3.2 | Navega a la pantalla de Garaje (tab o menú correspondiente) sin cerrar la app. | La pantalla de Garaje carga y lista los vehículos. | |
| 3.3 | Toca el vehículo B (el que NO es principal) y selecciona la opción "Establecer como principal" o equivalente. | El sistema confirma el cambio (toast o indicador visual). | |
| 3.4 | Regresa a la pantalla Home con el botón de atrás o el tab de Home. | La sección de garaje muestra ahora el vehículo B como principal, sin haber hecho pull-to-refresh ni recargado la pantalla. | |
| 3.5 | Verifica que la actualización es inmediata, sin parpadeo excesivo ni flash de contenido antiguo. | El card muestra el vehículo B directamente, sin mostrar temporalmente el vehículo A. | |

---

## 4. Archivar el vehículo principal — reactividad inmediata

> El vehículo A es el principal. Tener al menos un segundo vehículo activo.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 4.1 | Desde Home, confirma que el card de garaje muestra el vehículo A. | Card muestra el vehículo A. | |
| 4.2 | Ve a Garaje, abre las opciones del vehículo A y selecciona "Archivar". | El vehículo A desaparece de la lista activa de Garaje. | |
| 4.3 | Regresa a Home sin hacer pull-to-refresh. | La sección de garaje se actualiza: si hay otro vehículo activo, muestra un vehículo distinto como nuevo principal; si no hay más vehículos activos, muestra el card de estado vacío. | |
| 4.4 | Verifica que la pantalla no muestra error ni crash. | Home sigue en pie, sin pantalla roja de error. | |

---

## 5. Restaurar vehículo archivado — reactividad en Home

> Al menos un vehículo está archivado. El garaje activo puede estar vacío o con otros vehículos.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 5.1 | Desde Garaje, accede a la sección de vehículos archivados. | La lista de archivados aparece. | |
| 5.2 | Toca el vehículo archivado y selecciona "Restaurar" o equivalente. | El vehículo vuelve a la lista activa. | |
| 5.3 | Regresa a Home. | La sección de garaje refleja el estado actualizado (el vehículo restaurado aparece si es el principal o si era el único activo), sin pull-to-refresh. | |

---

## 6. Casos de borde

### 6A. Inicio de sesión sin conexión a internet

> Desactiva el WiFi y los datos móviles antes de abrir la app.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 6A.1 | Abre la app sin conexión. Espera a que Home intente cargar. | La sección de garaje no crashea. Puede mostrar el placeholder gris o un estado de error, pero la pantalla es navegable. | |
| 6A.2 | Reactiva la conexión y espera unos segundos (o haz pull-to-refresh si existe). | La sección de garaje se recupera y muestra el vehículo principal. | |

### 6B. Cuenta sin vehículos — regreso después de agregar uno

> Inicia con cuenta vacía (sin vehículos).

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 6B.1 | Desde Home (card de garaje vacío), toca "Agregar vehículo" y completa el formulario de creación. | El vehículo se guarda correctamente. | |
| 6B.2 | Regresa a Home. | La sección de garaje muestra el nuevo vehículo como principal, sin necesidad de reiniciar la app. | |

### 6C. Scroll en Home durante la carga

> Abre la app desde cero y desplaza el scroll de Home hacia abajo inmediatamente, antes de que VehicleCubit termine de cargar.

| # | Accion | Resultado esperado | ✅/❌ |
|---|--------|--------------------|-------|
| 6C.1 | Abre la app y desliza la pantalla Home hacia abajo de inmediato (antes de que aparezca el card del vehículo). | El placeholder de 200 px ocupa el espacio del garaje sin deformar el layout; el resto del contenido de Home se ve sin saltos bruscos. | |
| 6C.2 | Espera a que el vehículo cargue. | El card reemplaza el placeholder sin cambiar la posición del scroll de forma abrupta. | |

---

## 7. Verificaciones tecnicas (equipo de desarrollo)

> Estas verificaciones requieren acceso a logs de la app o herramientas de desarrollo.

| # | Verificacion | Resultado esperado | ✅/❌ |
|---|-------------|--------------------|-------|
| 7.1 | Ejecuta `grep -rn 'mainVehicle' lib/features/home/presentation/` en el repositorio. | Cero resultados en `home_state.dart`; solo puede aparecer la referencia a `data.mainVehicle` en `home_cubit.dart` (línea de Analytics) y la variable local `mainVehicle` en `home_garage_section.dart`. Ningún `HomeLoaded` construye con `mainVehicle:`. | |
| 7.2 | Ejecuta `grep -rn 'vehicle:' lib/features/home/presentation/widgets/home_scaffold.dart`. | Cero resultados (no se pasa el prop `vehicle:` a `HomeGarageSection`). | |
| 7.3 | Ejecuta `flutter test test/features/home/` y verifica el resultado. | 14/14 tests pasan (0 fallos). | |
| 7.4 | Ejecuta `dart analyze lib/features/home/` y verifica el resultado. | "No issues found" — cero errores, cero warnings nuevos. | |
| 7.5 | Conecta Flutter DevTools durante el caso 3.4. Filtra eventos de `HomeCubit`. Cambia el vehículo principal desde Garaje y regresa a Home. | `HomeCubit` NO emite un evento `loadHomeData` adicional tras el cambio de principal. Solo `VehicleCubit` emite el nuevo estado. | |
| 7.6 | Verifica que `lib/features/home/domain/home_data.dart` y `lib/features/home/data/dto/home_dto.dart` aún contienen el campo `mainVehicle`. | `grep -n 'mainVehicle' lib/features/home/domain/home_data.dart lib/features/home/data/dto/home_dto.dart` muestra resultados en ambos archivos. | |

---

## Resultado final

| Estado | Criterio |
|--------|----------|
| ✅ Aprobado | Todos los casos de las secciones 1–6 marcados como ✅ |
| ⚠️ Aprobado con observaciones | Maximo 2 casos fallidos de baja severidad en las secciones 2, 5 o 6, con ticket creado |
| ❌ Rechazado | Cualquier caso de las secciones 1, 3 o 4 marcado como ❌, o cualquier crash detectado |

**Revisado por:** ___________________
**Fecha:** ___________________
**Resultado:** ___________________
**Observaciones:** ___________________
