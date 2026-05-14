import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/features/notifications/domain/model/notification_model.dart';

sealed class NotificationsState {}

final class NotificationsInitial extends NotificationsState {}

final class NotificationsLoading extends NotificationsState {}

final class NotificationsLoaded extends NotificationsState {
  NotificationsLoaded(this.notifications);
  final List<NotificationModel> notifications;
}

final class NotificationsEmpty extends NotificationsState {}

final class NotificationsError extends NotificationsState {
  NotificationsError(this.message);
  final String message;
}

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit() : super(NotificationsInitial());

  final List<NotificationModel> _all = [];

  Future<void> loadNotifications() async {
    emit(NotificationsLoading());
    // TODO: replace with real data source when backend is ready
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (_all.isEmpty) {
      emit(NotificationsEmpty());
    } else {
      emit(NotificationsLoaded(List.unmodifiable(_all)));
    }
  }

  void markAsRead(String notificationId) {
    final index = _all.indexWhere((n) => n.id == notificationId);
    if (index == -1) return;
    _all[index] = _all[index].copyWith(isRead: true);
    emit(NotificationsLoaded(List.unmodifiable(_all)));
  }

  void markAllAsRead() {
    for (var i = 0; i < _all.length; i++) {
      _all[i] = _all[i].copyWith(isRead: true);
    }
    if (_all.isEmpty) {
      emit(NotificationsEmpty());
    } else {
      emit(NotificationsLoaded(List.unmodifiable(_all)));
    }
  }
}
