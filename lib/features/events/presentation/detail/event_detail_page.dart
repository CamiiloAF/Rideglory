import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/domain/use_cases/cancel_event_registration_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/get_my_registration_for_event_use_case.dart';
import 'package:rideglory/features/events/presentation/delete/cubit/event_delete_cubit.dart';
import 'package:rideglory/features/events/presentation/detail/cubit/event_detail_cubit.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_info_section.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_registration_status_card.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/app_app_bar.dart';
import 'package:rideglory/shared/widgets/modals/app_dialog.dart';
import 'package:rideglory/shared/widgets/modals/confirmation_dialog.dart';
import 'package:rideglory/shared/widgets/modals/dialog_type.dart';

// TODO STRINGS and widgets
class EventDetailPage extends StatelessWidget {
  final EventModel event;

  const EventDetailPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => EventDetailCubit(
            getIt<GetMyRegistrationForEventUseCase>(),
            getIt<CancelEventRegistrationUseCase>(),
          )..loadMyRegistration(event.id!),
        ),
        BlocProvider(create: (_) => getIt<EventDeleteCubit>()),
      ],
      child: _EventDetailView(event: event),
    );
  }
}

class _EventDetailView extends StatelessWidget {
  final EventModel event;
  const _EventDetailView({required this.event});

  @override
  Widget build(BuildContext context) {
    final currentUserId = getIt<AuthService>().currentUser?.uid;
    final isOwner = event.ownerId == currentUserId;

    return Scaffold(
      appBar: AppAppBar(
        title: EventStrings.eventDetail,
        actions: [
          if (isOwner) ...[
            IconButton(
              icon: const Icon(Icons.people_outline),
              tooltip: EventStrings.viewAttendees,
              onPressed: () =>
                  context.pushNamed(AppRoutes.eventAttendees, extra: event),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: () async {
                final result = await context.pushNamed<bool?>(
                  AppRoutes.editEvent,
                  extra: event,
                );
                if (result == true && context.mounted) {
                  context.pop(true);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar',
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<EventDeleteCubit, ResultState<Nothing>>(
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
              // Header
              _EventDetailHeader(event: event),
              const Divider(height: 1),
              // Info sections
              EventDetailInfoSection(event: event),
              const Divider(height: 1),
              // Registration status for non-owners
              if (!isOwner)
                BlocBuilder<
                  EventDetailCubit,
                  ResultState<EventRegistrationModel?>
                >(
                  builder: (context, state) {
                    return state.maybeWhen(
                      data: (registration) => EventRegistrationStatusCard(
                        event: event,
                        registration: registration,
                        onRegister: () => _navigateToRegistration(
                          context,
                          registration?.status == RegistrationStatus.cancelled
                              ? registration
                              : null,
                        ),
                        onEditRegistration: registration != null
                            ? () =>
                                  _navigateToRegistration(context, registration)
                            : null,
                        onCancelRegistration: registration != null
                            ? () => _confirmCancelRegistration(
                                context,
                                registration,
                              )
                            : null,
                        onViewRecommendations: event.recommendations != null
                            ? () => _showRecommendations(context)
                            : null,
                      ),
                      orElse: () => const SizedBox.shrink(),
                    );
                  },
                ),
              if (isOwner && event.recommendations != null) ...[
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
    );
  }

  Future<void> _navigateToRegistration(
    BuildContext context,
    EventRegistrationModel? existing,
  ) async {
    final result = await context.pushNamed<bool?>(
      AppRoutes.eventRegistration,
      extra: {'event': event, 'registration': existing},
    );
    if (result == true && context.mounted) {
      context.read<EventDetailCubit>().loadMyRegistration(event.id!);
    }
  }

  Future<void> _confirmCancelRegistration(
    BuildContext context,
    EventRegistrationModel registration,
  ) async {
    var confirmed = false;
    await ConfirmationDialog.show(
      context: context,
      title: EventStrings.cancelRegistrationTitle,
      content: EventStrings.cancelRegistrationMessage,
      dialogType: DialogType.warning,
      confirmLabel: AppStrings.accept,
      confirmType: DialogActionType.danger,
      onConfirm: () {
        confirmed = true;
      },
    );
    if (!confirmed || !context.mounted) return;
    final success = await context.read<EventDetailCubit>().cancelRegistration(
      registration.id!,
    );
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(EventStrings.cancelRegistrationSuccess),
          backgroundColor: Colors.green,
        ),
      );
    }
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
                  child: Text(
                    event.recommendations ?? '',
                    style: Theme.of(context).textTheme.bodyMedium,
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
      confirmLabel: 'Eliminar',
      confirmType: DialogActionType.danger,
      onConfirm: () {
        if (event.id != null) {
          context.read<EventDeleteCubit>().deleteEvent(event.id!);
        }
      },
    );
  }
}

class _EventDetailHeader extends StatelessWidget {
  final EventModel event;
  const _EventDetailHeader({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      color: colorScheme.primaryContainer,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: colorScheme.onPrimaryContainer.withOpacity(0.8),
              ),
              const SizedBox(width: 4),
              Text(
                event.city,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: colorScheme.onPrimaryContainer.withOpacity(0.8),
              ),
              const SizedBox(width: 4),
              Text(
                _formatDateRange(event),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(label: event.eventType.label, color: colorScheme.primary),
              _Chip(label: '🌶' * event.difficulty.value, color: Colors.red),
              _Chip(
                label: event.isFree
                    ? EventStrings.free
                    : '\$${event.price!.toStringAsFixed(0)}',
                color: event.isFree ? Colors.green : Colors.orange,
              ),
              _Chip(
                label: event.isMultiBrand
                    ? EventStrings.allBrands
                    : event.allowedBrands.join(', '),
                color: colorScheme.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateRange(EventModel event) {
    final formatter = DateFormat('d MMM yyyy', 'es');
    final start = formatter.format(event.startDate);
    if (event.endDate != null) {
      return '$start – ${formatter.format(event.endDate!)}';
    }
    return start;
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
