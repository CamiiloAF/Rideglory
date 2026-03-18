import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/attendees/widgets/attendees_filter_bottom_sheet.dart';
import 'package:rideglory/features/events/presentation/attendees/widgets/attendees_list.dart';
import 'package:rideglory/design_system/design_system.dart';

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

  bool get _hasFilters => _statusFilters.isNotEmpty;

  List<EventRegistrationModel> get _filteredRegistrations {
    var list = widget.registrations;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((r) {
        final name = r.fullName.toLowerCase();
        final vehicle =
            '${r.vehicleBrand} ${r.vehicleReference}'.toLowerCase();
        return name.contains(q) || vehicle.contains(q);
      }).toList();
    }
    if (_statusFilters.isNotEmpty) {
      list = list.where((r) => _statusFilters.contains(r.status)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: AppSearchBar(
                  hintText: EventStrings.searchAttendees,
                  onSearchChanged: (query) =>
                      setState(() => _searchQuery = query),
                  padding: EdgeInsets.zero,
                  darkMode: true,
                ),
              ),
              SizedBox(width: 12),
              SizedBox(
                width: 48,
                height: 48,
                child: Material(
                  color: context.colorScheme.primary,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _showFilters,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          color: context.colorScheme.onPrimary,
                          size: 24,
                        ),
                        if (_hasFilters)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: context.colorScheme.onPrimary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Expanded(
          child: AttendeesList(
            registrations: _filteredRegistrations,
            event: widget.event,
          ),
        ),
      ],
    );
  }

  Future<void> _showFilters() async {
    final selected = await AttendeesFilterBottomSheet.show(
      context: context,
      initialStatuses: Set.from(_statusFilters),
    );
    if (selected != null && mounted) {
      setState(() => _statusFilters = selected);
    }
  }
}
