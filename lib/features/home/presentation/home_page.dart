import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/features/home/presentation/cubit/home_cubit.dart';
import 'package:rideglory/features/home/presentation/widgets/home_header.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

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
                    child:
                        AppLoadingIndicator(variant: AppLoadingIndicatorVariant.page),
                  )
                else if (state is HomeError)
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
