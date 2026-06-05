// Widget tests for the generic shared widgets in vehicle_documents/presentation/widgets/.
//
// Each widget is tested once here (not duplicated per feature).
// Uses MaterialApp + AppLocalizations to satisfy context.l10n usage.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/soat/domain/models/soat_model.dart';
import 'package:rideglory/features/vehicle_documents/presentation/cubit/vehicle_document_cubit.dart';
import 'package:rideglory/features/vehicle_documents/presentation/widgets/data_view.dart';
import 'package:rideglory/features/vehicle_documents/presentation/widgets/detail_row.dart';
import 'package:rideglory/features/vehicle_documents/presentation/widgets/empty_state.dart';
import 'package:rideglory/features/vehicle_documents/presentation/widgets/section_header.dart';
import 'package:rideglory/features/vehicle_documents/presentation/widgets/status_view.dart';
import 'package:rideglory/features/vehicle_documents/presentation/widgets/validity_card.dart';
import 'package:rideglory/l10n/app_localizations.dart';

// ---------- Fake cubit for DocumentStatusView tests ----------
// VehicleDocumentCubit always starts in initial(). The fake exposes
// a [push] method so tests can drive it to any state without real use cases.

class _FakeVehicleDocumentCubit
    extends VehicleDocumentCubit<SoatModel> {
  @override
  Future<void> load(String vehicleId) async {}

  void push(ResultState<SoatModel> state) => emit(state);
}

// ---------- Wrapper helper ----------

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      home: Scaffold(body: child),
    );

void main() {
  // ----------------------------------------------------------------
  // DocumentEmptyState
  // ----------------------------------------------------------------

  group('DocumentEmptyState', () {
    testWidgets('renders icon, title, subtitle and CTA button', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          DocumentEmptyState(
            icon: Icons.shield_outlined,
            title: 'Sin documento',
            subtitle: 'No has registrado este documento.',
            ctaLabel: 'Registrar',
            onCta: () => tapped = true,
          ),
        ),
      );

      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
      expect(find.text('Sin documento'), findsOneWidget);
      expect(find.text('No has registrado este documento.'), findsOneWidget);
      expect(find.text('Registrar'), findsOneWidget);

      await tester.tap(find.text('Registrar'));
      expect(tapped, isTrue);
    });
  });

  // ----------------------------------------------------------------
  // DocumentDetailRow
  // ----------------------------------------------------------------

  group('DocumentDetailRow', () {
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DocumentDetailRow(label: 'Aseguradora', value: 'Sura'),
        ),
      );

      expect(find.text('Aseguradora'), findsOneWidget);
      expect(find.text('Sura'), findsOneWidget);
    });

    testWidgets('isLast: false applies non-zero bottom padding', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DocumentDetailRow(
            label: 'Campo',
            value: 'Valor',
            isLast: false,
          ),
        ),
      );

      // Find the outermost Padding widget of DocumentDetailRow
      final paddingFinder = find.byType(Padding);
      // The first Padding is the root of DocumentDetailRow
      final padding = tester.widget<Padding>(paddingFinder.first);
      expect(
        (padding.padding as EdgeInsets).bottom,
        12.0,
      );
    });

    testWidgets('isLast: true applies zero bottom padding', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DocumentDetailRow(
            label: 'Etiqueta',
            value: 'Dato',
            isLast: true,
          ),
        ),
      );

      final paddingFinder = find.byType(Padding);
      final padding = tester.widget<Padding>(paddingFinder.first);
      expect(
        (padding.padding as EdgeInsets).bottom,
        0.0,
      );
    });
  });

  // ----------------------------------------------------------------
  // DocumentSectionHeader
  // ----------------------------------------------------------------

  group('DocumentSectionHeader', () {
    testWidgets('renders icon and uppercased title', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DocumentSectionHeader(
            icon: Icons.info_outline,
            title: 'detalles',
          ),
        ),
      );

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.text('DETALLES'), findsOneWidget);
    });

    testWidgets('renders trailing widget when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DocumentSectionHeader(
            icon: Icons.info_outline,
            title: 'titulo',
            trailing: Text('EXTRA'),
          ),
        ),
      );

      expect(find.text('EXTRA'), findsOneWidget);
    });

    testWidgets('trailing absent when null', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DocumentSectionHeader(
            icon: Icons.info_outline,
            title: 'titulo',
          ),
        ),
      );

      expect(find.text('EXTRA'), findsNothing);
    });
  });

  // ----------------------------------------------------------------
  // DocumentDataView
  // ----------------------------------------------------------------

  group('DocumentDataView', () {
    final mockSoat = SoatModel(
      id: 'soat-1',
      vehicleId: 'v-1',
      expiryDate: DateTime.now().add(const Duration(days: 90)),
    );

    testWidgets('renders hero card title and detail rows', (tester) async {
      await tester.pumpWidget(
        _wrap(
          DocumentDataView<SoatModel>(
            document: mockSoat,
            heroColor: Colors.green,
            heroIcon: Icons.shield_outlined,
            heroTitle: 'SOAT vigente',
            heroDaysChip: '90 días',
            detailRows: const [
              DocumentDetailRow(label: 'Aseguradora', value: 'Sura'),
            ],
          ),
        ),
      );

      expect(find.text('SOAT vigente'), findsOneWidget);
      expect(find.text('90 días'), findsOneWidget);
      expect(find.text('Aseguradora'), findsOneWidget);
    });

    testWidgets('heroFooter rendered when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          DocumentDataView<SoatModel>(
            document: mockSoat,
            heroColor: Colors.green,
            heroIcon: Icons.shield_outlined,
            heroTitle: 'Vigente',
            heroDaysChip: null,
            detailRows: const [],
            heroFooter: const Text('Renovar'),
          ),
        ),
      );

      expect(find.text('Renovar'), findsOneWidget);
    });

    testWidgets('actions rendered when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          DocumentDataView<SoatModel>(
            document: mockSoat,
            heroColor: Colors.green,
            heroIcon: Icons.shield_outlined,
            heroTitle: 'Vigente',
            heroDaysChip: null,
            detailRows: const [],
            actions: const Text('Eliminar'),
          ),
        ),
      );

      expect(find.text('Eliminar'), findsOneWidget);
    });

    testWidgets('heroFooter absent when not provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          DocumentDataView<SoatModel>(
            document: mockSoat,
            heroColor: Colors.green,
            heroIcon: Icons.shield_outlined,
            heroTitle: 'Vigente',
            heroDaysChip: null,
            detailRows: const [],
          ),
        ),
      );

      expect(find.text('Renovar'), findsNothing);
      expect(find.text('Eliminar'), findsNothing);
    });
  });

  // ----------------------------------------------------------------
  // DocumentValidityCard
  // ----------------------------------------------------------------

  group('DocumentValidityCard', () {
    testWidgets('without dates → renders pending state (shield icon)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DocumentValidityCard(startDate: null, expiryDate: null),
        ),
      );

      // ValidityCardPending renders shield_outlined
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    });

    testWidgets('startDate == expiryDate → renders invalid dates (error_outline icon)',
        (tester) async {
      final date = DateTime(2025, 1, 1);
      await tester.pumpWidget(
        _wrap(
          DocumentValidityCard(startDate: date, expiryDate: date),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('expiryDate in the past → renders expired state',
        (tester) async {
      final start = DateTime(2023, 1, 1);
      final expiry = DateTime(2023, 6, 1);
      await tester.pumpWidget(
        _wrap(
          DocumentValidityCard(startDate: start, expiryDate: expiry),
        ),
      );

      // ValidityCardExpired uses shield_outlined icon and "vencido" text
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
      expect(find.textContaining('vencid'), findsOneWidget);
    });

    testWidgets('expiryDate in the future → renders valid state (verified_user icon)',
        (tester) async {
      final start = DateTime.now().subtract(const Duration(days: 30));
      final expiry = DateTime.now().add(const Duration(days: 90));
      await tester.pumpWidget(
        _wrap(
          DocumentValidityCard(startDate: start, expiryDate: expiry),
        ),
      );

      expect(find.byIcon(Icons.verified_user_outlined), findsOneWidget);
    });
  });

  // ----------------------------------------------------------------
  // DocumentStatusView
  // ----------------------------------------------------------------

  group('DocumentStatusView', () {
    Widget buildStatusView(_FakeVehicleDocumentCubit cubit) =>
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('es')],
          home: BlocProvider<_FakeVehicleDocumentCubit>.value(
            value: cubit,
            child: DocumentStatusView<_FakeVehicleDocumentCubit, SoatModel>(
              title: 'SOAT',
              vehicle: null,
              buildEmpty: (ctx) => const Text('empty-widget'),
              buildData: (ctx, data) => Text('data-${data.id}'),
              onRetry: () {},
            ),
          ),
        );

    testWidgets('loading state renders CircularProgressIndicator',
        (tester) async {
      final cubit = _FakeVehicleDocumentCubit();
      cubit.push(const ResultState.loading());
      await tester.pumpWidget(buildStatusView(cubit));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('empty state renders buildEmpty widget', (tester) async {
      final cubit = _FakeVehicleDocumentCubit();
      cubit.push(const ResultState.empty());
      await tester.pumpWidget(buildStatusView(cubit));
      await tester.pump();

      expect(find.text('empty-widget'), findsOneWidget);
    });

    testWidgets('data state renders buildData widget', (tester) async {
      final soat = SoatModel(
        id: 'soat-99',
        vehicleId: 'v-1',
        expiryDate: DateTime.now().add(const Duration(days: 90)),
      );
      final cubit = _FakeVehicleDocumentCubit();
      cubit.push(ResultState.data(data: soat));
      await tester.pumpWidget(buildStatusView(cubit));
      await tester.pump();

      expect(find.text('data-soat-99'), findsOneWidget);
    });

    testWidgets('error state renders error message', (tester) async {
      final cubit = _FakeVehicleDocumentCubit();
      cubit.push(
        const ResultState.error(
          error: DomainException(message: 'Algo salió mal'),
        ),
      );
      await tester.pumpWidget(buildStatusView(cubit));
      await tester.pump();

      expect(find.text('Algo salió mal'), findsOneWidget);
    });
  });
}
