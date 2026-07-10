// Unit tests for NotificationDto's private fallback title/body mapping
// (_titleFromType / _bodyFromType), reached indirectly via toModel() for the
// 4 backend types that don't have a dedicated NotificationType enum value:
// MAINTENANCE_DATE_REMINDER, EVENT_REMINDER, SOS_ALERT and TRACKING_ENDED.
//
// These all fall back to NotificationType.general on _parseType, but the
// title/body should still be a specific Spanish string, not the generic
// "Notificación"/"" fallback used for truly unknown types.

import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/features/notifications/data/dto/notification_dto.dart';
import 'package:rideglory/features/notifications/domain/model/notification_model.dart';

NotificationDto _buildDto({required String type}) => NotificationDto(
  id: 'n1',
  userId: 'u1',
  type: type,
  payload: const {},
  isRead: false,
  createdAt: DateTime(2026, 5, 1),
);

void main() {
  group('NotificationDto — fallback title/body for unmapped backend types '
      '(Caso 9A.1)', () {
    test(
      'MAINTENANCE_DATE_REMINDER → title/body específicos, type = general',
      () {
        final model = _buildDto(type: 'MAINTENANCE_DATE_REMINDER').toModel();

        expect(model.type, NotificationType.general);
        expect(model.title, 'Recordatorio de mantenimiento');
        expect(model.body, 'Tu mantenimiento está programado en 30 días');
      },
    );

    test('EVENT_REMINDER → title/body específicos, type = general', () {
      final model = _buildDto(type: 'EVENT_REMINDER').toModel();

      expect(model.type, NotificationType.general);
      expect(model.title, 'Recordatorio de rodada');
      expect(model.body, 'Tu rodada comienza en 24 horas');
    });

    test('SOS_ALERT → title/body específicos, type = general', () {
      final model = _buildDto(type: 'SOS_ALERT').toModel();

      expect(model.type, NotificationType.general);
      expect(model.title, 'Alerta SOS');
      expect(model.body, 'Un rider ha enviado una alerta SOS');
    });

    test('TRACKING_ENDED → title/body específicos, type = general', () {
      final model = _buildDto(type: 'TRACKING_ENDED').toModel();

      expect(model.type, NotificationType.general);
      expect(model.title, 'Rodada finalizada');
      expect(model.body, 'La rodada ha finalizado');
    });

    test(
      'un tipo totalmente desconocido cae al fallback genérico '
      '"Notificación" / body vacío',
      () {
        final model = _buildDto(type: 'SOME_FUTURE_TYPE').toModel();

        expect(model.type, NotificationType.general);
        expect(model.title, 'Notificación');
        expect(model.body, '');
      },
    );
  });
}
