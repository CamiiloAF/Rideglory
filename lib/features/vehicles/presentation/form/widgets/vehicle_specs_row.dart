import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:rideglory/design_system/design_system.dart';

class VehicleSpecsRow extends StatefulWidget {
  const VehicleSpecsRow({
    super.key,
    required this.fieldName,
    required this.label,
    required this.hintText,
    this.showDividerAbove = false,
  });

  final String fieldName;
  final String label;
  final String hintText;
  final bool showDividerAbove;

  @override
  State<VehicleSpecsRow> createState() => _VehicleSpecsRowState();
}

class _VehicleSpecsRowState extends State<VehicleSpecsRow> {
  bool _isEditing = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && _isEditing) {
      setState(() => _isEditing = false);
    }
  }

  void _startEditing() {
    setState(() => _isEditing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showDividerAbove)
          const Divider(height: 1, color: AppColors.darkBorderPrimary),
        GestureDetector(
          onTap: _isEditing ? null : _startEditing,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            color: Colors.transparent,
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textOnDarkSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _isEditing
                      ? AppTextField(
                          name: widget.fieldName,
                          focusNode: _focusNode,
                          hintText: widget.hintText,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) =>
                              setState(() => _isEditing = false),
                        )
                      : FormBuilderField<String>(
                          name: widget.fieldName,
                          builder: (field) {
                            final displayValue = field.value;
                            return Text(
                              displayValue != null && displayValue.isNotEmpty
                                  ? displayValue
                                  : widget.hintText,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: displayValue != null &&
                                        displayValue.isNotEmpty
                                    ? AppColors.textOnDarkPrimary
                                    : AppColors.textOnDarkTertiary,
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.edit_outlined,
                  size: 15,
                  color: AppColors.textOnDarkTertiary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
