import 'package:flutter/services.dart';

/// Formats integer input with dot-separated thousands as the user types.
/// Example: typing "11600" shows "11.600".
///
/// Strips existing dots before re-formatting so the formatter is idempotent.
/// Only digits are allowed; non-digit characters are discarded.
class ThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll('.', '').replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final formatted = _addThousandsDots(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _addThousandsDots(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Strips thousands dots so the raw number can be parsed.
  static double? parse(String? formatted) {
    if (formatted == null || formatted.isEmpty) return null;
    return double.tryParse(formatted.replaceAll('.', ''));
  }

  /// Pre-formats a numeric value for use as an initial field value.
  static String? format(num? value) {
    if (value == null) return null;
    return _addThousandsDots(value.toInt().toString());
  }
}
