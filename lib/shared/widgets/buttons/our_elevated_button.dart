import 'package:flutter/material.dart';

class OurElevatedButton extends StatelessWidget {
  const OurElevatedButton({
    required this.buttonText,
    required this.isLoading,
    this.onPressed,
    super.key,
  });

  final String buttonText;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 1,
        shape: const RoundedRectangleBorder(
          side: BorderSide.none,
          borderRadius: BorderRadius.all(Radius.circular(50)),
        ),
      ),
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Text(
                buttonText,
                textAlign: TextAlign.center,
              ),
      ),
    );
  }
}
