import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/extensions/build_context_extensions.dart';
import '../../../match_riders/presentation/pages/match_riders_page.dart';
import '../../../profile/presentation/widgets/form/complete_profile_form.dart';
import '../../../users/domain/entities/user_model.dart';
import '../../../users/presentation/cubit/current_user/current_user_cubit.dart';

@RoutePage()
class HomeScreen extends StatefulWidget {
  const HomeScreen({final Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? userModel;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((final _) async {
      await _checkCurrentUser();
    });

    super.initState();
  }

  @override
  Widget build(final BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFEAEAEA),
      body: MatchRidersPage(),
    );
  }

  Future<void> _checkCurrentUser() async {
    try {
      userModel = await context.read<CurrentUserCubit>().fetchCurrentUser();

      // if (userModel!.lookingFor.isEmpty) {
      _goToProfile(userModel!);
      // }
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      context.showSnackBar(e.toString());
    }
  }

  void _goToProfile(final UserModel userModel) {
    if (!context.mounted) {
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      // false = user must tap button, true = tap outside dialog
      builder: (final dialogContext) {
        return PopScope(
          canPop: false,
          child: Dialog.fullscreen(
            child: CompleteProfileForm(
              userModel: userModel,
            ),
          ),
        );
      },
    );
  }
}
