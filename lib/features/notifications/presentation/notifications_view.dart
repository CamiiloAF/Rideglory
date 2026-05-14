import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/notifications/domain/model/notification_model.dart';
import 'package:rideglory/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:rideglory/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:rideglory/features/notifications/presentation/widgets/notifications_data_view.dart';
import 'package:rideglory/features/notifications/presentation/widgets/notifications_empty_state.dart';
import 'package:rideglory/features/notifications/presentation/widgets/notifications_error_state.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      appBar: AppBar(
        title: Text(
          context.l10n.notification_centerTitle,
          style: const TextStyle(
            color: AppColors.textOnDarkPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.darkBgPrimary,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        actions: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, notifState) {
              if (notifState.unreadCount == 0) return const SizedBox.shrink();
              return AppTextButton(
                label: context.l10n.notification_markAllRead,
                onPressed: () =>
                    context.read<NotificationsCubit>().markAllRead(),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, notifState) {
          final result = notifState.listResult;
          if (result is Initial || result is Loading) {
            return const AppLoadingIndicator(
              variant: AppLoadingIndicatorVariant.page,
            );
          } else if (result is Error) {
            return NotificationsErrorState(
              message: (result as Error).error.message,
              onRetry: () => context.read<NotificationsCubit>().load(),
            );
          } else if (result is Empty) {
            return const NotificationsEmptyState();
          } else if (result is Data) {
            final notifications =
                (result as Data<List<NotificationModel>>).data;
            return NotificationsDataView(
              notifications: notifications,
              nextCursor: notifState.nextCursor,
              isLoadingMore: notifState.isLoadingMore,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
