import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/notifications/domain/model/notification_model.dart';
import 'package:rideglory/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:rideglory/features/notifications/domain/usecases/mark_all_notifications_read_usecase.dart';
import 'package:rideglory/features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'package:rideglory/features/notifications/presentation/cubit/notifications_state.dart';

@lazySingleton
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(
    this._getNotificationsUseCase,
    this._markReadUseCase,
    this._markAllReadUseCase,
  ) : super(const NotificationsState());

  final GetNotificationsUseCase _getNotificationsUseCase;
  final MarkNotificationReadUseCase _markReadUseCase;
  final MarkAllNotificationsReadUseCase _markAllReadUseCase;

  Future<void> load() async {
    emit(state.copyWith(
      listResult: const ResultState.loading(),
      nextCursor: null,
    ));
    final result = await _getNotificationsUseCase();
    result.fold(
      (error) => emit(state.copyWith(
        listResult: ResultState.error(error: error),
      )),
      (page) {
        final notifications = page.data;
        final unread = notifications.where((n) => !n.isRead).length;
        if (notifications.isEmpty) {
          emit(state.copyWith(
            listResult: const ResultState.empty(),
            nextCursor: null,
            unreadCount: 0,
          ));
        } else {
          emit(state.copyWith(
            listResult: ResultState.data(data: notifications),
            nextCursor: page.nextCursor,
            unreadCount: unread,
          ));
        }
      },
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.nextCursor == null) return;
    final currentList = state.listResult.maybeWhen(
      data: (data) => data,
      orElse: () => <NotificationModel>[],
    );

    emit(state.copyWith(isLoadingMore: true));
    final result = await _getNotificationsUseCase(cursor: state.nextCursor);
    result.fold(
      (_) => emit(state.copyWith(isLoadingMore: false)),
      (page) {
        final combined = [...currentList, ...page.data];
        final unread = combined.where((n) => !n.isRead).length;
        emit(state.copyWith(
          listResult: ResultState.data(data: combined),
          nextCursor: page.nextCursor,
          unreadCount: unread,
          isLoadingMore: false,
        ));
      },
    );
  }

  Future<void> markRead(String id) async {
    final currentList = state.listResult.maybeWhen(
      data: (data) => data,
      orElse: () => <NotificationModel>[],
    );
    if (currentList.isEmpty) return;

    // Optimistic update
    final updated = currentList
        .map((notification) => notification.id == id
            ? notification.copyWith(isRead: true)
            : notification)
        .toList();
    final unread = updated.where((n) => !n.isRead).length;
    emit(state.copyWith(
      listResult: ResultState.data(data: updated),
      unreadCount: unread,
    ));

    await _markReadUseCase(id);
  }

  Future<void> markAllRead() async {
    final currentList = state.listResult.maybeWhen(
      data: (data) => data,
      orElse: () => <NotificationModel>[],
    );
    if (currentList.isEmpty) return;

    final updated = currentList
        .map((notification) => notification.copyWith(isRead: true))
        .toList();
    emit(state.copyWith(
      listResult: ResultState.data(data: updated),
      unreadCount: 0,
    ));

    await _markAllReadUseCase();
  }
}
