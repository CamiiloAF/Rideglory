import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/event_registration/constants/registration_form_fields.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/presentation/cubit/registration_form_cubit.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_form_section_card.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/save_to_profile_checkbox.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/vehicle_selector_empty.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/vehicle_selector_field.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/vehicle_selector_loading.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/shared/widgets/form/form_focus_chain.dart';

const _registrationFocusChainFields = <String>[
  RegistrationFormFields.fullName,
  RegistrationFormFields.identificationNumber,
  RegistrationFormFields.phone,
  RegistrationFormFields.residenceCity,
  RegistrationFormFields.email,
  RegistrationFormFields.eps,
  RegistrationFormFields.bloodType,
  RegistrationFormFields.medicalInsurance,
  RegistrationFormFields.emergencyContactName,
  RegistrationFormFields.emergencyContactPhone,
];

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
    });
  }

  @override
  void dispose() {
    _focusChain.dispose();
    super.dispose();
  }

  Future<void> _openCreateVehicle(BuildContext context) async {
    final savedVehicle = await context.pushNamed<VehicleModel>(
      AppRoutes.createVehicle,
    );
    if (!context.mounted || savedVehicle == null) {
      return;
    }
    context
        .read<RegistrationFormCubit>()
        .formKey
        .currentState
        ?.fields[RegistrationFormFields.vehicleId]
        ?.didChange(savedVehicle.id);
  }

  void _submitRegistration() {
    final selectedVehicleId =
        context
                .read<RegistrationFormCubit>()
                .formKey
                .currentState
                ?.fields[RegistrationFormFields.vehicleId]
                ?.value
            as String?;

    final availableBrands = widget.event.allowedBrands
        .map((brand) => brand.trim())
        .where((brand) => brand.isNotEmpty && brand != '*')
        .toList();

    if (selectedVehicleId != null && availableBrands.isNotEmpty) {
      VehicleModel? vehicle;
      for (final currentVehicle
          in context.read<VehicleCubit>().availableVehicles) {
        if (currentVehicle.id == selectedVehicleId) {
          vehicle = currentVehicle;
          break;
        }
      }
      if (vehicle == null) {
        context.read<RegistrationFormCubit>().saveRegistration();
        return;
      }
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
        return;
      }
    }

    context.read<RegistrationFormCubit>().saveRegistration();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RegistrationFormCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RegistrationFormSectionCard(
          icon: Icons.person_outline,
          title: context.l10n.registration_personalData,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                name: RegistrationFormFields.fullName,
                labelText: context.l10n.registration_fullName,
                hintText: context.l10n.registration_fullNameHint,
                isRequired: true,
                textCapitalization: TextCapitalization.words,
                focusNode: _focusChain.nodeFor(RegistrationFormFields.fullName),
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _focusChain.requestNextAfter(
                  RegistrationFormFields.fullName,
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: context.l10n.registration_fullNameRequired,
                  ),
                  FormBuilderValidators.minLength(
                    2,
                    errorText: context.l10n.registration_minCharacters,
                  ),
                ]),
              ),
              AppSpacing.gapMd,
              AppTextField(
                name: RegistrationFormFields.identificationNumber,
                labelText: context.l10n.registration_identificationNumber,
                hintText: context.l10n.registration_identificationHint,
                isRequired: true,
                keyboardType: TextInputType.number,
                maxLength: 10,
                focusNode: _focusChain.nodeFor(
                  RegistrationFormFields.identificationNumber,
                ),
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _focusChain.requestNextAfter(
                  RegistrationFormFields.identificationNumber,
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: context.l10n.registration_idRequired,
                  ),
                  FormBuilderValidators.numeric(
                    errorText: context.l10n.registration_idInvalidLength,
                  ),
                  FormBuilderValidators.minLength(
                    6,
                    errorText: context.l10n.registration_idInvalidLength,
                  ),
                  FormBuilderValidators.maxLength(
                    10,
                    errorText: context.l10n.registration_idInvalidLength,
                  ),
                ]),
              ),
              AppSpacing.gapMd,
              AppDatePicker(
                fieldName: RegistrationFormFields.birthDate,
                labelText: context.l10n.registration_birthDate,
                isRequired: true,
                lastDate: DateTime.now(),
                hintText: context.l10n.registration_birthDateHint,
                focusNode: _focusChain.nodeFor(
                  RegistrationFormFields.birthDate,
                ),
              ),
              AppSpacing.gapMd,
              AppTextField(
                name: RegistrationFormFields.phone,
                labelText: context.l10n.registration_phone,
                hintText: context.l10n.registration_phoneHint,
                isRequired: true,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                focusNode: _focusChain.nodeFor(RegistrationFormFields.phone),
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    _focusChain.requestNextAfter(RegistrationFormFields.phone),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: context.l10n.registration_phoneRequired,
                  ),
                  FormBuilderValidators.numeric(
                    errorText: context.l10n.registration_phoneInvalidLength,
                  ),
                  FormBuilderValidators.minLength(
                    10,
                    errorText: context.l10n.registration_phoneInvalidLength,
                  ),
                  FormBuilderValidators.maxLength(
                    10,
                    errorText: context.l10n.registration_phoneInvalidLength,
                  ),
                ]),
              ),
              AppSpacing.gapMd,
              AppCityAutocomplete(
                name: RegistrationFormFields.residenceCity,
                labelText: context.l10n.registration_residenceCity,
                hintText: context.l10n.registration_residenceCityHint,
                isRequired: true,
                focusNode: _focusChain.nodeFor(
                  RegistrationFormFields.residenceCity,
                ),
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _focusChain.requestNextAfter(
                  RegistrationFormFields.residenceCity,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.l10n.registration_residenceCityRequired;
                  }
                  return null;
                },
              ),
              AppSpacing.gapMd,
              AppTextField(
                name: RegistrationFormFields.email,
                labelText: context.l10n.registration_email,
                hintText: context.l10n.registration_emailHint,
                isRequired: true,
                keyboardType: TextInputType.emailAddress,
                focusNode: _focusChain.nodeFor(RegistrationFormFields.email),
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    _focusChain.requestNextAfter(RegistrationFormFields.email),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: context.l10n.registration_emailRequired,
                  ),
                  FormBuilderValidators.email(
                    errorText: context.l10n.registration_emailInvalid,
                  ),
                ]),
              ),
            ],
          ),
        ),
        AppSpacing.gapXxl,
        RegistrationFormSectionCard(
          icon: Icons.medical_services_outlined,
          title: context.l10n.registration_medicalInfo,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      name: RegistrationFormFields.eps,
                      labelText: context.l10n.registration_eps,
                      hintText: context.l10n.registration_epsHint,
                      isRequired: true,
                      textCapitalization: TextCapitalization.words,
                      focusNode: _focusChain.nodeFor(
                        RegistrationFormFields.eps,
                      ),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => _focusChain.requestNextAfter(
                        RegistrationFormFields.eps,
                      ),
                      validator: FormBuilderValidators.required(
                        errorText: context.l10n.registration_epsRequired,
                      ),
                    ),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: AppDropdown<BloodType>(
                      name: RegistrationFormFields.bloodType,
                      labelText: context.l10n.registration_bloodType,
                      hintText: context.l10n.registration_bloodTypeHint,
                      isRequired: true,
                      focusNode: _focusChain.nodeFor(
                        RegistrationFormFields.bloodType,
                      ),
                      validator: FormBuilderValidators.required(
                        errorText: context.l10n.registration_bloodTypeRequired,
                      ),
                      items: BloodType.values
                          .map(
                            (type) => DropdownMenuItem<BloodType>(
                              value: type,
                              child: Text(type.label),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
              AppSpacing.gapMd,
              AppTextField(
                name: RegistrationFormFields.medicalInsurance,
                labelText: context.l10n.registration_medicalInsurance,
                hintText: context.l10n.registration_medicalInsuranceHint,
                textCapitalization: TextCapitalization.words,
                focusNode: _focusChain.nodeFor(
                  RegistrationFormFields.medicalInsurance,
                ),
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _focusChain.requestNextAfter(
                  RegistrationFormFields.medicalInsurance,
                ),
              ),
            ],
          ),
        ),
        AppSpacing.gapXxl,
        RegistrationFormSectionCard(
          icon: Icons.phone_outlined,
          title: context.l10n.registration_emergencyContactRequired,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                name: RegistrationFormFields.emergencyContactName,
                labelText: context.l10n.registration_emergencyContactName,
                hintText: context.l10n.registration_emergencyContactNameHint,
                isRequired: true,
                textCapitalization: TextCapitalization.words,
                focusNode: _focusChain.nodeFor(
                  RegistrationFormFields.emergencyContactName,
                ),
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _focusChain.requestNextAfter(
                  RegistrationFormFields.emergencyContactName,
                ),
                validator: FormBuilderValidators.required(
                  errorText:
                      context.l10n.registration_emergencyContactNameRequired,
                ),
              ),
              AppSpacing.gapMd,
              AppTextField(
                name: RegistrationFormFields.emergencyContactPhone,
                labelText: context.l10n.registration_emergencyContactPhone,
                hintText: context.l10n.registration_emergencyContactPhoneHint,
                isRequired: true,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                focusNode: _focusChain.nodeFor(
                  RegistrationFormFields.emergencyContactPhone,
                ),
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _focusChain.requestNextAfter(
                  RegistrationFormFields.emergencyContactPhone,
                ),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText:
                        context.l10n.registration_emergencyContactPhoneRequired,
                  ),
                  FormBuilderValidators.numeric(
                    errorText: context
                        .l10n
                        .registration_emergencyContactPhoneInvalidLength,
                  ),
                  FormBuilderValidators.minLength(
                    10,
                    errorText: context
                        .l10n
                        .registration_emergencyContactPhoneInvalidLength,
                  ),
                  FormBuilderValidators.maxLength(
                    10,
                    errorText: context
                        .l10n
                        .registration_emergencyContactPhoneInvalidLength,
                  ),
                ]),
              ),
            ],
          ),
        ),
        AppSpacing.gapXxl,
        RegistrationFormSectionCard(
          icon: Icons.two_wheeler_outlined,
          title: context.l10n.registration_vehicleData,
          child: BlocBuilder<VehicleCubit, ResultState<List<VehicleModel>>>(
            builder: (context, state) {
              return state.when(
                initial: () => const VehicleSelectorLoading(),
                loading: () => const VehicleSelectorLoading(),
                data: (vehicles) {
                  final available =
                      vehicles.where((vehicle) => !vehicle.isArchived).toList();
                  if (available.isEmpty) {
                    return VehicleSelectorEmpty(
                      onCreate: () => _openCreateVehicle(context),
                    );
                  }
                  return VehicleSelectorField(availableVehicles: available);
                },
                empty: () => VehicleSelectorEmpty(
                  onCreate: () => _openCreateVehicle(context),
                ),
                error: (_) => VehicleSelectorEmpty(
                  onCreate: () => _openCreateVehicle(context),
                ),
              );
            },
          ),
        ),
        AppSpacing.gapXxxl,
        BlocBuilder<RegistrationFormCubit, ResultState<EventRegistrationModel>>(
          builder: (context, state) {
            final isLoading = state is Loading;
            final isEditing = cubit.isEditing;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!cubit.isPreloadedFromProfile) ...[
                  const SaveToProfileCheckbox(),
                  AppSpacing.gapMd,
                ],
                AppButton(
                  label: isEditing
                      ? context.l10n.registration_updateRegistration
                      : context.l10n.registration_sendRegistration,
                  onPressed: _submitRegistration,
                  isLoading: isLoading,
                ),
                AppSpacing.gapMd,
                AppTextButton(
                  label: context.l10n.cancel,
                  onPressed: () => context.pop(),
                  variant: AppTextButtonVariant.muted,
                ),
              ],
            );
          },
        ),
        AppSpacing.gapXxxl,
      ],
    );
  }
}
