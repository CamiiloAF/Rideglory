import 'package:flutter/material.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/attendees/widgets/attendees_filter_chips.dart';
import 'package:rideglory/features/events/presentation/attendees/widgets/attendees_list.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class AttendeesDataView extends StatefulWidget {
  final List<EventRegistrationModel> registrations;
  final EventModel event;

  const AttendeesDataView({
    super.key,
    required this.registrations,
    required this.event,
  });

  @override
  State<AttendeesDataView> createState() => _AttendeesDataViewState();
}

class _AttendeesDataViewState extends State<AttendeesDataView> {
  String _searchQuery = '';
  Set<RegistrationStatus> _statusFilters = {};

  List<EventRegistrationModel> get _filteredRegistrations {
    var list = widget.registrations;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((registration) {
        final name = registration.fullName.toLowerCase();
        final vehicle = (registration.vehicleSummary?.displayName ?? '')
            .toLowerCase();
        return name.contains(query) || vehicle.contains(query);
      }).toList();
    }
    if (_statusFilters.isNotEmpty) {
      list = list
          .where((registration) => _statusFilters.contains(registration.status))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: AppSearchBar(
            hintText: context.l10n.event_searchAttendees,
            onSearchChanged: (query) => setState(() => _searchQuery = query),
            padding: EdgeInsets.zero,
            darkMode: true,
          ),
        ),
        AppSpacing.gapSm,
        AttendeesFilterChips(
          selected: _statusFilters,
          onSelected: (statuses) => setState(() => _statusFilters = statuses),
        ),
        AppSpacing.gapMd,
        Expanded(
          child: AttendeesList(
            registrations: _filteredRegistrations,
            event: widget.event,
          ),
        ),
      ],
    );
  }
}
