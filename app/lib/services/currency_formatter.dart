import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {

    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove tudo que não for número
    String onlyNumbers = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Converte para double considerando 2 casas decimais
    double value = double.parse(onlyNumbers) / 100;

    // Formata em moeda brasileira
    final newText = _formatter.format(value);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  static double deformatString(String value) {
    String cleaned = value.replaceAll("R\$", "").trim().replaceAll(".", "").replaceAll(",", ".");
    return double.parse(cleaned);
  }
}
