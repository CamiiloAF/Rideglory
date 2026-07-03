import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/shared/router/analytics_route_observer.dart';
import 'package:rideglory/shared/router/app_router.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/home_bottom_navigation_bar.dart';
import 'package:rideglory/shared/widgets/shell_screen_view_tracker.dart';

const int _addButtonBarIndex = 2;

int _branchIndexToBarIndex(int branchIndex) {
  if (branchIndex <= 1) return branchIndex;
  return branchIndex + 1;
}

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.navigationShell,
    this.showNotificationBadge = false,
    AnalyticsService? analyticsService,
    AnalyticsRouteObserver? analyticsObserver,
  }) : _analyticsService = analyticsService,
       _analyticsObserver = analyticsObserver;

  final StatefulNavigationShell navigationShell;
  final bool showNotificationBadge;

  // Inyectables para testing; en producción se obtienen desde DI / AppRouter.
  final AnalyticsService? _analyticsService;
  final AnalyticsRouteObserver? _analyticsObserver;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  void initState() {
    super.initState();
    // Precarga los vehículos al montar el shell (usuario ya autenticado).
    // GaragePage también llama fetchMyVehicles al visitarse, pero sin esta
    // llamada HomeGarageSection mostraría placeholder hasta que el usuario
    // navegue al tab de Garaje.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<VehicleCubit>();
      if (cubit.state is Initial) cubit.fetchMyVehicles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentBarIndex = _branchIndexToBarIndex(
      widget.navigationShell.currentIndex,
    );
    final analytics = widget._analyticsService ?? getIt<AnalyticsService>();
    final observer = widget._analyticsObserver ?? AppRouter.analyticsObserver;

    // Reexpone la MISMA instancia de VehicleCubit provista en la raíz
    // (sobre MaterialApp) a las ramas del StatefulShellRoute. No se usa el
    // contenedor de DI para evitar instancias duplicadas: el VehicleCubit ya
    // no es singleton, su ciclo de vida lo maneja el BlocProvider raíz.
    return BlocProvider.value(
      value: context.read<VehicleCubit>(),
      child: ShellScreenViewTracker(
        navigationShell: widget.navigationShell,
        analytics: analytics,
        observer: observer,
        child: Scaffold(
          body: widget.navigationShell,
          bottomNavigationBar: HomeBottomNavigationBar(
            currentIndex: currentBarIndex,
            showNotificationBadge: widget.showNotificationBadge,
            onTap: (int index) {
              if (index == _addButtonBarIndex) {
                context.pushNamed(AppRoutes.createEvent);
                return;
              }
              final branchIndex = index > _addButtonBarIndex
                  ? index - 1
                  : index;
              widget.navigationShell.goBranch(branchIndex);
            },
            onAddTap: () => context.pushNamed(AppRoutes.createEvent),
          ),
        ),
      ),
    );
  }
}
