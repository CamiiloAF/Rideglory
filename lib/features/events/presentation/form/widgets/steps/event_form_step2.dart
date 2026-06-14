import 'package:flutter/material.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/presentation/form/widgets/sections/event_form_ai_generate_section.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/event_step_nav_bar.dart';
import 'package:rideglory/features/events/presentation/form/widgets/steps/step_title.dart';

/// Step 2: Descripción del evento — diseño Pencil EzQtb.
///
/// - GENERAR DESCRIPCIÓN: card con IA para generar la descripción
/// - DESCRIPCIÓN: editor de texto enriquecido con barra de formato
class EventFormStep2 extends StatefulWidget {
  const EventFormStep2({super.key});

  @override
  State<EventFormStep2> createState() => _EventFormStep2State();
}

class _EventFormStep2State extends State<EventFormStep2> {
  late QuillController _quillController;

  static const _sectionLabelStyle = TextStyle(
    fontFamily: 'Space Grotesk',
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
    color: AppColors.textOnDarkTertiary,
  );

  @override
  void initState() {
    super.initState();
    _quillController = QuillController.basic();
  }

  @override
  void dispose() {
    _quillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StepTitle(
                  title: context.l10n.event_step2_title,
                  subtitle: context.l10n.event_step2_subtitle,
                ),
                const SizedBox(height: 20),
                const Text('GENERAR DESCRIPCIÓN', style: _sectionLabelStyle),
                const SizedBox(height: 10),
                EventFormAiGenerateSection(quillController: _quillController),
                AppSpacing.gapXxl,
                const Text('DESCRIPCIÓN', style: _sectionLabelStyle),
                const SizedBox(height: 10),
                AppRichTextEditor(
                  name: EventFormFields.description,
                  hintText: context.l10n.event_descriptionHint,
                  externalController: _quillController,
                  isRequired: true,
                  minLines: 8,
                  validator: FormBuilderValidators.required(
                    errorText: context.l10n.event_descriptionRequired,
                  ),
                ),
              ],
            ),
          ),
        ),
        const EventStepNavBar(),
      ],
    );
  }
}
