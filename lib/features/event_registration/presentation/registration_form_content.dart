import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/event_registration/constants/registration_form_fields.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/presentation/cubit/registration_form_cubit.dart';
import 'package:rideglory/features/event_registration/presentation/my_registrations_cubit.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/medical_consent_sheet.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_waiver_sheet.dart';
import 'package:rideglory/features/event_registration/presentation/wizard/registration_step_indicator.dart';
import 'package:rideglory/features/event_registration/presentation/wizard/registration_wizard_controller.dart';
import 'package:rideglory/features/event_registration/presentation/wizard/registration_wizard_navigation_bar.dart';
import 'package:rideglory/features/event_registration/presentation/wizard/steps/registration_emergency_step.dart';
import 'package:rideglory/features/event_registration/presentation/wizard/steps/registration_medical_step.dart';
import 'package:rideglory/features/event_registration/presentation/wizard/steps/registration_personal_step.dart';
import 'package:rideglory/features/event_registration/presentation/wizard/steps/registration_vehicle_step.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/form/form_focus_chain.dart';

const _registrationFocusChainFields = <String>[
  RegistrationFormFields.fullName,
  RegistrationFormFields.identificationNumber,
  RegistrationFormFields.phone,
  RegistrationFormFields.email,
  RegistrationFormFields.residenceCity,
  RegistrationFormFields.eps,
  RegistrationFormFields.medicalInsurance,
  RegistrationFormFields.bloodType,
  RegistrationFormFields.emergencyContactName,
  RegistrationFormFields.emergencyContactPhone,
];

/// Multi-step registration wizard. Keeps every step mounted (via [IndexedStack])
/// so the single shared [FormBuilder] retains all field values across steps and
/// the submit flow can validate the whole form at once.
class RegistrationFormContent extends StatefulWidget {
  final EventModel event;

  const RegistrationFormContent({super.key, required this.event});

  @override
  State<RegistrationFormContent> createState() =>
      _RegistrationFormContentState();
}

class _RegistrationFormContentState extends State<RegistrationFormContent> {
  late final FormFocusChain _focusChain = FormFocusChain(
    _registrationFocusChainFields,
  );

  late final RegistrationWizardController _wizard =
      RegistrationWizardController(
        stepCount: RegistrationWizardSteps.stepCount,
      );

  final ScrollController _scrollController = ScrollController();

  /// Blocks double-tap on "Siguiente" while the medical-consent gate sheet is
  /// open (the `await` for the modal result is in flight).
  bool _isCheckingConsent = false;

  /// Returns the scroll view to the top so each step starts from the header
  /// instead of inheriting the previous step's scroll offset.
  void _resetScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  /// Returns the canonical step name for analytics given a 0-based [stepIndex].
  static String _stepNameFor(int stepIndex) {
    const names = [
      AnalyticsParams.stepNamePersonal,
      AnalyticsParams.stepNameMedical,
      AnalyticsParams.stepNameEmergency,
      AnalyticsParams.stepNameVehicle,
    ];
    if (stepIndex < 0 || stepIndex >= names.length) return 'unknown';
    return names[stepIndex];
  }

  @override
  void initState() {
    super.initState();
    // Si los vehículos aún no se han cargado (el usuario llegó directo sin
    // pasar por el garaje), disparar el fetch para que el selector no quede
    // en spinner infinito.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VehicleCubit>().state.maybeWhen(
        initial: () => context.read<VehicleCubit>().fetchMyVehicles(),
        orElse: () {},
      );
      context.read<RegistrationFormCubit>().onWizardStarted();
    });
  }

  @override
  void dispose() {
    _wizard.dispose();
    _focusChain.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openCreateVehicle() async {
    final savedVehicle = await context.pushNamed<VehicleModel>(
      AppRoutes.createVehicle,
    );
    if (!mounted || savedVehicle == null) {
      return;
    }
    context
        .read<RegistrationFormCubit>()
        .formKey
        .currentState
        ?.fields[RegistrationFormFields.vehicleId]
        ?.didChange(savedVehicle.id);
  }

  Future<void> _onNext() async {
    if (_isCheckingConsent) return;
    FocusScope.of(context).unfocus();
    final stepFields =
        RegistrationWizardSteps.fieldsByStep[_wizard.currentStep];
    final cubit = context.read<RegistrationFormCubit>();
    final isStepValid = cubit.validateStepFields(stepFields);
    if (!isStepValid) return;

    // La autorización Ley 1581 se pide al salir del paso Médico (índice 1),
    // donde el rider ingresó sus datos médicos — no en el paso Personal. El
    // consentimiento es por inscripción: si ya se autorizó para esta
    // inscripción (o venía de una existente en edición) no se vuelve a pedir.
    if (_wizard.currentStep == 1 && cubit.medicalConsentAcceptedAt == null) {
      setState(() => _isCheckingConsent = true);
      final acceptedAt = await showMedicalConsentSheet(context: context);
      if (!mounted) return;
      setState(() => _isCheckingConsent = false);
      if (acceptedAt == null) return;
      cubit.acceptMedicalConsent(acceptedAt);
    }

    _wizard.next();
    final nextIndex = _wizard.currentStep;
    cubit.onStepAdvanced(nextIndex, _stepNameFor(nextIndex));
    _resetScroll();
  }

  void _onBack() {
    FocusScope.of(context).unfocus();
    _wizard.previous();
    final prevIndex = _wizard.currentStep;
    context.read<RegistrationFormCubit>().onStepBack(
      prevIndex,
      _stepNameFor(prevIndex),
    );
    _resetScroll();
  }

  /// Final wizard action: validates the selected vehicle's brand, then opens
  /// the risk-waiver sheet. Acceptance + submission happen inside the sheet,
  /// which resolves to the saved registration on success. On success this
  /// notifies [MyRegistrationsCubit], surfaces the confirmation and closes
  /// the page returning the saved model.
  Future<void> _onFinishPressed() async {
    FocusScope.of(context).unfocus();
    final cubit = context.read<RegistrationFormCubit>();
    // Valida los campos del último paso (p. ej. que haya un vehículo
    // seleccionado) antes de abrir el waiver sheet.
    final stepFields =
        RegistrationWizardSteps.fieldsByStep[_wizard.currentStep];
    if (!cubit.validateStepFields(stepFields)) return;
    if (!_isSelectedVehicleBrandAllowed()) return;

    final saved = await showRegistrationWaiverSheet(
      context: context,
      event: widget.event,
    );
    if (!mounted || saved == null) return;

    context.read<MyRegistrationsCubit>().onChangeRegistration(saved);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          cubit.isEditing
              ? context.l10n.registration_registrationUpdatedSuccess
              : context.l10n.registration_registrationSentSuccess,
        ),
        backgroundColor: AppColors.success,
      ),
    );
    context.pop(saved);
  }

  /// Returns false (after warning the rider) when the selected vehicle's brand
  /// is not in the event's allow-list. A missing/unknown vehicle is treated as
  /// allowed here; the server remains the source of truth.
  bool _isSelectedVehicleBrandAllowed() {
    final cubit = context.read<RegistrationFormCubit>();
    final selectedVehicleId =
        cubit
                .formKey
                .currentState
                ?.fields[RegistrationFormFields.vehicleId]
                ?.value
            as String?;

    final availableBrands = widget.event.allowedBrands
        .map((brand) => brand.trim())
        .where((brand) => brand.isNotEmpty && brand != '*')
        .toList();

    if (selectedVehicleId == null || availableBrands.isEmpty) return true;

    VehicleModel? vehicle;
    for (final currentVehicle
        in context.read<VehicleCubit>().availableVehicles) {
      if (currentVehicle.id == selectedVehicleId) {
        vehicle = currentVehicle;
        break;
      }
    }
    if (vehicle == null) return true;

    final selectedBrand = (vehicle.brand ?? '').trim().toLowerCase();
    final isAllowed = availableBrands
        .map((brand) => brand.toLowerCase())
        .contains(selectedBrand);
    if (!isAllowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${context.l10n.registration_vehicleBrandNotAllowed}: ${availableBrands.join(', ')}',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    }
    return isAllowed;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RegistrationFormCubit>();

    return ListenableBuilder(
      listenable: _wizard,
      builder: (context, _) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: RegistrationStepIndicator(
                stepCount: _wizard.stepCount,
                currentStep: _wizard.currentStep,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: IndexedStack(
                  index: _wizard.currentStep,
                  sizing: StackFit.loose,
                  children: [
                    RegistrationPersonalStep(focusChain: _focusChain),
                    RegistrationMedicalStep(focusChain: _focusChain),
                    RegistrationEmergencyStep(focusChain: _focusChain),
                    RegistrationVehicleStep(
                      onCreateVehicle: _openCreateVehicle,
                    ),
                  ],
                ),
              ),
            ),
            BlocBuilder<
              RegistrationFormCubit,
              ResultState<EventRegistrationModel>
            >(
              builder: (context, state) {
                return RegistrationWizardNavigationBar(
                  isFirstStep: _wizard.isFirstStep,
                  isLastStep: _wizard.isLastStep,
                  isEditing: cubit.isEditing,
                  isLoading: state is Loading || _isCheckingConsent,
                  onBack: _onBack,
                  onNext: _onNext,
                  onSubmit: _onFinishPressed,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
