import 'package:flutter/material.dart';

class OurTextButton extends StatelessWidget {
  const OurTextButton({
    required this.buttonText,
    this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final String buttonText;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(final BuildContext context) {
    return TextButton(
        onPressed: onPressed,
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator()
              : Text(
                  buttonText,
                  textAlign: TextAlign.center,
                ),
        ),);
  }
}
