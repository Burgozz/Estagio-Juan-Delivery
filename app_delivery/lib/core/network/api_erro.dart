import 'dart:convert';

import 'package:http/http.dart' as http;

/// Extrai a mensagem de erro de uma resposta da API.
///
/// O backend (GlobalExceptionHandler) responde em dois formatos:
/// - validação: `{"erros": ["msg1", "msg2"]}` → mensagens unidas por quebra de linha
/// - demais erros: `{"erro": "mensagem"}`
/// Se o corpo não estiver em nenhum deles, devolve `Erro {statusCode}`.
String parseErro(http.Response response) {
  try {
    final body = jsonDecode(response.body);
    if (body is Map) {
      if (body['erros'] is List) {
        return (body['erros'] as List).join('\n');
      }
      if (body['erro'] != null) return body['erro'].toString();
    }
  } catch (_) {}
  return 'Erro ${response.statusCode}';
}
