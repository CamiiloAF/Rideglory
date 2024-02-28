import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/di_manager.dart';
import '../../../../../shared/extensions/build_context_extensions.dart';
import '../../../../../shared/extensions/widget_extensions.dart';
import '../../../../../shared/widgets/buttons/our_text_button.dart';
import '../../../../users/domain/entities/enums/gender.dart';
import '../../../../users/domain/entities/enums/looking_for_option.dart';
import '../../../../users/domain/entities/user_model.dart';
import '../../../../users/domain/repositories/users_repository_contract.dart';
import '../../../../users/presentation/cubit/update_user/update_user_cubit.dart';
import '../profile_image_picker.dart';

class CompleteProfileForm extends StatelessWidget {
  const CompleteProfileForm({required this.userModel, super.key});

  final UserModel userModel;

  @override
  Widget build(final BuildContext context) {
    return BlocProvider(
      create: (final context) => UpdateUserCubit(
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
  final pictures = <String>[];

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appStrings.completeProfile),
        automaticallyImplyLeading: false,
        actions: [
          BlocConsumer<UpdateUserCubit, UpdateUserState>(
            listener: (final context, final state) {
              state.whenOrNull(
                error: context.showSnackBar,
                success: () => Navigator.of(context).pop(),
              );
            },
            builder: (final context, final state) {
              return OurTextButton(
                buttonText: appStrings.save,
                isLoading: state is UpdatingUser,
                onPressed: state is! UpdatingUser &&
                        lookingForOptions.isNotEmpty &&
                        gendersLike.isNotEmpty &&
                        pictures.isNotEmpty
                    ? () {
                        context.read<UpdateUserCubit>().updateUser(
                              widget.userModel.copyWith(
                                lookingFor: lookingForOptions,
                                gendersLike: gendersLike,
                                pictures: pictures,
                              ),
                            );
                      }
                    : null,
              );
            },
          ),
        ],
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(appStrings.interests),
          Wrap(
            children: LookingForOption.values
                .map(
                  (final e) => ChoiceChip(
                    label: Text(e.getText()),
                    selected: lookingForOptions.contains(e),
                    onSelected: (final selected) {
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
          Text(appStrings.genders),
          Wrap(
            children: Gender.values
                .take(2)
                .map(
                  (final e) => ChoiceChip(
                    label: Text(e.getText()),
                    selected: gendersLike.contains(e),
                    onSelected: (final selected) {
                      setState(() {
                        selected ? gendersLike.add(e) : gendersLike.remove(e);
                      });
                    },
                  ),
                )
                .toList(),
          ),
          Text(appStrings.photos),
          ProfileImagePicker(
            userModel: widget.userModel,
            onPickImage: (final fileURL) {
              setState(() {
                pictures.add(fileURL);
              });
            },
            onRemoveImage: (final fileURL) {
              setState(() {
                pictures.remove(fileURL);
              });
            },
          ),
        ],
      ),
    );
  }
}
