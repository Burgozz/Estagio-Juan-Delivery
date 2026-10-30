/// Faixa de teor alcoólico do vinho pela Lei nº 7.678/1988.
/// Igual ao @DecimalMin/@DecimalMax de teorAlcool no backend.
const kTeorAlcoolMin = 7.0;
const kTeorAlcoolMax = 20.0;
const kMsgTeorAlcoolInvalido = 'Teor alcoólico deve estar entre 7% e 20%';

/// Converte o texto do campo em número, aceitando ponto (12.5) ou vírgula (12,5),
/// que é como o usuário brasileiro digita. Retorna null se não for um número.
double? parseTeorAlcool(String? valor) => double.tryParse((valor ?? '').trim().replaceAll(',', '.'));

/// Valida o texto do campo de teor alcoólico (ex.: 12.5 ou 12,5).
/// Campo vazio retorna null: a obrigatoriedade é tratada pelo formulário.
String? validarTeorAlcool(String? valor) {
  if ((valor ?? '').trim().isEmpty) return null;
  final teor = parseTeorAlcool(valor);
  if (teor == null) return 'Valor inválido';
  if (teor < kTeorAlcoolMin || teor > kTeorAlcoolMax) return kMsgTeorAlcoolInvalido;
  return null;
}
