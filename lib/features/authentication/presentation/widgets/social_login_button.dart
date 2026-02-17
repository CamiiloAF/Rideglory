import 'package:flutter/material.dart';

/// Button type for social login
enum SocialLoginType { google, apple, email }

/// Reusable social login button widget
class SocialLoginButton extends StatefulWidget {
  final SocialLoginType type;
  final VoidCallback onPressed;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.type,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<SocialLoginButton> createState() => _SocialLoginButtonState();
}

class _SocialLoginButtonState extends State<SocialLoginButton> {
  late String label;
  late IconData icon;
  late Color backgroundColor;
  late Color textColor;

  @override
  void initState() {
    super.initState();
    _setupButtonStyle();
  }

  void _setupButtonStyle() {
    switch (widget.type) {
      case SocialLoginType.google:
        label = 'Continuar con Google';
        icon = Icons.login_rounded;
        backgroundColor = const Color(0xFFFAFAFA);
        textColor = const Color(0xFF1F2937);
        break;
      case SocialLoginType.apple:
        label = 'Continuar con Apple';
        icon = Icons.apple;
        backgroundColor = const Color(0xFF000000);
        textColor = Colors.white;
        break;
      case SocialLoginType.email:
        label = 'Continuar con Correo';
        icon = Icons.email_rounded;
        backgroundColor = const Color(0xFF6366F1);
        textColor = Colors.white;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: widget.isLoading ? null : widget.onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  )
                else ...[
                  Icon(icon, color: textColor, size: 20),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    widget.isLoading ? 'Iniciando sesión...' : label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (!widget.isLoading) const SizedBox(width: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
