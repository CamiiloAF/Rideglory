import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';


class OurReactiveDropDownInput<T> extends StatelessWidget {
  const OurReactiveDropDownInput({
    required this.formControlName,
    required this.items,
    this.readOnly = false,
    this.hint,
    this.onChange,
    super.key,
  });

  final String formControlName;
  final String? hint;
  final List<DropdownMenuItem<T>> items;
  final ReactiveFormFieldCallback<T>? onChange;
  final bool readOnly;

  @override
  Widget build(final BuildContext context) {
    return ReactiveDropdownField(
      formControlName: formControlName,
      hint: hint != null
          ? Text(
        hint!,
        // style: context.textTheme.bodyMedium!.copyWith(
        //   color: AppColors.mediumGray,
        // ),
      )
          : null,
      focusColor: Theme.of(context).scaffoldBackgroundColor,
      readOnly: readOnly,
      onChanged: onChange,
      // style: context.textTheme.bodyMedium,
      // dropdownColor: AppColors.whiteBackgroundAbsolute,
      icon: const Icon(
        Icons.keyboard_arrow_down_outlined,
        // color: AppColors.grayDropDownIcon,
      ),
      items: items,
    );
  }
}
