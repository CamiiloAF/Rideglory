import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/di/di_manager.dart';
import 'package:rideglory/features/users/domain/entities/enums/gender.dart';
import 'package:rideglory/features/users/domain/entities/enums/looking_for_option.dart';
import 'package:rideglory/features/users/domain/entities/user_model.dart';
import 'package:rideglory/features/users/domain/repositories/users_repository_contract.dart';
import 'package:rideglory/features/users/presentation/cubit/update_user/update_user_cubit.dart';
import 'package:rideglory/shared/extensions/build_context_extensions.dart';
import 'package:rideglory/shared/widgets/buttons/our_elevated_button.dart';

class CompleteProfileForm extends StatelessWidget {
  const CompleteProfileForm({super.key, required this.userModel});

  final UserModel userModel;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UpdateUserCubit(
        usersRepository: DIManager.getIt<UsersRepositoryContract>(),
      ),
      child: _CompleteProfileForm(userModel: userModel),
    );
  }
}

class _CompleteProfileForm extends StatefulWidget {
  const _CompleteProfileForm({required this.userModel});

  final UserModel userModel;

  @override
  State<_CompleteProfileForm> createState() => __CompleteProfileFormState();
}

class __CompleteProfileFormState extends State<_CompleteProfileForm> {
  final lookingForOptions = <LookingForOption>[];
  final gendersLike = <Gender>[];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Intereses: '),
        Wrap(
          children: LookingForOption.values
              .map(
                (e) => ChoiceChip(
                  label: Text(e.getText()),
                  selected: lookingForOptions.contains(e),
                  onSelected: (bool selected) {
                    setState(() {
                      selected
                          ? lookingForOptions.add(e)
                          : lookingForOptions.remove(e);
                    });

                    setState(() {});
                  },
                ),
              )
              .toList(),
        ),
        const Text('Géneros: '),
        Wrap(
          children: Gender.values
              .take(2)
              .map(
                (e) => ChoiceChip(
                  label: Text(e.getText()),
                  selected: gendersLike.contains(e),
                  onSelected: (bool selected) {
                    setState(() {
                      selected ? gendersLike.add(e) : gendersLike.remove(e);
                    });
                  },
                ),
              )
              .toList(),
        ),
        BlocConsumer<UpdateUserCubit, UpdateUserState>(
          listener: (context, state) {
            state.whenOrNull(
              error: context.showSnackBar,
              success: () => Navigator.of(context).pop(),
            );
          },
          builder: (context, state) {
            return OurElevatedButton(
              buttonText: 'Guardar',
              isLoading: state is UpdatingUser,
              onPressed: state is! UpdatingUser && lookingForOptions.isNotEmpty && gendersLike.isNotEmpty
                  ? () {
                      context.read<UpdateUserCubit>().updateUser(
                          widget.userModel.copyWith(
                              lookingFor: lookingForOptions,
                              gendersLike: gendersLike));
                    }
                  : null,
            );
          },
        )
      ],
    );
  }
}
