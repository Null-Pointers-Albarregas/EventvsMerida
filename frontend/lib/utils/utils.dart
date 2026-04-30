import 'package:flutter/services.dart';

class DayRangeTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    if (!RegExp(r'^\d+$').hasMatch(text)) return oldValue;
    if (text.length > 2) return oldValue;
    final value = int.tryParse(text) ?? 0;
    if (value < 1 || value > 31) return oldValue;
    return newValue;
  }
}