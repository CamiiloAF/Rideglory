import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/garage_vehicles_content.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/states/page_error_state_widget.dart';
import 'package:rideglory/shared/widgets/states/page_loading_state_widget.dart';

class GaragePageView extends StatefulWidget {
  const GaragePageView({super.key, required this.loadVehicles});

  final Future<void> Function() loadVehicles;

  @override
  State<GaragePageView> createState() => _GaragePageViewState();
}

class _GaragePageViewState extends State<GaragePageView> {
  int _currentIndex = 0;
  late final PageController _pageController;

  /// Keeps carousel index valid after local cubit updates (create/edit/delete).
  /// [focusVehicle] aligns the PageView when we know which row changed (API returns it).
  void _syncGaragePageIndex([VehicleModel? focusVehicle]) {
    if (!mounted) return;
    final vehicles = context
        .read<VehicleCubit>()
        .availableVehicles
        .where((v) => !v.isArchived)
        .toList();

    int newIndex = _currentIndex;
    if (vehicles.isEmpty) {
      newIndex = 0;
    } else {
      if (newIndex >= vehicles.length) {
        newIndex = vehicles.length - 1;
      }
      final focusId = focusVehicle?.id;
      if (focusId != null) {
        final i = vehicles.indexWhere((v) => v.id == focusId);
        if (i >= 0) newIndex = i;
      }
    }

    setState(() => _currentIndex = newIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.jumpToPage(newIndex);
    });
  }

  Future<void> _pushCreateVehicleThenSync() async {
    final result = await context.pushNamed(AppRoutes.createVehicle);
    if (!mounted || result == null) return;
    _syncGaragePageIndex(result is VehicleModel ? result : null);
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.loadVehicles();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(Icons.two_wheeler, color: context.colorScheme.primary),
        ),
        title: Text(
          context.l10n.vehicle_myGarage,
          style: context.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.notifications_none,
                color: context.colorScheme.primary,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<VehicleCubit, ResultState<List<VehicleModel>>>(
          builder: (context, state) {
            return state.maybeWhen(
              loading: () =>
                  PageLoadingStateWidget(onRefresh: widget.loadVehicles),
              error: (error) => PageErrorStateWidget(
                title: context.l10n.errorOccurred,
                message: context.l10n.errorMessage(error.message),
                onRetry: widget.loadVehicles,
                onRefresh: widget.loadVehicles,
              ),
              empty: () => EmptyStateWidget(
                icon: Icons.garage_outlined,
                title: context.l10n.vehicle_noVehicles,
                description: context.l10n.vehicle_noVehiclesDescription,
                actionButtonText: context.l10n.vehicle_addVehicle,
                onActionPressed: _pushCreateVehicleThenSync,
              ),
              data: (_) => GarageVehiclesContent(
                pageController: _pageController,
                currentIndex: _currentIndex,
                onIndexChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                onGarageListUpdatedLocally: _syncGaragePageIndex,
              ),
              orElse: () => const PageLoadingStateWidget(),
            );
          },
        ),
      ),
    );
  }
}
