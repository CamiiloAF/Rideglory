import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/use_cases/create_event_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/update_event_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/upload_event_image_use_case.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/users/domain/use_cases/get_current_user_id_use_case.dart';

class MockCreateEventUseCase extends Mock implements CreateEventUseCase {}

class MockUpdateEventUseCase extends Mock implements UpdateEventUseCase {}

class MockUploadEventImageUseCase extends Mock
    implements UploadEventImageUseCase {}

class MockGetCurrentUserIdUseCase extends Mock
    implements GetCurrentUserIdUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCreateEventUseCase mockCreate;
  late MockUpdateEventUseCase mockUpdate;
  late MockUploadEventImageUseCase mockUpload;
  late MockGetCurrentUserIdUseCase mockGetUserId;
  late MockAnalyticsService mockAnalytics;
  late EventFormCubit cubit;

  setUp(() {
    mockCreate = MockCreateEventUseCase();
    mockUpdate = MockUpdateEventUseCase();
    mockUpload = MockUploadEventImageUseCase();
    mockGetUserId = MockGetCurrentUserIdUseCase();
    mockAnalytics = MockAnalyticsService();

    when(() => mockAnalytics.logEvent(any(), any())).thenAnswer((_) async {});
    when(() => mockAnalytics.logEvent(any())).thenAnswer((_) async {});

    cubit = EventFormCubit(
      mockCreate,
      mockUpdate,
      mockUpload,
      mockGetUserId,
      mockAnalytics,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('EventFormCubit — stepper (Fase 1)', () {
    // TC-stp-1: initial currentStep is 0
    test('TC-stp-1: initial state.currentStep == 0', () {
      expect(cubit.state.currentStep, 0);
      expect(cubit.state.saveResult, const ResultState<EventModel>.initial());
    });

    // TC-stp-2: nextStep advances step
    test('TC-stp-2: nextStep() increments currentStep', () {
      cubit.nextStep();
      expect(cubit.state.currentStep, 1);
      cubit.nextStep();
      expect(cubit.state.currentStep, 2);
    });

    // TC-stp-3: nextStep at max step (3) does not exceed 3
    test('TC-stp-3: nextStep() at step 3 does not emit new state', () {
      cubit.goToStep(3);
      final stateBeforeExtra = cubit.state;
      cubit.nextStep();
      expect(cubit.state.currentStep, 3);
      expect(identical(cubit.state, stateBeforeExtra), isTrue);
    });

    // TC-stp-4: prevStep at step 0 does nothing
    test('TC-stp-4: prevStep() at step 0 does not emit new state', () {
      expect(cubit.state.currentStep, 0);
      final stateBeforeExtra = cubit.state;
      cubit.prevStep();
      expect(cubit.state.currentStep, 0);
      expect(identical(cubit.state, stateBeforeExtra), isTrue);
    });

    // TC-stp-5: prevStep decrements step
    test('TC-stp-5: prevStep() decrements currentStep', () {
      cubit.goToStep(2);
      cubit.prevStep();
      expect(cubit.state.currentStep, 1);
      cubit.prevStep();
      expect(cubit.state.currentStep, 0);
    });

    // TC-stp-6: goToStep navigates directly
    test('TC-stp-6: goToStep() emits correct step', () {
      cubit.goToStep(2);
      expect(cubit.state.currentStep, 2);
      cubit.goToStep(0);
      expect(cubit.state.currentStep, 0);
    });

    // TC-stp-7: goToStep asserts valid range
    test('TC-stp-7: goToStep() asserts 0..3', () {
      expect(() => cubit.goToStep(-1), throwsAssertionError);
      expect(() => cubit.goToStep(4), throwsAssertionError);
    });

    // TC-stp-8: stepFields cardinality
    test('TC-stp-8: _step1Fields.length == 5, _step2Fields.length == 7, _step3Fields.length == 2', () {
      expect(EventFormCubit.stepFields[0]!.length, 5);
      expect(EventFormCubit.stepFields[1]!.length, 7);
      expect(EventFormCubit.stepFields[2]!.length, 2);
    });

    // TC-stp-9: validateStep returns true when no form is attached (formKey.currentState == null)
    test('TC-stp-9: validateStep returns true when formKey.currentState is null', () {
      expect(cubit.validateStep(0), isTrue);
      expect(cubit.validateStep(1), isTrue);
      expect(cubit.validateStep(2), isTrue);
    });

    // TC-stp-10: isCurrentStepValid delegates to validateStep(currentStep)
    test('TC-stp-10: isCurrentStepValid() delegates to validateStep(currentStep)', () {
      cubit.goToStep(1);
      // formKey not attached, so validate returns true
      expect(cubit.isCurrentStepValid(), isTrue);
    });

    // TC-stp-11: stepFields for step 0 contains exactly the 5 expected field names
    test('TC-stp-11: step 0 fields are correct', () {
      expect(EventFormCubit.stepFields[0], containsAll([
        EventFormFields.name,
        EventFormFields.description,
        EventFormFields.dateRange,
        EventFormFields.isMultiDay,
        EventFormFields.meetingTime,
      ]));
    });

    // TC-stp-12: stepFields for step 1 contains exactly the 7 expected field names
    test('TC-stp-12: step 1 fields are correct', () {
      expect(EventFormCubit.stepFields[1], containsAll([
        EventFormFields.difficulty,
        EventFormFields.eventType,
        EventFormFields.price,
        EventFormFields.isFreeEvent,
        EventFormFields.maxParticipants,
        EventFormFields.isMultiBrand,
        EventFormFields.allowedBrands,
      ]));
    });

    // TC-stp-13: step navigation preserves other state fields
    test('TC-stp-13: nextStep preserves waypoints and routeType', () {
      cubit.initialize();
      cubit.addWaypoint('Bogotá');
      cubit.nextStep();
      expect(cubit.state.waypoints, ['Bogotá']);
      expect(cubit.state.routeType, RouteType.simple);
    });

    // TC-stp-14: full round-trip navigation
    test('TC-stp-14: full round-trip 0→1→2→3→2→1→0', () {
      cubit.nextStep(); expect(cubit.state.currentStep, 1);
      cubit.nextStep(); expect(cubit.state.currentStep, 2);
      cubit.nextStep(); expect(cubit.state.currentStep, 3);
      cubit.prevStep(); expect(cubit.state.currentStep, 2);
      cubit.prevStep(); expect(cubit.state.currentStep, 1);
      cubit.prevStep(); expect(cubit.state.currentStep, 0);
    });
  });
}
