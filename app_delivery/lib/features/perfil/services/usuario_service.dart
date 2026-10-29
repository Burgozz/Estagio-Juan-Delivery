import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../models/usuario.dart';

class UsuarioService {
  final String baseUrl = '${ApiConfig.baseUrl}/usuarios';

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

  Future<List<Usuario>> listarTodos() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode != 200) {
      throw Exception(_parseErro(response));
    }
    final List data = jsonDecode(response.body);
    return data.map((e) => Usuario.fromJson(e)).toList();
  }

  /// Usado pela tela de administração de usuários: lista todos os usuários,
  /// incluindo os inativos (GET /usuarios/admin).
  Future<List<Usuario>> listarTodosAdmin() async {
    final response = await http.get(Uri.parse('$baseUrl/admin'));
    if (response.statusCode != 200) {
      throw Exception(_parseErro(response));
    }
    final List data = jsonDecode(response.body);
    return data.map((e) => Usuario.fromJson(e)).toList();
  }

  Future<Usuario> buscarPorId(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'));
    if (response.statusCode != 200) {
      throw Exception(_parseErro(response));
    }
    return Usuario.fromJson(jsonDecode(response.body));
  }

  Future<void> criar(Usuario usuario) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(usuario.toJson()),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_parseErro(response));
    }
  }

  Future<void> atualizar(int id, Usuario usuario) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(usuario.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception(_parseErro(response));
    }
  }

  Future<void> deletar(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_parseErro(response));
    }
  }
}
