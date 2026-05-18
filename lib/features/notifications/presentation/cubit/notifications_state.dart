import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/notifications/domain/model/notification_model.dart';

part 'notifications_state.freezed.dart';

@freezed
abstract class NotificationsState with _$NotificationsState {
  const factory NotificationsState({
    @Default(ResultState<List<NotificationModel>>.initial())
    ResultState<List<NotificationModel>> listResult,
    @Default(null) String? nextCursor,
    @Default(0) int unreadCount,
    @Default(false) bool isLoadingMore,
  }) = _NotificationsState;
}
