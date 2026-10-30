/// Faixa de teor alcoólico do vinho pela Lei nº 7.678/1988.
/// Igual ao @DecimalMin/@DecimalMax de teorAlcool no backend.
const kTeorAlcoolMin = 7.0;
const kTeorAlcoolMax = 20.0;
const kMsgTeorAlcoolInvalido = 'Teor alcoólico deve estar entre 7% e 20%';

/// Valida o texto do campo de teor alcoólico (decimal com ponto, ex.: 12.5).
/// Campo vazio retorna null: a obrigatoriedade é tratada pelo formulário.
String? validarTeorAlcool(String? valor) {
  final texto = (valor ?? '').trim();
  if (texto.isEmpty) return null;
  final teor = double.tryParse(texto);
  if (teor == null) return 'Valor inválido';
  if (teor < kTeorAlcoolMin || teor > kTeorAlcoolMax) return kMsgTeorAlcoolInvalido;
  return null;
}
