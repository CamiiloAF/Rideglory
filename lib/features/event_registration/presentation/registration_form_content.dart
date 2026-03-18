import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/event_registration/constants/registration_form_fields.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/presentation/cubit/registration_form_cubit.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_form_section_card.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class RegistrationFormContent extends StatelessWidget {
  final EventModel event;

  const RegistrationFormContent({super.key, required this.event});

  Future<void> _preloadFromVehicle(BuildContext context) async {
    final cubit = context.read<RegistrationFormCubit>();
    final vehicles = context
        .read<VehicleCubit>()
        .availableVehicles
        .where((v) => !v.isArchived)
        .toList();
    if (vehicles.isEmpty) return;
    final selected = await VehicleSelectionBottomSheet.show(
      context: context,
      subtitle: context.l10n.registration_selectVehicleToPreload,
      vehicles: vehicles,
    );
    if (selected != null && context.mounted) {
      cubit.preloadFromVehicle(selected);
    }
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
                name: RegistrationFormFields.firstName,
                labelText: context.l10n.registration_firstName,
                hintText: context.l10n.registration_firstNameHint,
                isRequired: true,
                textCapitalization: TextCapitalization.words,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: context.l10n.registration_firstNameRequired,
                  ),
                  FormBuilderValidators.minLength(
                    2,
                    errorText: context.l10n.registration_minCharacters,
                  ),
                ]),
              ),
              SizedBox(height: 12),
              AppTextField(
                name: RegistrationFormFields.lastName,
                labelText: context.l10n.registration_lastName,
                hintText: context.l10n.registration_lastNameHint,
                isRequired: true,
                textCapitalization: TextCapitalization.words,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: context.l10n.registration_lastNameRequired,
                  ),
                  FormBuilderValidators.minLength(
                    2,
                    errorText: context.l10n.registration_minCharacters,
                  ),
                ]),
              ),
              SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      name: RegistrationFormFields.identificationNumber,
                      labelText: context.l10n.registration_identificationNumber,
                      hintText: context.l10n.registration_identificationHint,
                      isRequired: true,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
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
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: AppDatePicker(
                      fieldName: RegistrationFormFields.birthDate,
                      labelText: context.l10n.registration_birthDate,
                      isRequired: true,
                      lastDate: DateTime.now(),
                      hintText: context.l10n.registration_birthDateHint,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              AppTextField(
                name: RegistrationFormFields.phone,
                labelText: context.l10n.registration_phone,
                hintText: context.l10n.registration_phoneHint,
                isRequired: true,
                keyboardType: TextInputType.phone,
                maxLength: 10,
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
              SizedBox(height: 12),
              AppCityAutocomplete(
                name: RegistrationFormFields.residenceCity,
                labelText: context.l10n.registration_residenceCity,
                hintText: context.l10n.registration_residenceCityHint,
                isRequired: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return context.l10n.registration_residenceCityRequired;
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              AppTextField(
                name: RegistrationFormFields.email,
                labelText: context.l10n.registration_email,
                hintText: context.l10n.registration_emailHint,
                isRequired: true,
                keyboardType: TextInputType.emailAddress,
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
        SizedBox(height: 24),
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
                      validator: FormBuilderValidators.required(
                        errorText: context.l10n.registration_epsRequired,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: AppDropdown<BloodType>(
                      name: RegistrationFormFields.bloodType,
                      labelText: context.l10n.registration_bloodType,
                      hintText: context.l10n.registration_bloodTypeHint,
                      isRequired: true,
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
              SizedBox(height: 12),
              AppTextField(
                name: RegistrationFormFields.medicalInsurance,
                labelText: context.l10n.registration_medicalInsurance,
                hintText: context.l10n.registration_medicalInsuranceHint,
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
        ),
        SizedBox(height: 24),
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
                validator: FormBuilderValidators.required(
                  errorText: context.l10n.registration_emergencyContactNameRequired,
                ),
              ),
              SizedBox(height: 12),
              AppTextField(
                name: RegistrationFormFields.emergencyContactPhone,
                labelText: context.l10n.registration_emergencyContactPhone,
                hintText: context.l10n.registration_emergencyContactPhoneHint,
                isRequired: true,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: context.l10n.registration_emergencyContactPhoneRequired,
                  ),
                  FormBuilderValidators.numeric(
                    errorText:
                        context.l10n.registration_emergencyContactPhoneInvalidLength,
                  ),
                  FormBuilderValidators.minLength(
                    10,
                    errorText:
                        context.l10n.registration_emergencyContactPhoneInvalidLength,
                  ),
                  FormBuilderValidators.maxLength(
                    10,
                    errorText:
                        context.l10n.registration_emergencyContactPhoneInvalidLength,
                  ),
                ]),
              ),
            ],
          ),
        ),
        SizedBox(height: 24),
        RegistrationFormSectionCard(
          icon: Icons.two_wheeler_outlined,
          title: context.l10n.registration_vehicleData,
          trailing: AppTextButton(
            label: context.l10n.registration_preloadFromVehicle,
            onPressed: () => _preloadFromVehicle(context),
            icon: Icons.motorcycle_rounded,
            iconSize: 16,
            visualDensity: VisualDensity.compact,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      name: RegistrationFormFields.vehicleBrand,
                      labelText: context.l10n.registration_vehicleBrand,
                      hintText: context.l10n.registration_vehicleBrandHint,
                      isRequired: true,
                      textCapitalization: TextCapitalization.words,
                      validator: FormBuilderValidators.required(
                        errorText: context.l10n.registration_vehicleBrandRequired,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      name: RegistrationFormFields.vehicleReference,
                      labelText: context.l10n.registration_vehicleReference,
                      hintText: context.l10n.registration_vehicleReferenceHint,
                      isRequired: true,
                      textCapitalization: TextCapitalization.words,
                      validator: FormBuilderValidators.required(
                        errorText: context.l10n.registration_vehicleReferenceRequired,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      name: RegistrationFormFields.licensePlate,
                      labelText: context.l10n.registration_licensePlate,
                      hintText: context.l10n.registration_licensePlateHint,
                      isRequired: true,
                      textCapitalization: TextCapitalization.characters,
                      validator: FormBuilderValidators.required(
                        errorText: context.l10n.registration_licensePlateRequired,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      name: RegistrationFormFields.vin,
                      labelText: context.l10n.registration_vin,
                      hintText: context.l10n.registration_vinHint,
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 32),
        BlocBuilder<RegistrationFormCubit, ResultState<EventRegistrationModel>>(
          builder: (context, state) {
            final isLoading = state is Loading;
            final isEditing = cubit.isEditing;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppButton(
                  label: isEditing
                      ? context.l10n.registration_updateRegistration
                      : context.l10n.registration_sendRegistration,
                  onPressed: isLoading ? null : cubit.saveRegistration,
                  isLoading: isLoading,
                ),
                SizedBox(height: 12),
                AppTextButton(
                  label: context.l10n.cancel,
                  onPressed: () => context.pop(),
                  variant: AppTextButtonVariant.muted,
                ),
              ],
            );
          },
        ),
        SizedBox(height: 32),
      ],
    );
  }
}
