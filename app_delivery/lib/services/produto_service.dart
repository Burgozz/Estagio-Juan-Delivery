import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/produto.dart';

class ProdutoService {
  final String baseUrl = '${ApiConfig.baseUrl}/produtos';

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

  Future<List<Produto>> listarTodos() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode != 200) {
      throw Exception(_parseErro(response));
    }
    final List data = jsonDecode(response.body);
    return data.map((e) => Produto.fromJson(e)).toList();
  }

  /// Lista todos os produtos ativos do catálogo (GET /produtos).
  Future<List<Produto>> listarAtivos() => listarTodos();

  /// Usado pela tela de administração de produtos: lista todos os produtos,
  /// incluindo os inativos (GET /produtos/admin).
  Future<List<Produto>> listarTodosAdmin() async {
    final response = await http.get(Uri.parse('$baseUrl/admin'));
    if (response.statusCode != 200) {
      throw Exception(_parseErro(response));
    }
    final List data = jsonDecode(response.body);
    return data.map((e) => Produto.fromJson(e)).toList();
  }

  /// Lista os produtos ativos filtrando por categoria (GET /produtos?categoria=).
  Future<List<Produto>> listarPorCategoria(String categoria) async {
    final uri = Uri.parse(baseUrl).replace(queryParameters: {'categoria': categoria});
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception(_parseErro(response));
    }
    final List data = jsonDecode(response.body);
    return data.map((e) => Produto.fromJson(e)).toList();
  }

  /// Busca um produto ativo pelo id (GET /produtos/{id}).
  Future<Produto> buscarPorId(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'));
    if (response.statusCode != 200) {
      throw Exception(_parseErro(response));
    }
    return Produto.fromJson(jsonDecode(response.body));
  }

  Future<void> criar(Produto produto) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(produto.toJson()),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_parseErro(response));
    }
  }

  Future<void> atualizar(int id, Produto produto) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(produto.toJson()),
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
