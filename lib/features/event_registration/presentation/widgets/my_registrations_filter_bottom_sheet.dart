import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/presentation/my_registrations_cubit.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/design_system/design_system.dart';

class MyRegistrationsFilterBottomSheet extends StatefulWidget {
  const MyRegistrationsFilterBottomSheet({
    super.key,
    required this.cubitContext,
  });

  final BuildContext cubitContext;

  static Future<void> show({required BuildContext context}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MyRegistrationsFilterBottomSheet(cubitContext: context),
    );
  }

  @override
  State<MyRegistrationsFilterBottomSheet> createState() =>
      _MyRegistrationsFilterBottomSheetState();
}

class _MyRegistrationsFilterBottomSheetState
    extends State<MyRegistrationsFilterBottomSheet> {
  late Set<RegistrationStatus> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(
      widget.cubitContext.read<MyRegistrationsCubit>().statusFilter,
    );
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
                      widget.cubitContext
                          .read<MyRegistrationsCubit>()
                          .clearFilters();
                      Navigator.of(context).pop();
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
                      children: RegistrationStatus.values.map((status) {
                        final selected = _selected.contains(status);
                        return FilterChip(
                          label: Text(status.label),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              if (selected) {
                                _selected.remove(status);
                              } else {
                                _selected.add(status);
                              }
                            });
                          },
                        );
                      }).toList(),
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
                onPressed: () {
                  widget.cubitContext
                      .read<MyRegistrationsCubit>()
                      .updateStatusFilter(_selected);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
