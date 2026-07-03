import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/rider_telemetry_card.dart';
import 'package:rideglory/design_system/design_system.dart';

class RiderTelemetryRidersContent extends StatefulWidget {
  const RiderTelemetryRidersContent({
    super.key,
    required this.ridersResult,
    required this.selectedRiderId,
    required this.onRiderTap,
    this.sosUserId,
    this.currentUserLatitude,
    this.currentUserLongitude,
  });

  final ResultState<List<RiderTrackingModel>> ridersResult;
  final ValueListenable<String?> selectedRiderId;
  final ValueChanged<RiderTrackingModel> onRiderTap;

  /// User id of the rider broadcasting an SOS, if any (rendered in red).
  final String? sosUserId;
  final double? currentUserLatitude;
  final double? currentUserLongitude;

  @override
  State<RiderTelemetryRidersContent> createState() =>
      _RiderTelemetryRidersContentState();
}

class _RiderTelemetryRidersContentState
    extends State<RiderTelemetryRidersContent> {
  final ScrollController _scrollController = ScrollController();
  List<RiderTrackingModel> _riders = const [];

  static const double _cardWidthFactor = 0.82;
  static const double _gap = 16;

  @override
  void initState() {
    super.initState();
    widget.selectedRiderId.addListener(_onSelectionChanged);
  }

  @override
  void didUpdateWidget(RiderTelemetryRidersContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRiderId != widget.selectedRiderId) {
      oldWidget.selectedRiderId.removeListener(_onSelectionChanged);
      widget.selectedRiderId.addListener(_onSelectionChanged);
    }
  }

  @override
  void dispose() {
    widget.selectedRiderId.removeListener(_onSelectionChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSelectionChanged() {
    if (!mounted) return;
    setState(() {});
    _scrollToSelected();
  }

  void _scrollToSelected() {
    final selectedId = widget.selectedRiderId.value;
    if (selectedId == null) return;
    final index = _riders.indexWhere((r) => r.userId == selectedId);
    if (index < 0) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final viewportWidth = _scrollController.position.viewportDimension;
      final cardWidth = MediaQuery.of(context).size.width * _cardWidthFactor;
      final target =
          index * (cardWidth + _gap) - (viewportWidth - cardWidth) / 2;
      final clamped = target.clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.ridersResult.when(
      initial: () => const Center(
        child: AppLoadingIndicator(variant: AppLoadingIndicatorVariant.inline),
      ),
      loading: () => const Center(
        child: AppLoadingIndicator(variant: AppLoadingIndicatorVariant.inline),
      ),
      data: (riders) {
        _riders = riders;
        if (riders.isEmpty) {
          return _emptyState(context);
        }
        final selectedId = widget.selectedRiderId.value;
        return ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          itemCount: riders.length,
          separatorBuilder: (_, _) => AppSpacing.hGapMd,
          itemBuilder: (context, index) {
            final rider = riders[index];
            return RiderTelemetryCard(
              rider: rider,
              isSelected: rider.userId == selectedId,
              isSos:
                  widget.sosUserId != null && rider.userId == widget.sosUserId,
              onTap: () => widget.onRiderTap(rider),
              distanceFromCurrentUserMeters: _distanceFromCurrentUserMeters(
                rider: rider,
                currentUserLatitude: widget.currentUserLatitude,
                currentUserLongitude: widget.currentUserLongitude,
              ),
            );
          },
        );
      },
      empty: () => _emptyState(context),
      error: (e) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            e.message,
            textAlign: TextAlign.center,
            style: context.bodyMedium?.copyWith(
              color: context.colorScheme.error,
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Text(
        EventStrings.trackingNoActiveRiders,
        textAlign: TextAlign.center,
        style: context.bodyMedium?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

double? _distanceFromCurrentUserMeters({
  required RiderTrackingModel rider,
  required double? currentUserLatitude,
  required double? currentUserLongitude,
}) {
  final myLat = currentUserLatitude;
  final myLon = currentUserLongitude;
  if (myLat == null || myLon == null) {
    return null;
  }
  return Geolocator.distanceBetween(
    myLat,
    myLon,
    rider.latitude,
    rider.longitude,
  );
}
