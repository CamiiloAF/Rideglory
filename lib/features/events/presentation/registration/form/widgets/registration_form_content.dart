import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/constants/app_strings.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/constants/registration_form_fields.dart';
import 'package:rideglory/features/events/constants/registration_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/registration/form/cubit/registration_form_cubit.dart';
import 'package:rideglory/features/events/presentation/registration/form/widgets/registration_form_section_card.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';
import 'package:rideglory/shared/widgets/form/app_city_autocomplete.dart';
import 'package:rideglory/shared/widgets/form/app_date_picker.dart';
import 'package:rideglory/shared/widgets/form/app_dropdown.dart';
import 'package:rideglory/shared/widgets/form/app_text_button.dart';
import 'package:rideglory/shared/widgets/form/app_text_field.dart';
import 'package:rideglory/shared/widgets/vehicle_selection_bottom_sheet.dart';

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
      subtitle: RegistrationStrings.selectVehicleToPreload,
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
          title: RegistrationStrings.personalData,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                name: RegistrationFormFields.firstName,
                labelText: RegistrationStrings.firstName,
                hintText: RegistrationStrings.firstNameHint,
                isRequired: true,
                textCapitalization: TextCapitalization.words,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: RegistrationStrings.firstNameRequired,
                  ),
                  FormBuilderValidators.minLength(
                    2,
                    errorText: RegistrationStrings.minCharacters,
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              AppTextField(
                name: RegistrationFormFields.lastName,
                labelText: RegistrationStrings.lastName,
                hintText: RegistrationStrings.lastNameHint,
                isRequired: true,
                textCapitalization: TextCapitalization.words,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: RegistrationStrings.lastNameRequired,
                  ),
                  FormBuilderValidators.minLength(
                    2,
                    errorText: RegistrationStrings.minCharacters,
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      name: RegistrationFormFields.identificationNumber,
                      labelText: RegistrationStrings.identificationNumber,
                      hintText: RegistrationStrings.identificationHint,
                      isRequired: true,
                      keyboardType: TextInputType.number,
                      maxLength: 10,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(
                          errorText: RegistrationStrings.idRequired,
                        ),
                        FormBuilderValidators.numeric(
                          errorText: RegistrationStrings.idInvalidLength,
                        ),
                        FormBuilderValidators.minLength(
                          6,
                          errorText: RegistrationStrings.idInvalidLength,
                        ),
                        FormBuilderValidators.maxLength(
                          10,
                          errorText: RegistrationStrings.idInvalidLength,
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppDatePicker(
                      fieldName: RegistrationFormFields.birthDate,
                      labelText: RegistrationStrings.birthDate,
                      isRequired: true,
                      lastDate: DateTime.now(),
                      hintText: RegistrationStrings.birthDateHint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(
                name: RegistrationFormFields.phone,
                labelText: RegistrationStrings.phone,
                hintText: RegistrationStrings.phoneHint,
                isRequired: true,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: RegistrationStrings.phoneRequired,
                  ),
                  FormBuilderValidators.numeric(
                    errorText: RegistrationStrings.phoneInvalidLength,
                  ),
                  FormBuilderValidators.minLength(
                    10,
                    errorText: RegistrationStrings.phoneInvalidLength,
                  ),
                  FormBuilderValidators.maxLength(
                    10,
                    errorText: RegistrationStrings.phoneInvalidLength,
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              AppCityAutocomplete(
                name: RegistrationFormFields.residenceCity,
                labelText: RegistrationStrings.residenceCity,
                hintText: RegistrationStrings.residenceCityHint,
                isRequired: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return RegistrationStrings.residenceCityRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                name: RegistrationFormFields.email,
                labelText: RegistrationStrings.email,
                hintText: RegistrationStrings.emailHint,
                isRequired: true,
                keyboardType: TextInputType.emailAddress,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: RegistrationStrings.emailRequired,
                  ),
                  FormBuilderValidators.email(
                    errorText: RegistrationStrings.emailInvalid,
                  ),
                ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        RegistrationFormSectionCard(
          icon: Icons.medical_services_outlined,
          title: RegistrationStrings.medicalInfo,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      name: RegistrationFormFields.eps,
                      labelText: RegistrationStrings.eps,
                      hintText: RegistrationStrings.epsHint,
                      isRequired: true,
                      textCapitalization: TextCapitalization.words,
                      validator: FormBuilderValidators.required(
                        errorText: RegistrationStrings.epsRequired,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppDropdown<BloodType>(
                      name: RegistrationFormFields.bloodType,
                      labelText: RegistrationStrings.bloodType,
                      hintText: RegistrationStrings.bloodTypeHint,
                      isRequired: true,
                      validator: FormBuilderValidators.required(
                        errorText: RegistrationStrings.bloodTypeRequired,
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
              const SizedBox(height: 12),
              AppTextField(
                name: RegistrationFormFields.medicalInsurance,
                labelText: RegistrationStrings.medicalInsurance,
                hintText: RegistrationStrings.medicalInsuranceHint,
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        RegistrationFormSectionCard(
          icon: Icons.phone_outlined,
          title: RegistrationStrings.emergencyContactRequired,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                name: RegistrationFormFields.emergencyContactName,
                labelText: RegistrationStrings.emergencyContactName,
                hintText: RegistrationStrings.emergencyContactNameHint,
                isRequired: true,
                textCapitalization: TextCapitalization.words,
                validator: FormBuilderValidators.required(
                  errorText: RegistrationStrings.emergencyContactNameRequired,
                ),
              ),
              const SizedBox(height: 12),
              AppTextField(
                name: RegistrationFormFields.emergencyContactPhone,
                labelText: RegistrationStrings.emergencyContactPhone,
                hintText: RegistrationStrings.emergencyContactPhoneHint,
                isRequired: true,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                    errorText: RegistrationStrings.emergencyContactPhoneRequired,
                  ),
                  FormBuilderValidators.numeric(
                    errorText:
                        RegistrationStrings.emergencyContactPhoneInvalidLength,
                  ),
                  FormBuilderValidators.minLength(
                    10,
                    errorText:
                        RegistrationStrings.emergencyContactPhoneInvalidLength,
                  ),
                  FormBuilderValidators.maxLength(
                    10,
                    errorText:
                        RegistrationStrings.emergencyContactPhoneInvalidLength,
                  ),
                ]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        RegistrationFormSectionCard(
          icon: Icons.two_wheeler_outlined,
          title: RegistrationStrings.vehicleData,
          trailing: AppTextButton(
            label: RegistrationStrings.preloadFromVehicle,
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
                      labelText: RegistrationStrings.vehicleBrand,
                      hintText: RegistrationStrings.vehicleBrandHint,
                      isRequired: true,
                      textCapitalization: TextCapitalization.words,
                      validator: FormBuilderValidators.required(
                        errorText: RegistrationStrings.vehicleBrandRequired,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      name: RegistrationFormFields.vehicleReference,
                      labelText: RegistrationStrings.vehicleReference,
                      hintText: RegistrationStrings.vehicleReferenceHint,
                      isRequired: true,
                      textCapitalization: TextCapitalization.words,
                      validator: FormBuilderValidators.required(
                        errorText: RegistrationStrings.vehicleReferenceRequired,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      name: RegistrationFormFields.licensePlate,
                      labelText: RegistrationStrings.licensePlate,
                      hintText: RegistrationStrings.licensePlateHint,
                      isRequired: true,
                      textCapitalization: TextCapitalization.characters,
                      validator: FormBuilderValidators.required(
                        errorText: RegistrationStrings.licensePlateRequired,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      name: RegistrationFormFields.vin,
                      labelText: RegistrationStrings.vin,
                      hintText: RegistrationStrings.vinHint,
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        BlocBuilder<RegistrationFormCubit, ResultState<EventRegistrationModel>>(
          builder: (context, state) {
            final isLoading = state is Loading;
            final isEditing = cubit.isEditing;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppButton(
                  label: isEditing
                      ? RegistrationStrings.updateRegistration
                      : RegistrationStrings.sendRegistration,
                  onPressed: isLoading ? null : cubit.saveRegistration,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 12),
                AppTextButton(
                  label: AppStrings.cancel,
                  onPressed: () => context.pop(),
                  variant: AppTextButtonVariant.muted,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
