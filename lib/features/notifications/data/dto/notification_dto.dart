import 'package:json_annotation/json_annotation.dart';
import 'package:rideglory/core/http/api_date_time.dart';
import 'package:rideglory/features/notifications/domain/model/notification_model.dart';

part 'notification_dto.g.dart';

@JsonSerializable(converters: apiJsonDateTimeConverters)
class NotificationDto {
  const NotificationDto({
    required this.id,
    required this.userId,
    required this.type,
    required this.payload,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String type;
  final Map<String, dynamic> payload;
  final bool isRead;
  final DateTime? createdAt;

  factory NotificationDto.fromJson(Map<String, dynamic> json) =>
      _$NotificationDtoFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationDtoToJson(this);

  NotificationModel toModel() {
    return NotificationModel(
      id: id,
      type: _parseType(type),
      title: _titleFromType(),
      body: _bodyFromType(),
      createdAt: createdAt ?? DateTime.now(),
      isRead: isRead,
      payload: payload,
      route: payload['route'] as String?,
    );
  }

  NotificationType _parseType(String typeStr) {
    return switch (typeStr) {
      'SOAT_30D' => NotificationType.soat30d,
      'SOAT_7D' => NotificationType.soat7d,
      'SOAT_DAY_OF' => NotificationType.soatDayOf,
      'NEW_REGISTRATION' => NotificationType.newRegistration,
      'REGISTRATION_APPROVED' => NotificationType.registrationApproved,
      'REGISTRATION_REJECTED' => NotificationType.registrationRejected,
      _ => NotificationType.general,
    };
  }

  String _titleFromType() {
    return switch (type) {
      'NEW_REGISTRATION' => 'Nueva inscripción',
      'REGISTRATION_APPROVED' => 'Inscripción aprobada',
      'REGISTRATION_REJECTED' => 'Inscripción rechazada',
      'SOAT_30D' => 'Tu SOAT vence en 30 días',
      'SOAT_7D' => 'Tu SOAT vence en 7 días',
      'SOAT_DAY_OF' => 'Tu SOAT vence hoy',
      'MAINTENANCE_DATE_REMINDER' => 'Recordatorio de mantenimiento',
      'EVENT_REMINDER' => 'Recordatorio de rodada',
      'SOS_ALERT' => 'Alerta SOS',
      'TRACKING_ENDED' => 'Rodada finalizada',
      _ => 'Notificación',
    };
  }

  String _bodyFromType() {
    return switch (type) {
      'NEW_REGISTRATION' => 'Un rider se inscribió a tu evento',
      'REGISTRATION_APPROVED' => 'Tu inscripción fue aprobada',
      'REGISTRATION_REJECTED' => 'Tu inscripción fue rechazada',
      'SOAT_30D' => 'El SOAT de tu moto vence en 30 días',
      'SOAT_7D' => 'El SOAT de tu moto vence en 7 días',
      'SOAT_DAY_OF' => 'El SOAT de tu moto vence hoy',
      'MAINTENANCE_DATE_REMINDER' => 'Tu mantenimiento está programado en 30 días',
      'EVENT_REMINDER' => 'Tu rodada comienza en 24 horas',
      'SOS_ALERT' => 'Un rider ha enviado una alerta SOS',
      'TRACKING_ENDED' => 'La rodada ha finalizado',
      _ => '',
    };
  }
}

@JsonSerializable(converters: apiJsonDateTimeConverters)
class NotificationPageDto {
  const NotificationPageDto({
    required this.data,
    this.nextCursor,
  });

  final List<NotificationDto> data;
  final String? nextCursor;

  factory NotificationPageDto.fromJson(Map<String, dynamic> json) =>
      _$NotificationPageDtoFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationPageDtoToJson(this);
}
