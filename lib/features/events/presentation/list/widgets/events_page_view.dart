import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/delete/cubit/event_delete_cubit.dart';
import 'package:rideglory/features/events/presentation/list/events_cubit.dart';
import 'package:rideglory/features/events/presentation/list/widgets/events_data_view.dart';
import 'package:rideglory/features/events/presentation/list/widgets/events_state_widgets.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/app_drawer.dart';
import 'package:rideglory/shared/widgets/empty_state_widget.dart';
import 'package:rideglory/shared/widgets/main_bottom_navigation_bar.dart';

class EventsPageView extends StatelessWidget {
  final bool showMyEvents;
  const EventsPageView({super.key, this.showMyEvents = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      drawer: AppDrawer(
        currentRoute: showMyEvents ? AppRoutes.myEvents : AppRoutes.events,
      ),
      floatingActionButton: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.primaryGradient,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _navigateToCreate(context),
            borderRadius: BorderRadius.circular(32),
            child: const Icon(Icons.add, color: Colors.white, size: 32),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: MainBottomNavigationBar(
        currentIndex: 0, // Explorar activo
        onTap: (index) {
          // TODO: Implementar navegación entre secciones
          switch (index) {
            case 0:
              // Ya estamos en Explorar (Eventos)
              break;
            case 1:
              // Navegar a Mapa
              break;
            case 2:
              // Navegar a Garage
              context.pushNamed(AppRoutes.vehicles);
              break;
            case 3:
              // Navegar a Perfil
              break;
          }
        },
      ),
      body: SafeArea(
        child: MultiBlocListener(
          listeners: [
            BlocListener<EventDeleteCubit, ResultState<String>>(
              listener: (context, state) {
                state.whenOrNull(
                  data: (eventId) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(EventStrings.eventDeletedSuccess),
                        backgroundColor: Colors.green,
                      ),
                    );
                    context.read<EventsCubit>().removeEvent(eventId);
                  },
                  error: (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppStrings.errorMessage(error.message)),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                );
              },
            ),
          ],
          child: BlocBuilder<EventsCubit, ResultState<List<EventModel>>>(
            builder: (context, state) {
              final eventsCubit = context.read<EventsCubit>();
              return state.maybeWhen(
                loading: () => const EventsLoadingWidget(),
                error: (error) => EventsErrorWidget(
                  message: error.message,
                  onRefresh: () => eventsCubit.fetchEvents(),
                ),
                empty: () => EmptyStateWidget(
                  icon: Icons.event_outlined,
                  title: EventStrings.noEvents,
                  description: EventStrings.noEventsDescription,
                  actionButtonText: EventStrings.createEvent,
                  onActionPressed: () => _navigateToCreate(context),
                  onRefresh: () => eventsCubit.fetchEvents(),
                ),
                data: (events) => EventsDataView(events: events),
                orElse: () => const EventsLoadingWidget(),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToCreate(BuildContext context) async {
    final result = await context.pushNamed<EventModel?>(AppRoutes.createEvent);
    if (result != null && context.mounted) {
      context.read<EventsCubit>().addEvent(result);
    }
  }
}
