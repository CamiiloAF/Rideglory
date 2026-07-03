import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class RegistrationApproveButton extends StatelessWidget {
  const RegistrationApproveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.height = 48,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;
  final double height;

  @override
  Widget build(BuildContext context) {
    final contentColor = enabled
        ? AppColors.statusGreen
        : AppColors.textOnDarkTertiary;
    return SizedBox(
      height: height,
      child: Material(
        color: AppColors.darkTertiary,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: contentColor),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, size: 20, color: contentColor),
                  AppSpacing.hGapSm,
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: contentColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
