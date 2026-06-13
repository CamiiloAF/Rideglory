import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/domain/model/ai_description_request.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/features/events/presentation/form/cubit/ai_description_chat_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/ai_chat/ai_description_chat_page.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class EventFormBasicInfoSection extends StatefulWidget {
  const EventFormBasicInfoSection({
    super.key,
    this.isEditing = false,
    this.descriptionInitialValue,
  });

  final bool isEditing;
  final String? descriptionInitialValue;

  @override
  State<EventFormBasicInfoSection> createState() =>
      _EventFormBasicInfoSectionState();
}

class _EventFormBasicInfoSectionState
    extends State<EventFormBasicInfoSection> {
  late QuillController _quillController;

  @override
  void initState() {
    super.initState();
    _quillController = _initController();
  }

  QuillController _initController() {
    final initial = widget.descriptionInitialValue;
    if (initial != null && initial.isNotEmpty) {
      try {
        final doc = Document.fromJson(jsonDecode(initial) as List);
        return QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (_) {
        final doc = Document()..insert(0, initial);
        return QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    }
    return QuillController.basic();
  }

  @override
  void dispose() {
    _quillController.dispose();
    super.dispose();
  }

  AiDescriptionRequest _buildEventContext() {
    final formValues = FormBuilder.of(context)?.instantValue ?? {};

    final title = formValues[EventFormFields.name] as String? ?? '';
    final eventType =
        (formValues[EventFormFields.eventType] as EventType?)?.apiValue ?? '';
    final difficulty =
        (formValues[EventFormFields.difficulty] as EventDifficulty?)?.label;

    final dateRange =
        formValues[EventFormFields.dateRange] as DateTimeRange?;
    final startDate = dateRange?.start.toIso8601String();

    return AiDescriptionRequest(
      title: title,
      eventType: eventType,
      difficulty: difficulty,
      startDate: startDate,
      history: const [],
      userMessage: '',
    );
  }

  void _openAiChatPage() {
    final cubit = context.read<AiDescriptionChatCubit>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: AiDescriptionChatPage(
            quillController: _quillController,
            eventContext: _buildEventContext(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          name: EventFormFields.name,
          labelText: context.l10n.event_eventName,
          hintText: context.l10n.event_eventNameHint,
          isRequired: true,
          readonly: widget.isEditing,
          suffixIcon: !widget.isEditing
              ? Builder(
                  builder: (context) => IconButton(
                    icon: Icon(
                      Icons.info_outline,
                      color: context.appColors.inputIcon,
                    ),
                    onPressed: () {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      scaffoldMessenger.hideCurrentSnackBar();
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            context.l10n.event_eventNameCannotBeModified,
                          ),
                          duration: const Duration(seconds: 3),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                )
              : null,
          textInputAction: TextInputAction.next,
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(
              errorText: context.l10n.event_nameRequired,
            ),
            FormBuilderValidators.minLength(
              3,
              errorText: context.l10n.event_minCharacters,
            ),
          ]),
        ),
        AppSpacing.gapLg,
        AppRichTextEditor(
          name: EventFormFields.description,
          labelText: context.l10n.event_descriptionAndRecommendations,
          hintText: context.l10n.event_descriptionHint,
          externalController: _quillController,
          isRequired: true,
          minLines: 8,
          onAiSuggest: _openAiChatPage,
          onChanged: (value) {
            FormBuilder.of(
              context,
            )?.fields[EventFormFields.description]?.didChange(value);
          },
          validator: FormBuilderValidators.required(
            errorText: context.l10n.event_descriptionRequired,
          ),
        ),
      ],
    );
  }
}
