import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/di/di_manager.dart';
import 'package:rideglory/features/auth/sign_up/presentation/widgets/sign_up_form.dart';
import 'package:rideglory/shared/extensions/widget_extensions.dart';

import '../domain/repositories/sign_up_repository_contract.dart';
import 'manager/sign_up/sign_up_cubit.dart';

@RoutePage()
class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SignUpCubit(
          signUpRepositoryContract: DIManager.getIt<SignUpRepositoryContract>()),
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
