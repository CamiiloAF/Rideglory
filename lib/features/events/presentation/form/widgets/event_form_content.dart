import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';
import 'package:rideglory/shared/widgets/form/app_checkbox.dart';
import 'package:rideglory/shared/widgets/form/app_date_picker.dart';
import 'package:rideglory/shared/widgets/form/app_dropdown.dart';
import 'package:rideglory/shared/widgets/form/app_text_field.dart';

// TODO Optimizar
class EventFormContent extends StatefulWidget {
  const EventFormContent({super.key});

  @override
  State<EventFormContent> createState() => _EventFormContentState();
}

class _EventFormContentState extends State<EventFormContent> {
  bool _isMultiDay = false;
  bool _isFree = true;

  Map<String, dynamic> _getInitialValues() {
    final state = context.read<EventFormCubit>().state;
    return state.maybeWhen(
      editing: (event) => {
        EventFormFields.name: event.name,
        EventFormFields.description: event.description,
        EventFormFields.city: event.city,
        EventFormFields.startDate: event.startDate,
        EventFormFields.endDate: event.endDate,
        EventFormFields.isMultiDay: event.isMultiDay,
        EventFormFields.meetingTime: event.meetingTime,
        EventFormFields.difficulty: event.difficulty,
        EventFormFields.eventType: event.eventType,
        EventFormFields.meetingPoint: event.meetingPoint,
        EventFormFields.meetingPointLat:
            event.meetingPointLatLng?.latitude.toString() ?? '',
        EventFormFields.meetingPointLng:
            event.meetingPointLatLng?.longitude.toString() ?? '',
        EventFormFields.destination: event.destination,
        EventFormFields.destinationLat:
            event.destinationLatLng?.latitude.toString() ?? '',
        EventFormFields.destinationLng:
            event.destinationLatLng?.longitude.toString() ?? '',
        EventFormFields.isMultiBrand: event.isMultiBrand,
        EventFormFields.allowedBrands: event.allowedBrands.join(', '),
        EventFormFields.isFree: event.isFree,
        EventFormFields.price: event.price?.toString() ?? '',
        EventFormFields.recommendations: event.recommendations ?? '',
      },
      orElse: () => {
        EventFormFields.isMultiBrand: true,
        EventFormFields.isFree: true,
        EventFormFields.isMultiDay: false,
        EventFormFields.difficulty: EventDifficulty.one,
        EventFormFields.eventType: EventType.onRoad,
        EventFormFields.startDate: DateTime.now(),
        EventFormFields.meetingTime: DateTime.now(),
      },
    );
  }

  @override
  void initState() {
    super.initState();
    final state = context.read<EventFormCubit>().state;
    state.maybeWhen(
      editing: (event) {
        _isMultiDay = event.isMultiDay;
        _isFree = event.isFree;
      },
      orElse: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EventFormCubit>();
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: FormBuilder(
        key: cubit.formKey,
        initialValue: _getInitialValues(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Info section
            _SectionTitle(title: EventStrings.basicInfo),
            const SizedBox(height: 12),
            AppTextField(
              name: EventFormFields.name,
              labelText: EventStrings.eventName,
              isRequired: true,
              prefixIcon: Icons.event,
              textInputAction: TextInputAction.next,
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(
                  errorText: EventStrings.nameRequired,
                ),
                FormBuilderValidators.minLength(
                  3,
                  errorText: EventStrings.minCharacters,
                ),
              ]),
            ),
            const SizedBox(height: 16),
            AppTextField(
              name: EventFormFields.description,
              labelText: EventStrings.eventDescription,
              isRequired: true,
              prefixIcon: Icons.description_outlined,
              maxLines: 3,
              validator: FormBuilderValidators.required(
                errorText: EventStrings.descriptionRequired,
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              name: EventFormFields.city,
              labelText: EventStrings.eventCity,
              isRequired: true,
              prefixIcon: Icons.location_city_outlined,
              textInputAction: TextInputAction.next,
              validator: FormBuilderValidators.required(
                errorText: EventStrings.cityRequired,
              ),
            ),

            // Date & Time section
            const SizedBox(height: 24),
            _SectionTitle(title: EventStrings.dateAndTime),
            const SizedBox(height: 12),
            AppDatePicker(
              fieldName: EventFormFields.startDate,
              labelText: EventStrings.startDate,
              isRequired: true,
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
            ),
            const SizedBox(height: 8),
            FormBuilderCheckbox(
              name: EventFormFields.isMultiDay,
              title: const Text(EventStrings.isMultiDay),
              onChanged: (value) {
                setState(() => _isMultiDay = value ?? false);
              },
            ),
            if (_isMultiDay) ...[
              const SizedBox(height: 8),
              AppDatePicker(
                fieldName: EventFormFields.endDate,
                labelText: EventStrings.endDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              ),
            ],
            const SizedBox(height: 16),
            _TimePicker(
              name: EventFormFields.meetingTime,
              labelText: EventStrings.meetingTime,
            ),

            // Difficulty & Type section
            const SizedBox(height: 24),
            _SectionTitle(title: EventStrings.eventDetails),
            const SizedBox(height: 12),
            AppDropdown<EventDifficulty>(
              name: EventFormFields.difficulty,
              labelText: EventStrings.difficulty,
              isRequired: true,
              prefixIcon: const Icon(Icons.local_fire_department_outlined),
              validator: FormBuilderValidators.required(
                errorText: EventStrings.difficultyRequired,
              ),
              items: EventDifficulty.values
                  .map((d) => DropdownMenuItem(value: d, child: Text(d.label)))
                  .toList(),
            ),
            const SizedBox(height: 16),
            AppDropdown<EventType>(
              name: EventFormFields.eventType,
              labelText: EventStrings.eventType,
              isRequired: true,
              prefixIcon: const Icon(Icons.category_outlined),
              validator: FormBuilderValidators.required(
                errorText: EventStrings.eventTypeRequired,
              ),
              items: EventType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
            ),
            const SizedBox(height: 16),
            AppCheckbox(
              name: EventFormFields.isMultiBrand,
              title: EventStrings.isMultiBrand,
            ),
            FormBuilderTextField(
              name: EventFormFields.allowedBrands,
              decoration: InputDecoration(
                labelText: EventStrings.allowedBrands,
                hintText: 'Honda, Yamaha, Kawasaki...',
                prefixIcon: const Icon(Icons.shield_outlined),
                border: const OutlineInputBorder(),
                helperText:
                    'Separar con coma. Dejar vacío si acepta todas las marcas.',
              ),
            ),
            const SizedBox(height: 16),
            // Price
            FormBuilderCheckbox(
              name: EventFormFields.isFree,
              title: const Text(EventStrings.freeEvent),
              onChanged: (value) {
                setState(() => _isFree = value ?? true);
              },
            ),
            if (!_isFree) ...[
              const SizedBox(height: 8),
              AppTextField(
                name: EventFormFields.price,
                labelText: EventStrings.price,
                prefixIcon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.numeric(
                    errorText: EventStrings.invalidPrice,
                  ),
                ]),
              ),
            ],

            // Locations section
            const SizedBox(height: 24),
            _SectionTitle(title: EventStrings.locations),
            const SizedBox(height: 12),
            AppTextField(
              name: EventFormFields.meetingPoint,
              labelText: EventStrings.meetingPoint,
              isRequired: true,
              prefixIcon: Icons.flag_outlined,
              textInputAction: TextInputAction.next,
              validator: FormBuilderValidators.required(
                errorText: EventStrings.meetingPointRequired,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              EventStrings.meetingPointLocation,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            _LatLngFields(
              latName: EventFormFields.meetingPointLat,
              lngName: EventFormFields.meetingPointLng,
            ),
            const SizedBox(height: 16),
            AppTextField(
              name: EventFormFields.destination,
              labelText: EventStrings.destination,
              isRequired: true,
              prefixIcon: Icons.location_on_outlined,
              textInputAction: TextInputAction.next,
              validator: FormBuilderValidators.required(
                errorText: EventStrings.destinationRequired,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              EventStrings.destinationLocation,
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            _LatLngFields(
              latName: EventFormFields.destinationLat,
              lngName: EventFormFields.destinationLng,
            ),

            // Recommendations section
            const SizedBox(height: 24),
            _SectionTitle(title: EventStrings.recommendations),
            const SizedBox(height: 12),
            AppTextField(
              name: EventFormFields.recommendations,
              labelText: EventStrings.recommendationsLabel,
              hintText: EventStrings.recommendationsHint,
              prefixIcon: Icons.tips_and_updates_outlined,
              maxLines: 8,
              minLines: 4,
            ),
            const SizedBox(height: 32),
            // Save button
            BlocBuilder<EventFormCubit, EventFormState>(
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
                      ? EventStrings.updateEvent
                      : EventStrings.saveEvent,
                  isLoading: isLoading,
                  icon: Icons.save_outlined,
                  onPressed: isLoading
                      ? null
                      : () {
                          final cubit = context.read<EventFormCubit>();
                          final event = cubit.buildEventToSave();
                          if (event != null) cubit.saveEvent(event);
                        },
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const Divider(),
      ],
    );
  }
}

class _LatLngFields extends StatelessWidget {
  final String latName;
  final String lngName;

  const _LatLngFields({required this.latName, required this.lngName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppTextField(
            name: latName,
            labelText: EventStrings.latitude,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) return null;
              final lat = double.tryParse(value);
              if (lat == null || lat < -90 || lat > 90) {
                return EventStrings.invalidLatitude;
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppTextField(
            name: lngName,
            labelText: EventStrings.longitude,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) return null;
              final lng = double.tryParse(value);
              if (lng == null || lng < -180 || lng > 180) {
                return EventStrings.invalidLongitude;
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String name;
  final String labelText;

  const _TimePicker({required this.name, required this.labelText});

  @override
  Widget build(BuildContext context) {
    return FormBuilderDateTimePicker(
      name: name,
      inputType: InputType.time,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: const Icon(Icons.access_time_outlined),
        border: const OutlineInputBorder(),
      ),
      validator: FormBuilderValidators.required(
        errorText: EventStrings.meetingTimeRequired,
      ),
    );
  }
}
