import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/delete/cubit/event_delete_cubit.dart';
import 'package:rideglory/features/events/presentation/list/events_cubit.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_card.dart';
import 'package:rideglory/shared/widgets/no_search_results_empty_widget.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/form/app_search_bar.dart';
import 'package:rideglory/shared/widgets/modals/app_dialog.dart';
import 'package:rideglory/shared/widgets/modals/confirmation_dialog.dart';
import 'package:rideglory/shared/widgets/modals/dialog_type.dart';

class EventsDataView extends StatelessWidget {
  final List<EventModel> events;

  const EventsDataView({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final currentUserId = getIt<AuthService>().currentUser?.uid;

    return Column(
      children: [
        AppSearchBar(
          hintText: EventStrings.searchEvents,
          onSearchChanged: (query) =>
              context.read<EventsCubit>().updateSearchQuery(query),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        ),
        events.isEmpty
            ? NoSearchResultsEmptyWidget()
            : Expanded(
                child: RefreshIndicator(
                  onRefresh: () => context.read<EventsCubit>().fetchEvents(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: events.length,
                    itemBuilder: (_, i) {
                      final event = events[i];
                      final isOwner = event.ownerId == currentUserId;
                      return EventCard(
                        event: event,
                        isOwner: isOwner,
                        onTap: () async {
                          final result = await context.pushNamed<bool?>(
                            AppRoutes.eventDetail,
                            extra: event,
                          );
                          if (result == true && context.mounted) {
                            context.read<EventsCubit>().fetchEvents();
                          }
                        },
                        onEdit: isOwner
                            ? () async {
                                final result = await context.pushNamed<bool?>(
                                  AppRoutes.editEvent,
                                  extra: event,
                                );
                                if (result == true && context.mounted) {
                                  context.read<EventsCubit>().fetchEvents();
                                }
                              }
                            : null,
                        onDelete: isOwner
                            ? () => _confirmDelete(context, event)
                            : null,
                      );
                    },
                  ),
                ),
              ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, EventModel event) =>
      ConfirmationDialog.show(
        context: context,
        title: EventStrings.deleteEvent,
        content: EventStrings.deleteEventMessage,
        confirmLabel: AppStrings.delete,
        confirmType: DialogActionType.danger,
        dialogType: DialogType.warning,
        onConfirm: () {
          if (event.id != null) {
            context.read<EventDeleteCubit>().deleteEvent(event.id!);
          }
        },
      );
}
