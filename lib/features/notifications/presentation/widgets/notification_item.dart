import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/notifications/domain/model/notification_model.dart';

class NotificationItem extends StatelessWidget {
  const NotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback onTap;

  Color _iconBgColor(NotificationType type) {
    return switch (type) {
      NotificationType.registrationApproved => AppColors.successSubtle,
      NotificationType.registrationRejected => AppColors.errorSubtle,
      NotificationType.newRegistration => AppColors.primarySubtle,
      NotificationType.soat30d ||
      NotificationType.soat7d ||
      NotificationType.soatDayOf =>
        AppColors.warningSubtle,
      NotificationType.general => AppColors.darkTertiary,
    };
  }

  Color _iconColor(NotificationType type) {
    return switch (type) {
      NotificationType.registrationApproved => AppColors.success,
      NotificationType.registrationRejected => AppColors.error,
      NotificationType.newRegistration => AppColors.primary,
      NotificationType.soat30d ||
      NotificationType.soat7d ||
      NotificationType.soatDayOf =>
        AppColors.warning,
      NotificationType.general => AppColors.textOnDarkSecondary,
    };
  }

  IconData _icon(NotificationType type) {
    return switch (type) {
      NotificationType.registrationApproved =>
        Icons.check_circle_outline_rounded,
      NotificationType.registrationRejected => Icons.cancel_outlined,
      NotificationType.newRegistration => Icons.person_add_alt_1_outlined,
      NotificationType.soat30d ||
      NotificationType.soat7d ||
      NotificationType.soatDayOf =>
        Icons.description_outlined,
      NotificationType.general => Icons.notifications_outlined,
    };
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 1) return 'Hace ${diff.inDays}d';
    if (diff.inHours >= 1) return 'Hace ${diff.inHours}h';
    if (diff.inMinutes >= 1) return 'Hace ${diff.inMinutes}m';
    return 'Ahora';
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return Semantics(
      button: true,
      label: context.l10n.notification_item_accessibility_label(
        notification.title,
        _timeAgo(notification.createdAt),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: isUnread ? 1.0 : 0.7,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUnread ? AppColors.darkCard : AppColors.darkBgSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isUnread
                    ? AppColors.primary.withValues(alpha: 0.25)
                    : AppColors.darkBorderPrimary,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _iconBgColor(notification.type),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _icon(notification.type),
                    color: _iconColor(notification.type),
                    size: 22,
                  ),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                color: AppColors.textOnDarkPrimary,
                                fontSize: 14,
                                fontWeight: isUnread
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AppSpacing.hGapSm,
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      AppSpacing.gapXxs,
                      Text(
                        notification.body,
                        style: const TextStyle(
                          color: AppColors.textOnDarkSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      AppSpacing.gapXxs,
                      Text(
                        _timeAgo(notification.createdAt),
                        style: const TextStyle(
                          color: AppColors.textOnDarkTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
