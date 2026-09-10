import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../cubit/registration_cubit.dart';
import 'registration_view.dart';

/// Entrada de ruta de EV4: `/events/detail/:id/inscripcion`.
class RegistrationPage extends StatelessWidget {
  const RegistrationPage({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RegistrationCubit>()..load(),
      child: RegistrationView(eventId: eventId),
    );
  }
}
