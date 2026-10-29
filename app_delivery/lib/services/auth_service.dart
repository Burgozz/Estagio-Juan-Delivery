import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AuthService {
  final String baseUrl = '${ApiConfig.baseUrl}/auth';

  String _parseErro(http.Response response) {
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

  /// Realiza o login e retorna os dados básicos do usuário
  /// ({id, nome, email}). Lança [Exception] com a mensagem da API
  /// em caso de credenciais inválidas ou outro erro.
  Future<Map<String, dynamic>> login(String email, String senha) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'senha': senha}),
    );
    if (response.statusCode != 200) {
      throw Exception(_parseErro(response));
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
