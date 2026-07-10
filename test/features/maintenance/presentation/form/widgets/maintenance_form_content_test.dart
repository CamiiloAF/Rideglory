// Widget tests for MaintenanceFormContent / MaintenanceFormView:
// verifica que los campos exclusivos del modo "Completado"
// (fecha de servicio, kilometraje de servicio, taller) se OCULTAN cuando
// el usuario cambia el MaintenanceStatusToggle a "Programado", y vuelven a
// aparecer al cambiar de nuevo a "Completado".
//
// Cubre el gap documentado en docs/testing/qa-checklists/
// maintenance_QA_CHECKLIST.md fila 2.1.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/features/maintenance/domain/model/maintenance_model.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/add_maintenance_use_case.dart';
import 'package:rideglory/features/maintenance/domain/use_cases/update_maintenance_use_case.dart';
import 'package:rideglory/features/maintenance/constants/maintenance_form_fields.dart';
import 'package:rideglory/features/maintenance/presentation/form/cubit/maintenance_form_cubit.dart';
import 'package:rideglory/features/maintenance/presentation/form/widgets/maintenance_form_view.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/widgets/form/app_date_picker.dart';
import 'package:rideglory/shared/widgets/form/app_mileage_field.dart';
import 'package:rideglory/shared/widgets/form/app_text_field.dart';

class MockAddMaintenanceUseCase extends Mock implements AddMaintenanceUseCase {}

class MockUpdateMaintenanceUseCase extends Mock
    implements UpdateMaintenanceUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockVehicleCubit extends MockCubit<ResultState<List<VehicleModel>>>
    implements VehicleCubit {}

const _testVehicle = VehicleModel(
  id: 'vehicle-1',
  name: 'Mi moto',
  currentMileage: 10000,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAddMaintenanceUseCase addUseCase;
  late MockUpdateMaintenanceUseCase updateUseCase;
  late MockAnalyticsService analyticsService;
  late MaintenanceFormCubit formCubit;
  late MockVehicleCubit vehicleCubit;

  setUp(() {
    addUseCase = MockAddMaintenanceUseCase();
    updateUseCase = MockUpdateMaintenanceUseCase();
    analyticsService = MockAnalyticsService();
    when(
      () => analyticsService.logEvent(any(), any()),
    ).thenAnswer((_) async {});

    formCubit = MaintenanceFormCubit(
      addUseCase,
      updateUseCase,
      analyticsService,
    )..initialize();

    vehicleCubit = MockVehicleCubit();
    when(
      () => vehicleCubit.state,
    ).thenReturn(const ResultState<List<VehicleModel>>.initial());
    when(() => vehicleCubit.currentVehicle).thenReturn(_testVehicle);
    when(
      () => vehicleCubit.currentMileage,
    ).thenReturn(_testVehicle.currentMileage);
  });

  tearDown(() => formCubit.close());

  Widget buildApp() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MaintenanceFormCubit>.value(value: formCubit),
        BlocProvider<VehicleCubit>.value(value: vehicleCubit),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MaintenanceFormView(
            selectedType: MaintenanceType.oilChange,
            onChangeType: () {},
          ),
        ),
      ),
    );
  }

  // Los campos exclusivos de "completado" se buscan por el widget de form
  // (fieldName/name), no por su Text.rich renderizado (TextFieldLabel usa
  // Text.rich con un TextSpan hijo para el asterisco cuando isRequired, así
  // que el texto plano nunca coincide exactamente con `find.text`).
  final serviceDateField = find.byWidgetPredicate(
    (widget) =>
        widget is AppDatePicker &&
        widget.fieldName == MaintenanceFormFields.date,
  );
  final serviceMileageField = find.byWidgetPredicate(
    (widget) =>
        widget is AppMileageField &&
        widget.name == MaintenanceFormFields.currentMileage,
  );
  final workshopField = find.byWidgetPredicate(
    (widget) =>
        widget is AppTextField && widget.name == MaintenanceFormFields.workshop,
  );

  group('MaintenanceFormContent — visibilidad de campos por modo', () {
    testWidgets('en modo Completado (por defecto) muestra fecha de servicio, '
        'kilometraje y taller', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(serviceDateField, findsOneWidget);
      expect(serviceMileageField, findsOneWidget);
      expect(workshopField, findsOneWidget);
    });

    testWidgets('al cambiar el toggle a Programado, oculta fecha de servicio, '
        'kilometraje y taller', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Programado'));
      await tester.pumpAndSettle();

      expect(serviceDateField, findsNothing);
      expect(serviceMileageField, findsNothing);
      expect(workshopField, findsNothing);
    });

    testWidgets('al volver a Completado tras estar en Programado, los campos '
        'reaparecen', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Programado'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Completado'));
      await tester.pumpAndSettle();

      expect(serviceDateField, findsOneWidget);
      expect(serviceMileageField, findsOneWidget);
      expect(workshopField, findsOneWidget);
    });
  });
}
