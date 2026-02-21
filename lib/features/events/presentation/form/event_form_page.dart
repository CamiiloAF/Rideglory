import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/event_form_view.dart';

class EventFormPage extends StatelessWidget {
  final EventModel? event;

  const EventFormPage({super.key, this.event});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<EventFormCubit>()..initialize(event: event),
      child: const EventFormView(),
    );
  }
}
