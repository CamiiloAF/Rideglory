import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/design_system/atoms/buttons/app_circle_icon_button.dart';

/// Variants of left/right actions in [AppFormNavHeader].
sealed class AppFormNavAction {
  const AppFormNavAction();

  const factory AppFormNavAction.text({
    required String label,
    required VoidCallback onTap,
    bool emphasized,
    bool isLoading,
  }) = _TextAction;

  const factory AppFormNavAction.icon({
    required IconData icon,
    required VoidCallback onTap,
    bool pill,
  }) = _IconAction;

  const factory AppFormNavAction.pillText({
    required String label,
    required VoidCallback onTap,
    bool isLoading,
  }) = _PillTextAction;
}

class _TextAction extends AppFormNavAction {
  const _TextAction({
    required this.label,
    required this.onTap,
    this.emphasized = false,
    this.isLoading = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool emphasized;
  final bool isLoading;
}

class _IconAction extends AppFormNavAction {
  const _IconAction({
    required this.icon,
    required this.onTap,
    this.pill = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool pill;
}

class _PillTextAction extends AppFormNavAction {
  const _PillTextAction({
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool isLoading;
}

/// Centralized form-screen header (left action / center title / right action).
/// Replaces VehicleFormNavHeader, MaintenanceFormNavHeader, and the inline AppBar
/// in event_form_view.dart.
class AppFormNavHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppFormNavHeader({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.bottom,
    this.height = 56.0,
    this.showBottomBorder = true,
    this.centerTitle = true,
  });

  final String title;
  final AppFormNavAction? leading;
  final AppFormNavAction? trailing;
  final Widget? bottom;
  final double height;
  final bool showBottomBorder;
  final bool centerTitle;

  // preferredSize accounts for: status bar (up to 48px), the action row height,
  // the optional bottom slot height, and the 1px bottom border. The Scaffold
  // gives the AppBar exactly `preferredSize.height` and SafeArea consumes the
  // status bar inset internally, so the AppBar content fits without overflow.
  @override
  Size get preferredSize => Size.fromHeight(
    height +
        (bottom != null ? _bottomSlotHeight : 0) +
        (showBottomBorder ? 1 : 0) +
        _maxStatusBarHeight,
  );

  static const double _bottomSlotHeight = 24;
  static const double _maxStatusBarHeight = 48;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: showBottomBorder
          ? const BoxDecoration(
              color: AppColors.darkBgPrimary,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.darkBorderPrimary,
                  width: 1,
                ),
              ),
            )
          : const BoxDecoration(color: AppColors.darkBgPrimary),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _renderAction(context, leading),
                      ),
                    ),
                    if (centerTitle)
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textOnDarkPrimary,
                        ),
                      ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _renderAction(context, trailing),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (bottom != null) bottom!,
          ],
        ),
      ),
    );
  }

  Widget _renderAction(BuildContext context, AppFormNavAction? action) {
    if (action == null) return const SizedBox.shrink();
    if (action is _TextAction) {
      final color = action.isLoading
          ? AppColors.primary.withValues(alpha: 0.5)
          : (action.emphasized
                ? AppColors.primary
                : AppColors.textOnDarkSecondary);
      return GestureDetector(
        onTap: action.isLoading ? null : action.onTap,
        child: Text(
          action.label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: action.emphasized ? FontWeight.w700 : FontWeight.normal,
            color: color,
          ),
        ),
      );
    }
    if (action is _IconAction) {
      if (action.pill) {
        return AppCircleIconButton(
          icon: action.icon,
          onTap: action.onTap,
          hasBorder: true,
        );
      }
      return IconButton(
        icon: Icon(action.icon, color: AppColors.textOnDarkPrimary),
        onPressed: action.onTap,
      );
    }
    if (action is _PillTextAction) {
      final onPrimary = Theme.of(context).colorScheme.onPrimary;
      return GestureDetector(
        onTap: action.isLoading ? null : action.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: action.isLoading
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            action.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: onPrimary,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
