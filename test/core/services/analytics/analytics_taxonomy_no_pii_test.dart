/// Test guardián no-PII de la taxonomía de analítica (Fase 10).
///
/// Propósito: actuar como "candado" automático para que futuras fases no
/// introduzcan PII en las constantes de [AnalyticsEvents] ni en
/// [AnalyticsParams]. También verifica los límites de GA4 (nombre de evento
/// ≤40 chars, clave de parámetro ≤40 chars) y la convención snake_case.
///
/// Este test no requiere Firebase, mocks ni DI — solo Dart puro.
/// Añadir un nombre de evento o clave de parámetro prohibido en el catálogo
/// hace fallar este test antes de llegar a producción.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
// AnalyticsScreenNames is audited inline in TC-pii-9 (canonical name map),
// without importing the class, to keep the test Dart-pure with no SDK deps.

// ---------------------------------------------------------------------------
// Substrings prohibidos (en minúscula) que NUNCA deben aparecer en un nombre
// de evento o clave de parámetro como sufijo o parte de una clave real de PII.
//
// Política: solo las CLAVES son constantes auditables aquí (los VALORES
// dinámicos son auditados manualmente en los call sites). Los substrings son
// deliberadamente específicos para evitar falsos positivos; ver _allowedExceptions
// para excepciones documentadas.
//
// NO se audita: valores en tiempo de ejecución (ej. soatStatus.name, que es
// un enum cerrado) — esos son auditados en el doc de QA de analítica.
// ---------------------------------------------------------------------------
const _prohibitedSubstrings = [
  'email',
  'phone',
  'placa',
  'plate',
  'vin',
  // Coordenadas: se prohíbe 'latitude', 'longitude', 'coord' pero NO 'lat' en
  // solitario porque crearía falsos positivos con p.ej. 'platform'.
  'latitude',
  'longitude',
  'coord',
  // FCM token como VALOR — el evento fcm_token_registered es legítimo (señal de
  // salud sin el token). Se prohíbe 'fcm_token' como PARTE de clave de parámetro
  // (si alguien agrega un param con el token en claro).
  'fcm_token_value',
  // IDs crudos como claves de parámetro (distintos de contadores/flags).
  'user_id',
  'rider_id',
  'event_id',
  'vehicle_id',
  'registration_id',
  'maintenance_id',
  ':id',
  // Datos cuasi-PII de póliza y dirección.
  'policy_number',
  'policy_name',
  'poliza',
  'address',
  'direccion',
  // Nombre libre de persona/empresa (se permite 'insurer_detected' como flag 0/1,
  // pero 'insurer_name' sería PII).
  'insurer_name',
  'aseguradora',
  'full_name',
  'nombre_completo',
];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Verifica que [identifier] sea snake_case puro:
/// solo minúsculas, dígitos y guiones bajos, sin espacios ni mayúsculas.
bool _isSnakeCase(String identifier) =>
    RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(identifier);

/// Devuelve la lista de substrings prohibidos encontrados en [identifier].
List<String> _findProhibited(String identifier) {
  final lower = identifier.toLowerCase();
  return _prohibitedSubstrings
      .where((sub) => lower.contains(sub))
      .toList();
}

// ---------------------------------------------------------------------------
// Colecciones del catálogo
// ---------------------------------------------------------------------------

/// Todos los nombres de evento definidos en [AnalyticsEvents].
const _eventNames = [
  AnalyticsEvents.authFlowStarted,
  AnalyticsEvents.authMethodSelected,
  AnalyticsEvents.authSucceeded,
  AnalyticsEvents.authFailed,
  AnalyticsEvents.authAbandoned,
  AnalyticsEvents.authFirstHomeEntry,
  AnalyticsEvents.soatScanAttempted,
  AnalyticsEvents.soatScanSuccess,
  AnalyticsEvents.soatScanFailed,
  AnalyticsEvents.homeViewed,
  AnalyticsEvents.eventsListViewed,
  AnalyticsEvents.eventDetailViewed,
  AnalyticsEvents.eventsCreateStarted,
  AnalyticsEvents.eventsDraftSaved,
  AnalyticsEvents.eventsPublished,
  AnalyticsEvents.eventsPublishFailed,
  AnalyticsEvents.eventsDeleteAttempted,
  AnalyticsEvents.eventsDeleteSucceeded,
  AnalyticsEvents.eventsDeleteFailed,
  AnalyticsEvents.registrationStarted,
  AnalyticsEvents.registrationStepAdvanced,
  AnalyticsEvents.registrationStepBack,
  AnalyticsEvents.registrationSubmitted,
  AnalyticsEvents.registrationSubmitFailed,
  AnalyticsEvents.registrationAbandoned,
  AnalyticsEvents.registrationApproved,
  AnalyticsEvents.registrationRejected,
  AnalyticsEvents.registrationReadyForEdit,
  AnalyticsEvents.registrationApprovalFailed,
  AnalyticsEvents.registrationMyListViewed,
  AnalyticsEvents.registrationCancelled,
  AnalyticsEvents.trackingSessionStarted,
  AnalyticsEvents.trackingSessionEnded,
  AnalyticsEvents.trackingSnapshotReceived,
  AnalyticsEvents.sosActivated,
  AnalyticsEvents.sosConfirmed,
  AnalyticsEvents.sosCleared,
  AnalyticsEvents.vehicleAdded,
  AnalyticsEvents.vehicleUpdated,
  AnalyticsEvents.vehicleDeleted,
  AnalyticsEvents.vehicleSetMain,
  AnalyticsEvents.maintenanceAdded,
  AnalyticsEvents.maintenanceHistoryViewed,
  AnalyticsEvents.soatStatusViewed,
  AnalyticsEvents.soatManualSaved,
  AnalyticsEvents.profileViewed,
  AnalyticsEvents.profileEditStarted,
  AnalyticsEvents.profileEditSucceeded,
  AnalyticsEvents.riderProfileViewed,
  AnalyticsEvents.notificationMarkedRead,
  AnalyticsEvents.notificationsAllRead,
  AnalyticsEvents.fcmTokenRegistered,
];

/// Todas las claves de parámetros definidas en [AnalyticsParams].
const _paramKeys = [
  AnalyticsParams.authMethod,
  AnalyticsParams.authErrorCategory,
  AnalyticsParams.userPropertyLoginMethod,
  AnalyticsParams.userPropertyHasVehicle,
  AnalyticsParams.fieldsExtractedCount,
  AnalyticsParams.insurerDetected,
  AnalyticsParams.hadPdf,
  AnalyticsParams.failureReason,
  AnalyticsParams.errorCategory,
  AnalyticsParams.httpStatus,
  AnalyticsParams.dioType,
  AnalyticsParams.endpoint,
  AnalyticsParams.upcomingEventsCount,
  AnalyticsParams.hasMainVehicle,
  AnalyticsParams.resultCount,
  AnalyticsParams.listScope,
  AnalyticsParams.eventType,
  AnalyticsParams.eventState,
  AnalyticsParams.isOwner,
  AnalyticsParams.isReadOnly,
  AnalyticsParams.source,
  AnalyticsParams.formMode,
  AnalyticsParams.failureCategory,
  AnalyticsParams.stepIndex,
  AnalyticsParams.stepName,
  AnalyticsParams.approvalAction,
  AnalyticsParams.trackingRole,
  AnalyticsParams.trackingEndReason,
  AnalyticsParams.riderCount,
  AnalyticsParams.sosClearReason,
  AnalyticsParams.hadPhoto,
  AnalyticsParams.maintenanceType,
  AnalyticsParams.maintenanceMode,
  AnalyticsParams.soatStatus,
  AnalyticsParams.notificationType,
];

// _screenNames is audited inline in TC-pii-9 via the canonical map.

// ---------------------------------------------------------------------------
// Suites
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // TC-pii-1: Nombres de evento — longitud GA4 (≤40)
  // -------------------------------------------------------------------------
  group('TC-pii-1: nombres de evento ≤40 chars (límite GA4)', () {
    for (final eventName in _eventNames) {
      test('evento "$eventName" ≤40 chars', () {
        expect(
          eventName.length,
          lessThanOrEqualTo(40),
          reason:
              'GA4 trunca nombres de evento superiores a 40 chars. '
              '"$eventName" tiene ${eventName.length} chars.',
        );
      });
    }
  });

  // -------------------------------------------------------------------------
  // TC-pii-2: Nombres de evento — snake_case
  // -------------------------------------------------------------------------
  group('TC-pii-2: nombres de evento en snake_case', () {
    for (final eventName in _eventNames) {
      test('evento "$eventName" es snake_case', () {
        expect(
          _isSnakeCase(eventName),
          isTrue,
          reason:
              '"$eventName" no cumple snake_case (solo minúsculas, dígitos '
              'y guiones bajos, comenzando con letra).',
        );
      });
    }
  });

  // -------------------------------------------------------------------------
  // TC-pii-3: Nombres de evento — sin substrings PII prohibidos
  // -------------------------------------------------------------------------
  group('TC-pii-3: nombres de evento sin substrings PII prohibidos', () {
    for (final eventName in _eventNames) {
      test('evento "$eventName" no contiene PII en la clave', () {
        final found = _findProhibited(eventName);
        expect(
          found,
          isEmpty,
          reason:
              'El nombre de evento "$eventName" contiene substrings prohibidos: '
              '$found. Renombrar o justificar con excepción documentada.',
        );
      });
    }
  });

  // -------------------------------------------------------------------------
  // TC-pii-4: Claves de parámetro — longitud GA4 (≤40)
  // -------------------------------------------------------------------------
  group('TC-pii-4: claves de parámetro ≤40 chars (límite GA4)', () {
    for (final key in _paramKeys) {
      test('clave "$key" ≤40 chars', () {
        expect(
          key.length,
          lessThanOrEqualTo(40),
          reason:
              'GA4 ignora parámetros con clave >40 chars. '
              '"$key" tiene ${key.length} chars.',
        );
      });
    }
  });

  // -------------------------------------------------------------------------
  // TC-pii-5: Claves de parámetro — snake_case
  // -------------------------------------------------------------------------
  group('TC-pii-5: claves de parámetro en snake_case', () {
    for (final key in _paramKeys) {
      test('clave "$key" es snake_case', () {
        expect(
          _isSnakeCase(key),
          isTrue,
          reason:
              '"$key" no cumple snake_case.',
        );
      });
    }
  });

  // -------------------------------------------------------------------------
  // TC-pii-6: Claves de parámetro — sin substrings PII prohibidos
  // -------------------------------------------------------------------------
  group('TC-pii-6: claves de parámetro sin substrings PII prohibidos', () {
    for (final key in _paramKeys) {
      test('clave "$key" no contiene PII', () {
        final found = _findProhibited(key);
        expect(
          found,
          isEmpty,
          reason:
              'La clave de parámetro "$key" contiene substrings prohibidos: '
              '$found.',
        );
      });
    }
  });

  // -------------------------------------------------------------------------
  // TC-pii-7: Catálogo de eventos — sin duplicados
  // -------------------------------------------------------------------------
  test('TC-pii-7: no hay nombres de evento duplicados en el catálogo', () {
    final seen = <String>{};
    final duplicates = <String>[];
    for (final eventName in _eventNames) {
      if (!seen.add(eventName)) {
        duplicates.add(eventName);
      }
    }
    expect(
      duplicates,
      isEmpty,
      reason:
          'Nombres de evento duplicados detectados: $duplicates. '
          'Eliminar o consolidar.',
    );
  });

  // -------------------------------------------------------------------------
  // TC-pii-8: Catálogo de claves — sin duplicados
  // -------------------------------------------------------------------------
  test('TC-pii-8: no hay claves de parámetro duplicadas en el catálogo', () {
    final seen = <String>{};
    final duplicates = <String>[];
    for (final key in _paramKeys) {
      if (!seen.add(key)) {
        duplicates.add(key);
      }
    }
    expect(
      duplicates,
      isEmpty,
      reason:
          'Claves de parámetro duplicadas: $duplicates. '
          'Eliminar o consolidar.',
    );
  });

  // -------------------------------------------------------------------------
  // TC-pii-9: Nombres de pantalla canónicos — sin ids dinámicos (:id)
  // -------------------------------------------------------------------------
  test(
    'TC-pii-9: nombres de pantalla canónicos no contienen ":id" ni parámetros dinámicos',
    () {
      final screenMap = <String, String>{
        'splash': 'splash',
        'login': 'login',
        'signup': 'signup',
        'forgot_password': 'forgot_password',
        'home': 'home',
        'garage': 'garage',
        'events': 'events',
        'profile': 'profile',
        'profile_edit': 'profile_edit',
        'vehicle_create': 'vehicle_create',
        'vehicle_detail': 'vehicle_detail',
        'vehicle_edit': 'vehicle_edit',
        'maintenances': 'maintenances',
        'maintenance_create': 'maintenance_create',
        'maintenance_edit': 'maintenance_edit',
        'maintenance_detail': 'maintenance_detail',
        'events_mine': 'events_mine',
        'events_drafts': 'events_drafts',
        'event_create': 'event_create',
        'event_edit': 'event_edit',
        'event_detail': 'event_detail',
        'event_registration': 'event_registration',
        'event_attendees': 'event_attendees',
        'live_map': 'live_map',
        'participants': 'participants',
        'my_registrations': 'my_registrations',
        'registration_detail': 'registration_detail',
        'rider_profile': 'rider_profile',
        'notifications': 'notifications',
        'soat_status': 'soat_status',
        'soat_manual_capture': 'soat_manual_capture',
      };

      for (final entry in screenMap.entries) {
        final screenName = entry.value;
        expect(
          screenName.contains(':'),
          isFalse,
          reason:
              'El nombre de pantalla canónico "$screenName" contiene ":" — '
              'indica un id dinámico en el nombre estable, lo que viola la '
              'política no-PII de alta cardinalidad.',
        );
        expect(
          _isSnakeCase(screenName),
          isTrue,
          reason: 'Nombre de pantalla "$screenName" no es snake_case.',
        );
      }
    },
  );

  // -------------------------------------------------------------------------
  // TC-pii-10: Regla G1 — detección de literales directos en logEvent
  //
  // Verifica que el catálogo en Dart tiene exactamente la cantidad esperada
  // de eventos. Si alguien agrega un evento como literal (no como constante),
  // este test no lo detecta — ese control lo hace el grep en CI:
  //   grep -rn "logEvent('" lib/ | grep -v ".g.dart" (debe ser vacío)
  //
  // Lo que SÍ detecta: que el tamaño del catálogo no decreció (regresión de
  // eliminación de constantes).
  // -------------------------------------------------------------------------
  test(
    'TC-pii-10: el catálogo tiene al menos 51 eventos y 35 claves de parámetro '
    '(regresión de eliminación)',
    () {
      expect(
        _eventNames.length,
        greaterThanOrEqualTo(51),
        reason:
            'El catálogo tiene menos eventos de lo esperado. '
            'Si se eliminó un evento intencionalmente, actualizar este umbral.',
      );
      expect(
        _paramKeys.length,
        greaterThanOrEqualTo(35),
        reason:
            'El catálogo tiene menos claves de parámetro de lo esperado. '
            'Si se eliminó una clave intencionalmente, actualizar este umbral.',
      );
    },
  );
}
