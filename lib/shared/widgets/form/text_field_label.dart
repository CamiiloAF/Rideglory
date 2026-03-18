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
    final colorScheme = Theme.of(context).colorScheme;

    final child = !isRequired
        ? Text(labelText)
        : Text.rich(
            TextSpan(
              text: labelText,
              children: [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: colorScheme.error),
                ),
              ],
            ),
          );

    return Padding(padding: const EdgeInsets.only(bottom: 6), child: child);
  }
}
