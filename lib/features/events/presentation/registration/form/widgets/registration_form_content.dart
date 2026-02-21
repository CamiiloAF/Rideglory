import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/features/events/constants/registration_form_fields.dart';
import 'package:rideglory/features/events/constants/registration_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/registration/form/cubit/registration_form_cubit.dart';
import 'package:rideglory/features/events/presentation/registration/form/widgets/vehicle_preload_bottom_sheet.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/features/vehicles/presentation/list/cubit/vehicle_list_cubit.dart';

// TODO Improve widgets
class RegistrationFormContent extends StatelessWidget {
  final EventModel event;

  const RegistrationFormContent({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RegistrationFormCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PreloadActions(
          onPreloadFromProfile: () => cubit.preloadFromRiderProfile(),
          onPreloadFromVehicle: () async {
            final vehicleListCubit = getIt<VehicleListCubit>();
            final vehicles = vehicleListCubit.activeVehicles;
            if (vehicles.isEmpty) return;
            final selected = await VehiclePreloadBottomSheet.show(
              context: context,
              vehicles: vehicles,
              currentVehicle: context.read<VehicleCubit>().currentVehicle,
            );
            if (selected != null && context.mounted) {
              cubit.preloadFromVehicle(selected);
            }
          },
        ),
        const SizedBox(height: 20),
        _SectionHeader(title: RegistrationStrings.personalInfo),
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
        _SectionHeader(title: RegistrationStrings.medicalInfo),
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
        _SectionHeader(title: RegistrationStrings.emergencyContact),
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
        _SectionHeader(title: RegistrationStrings.vehicleInfo),
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
            return FilledButton(
              onPressed: isLoading
                  ? null
                  : () => context
                        .read<RegistrationFormCubit>()
                        .saveRegistration(),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isEditing
                          ? RegistrationStrings.updateRegistration
                          : RegistrationStrings.sendRegistration,
                    ),
            );
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(height: 8),
      ],
    );
  }
}

class _PreloadActions extends StatelessWidget {
  final VoidCallback onPreloadFromProfile;
  final VoidCallback onPreloadFromVehicle;

  const _PreloadActions({
    required this.onPreloadFromProfile,
    required this.onPreloadFromVehicle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: onPreloadFromProfile,
          icon: const Icon(Icons.person_outlined, size: 18),
          label: const Text(RegistrationStrings.preloadFromMainVehicle),
        ),
        OutlinedButton.icon(
          onPressed: onPreloadFromVehicle,
          icon: const Icon(Icons.two_wheeler_outlined, size: 18),
          label: const Text(RegistrationStrings.preloadFromVehicle),
        ),
      ],
    );
  }
}
