import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/domain/model/ai_description_request.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/cubit/ai_description_chat_cubit.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/ai_chat/ai_description_chat_page.dart';

/// Card de generación de descripción con IA — diseño Pencil EzQtb.
///
/// Muestra chips con el contexto del evento llenado hasta ahora y un botón
/// para abrir [AiDescriptionChatPage].
class EventFormAiGenerateSection extends StatelessWidget {
  const EventFormAiGenerateSection({
    super.key,
    required this.quillController,
  });

  final QuillController quillController;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Generar descripción con IA',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textOnDarkPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2117),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'BETA',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.darkBorderPrimary),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Con los datos ya llenados, la IA generará una descripción precisa:',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 12,
                    color: AppColors.textOnDarkSecondary,
                  ),
                ),
                SizedBox(height: 10),
                _ContextChipsRow(),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(12),
                  ),
                ),
                padding: EdgeInsets.zero,
              ),
              onPressed: () => _openAiChat(context),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: AppColors.darkBgPrimary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Generar descripción',
                    style: TextStyle(
                      fontFamily: 'Space Grotesk',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkBgPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAiChat(BuildContext context) {
    final cubit = context.read<AiDescriptionChatCubit>();
    final formValues = FormBuilder.of(context)?.instantValue ?? {};
    final title = formValues[EventFormFields.name] as String? ?? '';
    final eventType =
        (formValues[EventFormFields.eventType] as EventType?)?.apiValue ?? '';
    final difficulty =
        (formValues[EventFormFields.difficulty] as EventDifficulty?)?.label;
    final dateRange = formValues[EventFormFields.dateRange] as DateTimeRange?;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: AiDescriptionChatPage(
            quillController: quillController,
            autoGenerate: true,
            eventContext: AiDescriptionRequest(
              title: title,
              eventType: eventType,
              difficulty: difficulty,
              startDate: dateRange?.start.toIso8601String(),
              history: const [],
              userMessage: '',
            ),
          ),
        ),
      ),
    );
  }
}

class _ContextChipsRow extends StatelessWidget {
  const _ContextChipsRow();

  String _formatDate(DateTime date) {
    const weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    final wd = weekdays[date.weekday - 1];
    final mo = months[date.month - 1];
    return '$wd ${date.day} $mo';
  }

  @override
  Widget build(BuildContext context) {
    // BlocBuilder hace que este widget se reconstruya cuando el cubit emite
    // (ej. al navegar entre steps), leyendo los valores actuales del form.
    return BlocBuilder<EventFormCubit, EventFormState>(
      builder: (context, _) => _buildChips(context),
    );
  }

  Widget _buildChips(BuildContext context) {
    final formValues = FormBuilder.of(context)?.instantValue ?? {};
    final eventType =
        (formValues[EventFormFields.eventType] as EventType?)?.label;
    final difficulty =
        (formValues[EventFormFields.difficulty] as EventDifficulty?)?.label;
    final name = formValues[EventFormFields.name] as String?;
    final dateRange = formValues[EventFormFields.dateRange] as DateTimeRange?;
    final dateLabel =
        dateRange != null ? _formatDate(dateRange.start) : null;

    final hasAny = (eventType?.isNotEmpty ?? false) ||
        (difficulty?.isNotEmpty ?? false) ||
        (name?.isNotEmpty ?? false) ||
        dateLabel != null;

    if (!hasAny) {
      return const Text(
        'Completa el paso 1 para ver el contexto',
        style: TextStyle(
          fontFamily: 'Space Grotesk',
          fontSize: 12,
          color: AppColors.textOnDarkTertiary,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (eventType != null && eventType.isNotEmpty)
              _ContextChip(icon: Icons.route, label: eventType),
            if ((eventType?.isNotEmpty ?? false) &&
                (difficulty?.isNotEmpty ?? false))
              const SizedBox(width: 8),
            if (difficulty != null && difficulty.isNotEmpty)
              _ContextChip(
                icon: LucideIcons.flame,
                label: difficulty,
              ),
          ],
        ),
        if ((dateLabel != null) || (name?.isNotEmpty ?? false))
          const SizedBox(height: 8),
        Row(
          children: [
            if (dateLabel != null)
              _ContextChip(icon: Icons.calendar_today_outlined, label: dateLabel),
            if (dateLabel != null && (name?.isNotEmpty ?? false))
              const SizedBox(width: 8),
            if (name != null && name.isNotEmpty)
              Flexible(
                child: _ContextChip(icon: Icons.edit_outlined, label: name),
              ),
          ],
        ),
      ],
    );
  }
}

class _ContextChip extends StatelessWidget {
  const _ContextChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.darkBgSecondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textOnDarkSecondary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Space Grotesk',
                fontSize: 12,
                color: AppColors.textOnDarkSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
