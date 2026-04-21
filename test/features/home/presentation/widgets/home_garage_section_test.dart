import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/nothing.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/vehicle_preferences_service.dart';
import 'package:rideglory/features/home/presentation/widgets/home_empty_garage_card.dart';
import 'package:rideglory/features/home/presentation/widgets/home_garage_card.dart';
import 'package:rideglory/features/home/presentation/widgets/home_garage_section.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/repository/maintenance_repository.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/get_maintenances_by_vehicle_id_use_case.dart';
import 'package:rideglory/features/vehicles/domain/models/user_main_vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/domain/repository/user_main_vehicle_repository.dart';
import 'package:rideglory/features/vehicles/domain/usecases/get_main_vehicle_id_usecase.dart';
import 'package:rideglory/features/vehicles/domain/usecases/set_main_vehicle_usecase.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/router/app_routes.dart';

void main() {
  late VehicleCubit vehicleCubit;

  setUp(() {
    getIt.reset();
    getIt.registerFactory<GetMaintenancesByVehicleIdUseCase>(
      () => GetMaintenancesByVehicleIdUseCase(_FakeMaintenanceRepository()),
    );
    vehicleCubit = VehicleCubit(
      _FakeVehiclePreferencesService(),
      GetMainVehicleIdUseCase(_FakeUserMainVehicleRepository()),
      SetMainVehicleUseCase(_FakeUserMainVehicleRepository()),
    );
  });

  testWidgets('shows empty garage card when no effective vehicle exists', (
    tester,
  ) async {
    final app = _buildRouterApp(vehicleCubit: vehicleCubit, child: const HomeGarageSection());

    await tester.pumpWidget(app);

    expect(find.byType(HomeEmptyGarageCard), findsOneWidget);
    expect(find.byType(HomeGarageCard), findsNothing);
  });

  testWidgets('shows provided vehicle when VehicleCubit has no current vehicle', (
    tester,
  ) async {
    final providedVehicle = _vehicle('provided');
    final app = _buildRouterApp(
      vehicleCubit: vehicleCubit,
      child: HomeGarageSection(vehicle: providedVehicle),
    );

    await tester.pumpWidget(app);

    expect(find.byType(HomeGarageCard), findsOneWidget);
    expect(find.byType(HomeEmptyGarageCard), findsNothing);
    expect(find.text('provided'), findsOneWidget);
  });

  testWidgets('prioritizes VehicleCubit.currentVehicle over constructor vehicle', (
    tester,
  ) async {
    await vehicleCubit.setCurrentVehicle(_vehicle('from-cubit'));
    final app = _buildRouterApp(
      vehicleCubit: vehicleCubit,
      child: HomeGarageSection(vehicle: _vehicle('from-param')),
    );

    await tester.pumpWidget(app);

    expect(find.text('from-cubit'), findsOneWidget);
    expect(find.text('from-param'), findsNothing);
  });

  testWidgets('navigates to garage route when tapping VER TODO', (tester) async {
    final app = _buildRouterApp(vehicleCubit: vehicleCubit, child: const HomeGarageSection());

    await tester.pumpWidget(app);
    await tester.tap(find.text('VER TODO'));
    await tester.pumpAndSettle();

    expect(find.text('Garage page'), findsOneWidget);
  });
}

Widget _buildRouterApp({required VehicleCubit vehicleCubit, required Widget child}) {
  final router = GoRouter(
    initialLocation: '/test-home',
    routes: [
      GoRoute(
        path: '/test-home',
        builder: (context, state) => Scaffold(body: child),
      ),
      GoRoute(
        path: AppRoutes.garage,
        name: AppRoutes.garage,
        builder: (context, state) => const Scaffold(body: Text('Garage page')),
      ),
    ],
  );

  return BlocProvider<VehicleCubit>.value(
    value: vehicleCubit,
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        AppLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

VehicleModel _vehicle(String name) {
  return VehicleModel(id: name, name: name, currentMileage: 1234);
}

class _FakeVehiclePreferencesService extends VehiclePreferencesService {
  @override
  Future<bool> clearSelectedVehicleId() async => true;

  @override
  Future<String?> getSelectedVehicleId() async => null;

  @override
  Future<bool> saveSelectedVehicleId(String vehicleId) async => true;
}

class _FakeUserMainVehicleRepository implements UserMainVehicleRepository {
  @override
  Future<Either<DomainException, UserMainVehicleModel?>> getMainVehicle() async {
    return const Right(null);
  }

  @override
  Future<Either<DomainException, String?>> getMainVehicleId() async {
    return const Right(null);
  }

  @override
  Future<Either<DomainException, UserMainVehicleModel>> setMainVehicleId(
    String vehicleId,
  ) async {
    return Right(UserMainVehicleModel(userId: 'user', mainVehicleId: vehicleId));
  }
}

class _FakeMaintenanceRepository implements MaintenanceRepository {
  @override
  Future<Either<DomainException, List<MaintenanceModel>>> getMaintenancesByVehicleId(
    String vehicleId,
  ) async {
    return const Right([]);
  }

  @override
  Future<Either<DomainException, MaintenanceModel>> addMaintenance(
    MaintenanceModel maintenance,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<Either<DomainException, Nothing>> deleteMaintenance(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Either<DomainException, List<MaintenanceModel>>> getMaintenancesByUserId() {
    throw UnimplementedError();
  }

  @override
  Future<Either<DomainException, MaintenanceModel>> updateMaintenance(
    MaintenanceModel maintenance,
  ) {
    throw UnimplementedError();
  }
}
