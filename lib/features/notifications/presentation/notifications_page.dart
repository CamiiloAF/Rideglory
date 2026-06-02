import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:rideglory/features/notifications/presentation/notifications_view.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    // Usa la instancia global provista en la raíz para que la lista y el badge
    // de la campana compartan el mismo estado (antes dependía del singleton DI).
    context.read<NotificationsCubit>().load();
  }

  @override
  Widget build(BuildContext context) => const NotificationsView();
}
