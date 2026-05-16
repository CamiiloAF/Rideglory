import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/shared/widgets/form/text_field_label.dart';

class AppDatePicker extends StatefulWidget {
  const AppDatePicker({
    super.key,
    required this.fieldName,
    required this.labelText,
    this.initialValue,
    this.firstDate,
    this.lastDate,
    this.isRequired = false,
    this.hintText,
    this.prefixIcon,
    this.inputType,
    this.enabled = true,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
    this.onChanged,
  });

  final String fieldName;
  final String labelText;
  final String? hintText;
  final DateTime? initialValue;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool isRequired;
  final Widget? prefixIcon;
  final InputType? inputType;
  final bool enabled;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(DateTime? value)? onFieldSubmitted;
  final void Function(DateTime?)? onChanged;

  @override
  State<AppDatePicker> createState() => _AppDatePickerState();
}

class _AppDatePickerState extends State<AppDatePicker> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFieldLabel(
          labelText: widget.labelText,
          isRequired: widget.isRequired,
        ),
        FormBuilderDateTimePicker(
          name: widget.fieldName,
          initialValue: widget.initialValue,
          inputType: widget.inputType ?? InputType.date,
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
          enabled: widget.enabled,
          focusNode: widget.focusNode,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          onChanged: (value) {
            FocusScope.of(context).unfocus();
            widget.onChanged?.call(value);
          },
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon,
          ),
        ),
      ],
    );
  }
}
