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
import 'package:rideglory/features/events/presentation/detail/params.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class MyRegistrationsDataView extends StatelessWidget {
  const MyRegistrationsDataView({super.key, required this.items});

  final List<RegistrationWithEvent> items;

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
                child: AppTextField(
                  name: 'search',
                  hintText: context.l10n.event_searchRegistrations,
                  prefixIcon: Icons.search_rounded,
                  textCapitalization: TextCapitalization.none,
                  onChanged: (value) => cubit.updateSearchQuery(value ?? ''),
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
        SizedBox(height: 8),
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
                        onTap: () => context.pushNamed(
                          AppRoutes.eventDetailById,
                          extra: item.registration.eventId,
                        ),
                        onDetails: () {
                          final ev = item.event;
                          if (ev != null) {
                            context.pushNamed(
                              AppRoutes.registrationDetail,
                              extra: RegistrationDetailExtra(
                                registration: item.registration,
                              ),
                            );
                          } else {
                            context.pushNamed(
                              AppRoutes.eventDetailById,
                              extra: item.registration.eventId,
                            );
                          }
                        },
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

  Future<void> _showFilters(BuildContext context) async {
    await MyRegistrationsFilterBottomSheet.show(context: context);
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
            extra: EventRegistrationParams(
              event: event,
              registration: registration,
            ),
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
            extra: EventRegistrationParams(event: event, registration: null),
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
