import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/features/events/data/dto/event_dto.dart';

Map<String, dynamic> _minimalJson() => <String, dynamic>{
  'id': 'event-1',
  'ownerId': 'owner-1',
  'name': 'Rodada Test',
  'description': 'Descripción',
  'startDate': '2026-07-01T10:00:00.000Z',
  'difficulty': 'EASY',
  'meetingTime': '2026-07-01T09:00:00.000Z',
  'eventType': 'ON_ROAD',
};

void main() {
  group('EventDto — organizerAcceptedResponsibilityAt / sosTriggeredAt (AC#4)', () {
    test(
      'TC-dto-01: fromJson parses both ISO-8601 fields into non-null DateTime',
      () {
        final json = _minimalJson()
          ..['organizerAcceptedResponsibilityAt'] =
              '2026-06-19T12:00:00.000Z'
          ..['sosTriggeredAt'] = '2026-06-20T08:30:00.000Z';

        final dto = EventDto.fromJson(json);

        expect(dto.organizerAcceptedResponsibilityAt, isNotNull);
        expect(
          dto.organizerAcceptedResponsibilityAt!.toUtc(),
          DateTime.parse('2026-06-19T12:00:00.000Z').toUtc(),
        );
        expect(dto.sosTriggeredAt, isNotNull);
        expect(
          dto.sosTriggeredAt!.toUtc(),
          DateTime.parse('2026-06-20T08:30:00.000Z').toUtc(),
        );
      },
    );

    test('TC-dto-02: fromJson with both fields absent decodes to null', () {
      final dto = EventDto.fromJson(_minimalJson());

      expect(dto.organizerAcceptedResponsibilityAt, isNull);
      expect(dto.sosTriggeredAt, isNull);
    });
  });
}
