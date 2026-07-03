import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/services/dto/geocode_result_dto.dart';
import 'package:rideglory/core/services/place_service.dart';
import 'package:rideglory/design_system/atoms/feedback/app_loading_indicator.dart';
import 'package:rideglory/design_system/foundation/theme/app_theme.dart';
import 'package:rideglory/l10n/app_localizations.dart';
import 'package:rideglory/shared/widgets/map/route_map_preview.dart';

class MockPlaceService extends Mock implements PlaceService {}

Widget _buildWidget({String? meetingPoint, String? destination}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: ThemeMode.dark,
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      AppLocalizations.delegate,
    ],
    supportedLocales: const [Locale('es')],
    home: Scaffold(
      body: RouteMapPreview(
        meetingPoint: meetingPoint,
        destination: destination,
      ),
    ),
  );
}

void main() {
  late MockPlaceService mockPlaceService;

  setUp(() {
    mockPlaceService = MockPlaceService();
    GetIt.I.allowReassignment = true;
    GetIt.I.registerSingleton<PlaceService>(mockPlaceService);
  });

  tearDown(() {
    if (GetIt.I.isRegistered<PlaceService>()) {
      GetIt.I.unregister<PlaceService>();
    }
    GetIt.I.allowReassignment = false;
  });

  group('RouteMapPreview — State Display Tests (TC-3-6, Story 3.0)', () {
    testWidgets(
      'TC-3-6a: Loading state — shows spinner overlay while geocode is pending',
      (WidgetTester tester) async {
        // Arrange: geocode never completes — loading state stays active
        final completer = Completer<GeocodeResultDto>();
        when(
          () => mockPlaceService.geocode(any()),
        ).thenAnswer((_) => completer.future);

        // Act: pump once (enough to build widget + trigger initState async call)
        await tester.pumpWidget(
          _buildWidget(
            meetingPoint: 'Parque Berrío, Medellín',
            destination: 'El Poblado, Medellín',
          ),
        );
        await tester.pump();

        // Assert: loading indicator is visible
        expect(find.byType(RouteMapPreview), findsOneWidget);
        expect(find.byType(AppLoadingIndicator), findsOneWidget);

        // Cleanup: complete to avoid dangling futures
        completer.completeError(Exception('test teardown'));
      },
    );

    testWidgets(
      'TC-3-6b: Error state — shows error banner and does not crash when geocode throws',
      (WidgetTester tester) async {
        // Arrange: geocode throws DioException (network error)
        when(() => mockPlaceService.geocode(any())).thenAnswer(
          (_) async => throw DioException(
            requestOptions: RequestOptions(path: '/places/geocode'),
            type: DioExceptionType.connectionTimeout,
            message: 'Connection timed out',
          ),
        );

        // Act
        await tester.pumpWidget(
          _buildWidget(
            meetingPoint: 'Parque Berrío, Medellín',
            destination: 'El Poblado, Medellín',
          ),
        );
        // Pump enough for the future to resolve and setState to fire
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert: widget is alive and error banner is rendered
        expect(find.byType(RouteMapPreview), findsOneWidget);
        expect(
          find.text('No se pudo obtener las coordenadas.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'TC-3-6c: Data state — widget renders without crash when geocode returns valid coordinates',
      (WidgetTester tester) async {
        // Arrange: geocode returns a valid result
        const geocodeResult = GeocodeResultDto(
          latitude: 6.2442,
          longitude: -75.5812,
          formattedAddress: 'Medellín, Colombia',
        );
        when(
          () => mockPlaceService.geocode(any()),
        ).thenAnswer((_) async => geocodeResult);

        // Act: pump once (widget builds in loading state before async resolves)
        await tester.pumpWidget(
          _buildWidget(meetingPoint: 'Parque Berrío, Medellín'),
        );
        // One pump to trigger initState future
        await tester.pump();

        // Assert: widget renders without exception (data flow is correct)
        expect(find.byType(RouteMapPreview), findsOneWidget);
        // Error banner must NOT appear
        expect(find.text('No se pudo obtener las coordenadas.'), findsNothing);
      },
    );

    testWidgets(
      'TC-3-6d: Empty state — shows placeholder when meetingPoint and destination are null',
      (WidgetTester tester) async {
        // Arrange: no geocode calls expected (both fields are null/empty)
        // Act
        await tester.pumpWidget(
          _buildWidget(meetingPoint: null, destination: null),
        );
        await tester.pump();

        // Assert: placeholder text is visible, no loading indicator or error
        expect(find.byType(RouteMapPreview), findsOneWidget);
        expect(find.text('Vista previa del mapa'), findsOneWidget);
        expect(find.byType(AppLoadingIndicator), findsNothing);
        expect(find.text('No se pudo obtener las coordenadas.'), findsNothing);

        // geocode should never be called when both fields are null
        verifyNever(() => mockPlaceService.geocode(any()));
      },
    );
  });
}
