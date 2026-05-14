import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:rideglory/features/notifications/presentation/widgets/notification_item.dart';

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
            builder: (context, state) {
              final hasUnread = state is NotificationsLoaded &&
                  state.notifications.any((n) => !n.isRead);
              if (!hasUnread) return const SizedBox.shrink();
              return TextButton(
                onPressed: () =>
                    context.read<NotificationsCubit>().markAllAsRead(),
                child: Text(
                  context.l10n.notification_markAllRead,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          if (state is NotificationsLoading || state is NotificationsInitial) {
            return const AppLoadingIndicator(
              variant: AppLoadingIndicatorVariant.page,
            );
          }

          if (state is NotificationsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 48,
                    ),
                    AppSpacing.gapLg,
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textOnDarkSecondary,
                        fontSize: 14,
                      ),
                    ),
                    AppSpacing.gapLg,
                    AppButton(
                      label: context.l10n.retry,
                      onPressed: () =>
                          context.read<NotificationsCubit>().loadNotifications(),
                      isFullWidth: false,
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is NotificationsEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.darkBorderPrimary),
                      ),
                      child: const Icon(
                        Icons.notifications_none_outlined,
                        color: AppColors.textOnDarkTertiary,
                        size: 40,
                      ),
                    ),
                    AppSpacing.gapXxl,
                    Text(
                      context.l10n.notification_emptyTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textOnDarkPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AppSpacing.gapSm,
                    Text(
                      context.l10n.notification_emptySubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textOnDarkSecondary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is NotificationsLoaded) {
            final notifications = state.notifications;
            final unreadCount = notifications.where((n) => !n.isRead).length;

            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.darkCard,
              onRefresh: () =>
                  context.read<NotificationsCubit>().loadNotifications(),
              child: CustomScrollView(
                slivers: [
                  if (unreadCount > 0)
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
                                '$unreadCount',
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
                      itemCount: notifications.where((n) => !n.isRead).length,
                      separatorBuilder: (_, _) => AppSpacing.gapSm,
                      itemBuilder: (context, index) {
                        final unread =
                            notifications.where((n) => !n.isRead).toList();
                        final notif = unread[index];
                        return NotificationItem(
                          notification: notif,
                          onTap: () => context
                              .read<NotificationsCubit>()
                              .markAsRead(notif.id),
                        );
                      },
                    ),
                  ),
                  if (notifications.any((n) => n.isRead)) ...[
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
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      sliver: SliverList.separated(
                        itemCount:
                            notifications.where((n) => n.isRead).length,
                        separatorBuilder: (_, _) => AppSpacing.gapSm,
                        itemBuilder: (context, index) {
                          final read =
                              notifications.where((n) => n.isRead).toList();
                          final notif = read[index];
                          return NotificationItem(
                            notification: notif,
                            onTap: () {},
                          );
                        },
                      ),
                    ),
                  ] else
                    const SliverToBoxAdapter(child: AppSpacing.gap100),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
