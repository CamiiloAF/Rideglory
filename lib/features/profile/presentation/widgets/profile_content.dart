import 'package:flutter/material.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';
import 'package:rideglory/features/profile/presentation/widgets/profile_actions_list.dart';
import 'package:rideglory/features/profile/presentation/widgets/profile_header.dart';
import 'package:rideglory/features/profile/presentation/widgets/profile_main_vehicle_card.dart';

class ProfileContent extends StatelessWidget {
  const ProfileContent({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ProfileHeader(user: user),
        const SizedBox(height: 24),
        const ProfileMainVehicleCard(),
        const SizedBox(height: 24),
        const Divider(),
        const ProfileActionsList(),
      ],
    );
  }
}
