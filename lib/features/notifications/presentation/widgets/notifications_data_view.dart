import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/notifications/domain/model/notification_model.dart';
import 'package:rideglory/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:rideglory/features/notifications/presentation/widgets/notification_item.dart';
import 'package:rideglory/shared/router/app_router.dart';

class NotificationsDataView extends StatelessWidget {
  const NotificationsDataView({
    super.key,
    required this.notifications,
    required this.nextCursor,
    required this.isLoadingMore,
  });

  final List<NotificationModel> notifications;
  final String? nextCursor;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    final unread = notifications.where((n) => !n.isRead).toList();
    final read = notifications.where((n) => n.isRead).toList();

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.darkCard,
      onRefresh: () => context.read<NotificationsCubit>().load(),
      child: CustomScrollView(
        slivers: [
          if (unread.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Row(
                  children: [
                    Text(
                      context.l10n.notification_sectionUnread,
                      style: const TextStyle(
                        color: AppColors.textOnDarkSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                    AppSpacing.hGapSm,
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${unread.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              sliver: SliverList.separated(
                itemCount: unread.length,
                separatorBuilder: (_, _) => AppSpacing.gapSm,
                itemBuilder: (context, index) {
                  final notification = unread[index];
                  return NotificationItem(
                    notification: notification,
                    onTap: () {
                      context
                          .read<NotificationsCubit>()
                          .markRead(notification.id);
                      if (notification.route != null) {
                        AppRouter.pushDeepLink(notification.route!);
                      }
                    },
                  );
                },
              ),
            ),
          ],
          if (read.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  context.l10n.notification_sectionRead,
                  style: const TextStyle(
                    color: AppColors.textOnDarkSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              sliver: SliverList.separated(
                itemCount: read.length,
                separatorBuilder: (_, _) => AppSpacing.gapSm,
                itemBuilder: (context, index) {
                  final notification = read[index];
                  return NotificationItem(
                    notification: notification,
                    onTap: () {
                      if (notification.route != null) {
                        AppRouter.pushDeepLink(notification.route!);
                      }
                    },
                  );
                },
              ),
            ),
          ],
          if (nextCursor != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: isLoadingMore
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : Center(
                        child: AppTextButton(
                          label: context.l10n.notification_loadMore,
                          onPressed: () =>
                              context.read<NotificationsCubit>().loadMore(),
                        ),
                      ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
