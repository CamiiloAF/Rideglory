// Widget tests for VehicleSessionSync.
//
// Verifies VehicleCubit is kept in sync with AuthCubit transitions: refetched
// on authentication, cleared on sign-out. Without this, the app-wide
// VehicleCubit singleton retains a previous session's state across
// logout/login without a full process restart.

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/shared/widgets/vehicle_session_sync.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class MockVehicleCubit extends MockCubit<ResultState<List<VehicleModel>>>
    implements VehicleCubit {}

Widget _wrap({
  required AuthCubit authCubit,
  required VehicleCubit vehicleCubit,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthCubit>.value(value: authCubit),
      BlocProvider<VehicleCubit>.value(value: vehicleCubit),
    ],
    child: const MaterialApp(home: VehicleSessionSync(child: SizedBox())),
  );
}

void main() {
  late MockAuthCubit authCubit;
  late MockVehicleCubit vehicleCubit;
  late StreamController<AuthState> authStream;

  setUp(() {
    authCubit = MockAuthCubit();
    vehicleCubit = MockVehicleCubit();
    authStream = StreamController<AuthState>.broadcast();

    when(() => vehicleCubit.state).thenReturn(const ResultState.initial());
    when(() => vehicleCubit.fetchMyVehicles()).thenAnswer((_) async {});
    when(() => vehicleCubit.clearVehicles()).thenReturn(null);
  });

  tearDown(() async {
    await authStream.close();
  });

  testWidgets(
    'TC-vehicle-sync-1: AuthState.authenticated triggers fetchMyVehicles',
    (tester) async {
      when(() => authCubit.state).thenReturn(const AuthState.initial());
      whenListen(
        authCubit,
        authStream.stream,
        initialState: const AuthState.initial(),
      );

      await tester.pumpWidget(
        _wrap(authCubit: authCubit, vehicleCubit: vehicleCubit),
      );
      await tester.pump();

      authStream.add(const AuthState.authenticated(null));
      await tester.pump();

      verify(() => vehicleCubit.fetchMyVehicles()).called(1);
      verifyNever(() => vehicleCubit.clearVehicles());
    },
  );

  testWidgets(
    'TC-vehicle-sync-2: AuthState.unauthenticated triggers clearVehicles',
    (tester) async {
      when(() => authCubit.state).thenReturn(const AuthState.initial());
      whenListen(
        authCubit,
        authStream.stream,
        initialState: const AuthState.initial(),
      );

      await tester.pumpWidget(
        _wrap(authCubit: authCubit, vehicleCubit: vehicleCubit),
      );
      await tester.pump();

      authStream.add(const AuthState.unauthenticated());
      await tester.pump();

      verify(() => vehicleCubit.clearVehicles()).called(1);
      verifyNever(() => vehicleCubit.fetchMyVehicles());
    },
  );

  testWidgets(
    'TC-vehicle-sync-3: intermediate loading/error states do not touch VehicleCubit',
    (tester) async {
      when(() => authCubit.state).thenReturn(const AuthState.initial());
      whenListen(
        authCubit,
        authStream.stream,
        initialState: const AuthState.initial(),
      );

      await tester.pumpWidget(
        _wrap(authCubit: authCubit, vehicleCubit: vehicleCubit),
      );
      await tester.pump();

      authStream.add(const AuthState.loading());
      await tester.pump();
      authStream.add(const AuthState.error('boom'));
      await tester.pump();

      verifyNever(() => vehicleCubit.fetchMyVehicles());
      verifyNever(() => vehicleCubit.clearVehicles());
    },
  );

  testWidgets(
    'TC-vehicle-sync-4: logout followed by a new login refetches for the new session',
    (tester) async {
      when(() => authCubit.state).thenReturn(const AuthState.initial());
      whenListen(
        authCubit,
        authStream.stream,
        initialState: const AuthState.initial(),
      );

      await tester.pumpWidget(
        _wrap(authCubit: authCubit, vehicleCubit: vehicleCubit),
      );
      await tester.pump();

      authStream.add(const AuthState.unauthenticated());
      await tester.pump();
      authStream.add(const AuthState.authenticated(null));
      await tester.pump();

      verify(() => vehicleCubit.clearVehicles()).called(1);
      verify(() => vehicleCubit.fetchMyVehicles()).called(1);
    },
  );
}
