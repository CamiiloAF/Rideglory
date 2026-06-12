import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Bottom CTA bar for the custom route builder.
///
/// Design spec (Pencil veaGt / IMyvf):
/// - With waypoints: orange button with arrow-right icon + "Continuar", with
///   orange glow shadow. Fill #0D0D0F on text.
/// - Without waypoints: dark button (#242429) at 40% opacity, no icon.
/// - Container: fill #0D0D0F, top border #2A2A32 1px, padding [16,20,32,20].
class RouteCtaBar extends StatelessWidget {
  const RouteCtaBar({super.key, required this.hasWaypoints});

  final bool hasWaypoints;

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.route_builder_continue;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkBgPrimary,
        border: Border(top: BorderSide(color: AppColors.darkBorderPrimary)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
      child: hasWaypoints
          // Custom: AppButton no soporta boxShadow glow requerido por Pencil spec veaGt
          // (orange glow shadow blurRadius 20 sobre el botón CTA activo).
          ? GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x55F98C1F),
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.arrow_forward,
                      size: 18,
                      color: AppColors.darkBgPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Space Grotesk',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkBgPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          // Custom: AppButton no soporta Opacity wrapping + estado deshabilitado visual
          // con opacidad 40% al 0 waypoints (Pencil spec veaGt disabled state).
          : Opacity(
              opacity: 0.4,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.darkTertiary,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textOnDarkSecondary,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
