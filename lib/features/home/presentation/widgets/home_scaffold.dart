import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/home/presentation/cubit/home_cubit.dart';
import 'package:rideglory/features/home/presentation/widgets/home_events_section.dart';
import 'package:rideglory/features/home/presentation/widgets/home_garage_section.dart';
import 'package:rideglory/features/home/presentation/widgets/home_header.dart';
import 'package:rideglory/features/home/presentation/widgets/home_view_all_events_button.dart';
import 'package:rideglory/shared/widgets/states/page_error_state_widget.dart';

class HomeScaffold extends StatelessWidget {
  const HomeScaffold({super.key});

  Future<void> _showExitConfirmation(BuildContext context) async {
    await ConfirmationDialog.show(
      context: context,
      title: context.l10n.exitAppTitle,
      content: context.l10n.exitAppMessage,
      cancelLabel: context.l10n.cancel,
      confirmLabel: context.l10n.exit,
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
        backgroundColor: AppColors.darkBgPrimary,
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
                  if (state is HomeLoading || state is HomeInitial)
                    const SliverFillRemaining(
                      child: AppLoadingIndicator(
                        variant: AppLoadingIndicatorVariant.page,
                      ),
                    )
                  else if (state is HomeLoaded) ...[
                    const SliverToBoxAdapter(
                      child: HomeGarageSection(),
                    ),
                    SliverToBoxAdapter(
                      child: HomeEventsSection(events: state.upcomingEvents),
                    ),
                    const SliverToBoxAdapter(child: HomeViewAllEventsButton()),
                  ] else if (state is HomeError)
                    SliverFillRemaining(
                      child: PageErrorStateWidget(
                        title: context.l10n.errorOccurred,
                        message: state.message,
                        onRetry: () => context.read<HomeCubit>().loadHomeData(),
                      ),
                    ),
                  const SliverToBoxAdapter(child: AppSpacing.gap100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
