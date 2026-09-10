import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../design_system/components/app_text_field.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../cubit/create_event_cubit.dart';
import '../cubit/create_event_state.dart';
import 'create_event_photo_picker.dart';

/// Paso 1 del asistente: nombre, fecha/hora y punto de encuentro.
class CreateEventStep1 extends StatefulWidget {
  const CreateEventStep1({required this.state, required this.cubit, super.key});

  final CreateEventState state;
  final CreateEventCubit cubit;

  @override
  State<CreateEventStep1> createState() => _CreateEventStep1State();
}

class _CreateEventStep1State extends State<CreateEventStep1> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.state.name,
  );
  late final TextEditingController _meetingPointController =
      TextEditingController(text: widget.state.meetingPoint);

  @override
  void dispose() {
    _nameController.dispose();
    _meetingPointController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final startAt = widget.state.startAt;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.events_create_step1_title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 16),
          CreateEventPhotoPicker(
            localImagePath: widget.state.localImagePath,
            onPicked: widget.cubit.updateLocalImagePath,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: context.l10n.events_create_name_label,
            controller: _nameController,
            helperText: context.l10n.events_create_name_hint,
            onChanged: widget.cubit.updateName,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: context.l10n.events_create_datetime_label,
            readOnly: true,
            controller: TextEditingController(
              text: startAt == null
                  ? ''
                  : DateFormat(
                      "EEEE d 'de' MMMM · h:mm a",
                      'es',
                    ).format(startAt),
            ),
            helperText: startAt == null
                ? context.l10n.events_create_datetime_placeholder
                : null,
            onTap: () => _pickDateTime(context),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: context.l10n.events_create_meeting_point_label,
            controller: _meetingPointController,
            helperText: context.l10n.events_create_meeting_point_hint,
            onChanged: widget.cubit.updateMeetingPoint,
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: widget.state.startAt ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(widget.state.startAt ?? now),
    );
    if (time == null) return;
    widget.cubit.updateStartAt(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }
}
