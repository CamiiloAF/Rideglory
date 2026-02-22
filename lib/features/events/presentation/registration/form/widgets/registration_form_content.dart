import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/features/events/constants/registration_form_fields.dart';
import 'package:rideglory/features/events/constants/registration_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/registration/form/cubit/registration_form_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/list/cubit/vehicle_list_cubit.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';
import 'package:rideglory/shared/widgets/form/app_text_button.dart';
import 'package:rideglory/shared/widgets/form/form_section_header.dart';
import 'package:rideglory/shared/widgets/vehicle_selection_bottom_sheet.dart';

class RegistrationFormContent extends StatelessWidget {
  final EventModel event;

  const RegistrationFormContent({super.key, required this.event});

  Future<void> _preloadFromVehicle(BuildContext context) async {
    final cubit = context.read<RegistrationFormCubit>();
    final vehicles = context.read<VehicleListCubit>().activeVehicles;
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

  void _clearForm(BuildContext context) {
    context.read<RegistrationFormCubit>().formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RegistrationFormCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: AppTextButton(
            label: RegistrationStrings.clearForm,
            onPressed: () => _clearForm(context),
            icon: Icons.clear_all_rounded,
            variant: AppTextButtonVariant.muted,
          ),
        ),
        const SizedBox(height: 4),
        FormSectionHeader(title: RegistrationStrings.personalInfo),
        const SizedBox(height: 12),
        FormBuilderTextField(
          name: RegistrationFormFields.firstName,
          decoration: InputDecoration(labelText: RegistrationStrings.firstName),
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
        FormBuilderTextField(
          name: RegistrationFormFields.lastName,
          decoration: InputDecoration(labelText: RegistrationStrings.lastName),
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
        FormBuilderTextField(
          name: RegistrationFormFields.identificationNumber,
          decoration: InputDecoration(
            labelText: RegistrationStrings.identificationNumber,
          ),
          keyboardType: TextInputType.number,
          validator: FormBuilderValidators.required(
            errorText: RegistrationStrings.idRequired,
          ),
        ),
        const SizedBox(height: 12),
        FormBuilderDateTimePicker(
          name: RegistrationFormFields.birthDate,
          inputType: InputType.date,
          decoration: InputDecoration(labelText: RegistrationStrings.birthDate),
          lastDate: DateTime.now(),
          validator: FormBuilderValidators.required(
            errorText: RegistrationStrings.birthDateRequired,
          ),
        ),
        const SizedBox(height: 12),
        FormBuilderTextField(
          name: RegistrationFormFields.phone,
          decoration: InputDecoration(labelText: RegistrationStrings.phone),
          keyboardType: TextInputType.phone,
          validator: FormBuilderValidators.required(
            errorText: RegistrationStrings.phoneRequired,
          ),
        ),
        const SizedBox(height: 12),
        FormBuilderTextField(
          name: RegistrationFormFields.email,
          decoration: InputDecoration(labelText: RegistrationStrings.email),
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
        const SizedBox(height: 12),
        FormBuilderTextField(
          name: RegistrationFormFields.residenceCity,
          decoration: InputDecoration(
            labelText: RegistrationStrings.residenceCity,
          ),
          textCapitalization: TextCapitalization.words,
          validator: FormBuilderValidators.required(
            errorText: RegistrationStrings.residenceCityRequired,
          ),
        ),
        const SizedBox(height: 24),
        FormSectionHeader(title: RegistrationStrings.medicalInfo),
        const SizedBox(height: 12),
        FormBuilderTextField(
          name: RegistrationFormFields.eps,
          decoration: InputDecoration(labelText: RegistrationStrings.eps),
          textCapitalization: TextCapitalization.words,
          validator: FormBuilderValidators.required(
            errorText: RegistrationStrings.epsRequired,
          ),
        ),
        const SizedBox(height: 12),
        FormBuilderTextField(
          name: RegistrationFormFields.medicalInsurance,
          decoration: InputDecoration(
            labelText: RegistrationStrings.medicalInsurance,
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 12),
        FormBuilderDropdown<BloodType>(
          name: RegistrationFormFields.bloodType,
          decoration: InputDecoration(labelText: RegistrationStrings.bloodType),
          items: BloodType.values
              .map(
                (type) =>
                    DropdownMenuItem(value: type, child: Text(type.label)),
              )
              .toList(),
          validator: FormBuilderValidators.required(
            errorText: RegistrationStrings.bloodTypeRequired,
          ),
        ),
        const SizedBox(height: 24),
        FormSectionHeader(title: RegistrationStrings.emergencyContact),
        const SizedBox(height: 12),
        FormBuilderTextField(
          name: RegistrationFormFields.emergencyContactName,
          decoration: InputDecoration(
            labelText: RegistrationStrings.emergencyContactName,
          ),
          textCapitalization: TextCapitalization.words,
          validator: FormBuilderValidators.required(
            errorText: RegistrationStrings.emergencyContactNameRequired,
          ),
        ),
        const SizedBox(height: 12),
        FormBuilderTextField(
          name: RegistrationFormFields.emergencyContactPhone,
          decoration: InputDecoration(
            labelText: RegistrationStrings.emergencyContactPhone,
          ),
          keyboardType: TextInputType.phone,
          validator: FormBuilderValidators.required(
            errorText: RegistrationStrings.emergencyContactPhoneRequired,
          ),
        ),
        const SizedBox(height: 24),
        // Vehicle section header with preload button
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: FormSectionHeader(title: RegistrationStrings.vehicleInfo),
            ),
            AppTextButton(
              label: RegistrationStrings.preloadFromVehicle,
              onPressed: () => _preloadFromVehicle(context),
              icon: Icons.motorcycle_rounded,
              iconSize: 16,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 12),
        FormBuilderTextField(
          name: RegistrationFormFields.vehicleBrand,
          decoration: InputDecoration(
            labelText: RegistrationStrings.vehicleBrand,
          ),
          textCapitalization: TextCapitalization.words,
          validator: FormBuilderValidators.required(
            errorText: RegistrationStrings.vehicleBrandRequired,
          ),
        ),
        const SizedBox(height: 12),
        FormBuilderTextField(
          name: RegistrationFormFields.vehicleReference,
          decoration: InputDecoration(
            labelText: RegistrationStrings.vehicleReference,
          ),
          textCapitalization: TextCapitalization.words,
          validator: FormBuilderValidators.required(
            errorText: RegistrationStrings.vehicleReferenceRequired,
          ),
        ),
        const SizedBox(height: 12),
        FormBuilderTextField(
          name: RegistrationFormFields.licensePlate,
          decoration: InputDecoration(
            labelText: RegistrationStrings.licensePlate,
          ),
          textCapitalization: TextCapitalization.characters,
          validator: FormBuilderValidators.required(
            errorText: RegistrationStrings.licensePlateRequired,
          ),
        ),
        const SizedBox(height: 12),
        FormBuilderTextField(
          name: RegistrationFormFields.vin,
          decoration: InputDecoration(labelText: RegistrationStrings.vin),
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 32),
        BlocBuilder<RegistrationFormCubit, RegistrationFormState>(
          builder: (context, state) {
            final isLoading = state.maybeWhen(
              loading: () => true,
              orElse: () => false,
            );
            final isEditing = state.maybeWhen(
              editing: (_) => true,
              orElse: () => false,
            );
            return AppButton(
              label: isEditing
                  ? RegistrationStrings.updateRegistration
                  : RegistrationStrings.sendRegistration,
              onPressed: isLoading ? null : cubit.saveRegistration,
              isLoading: isLoading,
            );
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
