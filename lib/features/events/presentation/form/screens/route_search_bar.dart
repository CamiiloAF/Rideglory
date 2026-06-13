import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/waypoint_search_field.dart';
import 'package:rideglory/shared/models/address_location.dart';

/// Search bar for the custom route builder.
///
/// Design spec (Pencil IMyvf / z58GM):
/// - Normal: fill #1A1A1F, border #2A2A32 1px, search icon gray
/// - Active (focused): border #F98C1F 1.5px, search icon orange
/// - Disabled (atLimit): fill #242429, opacity 0.6, border #2A2A32
/// - Height: 48px, cornerRadius 12 (bottom radius removed when focused for dropdown)
class RouteSearchBar extends StatefulWidget {
  const RouteSearchBar({
    super.key,
    required this.atLimit,
    required this.onPlaceSelected,
  });

  final bool atLimit;
  final void Function(String name, AddressLocation? location) onPlaceSelected;

  @override
  State<RouteSearchBar> createState() => _RouteSearchBarState();
}

class _RouteSearchBarState extends State<RouteSearchBar> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()
      ..addListener(() {
        if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
      });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.atLimit) {
      return Opacity(
        opacity: 0.6,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.darkTertiary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.darkBorderPrimary),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Icon(
                Icons.search,
                size: 16,
                color: AppColors.textOnDarkTertiary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.route_builder_search_placeholder_disabled,
                  style: const TextStyle(
                    fontFamily: 'Space Grotesk',
                    color: AppColors.textOnDarkTertiary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.darkBgSecondary,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft:
              _isFocused ? Radius.zero : const Radius.circular(12),
          bottomRight:
              _isFocused ? Radius.zero : const Radius.circular(12),
        ),
        border: Border.all(
          color: _isFocused ? AppColors.primary : AppColors.darkBorderPrimary,
          width: _isFocused ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 16,
            color: _isFocused
                ? AppColors.primary
                : AppColors.textOnDarkTertiary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: WaypointSearchField(
              onPlaceSelected: widget.onPlaceSelected,
              focusNode: _focusNode,
            ),
          ),
        ],
      ),
    );
  }
}
