import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import '../models/endereco.dart';

class EnderecoService {
  final String baseUrl = ApiConfig.baseUrl;

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

  Future<List<Endereco>> listarPorUsuario(int usuarioId) async {
    final response = await http.get(Uri.parse('$baseUrl/usuarios/$usuarioId/enderecos'));
    if (response.statusCode != 200) {
      throw Exception(_parseErro(response));
    }
    final List data = jsonDecode(response.body);
    return data.map((e) => Endereco.fromJson(e)).toList();
  }

  Future<void> criar(int usuarioId, Endereco endereco) async {
    final response = await http.post(
      Uri.parse('$baseUrl/usuarios/$usuarioId/enderecos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(endereco.toJson()),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_parseErro(response));
    }
  }

  Future<void> deletar(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/enderecos/$id'));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_parseErro(response));
    }
  }
}
