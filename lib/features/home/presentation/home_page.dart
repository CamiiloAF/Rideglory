import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/home/presentation/cubit/home_cubit.dart';
import 'package:rideglory/features/home/presentation/widgets/home_events_section.dart';
import 'package:rideglory/features/home/presentation/widgets/home_garage_section.dart';
import 'package:rideglory/features/home/presentation/widgets/home_header.dart';
import 'package:rideglory/features/home/presentation/widgets/home_view_all_events_button.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/home_bottom_navigation_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HomeCubit>()..loadHomeData(),
      child: const _HomeScaffold(),
    );
  }
}

class _HomeScaffold extends StatelessWidget {
  const _HomeScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) => RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.darkSurface,
            onRefresh: () => context.read<HomeCubit>().loadHomeData(),
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: HomeHeader()),
                if (state is HomeLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else if (state is HomeLoaded) ...[
                  SliverToBoxAdapter(
                    child: HomeGarageSection(vehicle: state.mainVehicle),
                  ),
                  SliverToBoxAdapter(
                    child: HomeEventsSection(events: state.upcomingEvents),
                  ),
                  const SliverToBoxAdapter(child: HomeViewAllEventsButton()),
                ] else if (state is HomeError)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        state.message,
                        style: const TextStyle(
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: HomeBottomNavigationBar(
        currentIndex: 0,
        showNotificationBadge: true,
        onTap: (index) {
          switch (index) {
            case 1:
              context.pushNamed(AppRoutes.garage);
            case 3:
              context.pushNamed(AppRoutes.events);
            case 4:
              break;
          }
        },
        onAddTap: () => context.pushNamed(AppRoutes.createEvent),
      ),
    );
  }
}
