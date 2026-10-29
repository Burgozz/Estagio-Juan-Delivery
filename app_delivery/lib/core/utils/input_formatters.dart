import 'package:flutter/services.dart';

/// Remove tudo que não for dígito (o backend espera só números).
String somenteDigitos(String? valor) => (valor ?? '').replaceAll(RegExp(r'[^0-9]'), '');

/// Formata um telefone no padrão (XX) XXXX-XXXX (fixo, 10 dígitos) ou
/// (XX) XXXXX-XXXX (celular, 11 dígitos). Aceita valores parciais.
String formatarTelefone(String? valor) {
  var d = somenteDigitos(valor);
  if (d.length > 11) d = d.substring(0, 11);
  if (d.isEmpty) return '';
  if (d.length <= 2) return '($d';

  final ddd = d.substring(0, 2);
  final numero = d.substring(2);
  if (numero.length <= 5) return '($ddd) $numero';

  // Celular (9 dígitos no número): hífen após o 5º; senão após o 4º.
  final corte = numero.length == 9 ? 5 : 4;
  return '($ddd) ${numero.substring(0, corte)}-${numero.substring(corte)}';
}

/// Formata um CPF no padrão XXX.XXX.XXX-XX. Aceita valores parciais.
String formatarCpf(String? valor) {
  var d = somenteDigitos(valor);
  if (d.length > 11) d = d.substring(0, 11);

  final buffer = StringBuffer();
  for (var i = 0; i < d.length; i++) {
    if (i == 3 || i == 6) buffer.write('.');
    if (i == 9) buffer.write('-');
    buffer.write(d[i]);
  }
  return buffer.toString();
}

/// Base dos formatters de máscara: ignora tudo que não for dígito, limita a
/// quantidade de dígitos e mantém o cursor sempre no final do texto.
///
/// Se o backspace apagar apenas um símbolo da máscara (parêntese, ponto,
/// espaço ou hífen), o dígito anterior a ele também é removido, para que o
/// cursor não "trave" diante do símbolo.
abstract class _MascaraNumericaFormatter extends TextInputFormatter {
  int get maxDigitos;
  String formatar(String digitos);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digitos = somenteDigitos(newValue.text);

    final apagouSoSimbolo = newValue.text.length < oldValue.text.length &&
        digitos == somenteDigitos(oldValue.text);
    if (apagouSoSimbolo && digitos.isNotEmpty) {
      final cursor = newValue.selection.isValid
          ? newValue.selection.baseOffset.clamp(0, newValue.text.length)
          : newValue.text.length;
      final digitosAntes = somenteDigitos(newValue.text.substring(0, cursor)).length;
      if (digitosAntes > 0) {
        digitos = digitos.substring(0, digitosAntes - 1) + digitos.substring(digitosAntes);
      }
    }

    if (digitos.length > maxDigitos) digitos = digitos.substring(0, maxDigitos);

    final texto = formatar(digitos);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

/// Máscara dinâmica de telefone: (XX) XXXX-XXXX ou (XX) XXXXX-XXXX.
class TelefoneInputFormatter extends _MascaraNumericaFormatter {
  @override
  int get maxDigitos => 11;

  @override
  String formatar(String digitos) => formatarTelefone(digitos);
}

/// Máscara de CPF: XXX.XXX.XXX-XX.
class CpfInputFormatter extends _MascaraNumericaFormatter {
  @override
  int get maxDigitos => 11;

  @override
  String formatar(String digitos) => formatarCpf(digitos);
}
