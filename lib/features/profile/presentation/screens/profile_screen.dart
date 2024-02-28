import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/extensions/widget_extensions.dart';
import '../../../users/presentation/cubit/current_user/current_user_cubit.dart';
import '../widgets/form/complete_profile_form.dart';

@RoutePage()
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appStrings.profile),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CompleteProfileForm(
              userModel: context.read<CurrentUserCubit>().userModel!,
            ),
          ],
        ),
      ),
    );
  }
}
