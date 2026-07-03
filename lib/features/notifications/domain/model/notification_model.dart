enum NotificationType {
  soat30d,
  soat7d,
  soatDayOf,
  newRegistration,
  registrationApproved,
  registrationRejected,
  general,
}

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.payload,
    this.route,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? payload;

  /// URI de deep link para abrir la pantalla correspondiente al tapear.
  /// Ejemplo: `rideglory://events/detail-by-id?id=xxx`
  final String? route;

  NotificationModel copyWith({bool? isRead, String? title, String? body}) {
    return NotificationModel(
      id: id,
      type: type,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      payload: payload,
      route: route,
    );
  }
}
