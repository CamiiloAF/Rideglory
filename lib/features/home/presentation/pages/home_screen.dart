import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/features/match_riders/presentation/pages/match_riders_page.dart';
import 'package:rideglory/features/users/domain/entities/user_model.dart';
import 'package:rideglory/features/users/presentation/cubit/current_user/current_user_cubit.dart';
import 'package:rideglory/features/users/presentation/widgets/form/complete_profile_form.dart';
import 'package:rideglory/shared/extensions/build_context_extensions.dart';

@RoutePage()
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? userModel;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkCurrentUser();
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFEAEAEA),
      body: MatchRidersPage(),
    );
  }

  Future<void> _checkCurrentUser() async {
    try {
      userModel = await context.read<CurrentUserCubit>().getCurrentUser();

      if (userModel!.lookingFor.isEmpty) {
        _setUpUserData(userModel!);
      }
    } catch (e) {
      if (!context.mounted) return;
      context.showSnackBar(e.toString());
    }
  }

  void _setUpUserData(UserModel userModel) {
    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      // false = user must tap button, true = tap outside dialog
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('title'),
          content: CompleteProfileForm(userModel: userModel),
        );
      },
    );
  }
}
