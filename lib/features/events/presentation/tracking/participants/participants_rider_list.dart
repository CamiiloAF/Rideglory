import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';
import 'package:rideglory/features/events/presentation/tracking/participants/participants_filter.dart';
import 'package:rideglory/features/events/presentation/tracking/participants/rider_list_item.dart';

class ParticipantsRiderList extends StatelessWidget {
  const ParticipantsRiderList({
    super.key,
    required this.riders,
    required this.filter,
    required this.searchQuery,
    required this.event,
    required this.registrations,
    this.sosUserId,
    this.currentUserLat,
    this.currentUserLon,
  });

  final List<RiderTrackingModel> riders;
  final ParticipantsFilter filter;
  final String searchQuery;
  final EventModel event;

  /// Registrations loaded from [AttendeesCache]. May be empty.
  final List<EventRegistrationModel> registrations;

  /// userId of the rider currently in SOS, if any.
  final String? sosUserId;

  /// Current viewer's GPS coordinates for computing distance to each rider.
  final double? currentUserLat;
  final double? currentUserLon;

  /// A rider is "effectively active" only if [RiderTrackingModel.isActive] is
  /// true AND their last update is within the past minute.
  bool _isEffectivelyActive(RiderTrackingModel rider) {
    if (!rider.isActive) return false;
    return DateTime.now().difference(rider.lastUpdated) <=
        const Duration(minutes: 1);
  }

  List<RiderTrackingModel> _filtered() {
    return riders.where((rider) {
      final query = searchQuery.toLowerCase().trim();
      if (query.isNotEmpty && !rider.fullName.toLowerCase().contains(query)) {
        return false;
      }
      final effectivelyActive = _isEffectivelyActive(rider);
      switch (filter) {
        case ParticipantsFilter.all:
          return true;
        case ParticipantsFilter.sos:
          return rider.userId == sosUserId;
        case ParticipantsFilter.active:
          return effectivelyActive && rider.userId != sosUserId;
        case ParticipantsFilter.stopped:
          return !effectivelyActive && rider.userId != sosUserId;
      }
    }).toList();
  }

  EventRegistrationModel? _registrationFor(String userId) {
    try {
      return registrations.firstWhere((r) => r.userId == userId);
    } catch (_) {
      return null;
    }
  }

  double? _distanceToRider(RiderTrackingModel rider) {
    if (currentUserLat == null || currentUserLon == null) return null;
    return Geolocator.distanceBetween(
      currentUserLat!,
      currentUserLon!,
      rider.latitude,
      rider.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleRiders = _filtered();

    if (visibleRiders.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: visibleRiders.length,
      itemBuilder: (context, index) {
        final rider = visibleRiders[index];
        final registration = _registrationFor(rider.userId);
        final isSos = rider.userId == sosUserId;

        return RiderListItem(
          rider: rider,
          isSos: isSos,
          isActive: _isEffectivelyActive(rider),
          phone: registration?.phone,
          vehicleDisplayName: registration?.vehicleSummary?.displayName,
          distanceFromUserMeters: _distanceToRider(rider),
          onLocate: () => context.pop(),
        );
      },
    );
  }
}
