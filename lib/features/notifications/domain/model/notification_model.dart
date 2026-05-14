enum NotificationType {
  registrationApproved,
  registrationRejected,
  registrationReadyForEdit,
  eventStarted,
  newRegistration,
  eventReminder,
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
    this.eventId,
    this.registrationId,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? eventId;
  final String? registrationId;

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      type: type,
      title: title,
      body: body,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      eventId: eventId,
      registrationId: registrationId,
    );
  }
}
