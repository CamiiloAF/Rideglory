import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/delete/cubit/event_delete_cubit.dart';
import 'package:rideglory/features/events/presentation/detail/cubit/event_detail_cubit.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_header.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_info_section.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_registration_status_card.dart';
import 'package:rideglory/features/events/presentation/shared/dialogs/cancel_registration_dialog.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/app_app_bar.dart';
import 'package:rideglory/shared/widgets/modals/app_dialog.dart';
import 'package:rideglory/shared/widgets/modals/confirmation_dialog.dart';
import 'package:rideglory/shared/widgets/rich_text_viewer.dart';
import 'package:rideglory/shared/widgets/modals/dialog_type.dart';

class EventDetailView extends StatefulWidget {
  final EventModel event;

  const EventDetailView({super.key, required this.event});

  @override
  State<EventDetailView> createState() => _EventDetailViewState();
}

class _EventDetailViewState extends State<EventDetailView> {
  late EventModel _currentEvent;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = getIt<AuthService>().currentUser?.uid;
    final isOwner = _currentEvent.ownerId == currentUserId;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.pop(_currentEvent);
      },
      child: Scaffold(
        appBar: AppAppBar(
          title: EventStrings.eventDetail,
          actions: [
            if (isOwner) ...[
              IconButton(
                icon: const Icon(Icons.people_outline),
                tooltip: EventStrings.viewAttendees,
                onPressed: () => context.pushNamed(
                  AppRoutes.eventAttendees,
                  extra: _currentEvent,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: AppStrings.edit,
                onPressed: () async {
                  final result = await context.pushNamed<EventModel?>(
                    AppRoutes.editEvent,
                    extra: _currentEvent,
                  );
                  if (result != null && mounted) {
                    setState(() => _currentEvent = result);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: AppStrings.delete,
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ],
        ),
        body: MultiBlocListener(
          listeners: [
            BlocListener<EventDeleteCubit, ResultState<String>>(
              listener: (context, state) {
                state.whenOrNull(
                  data: (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(EventStrings.eventDeletedSuccess),
                        backgroundColor: Colors.green,
                      ),
                    );
                    context.pop(true);
                  },
                );
              },
            ),
          ],
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EventDetailHeader(event: _currentEvent),
                const Divider(height: 1),
                EventDetailInfoSection(event: _currentEvent),
                const Divider(height: 1),
                if (!isOwner)
                  BlocBuilder<
                    EventDetailCubit,
                    ResultState<EventRegistrationModel?>
                  >(
                    builder: (context, state) {
                      return state.maybeWhen(
                        data: (registration) => EventRegistrationStatusCard(
                          event: _currentEvent,
                          registration: registration,
                          onRegister: () =>
                              _navigateToRegistration(context, null),
                          onEditRegistration: registration != null
                              ? () => _navigateToRegistration(
                                  context,
                                  registration,
                                )
                              : null,
                          onCancelRegistration: registration != null
                              ? () => _confirmCancelRegistration(
                                  context,
                                  registration,
                                )
                              : null,
                          onViewRecommendations:
                              _currentEvent.recommendations != null
                              ? () => _showRecommendations(context)
                              : null,
                        ),
                        orElse: () => const SizedBox.shrink(),
                      );
                    },
                  ),
                if (_currentEvent.recommendations != null) ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: OutlinedButton.icon(
                      onPressed: () => _showRecommendations(context),
                      icon: const Icon(Icons.tips_and_updates_outlined),
                      label: const Text(EventStrings.viewRecommendations),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToRegistration(
    BuildContext context,
    EventRegistrationModel? existing,
  ) async {
    final result = await context.pushNamed<bool?>(
      AppRoutes.eventRegistration,
      extra: {'event': _currentEvent, 'registration': existing},
    );
    if (result == true && context.mounted) {
      context.read<EventDetailCubit>().loadMyRegistration(_currentEvent.id!);
    }
  }

  Future<void> _confirmCancelRegistration(
    BuildContext context,
    EventRegistrationModel registration,
  ) async {
    await CancelRegistrationDialog.showAndExecute(
      context: context,
      onConfirm: () {
        if (registration.id != null && context.mounted) {
          context.read<EventDetailCubit>().cancelRegistration(registration.id!);
        }
      },
    );
  }

  void _showRecommendations(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                EventStrings.viewRecommendations,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  child: RichTextViewer(
                    content: _currentEvent.recommendations ?? '',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    await ConfirmationDialog.show(
      context: context,
      title: EventStrings.deleteEvent,
      content: EventStrings.deleteEventMessage,
      dialogType: DialogType.warning,
      confirmLabel: AppStrings.delete,
      confirmType: DialogActionType.danger,
      onConfirm: () {
        if (_currentEvent.id != null) {
          context.read<EventDeleteCubit>().deleteEvent(_currentEvent.id!);
        }
      },
    );
  }
}
