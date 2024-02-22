import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reactive_forms/reactive_forms.dart';

class OurReactiveTextField<T> extends StatelessWidget {
  const OurReactiveTextField({
    required this.formControlName,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines = 1,
    this.readOnly = false,
    this.hintText,
    this.onTap,
    this.disable = false,
    this.inputFormatters,
    this.decoration,
    super.key,
  });

  final String formControlName;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final int? minLines;
  final bool readOnly;
  final bool disable;
  final ReactiveFormFieldCallback<T>? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final InputDecoration? decoration;

  @override
  Widget build(final BuildContext context) {
    return ReactiveTextField<T>(
      formControlName: formControlName,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters ?? [],
      minLines: minLines,
      readOnly: readOnly || disable,
      onTap: onTap,
      maxLines: maxLines,
      // style: context.textTheme.bodyMedium!.copyWith(
      //   color: AppColors.grayInputFieldLabel,
      // ),
      decoration: decoration ?? const InputDecoration(),
    );
  }
}
