import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../core/network/api_erro.dart';

class AuthService {
  final String baseUrl = '${ApiConfig.baseUrl}/auth';

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
      throw Exception(parseErro(response));
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
