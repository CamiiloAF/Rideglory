import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/home/presentation/cubit/home_cubit.dart';
import 'package:rideglory/features/home/presentation/widgets/home_events_section.dart';
import 'package:rideglory/features/home/presentation/widgets/home_garage_section.dart';
import 'package:rideglory/features/home/presentation/widgets/home_header.dart';
import 'package:rideglory/features/home/presentation/widgets/home_view_all_events_button.dart';
import 'package:rideglory/design_system/design_system.dart';

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

  Future<void> _showExitConfirmation(BuildContext context) async {
    await ConfirmationDialog.show(
      context: context,
      title: AppStrings.exitAppTitle,
      content: AppStrings.exitAppMessage,
      cancelLabel: AppStrings.cancel,
      confirmLabel: AppStrings.exit,
      dialogType: DialogType.warning,
      onConfirm: () => SystemNavigator.pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) {
        if (!didPop) _showExitConfirmation(context);
      },
      child: Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) => RefreshIndicator(
            color: context.colorScheme.primary,
            backgroundColor: context.colorScheme.surface,
            onRefresh: () => context.read<HomeCubit>().loadHomeData(),
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: HomeHeader()),
                if (state is HomeLoading)
                  SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: context.colorScheme.primary,
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
                        style: TextStyle(
                          color: context.colorScheme.onSurfaceVariant,
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
      ),
    );
  }
}
