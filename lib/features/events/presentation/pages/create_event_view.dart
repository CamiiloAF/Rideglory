import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../design_system/components/app_page_header.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../cubit/create_event_cubit.dart';
import '../cubit/create_event_state.dart';
import '../widgets/create_event_cta.dart';
import '../widgets/create_event_progress.dart';
import '../widgets/create_event_saving_view.dart';
import '../widgets/create_event_step1.dart';
import '../widgets/create_event_step2.dart';
import '../widgets/create_event_step3.dart';
import '../../../../core/domain/result_state.dart';

/// EV3: asistente de creación en 3 pasos + publicar.
class CreateEventView extends StatelessWidget {
  const CreateEventView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CreateEventCubit>();
    return BlocListener<CreateEventCubit, CreateEventState>(
      listenWhen: (previous, current) =>
          previous.submission != current.submission,
      listener: (context, state) {
        state.submission.whenOrNull(
          data: (_) => Navigator.of(context).pop(true),
        );
      },
      child: Scaffold(
        appBar: AppPageHeader(title: context.l10n.events_create_title),
        body: SafeArea(
          top: false,
          child: BlocBuilder<CreateEventCubit, CreateEventState>(
            builder: (context, state) {
              final isSaving = state.step == 2 && state.isSubmitting;
              final hasError =
                  state.step == 2 &&
                  state.submission.maybeWhen(
                    error: (_) => true,
                    orElse: () => false,
                  );
              return Column(
                children: [
                  CreateEventProgress(step: state.step),
                  Expanded(
                    child: (isSaving || hasError)
                        ? CreateEventSavingView(hasError: hasError)
                        : switch (state.step) {
                            0 => CreateEventStep1(state: state, cubit: cubit),
                            1 => CreateEventStep2(state: state, cubit: cubit),
                            _ => CreateEventStep3(state: state, cubit: cubit),
                          },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: CreateEventCta(
                      state: state,
                      cubit: cubit,
                      isSaving: isSaving,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
