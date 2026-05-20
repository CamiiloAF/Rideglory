import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class VehicleFormNavHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const VehicleFormNavHeader({
    super.key,
    required this.isEditing,
    required this.isLoading,
    required this.onCancel,
    required this.onSave,
  });

  final bool isEditing;
  final bool isLoading;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          color: AppColors.darkBgPrimary,
          border: Border(
            bottom: BorderSide(color: AppColors.darkBorderPrimary, width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: onCancel,
                  child: Text(
                    context.l10n.vehicle_form_nav_cancel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: AppColors.textOnDarkSecondary,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  isEditing
                      ? context.l10n.vehicle_editVehicle
                      : context.l10n.vehicle_addVehicle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textOnDarkPrimary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: isLoading ? null : onSave,
                  child: Text(
                    context.l10n.vehicle_form_nav_save,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isLoading
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
