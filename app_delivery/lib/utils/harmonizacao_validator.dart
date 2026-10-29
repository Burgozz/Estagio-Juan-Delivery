import 'package:flutter/services.dart';

const kMsgHarmonizacaoInvalida = 'Harmonização deve conter apenas letras e pontuação simples';

/// Letras (com e sem acento), espaço, vírgula, ponto, hífen e barra.
/// Mesmo conjunto aceito pelo @Pattern de ProdutoDTO.harmonizacao no backend.
final _caracterPermitido = RegExp(r"[a-zA-ZÀ-ÿ\s,.\-/]");
final _somentePermitidos = RegExp(r"^[a-zA-ZÀ-ÿ\s,.\-/]+$");
final _letra = RegExp(r"[a-zA-ZÀ-ÿ]");

/// Ignora números e símbolos durante a digitação.
final harmonizacaoInputFormatter = FilteringTextInputFormatter.allow(_caracterPermitido);

/// Aplica trim e troca espaços repetidos por um só.
String normalizarHarmonizacao(String? valor) =>
    (valor ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');

/// Validação da harmonização (obrigatória para vinhos). Retorna null se válida.
String? validarHarmonizacao(String? valor) {
  final texto = normalizarHarmonizacao(valor);
  if (texto.isEmpty) return 'Informe a harmonização';
  if (texto.length < 3 || texto.length > 150) {
    return 'Harmonização deve ter entre 3 e 150 caracteres';
  }
  if (!_somentePermitidos.hasMatch(texto) || _letra.allMatches(texto).length < 3) {
    return kMsgHarmonizacaoInvalida;
  }
  return null;
}
