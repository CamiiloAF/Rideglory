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
      title: _titleFromPayload(),
      body: _bodyFromPayload(),
      createdAt: createdAt ?? DateTime.now(),
      isRead: isRead,
      payload: payload,
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

  String _titleFromPayload() {
    return payload['title'] as String? ?? '';
  }

  String _bodyFromPayload() {
    return payload['body'] as String? ?? '';
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
