# Fase 2 — Event List Date Filter (Flutter)

**Slug:** event-tracking-fixes / phase-02
**Timestamp:** 2026-06-20T00:21:38Z
**Nivel rg-exec:** lite
**Dependencias:** ninguna (independiente de Fase 1 y Fase 3)

---

## Objetivo

El listado público de eventos muestra eventos pasados porque `EventsCubit.fetchEvents()` envía `dateFrom: null` cuando el usuario no aplica ningún filtro manual. El objetivo es agregar un piso automático de "medianoche local de hoy" que se envía al backend siempre que `_filters.startDate == null`, de modo que la pantalla de descubrimiento de rodadas muestre solo eventos de hoy en adelante por defecto.

`EventsCubit.myEvents` no se modifica: mostrar rodadas pasadas propias es UX intencional (el owner necesita ver el historial).

---

## Alcance (entra / no entra)

### Entra
- Modificación de `EventsCubit.fetchEvents()` para calcular `dateFrom` como medianoche local cuando `_filters.startDate == null` y `_isMyEvents == false`.
- Tests unitarios que cubren los cuatro escenarios obligatorios (sin filtro, con filtro manual, `clearFilters()`, `myEvents`).
- Actualización de los tests existentes que hacen stub de `getEventsUseCase` con `dateFrom: null` — ahora deberán aceptar cualquier `dateFrom` en los casos sin filtro.

### No entra
- Cambios en `EventsCubit.myEvents` (ni en `GetMyEventsUseCase`).
- Cambios en `_applyFiltersAndEmit()` (filtros locales in-memory — sin modificar).
- Cambios de contrato en `GetEventsUseCase`, `EventRepository`, o cualquier endpoint del backend.
- UI nueva o cambios en widgets de la pantalla de eventos.
- Manejo especial de eventos `IN_PROGRESS` en el listado general (ver edge case R7 abajo).
- Migraciones de base de datos o cambios en `rideglory-api`.

---

## Que se debe hacer (pasos concretos y ordenados)

1. **Leer `events_cubit.dart` línea 97-127** para ubicar exactamente `fetchEvents()` y confirmar que `filters.startDate?.toIso8601String().substring(0, 10)` es la expresión actual en la línea 102.

2. **Modificar `fetchEvents()`** en `EventsCubit` (solo el constructor `EventsCubit(...)`, no `.myEvents`):

   Reemplazar:
   ```dart
   dateFrom: filters.startDate?.toIso8601String().substring(0, 10),
   ```
   por:
   ```dart
   dateFrom: _isMyEvents
       ? null
       : (filters.startDate != null
           ? filters.startDate!.toIso8601String().substring(0, 10)
           : () {
               final now = DateTime.now();
               return DateTime(now.year, now.month, now.day)
                   .toIso8601String()
                   .substring(0, 10);
             }()),
   ```

   **Alternativa más legible (preferida):** extraer la lógica antes del call a `_fetchFn`:
   ```dart
   Future<void> fetchEvents() async {
     emit(const ResultState.loading());
     final filters = _filters;

     final String? dateFrom;
     if (_isMyEvents) {
       dateFrom = null;
     } else if (filters.startDate != null) {
       dateFrom = filters.startDate!.toIso8601String().substring(0, 10);
     } else {
       final now = DateTime.now();
       dateFrom = DateTime(now.year, now.month, now.day)
           .toIso8601String()
           .substring(0, 10);
     }

     final result = await _fetchFn(
       type: filters.types.isNotEmpty ? filters.types.first.apiValue : null,
       dateFrom: dateFrom,
       dateTo: filters.endDate?.toIso8601String().substring(0, 10),
     );
     // ... resto sin cambios
   }
   ```

   El implementador elige la forma más legible. Lo invariante es: **`DateTime.now()` nunca con `.toUtc()`**, y **`.substring(0, 10)`** para el formato `yyyy-MM-dd`.

3. **Actualizar tests existentes** que verificaban `dateFrom: null` en el path sin filtros dentro de `events_filter_cubit_test.dart` (TC-2-1, TC-2-6) y `events_cubit_analytics_test.dart` (TC-evlist-a1, TC-evlist-a4). Estos tests ahora deben usar `any(named: 'dateFrom')` o un matcher con el valor de medianoche local — ver sección Pruebas para el approach correcto.

4. **Agregar archivo de tests nuevos** `test/features/events/presentation/list/events_cubit_date_filter_test.dart` con los cuatro casos de la sección Pruebas.

5. **Ejecutar `dart analyze`** y resolver cualquier lint (no debe haber: el cambio es puro Dart, sin imports nuevos).

6. **Ejecutar `flutter test`** — todos los tests deben pasar incluyendo los nuevos.

---

## Archivos a crear/modificar (rutas reales, una linea de "que cambia")

| Accion | Ruta | Que cambia |
|--------|------|------------|
| Modificar | `lib/features/events/presentation/list/events_cubit.dart` | Agrega piso `dateFrom` = medianoche local en `fetchEvents()` cuando no hay filtro de fecha y `_isMyEvents == false`. |
| Modificar | `test/features/events/presentation/cubit/events_filter_cubit_test.dart` | TC-2-1 y TC-2-6 cambian el stub de `dateFrom: null` a `dateFrom: any(named: 'dateFrom')` (o matcher de fecha). |
| Modificar | `test/features/events/presentation/list/events_cubit_analytics_test.dart` | TC-evlist-a1 y TC-evlist-a4 cambian el stub de `dateFrom: null` a `dateFrom: any(named: 'dateFrom')`. |
| Crear | `test/features/events/presentation/list/events_cubit_date_filter_test.dart` | Tests unitarios nuevos para el piso de fecha (TC-df-1 a TC-df-4). |

---

## Contratos / API rideglory-api

Ninguno. El parámetro `dateFrom` ya existe en `GetEventsUseCase`, `EventRepository.getEvents()`, y el endpoint backend (`GET /api/events?dateFrom=`). Solo cambia cuándo se pasa un valor vs. `null` desde el cliente.

---

## Cambios de datos / migraciones

Ninguno.

---

## Criterios de aceptacion (numerados, observables, testeables)

1. Al abrir la pantalla de eventos sin aplicar ningún filtro, `GetEventsUseCase` es invocado con `dateFrom` igual a la fecha de hoy en formato `yyyy-MM-dd` (hora local del dispositivo, nunca UTC). Si hoy es `2026-06-20` en la zona local, el valor enviado es `"2026-06-20"`.

2. Al abrir la pantalla de eventos con un filtro manual de fecha de inicio `2026-07-15`, `GetEventsUseCase` es invocado con `dateFrom: "2026-07-15"` (el valor del filtro del usuario, no el piso automático).

3. Después de llamar `clearFilters()`, el siguiente `fetchEvents()` envía nuevamente el piso automático (`dateFrom` = hoy local), no `null`.

4. `EventsCubit.myEvents.fetchEvents()` envía `dateFrom: null` sin importar la fecha actual. El usuario ve todas sus rodadas incluyendo las pasadas.

5. `dart analyze` reporta 0 errores y 0 warnings nuevos introducidos por este cambio.

6. `flutter test` pasa al 100%, incluyendo los tests nuevos y los tests existentes modificados.

---

## Pruebas (unitarias/widget/integracion)

**Archivo nuevo:** `test/features/events/presentation/list/events_cubit_date_filter_test.dart`

Utilizar el mismo scaffold de mocks que `events_filter_cubit_test.dart` (`MockGetEventsUseCase`, `MockUpdateEventUseCase`, `MockAnalyticsService`). No requiere `MockGetMyEventsUseCase` para los tests de piso; sí para TC-df-4.

### TC-df-1 — Sin filtro → dateFrom es hoy local

```dart
test('TC-df-1: fetchEvents() sin filtro → dateFrom = medianoche local de hoy', () async {
  final today = DateTime.now();
  final expectedDateFrom = '${today.year.toString().padLeft(4, '0')}'
      '-${today.month.toString().padLeft(2, '0')}'
      '-${today.day.toString().padLeft(2, '0')}';

  when(() => mockGetEventsUseCase(
        type: null,
        dateFrom: expectedDateFrom,
        dateTo: null,
      )).thenAnswer((_) async => Right([]));

  await cubit.fetchEvents();

  verify(() => mockGetEventsUseCase(
        type: null,
        dateFrom: expectedDateFrom,
        dateTo: null,
      )).called(1);
});
```

### TC-df-2 — Con filtro manual → dateFrom = filtro del usuario

```dart
test('TC-df-2: fetchEvents() con filtro manual → dateFrom = filtro, no el piso', () async {
  when(() => mockGetEventsUseCase(
        type: null,
        dateFrom: '2026-09-01',
        dateTo: null,
      )).thenAnswer((_) async => Right([]));

  cubit.updateFilters(EventFilters(startDate: DateTime(2026, 9, 1)));
  await Future<void>.delayed(Duration.zero);

  verify(() => mockGetEventsUseCase(
        type: null,
        dateFrom: '2026-09-01',
        dateTo: null,
      )).called(1);
});
```

### TC-df-3 — clearFilters() restablece el piso automático

```dart
test('TC-df-3: clearFilters() → siguiente fetch usa piso de hoy, no null', () async {
  final today = DateTime.now();
  final expectedDateFrom = '${today.year.toString().padLeft(4, '0')}'
      '-${today.month.toString().padLeft(2, '0')}'
      '-${today.day.toString().padLeft(2, '0')}';

  // Arrange: stub para el fetch con filtro y para el fetch post-clear
  when(() => mockGetEventsUseCase(
        type: null,
        dateFrom: '2026-09-01',
        dateTo: null,
      )).thenAnswer((_) async => Right([]));
  when(() => mockGetEventsUseCase(
        type: null,
        dateFrom: expectedDateFrom,
        dateTo: null,
      )).thenAnswer((_) async => Right([]));

  cubit.updateFilters(EventFilters(startDate: DateTime(2026, 9, 1)));
  await Future<void>.delayed(Duration.zero);
  cubit.clearFilters();
  await Future<void>.delayed(Duration.zero);

  // El segundo fetch (post-clear) debe usar el piso, no null
  verify(() => mockGetEventsUseCase(
        type: null,
        dateFrom: expectedDateFrom,
        dateTo: null,
      )).called(1);
  // Y los filtros deben estar limpios
  expect(cubit.filters.hasFilters, false);
});
```

### TC-df-4 — myEvents → dateFrom siempre null

```dart
test('TC-df-4: EventsCubit.myEvents → dateFrom = null (no aplica piso)', () async {
  when(() => mockGetMyEventsUseCase()).thenAnswer((_) async => Right([]));

  final myEventsCubit = EventsCubit.myEvents(
    mockGetMyEventsUseCase,
    mockUpdateEventUseCase,
    mockAnalytics,
  );
  addTearDown(myEventsCubit.close);

  await myEventsCubit.fetchEvents();

  // myEvents no llama al use case de get events con dateFrom — simplemente no envía dateFrom
  verify(() => mockGetMyEventsUseCase()).called(1);
  // Verificar que getEventsUseCase NO fue llamado (myEvents usa _fetchFn distinto)
  verifyNever(() => mockGetEventsUseCase(
        type: any(named: 'type'),
        dateFrom: any(named: 'dateFrom'),
        dateTo: any(named: 'dateTo'),
      ));
});
```

**Ajuste a tests existentes:**

En `events_filter_cubit_test.dart`, los tests TC-2-1 y TC-2-6 hacen:
```dart
when(() => mockGetEventsUseCase(type: null, dateFrom: null, dateTo: null))
```
Esto romperá porque ahora `dateFrom` ya no es `null` en el path sin filtros. Cambiar a:
```dart
when(() => mockGetEventsUseCase(
  type: null,
  dateFrom: any(named: 'dateFrom'),
  dateTo: null,
)).thenAnswer(...)
```

Lo mismo aplica a TC-evlist-a1 y TC-evlist-a4 en `events_cubit_analytics_test.dart`.

---

## Riesgos y mitigaciones

| ID | Riesgo | Probabilidad | Impacto | Mitigacion |
|----|--------|-------------|---------|------------|
| R1 | Timezone: `DateTime.now()` devuelve hora local, pero `.toIso8601String()` en Dart siempre usa la zona local para el componente de fecha. Riesgo teórico: usuario cerca de medianoche ve eventos de "mañana" ya incluidos — eso es correcto UX. | Baja | Bajo | Documentado explícitamente con comentario en código: `// Usar DateTime.now() local — nunca .toUtc()`. |
| R2 | Tests existentes que stubean `dateFrom: null` en paths sin filtros empezarán a fallar con `MissingStubError`. | Alta (segura) | Medio | El paso 3 del plan actualiza esos stubs. El implementador corre `flutter test` antes de hacer PR y resuelve cualquier stub roto. |
| R3 | Edge case R7 (evento `IN_PROGRESS` iniciado ayer visible para un rider activo): el backend ya filtra `IN_PROGRESS` para no-participantes. Para riders participantes, el acceso a la rodada en curso es via FCM o `/events/:id/tracking`. El listado general no es la ruta de entrada para rodadas en curso. | Baja | Bajo | Documentado en comentario en código junto al `dateFrom` floor. No requiere cambio en `_applyFiltersAndEmit`. |
| R4 | Formato de fecha: `DateTime(now.year, now.month, now.day).toIso8601String()` produce `"2026-06-20T00:00:00.000"`. El `.substring(0, 10)` extrae `"2026-06-20"`, que coincide con el formato que el backend ya espera (igual que el filtro manual). | Muy baja | Bajo | Validado contra el uso existente en la línea original del cubit (`filters.startDate?.toIso8601String().substring(0, 10)`). |

---

## Dependencias (fases prerequisito y por que)

Ninguna. Esta fase es independiente de Fase 1 (WS Cleanup) y de Fase 3 (Auto-End Backend). Solo toca la capa de presentación Flutter y no modifica contratos de API ni lógica de WebSocket.

El orden de despliegue recomendado en `05-sintesis.md` es Fase 1 → Fase 2 → Fase 3 (ascendente por riesgo), pero las Fases 1 y 2 pueden desarrollarse en paralelo si se trabaja en ramas separadas.

---

## Ejecucion recomendada (nivel rg-exec: lite)

**Por que lite:** Cambio mecánico en una sola expresión dentro de `EventsCubit.fetchEvents()`. No hay cambios de contrato API, no hay UI nueva, no hay migraciones de base de datos, y no hay interacción con servicios externos nuevos. El riesgo de timezone está mitigado explícitamente con `DateTime.now()` local (nunca `.toUtc()`). El cambio es reversible inmediatamente eliminando la expresión del `dateFrom` floor y restaurando `filters.startDate?.toIso8601String().substring(0, 10)`. La mayor parte del esfuerzo de esta fase es actualizar stubs de tests existentes, no lógica nueva.
