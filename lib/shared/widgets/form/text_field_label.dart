import 'package:flutter/material.dart';

class TextFieldLabel extends StatelessWidget {
  final String labelText;
  final bool isRequired;

  const TextFieldLabel({
    super.key,
    required this.labelText,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isRequired) {
      return Text(labelText);
    }

    return Text.rich(
      TextSpan(
        text: labelText,
        style: const TextStyle(color: Color(0xFF374151)),
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }
}
