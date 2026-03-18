import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/design_system/design_system.dart';

class AttendeesFilterBottomSheet extends StatefulWidget {
  final Set<RegistrationStatus> initialStatuses;

  const AttendeesFilterBottomSheet({super.key, required this.initialStatuses});

  static Future<Set<RegistrationStatus>?> show({
    required BuildContext context,
    required Set<RegistrationStatus> initialStatuses,
  }) {
    return showModalBottomSheet<Set<RegistrationStatus>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          AttendeesFilterBottomSheet(initialStatuses: initialStatuses),
    );
  }

  @override
  State<AttendeesFilterBottomSheet> createState() =>
      _AttendeesFilterBottomSheetState();
}

class _AttendeesFilterBottomSheetState
    extends State<AttendeesFilterBottomSheet> {
  late Set<RegistrationStatus> _selected;

  static const _pendingGroup = {
    RegistrationStatus.pending,
    RegistrationStatus.readyForEdit,
  };

  bool get _pendingSelected =>
      _pendingGroup.every((s) => _selected.contains(s));

  bool get _approvedSelected => _selected.contains(RegistrationStatus.approved);
  bool get _rejectedSelected => _selected.contains(RegistrationStatus.rejected);

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initialStatuses);
  }

  void _togglePending(bool selected) {
    setState(() {
      if (selected) {
        _selected.addAll(_pendingGroup);
      } else {
        _selected.removeAll(_pendingGroup);
      }
    });
  }

  void _toggleApproved(bool selected) {
    setState(() {
      if (selected) {
        _selected.add(RegistrationStatus.approved);
      } else {
        _selected.remove(RegistrationStatus.approved);
      }
    });
  }

  void _toggleRejected(bool selected) {
    setState(() {
      if (selected) {
        _selected.add(RegistrationStatus.rejected);
      } else {
        _selected.remove(RegistrationStatus.rejected);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = context.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      maxChildSize: 0.6,
      minChildSize: 0.3,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    EventStrings.filters,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppTextButton(
                    label: EventStrings.clearFilters,
                    onPressed: () {
                      setState(() => _selected.clear());
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      EventStrings.filterByStatus,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text(EventStrings.pending),
                          selected: _pendingSelected,
                          onSelected: (_) => _togglePending(!_pendingSelected),
                        ),
                        FilterChip(
                          label: const Text(EventStrings.approved),
                          selected: _approvedSelected,
                          onSelected: (_) =>
                              _toggleApproved(!_approvedSelected),
                        ),
                        FilterChip(
                          label: const Text(EventStrings.rejected),
                          selected: _rejectedSelected,
                          onSelected: (_) =>
                              _toggleRejected(!_rejectedSelected),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 8,
              ),
              child: AppButton(
                label: EventStrings.applyFilters,
                onPressed: () => Navigator.of(context).pop(_selected),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
