import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/di_manager.dart';
import '../../../../shared/extensions/widget_extensions.dart';
import '../domain/repositories/sign_up_repository_contract.dart';
import 'manager/sign_up/sign_up_cubit.dart';
import 'widgets/sign_up_form.dart';

@RoutePage()
class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(final BuildContext context) {
    return BlocProvider(
      create: (final context) => SignUpCubit(
          signUpRepositoryContract: DIManager.getIt<SignUpRepositoryContract>(),),
      child: Scaffold(
        appBar: AppBar(
          title: Text(appStrings.personalInfo),
        ),
        body: const SingleChildScrollView(
          child: SignUpForm(),
        ),
      ),
    );
  }
}
