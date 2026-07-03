// Tests para VehicleDetailNav — fase 3: modo read-only de vehículo archivado.
//
// Cubre el criterio de aceptación QA sección 4.3:
//   "El botón 'Editar' no aparece en ninguna parte de la pantalla"
// Y el caso positivo: el botón SÍ aparece cuando el vehículo está activo.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/garage/widgets/vehicle_detail_nav.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/router/app_routes.dart';

// ─── Fixture ─────────────────────────────────────────────────────────────────

const _vehicle = VehicleModel(
  id: 'v-nav-1',
  name: 'BMW R1250GS',
  currentMileage: 12000,
  isArchived: false,
);

// ─── Helper ──────────────────────────────────────────────────────────────────

Widget _pump(VehicleDetailNav nav) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, s) => Scaffold(body: nav),
        routes: [
          GoRoute(
            path: 'vehicles/edit',
            name: AppRoutes.editVehicle,
            builder: (_, s2) => const Scaffold(body: Text('edit')),
          ),
        ],
      ),
    ],
  );

  return MaterialApp.router(
    routerConfig: router,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [Locale('es')],
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  // TC-nav-1: vehículo archivado → botón editar ausente
  testWidgets('TC-nav-1: isArchived=true — edit button is NOT rendered', (
    tester,
  ) async {
    await tester.pumpWidget(
      _pump(
        VehicleDetailNav(vehicle: _vehicle, isArchived: true, onBack: () {}),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.edit_outlined), findsNothing);
  });

  // TC-nav-2: vehículo activo → botón editar presente
  testWidgets('TC-nav-2: isArchived=false — edit button IS rendered', (
    tester,
  ) async {
    await tester.pumpWidget(
      _pump(
        VehicleDetailNav(vehicle: _vehicle, isArchived: false, onBack: () {}),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
  });

  // TC-nav-3: vehículo archivado → nombre del vehículo siempre visible
  testWidgets('TC-nav-3: isArchived=true — vehicle name is still displayed', (
    tester,
  ) async {
    await tester.pumpWidget(
      _pump(
        VehicleDetailNav(vehicle: _vehicle, isArchived: true, onBack: () {}),
      ),
    );
    await tester.pump();

    expect(find.text('BMW R1250GS'), findsOneWidget);
  });
}
