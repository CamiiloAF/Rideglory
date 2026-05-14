import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:rideglory/features/notifications/presentation/notifications_view.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationsCubit()..loadNotifications(),
      child: const NotificationsView(),
    );
  }
}
