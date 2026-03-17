import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/domain/model/registration_with_event.dart';
import 'package:rideglory/features/event_registration/presentation/my_registrations_cubit.dart';
import 'package:rideglory/features/event_registration/presentation/registration_detail_extra.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/inscription_card.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/my_registrations_filter_bottom_sheet.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/no_search_results_empty_widget.dart';

class MyRegistrationsDataView extends StatelessWidget {
  const MyRegistrationsDataView({super.key, required this.items});

  final List<RegistrationWithEvent> items;

  Future<void> _showFilters(BuildContext context) async {
    await MyRegistrationsFilterBottomSheet.show(context: context);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MyRegistrationsCubit>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showFilters(context),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: context.colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: context.colorScheme.outline.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          color: context.colorScheme.onSurface,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          cubit.hasFilters
                              ? _filterSummary(cubit.statusFilter)
                              : EventStrings.filterAll,
                          style: context.bodyMedium?.copyWith(
                            color: context.colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: context.colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 48,
                height: 48,
                child: Material(
                  color: context.colorScheme.primary,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _showFilters(context),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          color: context.colorScheme.onPrimary,
                          size: 24,
                        ),
                        if (cubit.hasFilters)
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
        const SizedBox(height: 8),
        items.isEmpty
            ? const Expanded(child: NoSearchResultsEmptyWidget())
            : Expanded(
                child: RefreshIndicator(
                  onRefresh: () => cubit.fetchMyRegistrations(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return InscriptionCard(
                        item: item,
                        onDetails: () => context.pushNamed(
                          AppRoutes.eventDetailById,
                          extra: item.registration.eventId,
                        ),
                        onSecondaryAction:
                            item.registration.status ==
                                RegistrationStatus.readyForEdit
                            ? () => _onSecondaryAction(context, item)
                            : null,
                      );
                    },
                  ),
                ),
              ),
      ],
    );
  }

  String _filterSummary(Set<RegistrationStatus> statuses) {
    if (statuses.isEmpty) return EventStrings.filterAll;
    if (statuses.length == 1) return statuses.first.label;
    return '${statuses.length} estados';
  }

  Future<void> _onSecondaryAction(
    BuildContext context,
    RegistrationWithEvent item,
  ) async {
    final registration = item.registration;
    final event = item.event;
    final cubit = context.read<MyRegistrationsCubit>();

    switch (registration.status) {
      case RegistrationStatus.approved:
        context.pushNamed(
          AppRoutes.registrationDetail,
          extra: RegistrationDetailExtra(
            registration: registration,
            onCancelRegistration: registration.id != null
                ? () async => cubit.cancelRegistration(registration.id!)
                : null,
          ),
        );
        break;
      case RegistrationStatus.pending:
        context.pushNamed(
          AppRoutes.registrationDetail,
          extra: RegistrationDetailExtra(registration: registration),
        );
        break;
      case RegistrationStatus.readyForEdit:
        if (event != null) {
          final result = await context.pushNamed<EventRegistrationModel?>(
            AppRoutes.eventRegistration,
            extra: {'event': event, 'registration': registration},
          );
          if (result != null && context.mounted) {
            cubit.onChangeRegistration(result);
          }
        } else {
          context.pushNamed(
            AppRoutes.eventDetailById,
            extra: registration.eventId,
          );
        }
        break;
      case RegistrationStatus.rejected:
        context.pushNamed(
          AppRoutes.registrationDetail,
          extra: RegistrationDetailExtra(registration: registration),
        );
        break;
      case RegistrationStatus.cancelled:
        if (event != null) {
          final result = await context.pushNamed<EventRegistrationModel?>(
            AppRoutes.eventRegistration,
            extra: {'event': event, 'registration': null},
          );
          if (result != null && context.mounted) {
            cubit.onChangeRegistration(result);
          }
        } else {
          context.pushNamed(
            AppRoutes.eventDetailById,
            extra: registration.eventId,
          );
        }
        break;
    }
  }
}
