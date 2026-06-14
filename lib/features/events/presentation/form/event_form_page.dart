import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/services/image_storage_service.dart';
import 'package:rideglory/features/events/presentation/form/cubit/ai_description_chat_cubit.dart';
import 'package:rideglory/shared/cubits/form_image_cubit.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/cubit/event_form_cubit.dart';
import 'package:rideglory/features/events/presentation/form/widgets/event_form_view.dart';

class EventFormPage extends StatelessWidget {
  final EventModel? event;
  final void Function(EventModel)? onSaved;

  const EventFormPage({super.key, this.event, this.onSaved});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              FormImageCubit(getIt<ImageStorageService>())
                ..initialize(remoteImageUrl: event?.imageUrl),
        ),
        BlocProvider(
          create: (_) => getIt<EventFormCubit>()..initialize(event: event),
        ),
        BlocProvider(
          create: (_) => getIt<AiDescriptionChatCubit>()..initQuota(),
        ),
      ],
      child: EventFormView(onSaved: onSaved),
    );
  }
}
