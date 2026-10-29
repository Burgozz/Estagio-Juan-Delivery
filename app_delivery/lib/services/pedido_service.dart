import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/pedido.dart';
import '../models/item_pedido.dart';

class PedidoService {
  final String baseUrl = '${ApiConfig.baseUrl}/pedidos';

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

  /// Cria o pedido (POST /pedidos) e retorna o id gerado. O backend
  /// (PedidoDTO) só usa o campo usuarioId, calculando status, dataPedido e
  /// valorTotal por conta própria; os demais campos são enviados apenas
  /// para deixar a intenção explícita, sem depender do backend aceitá-los.
  Future<int> criar({
    required int usuarioId,
    required double valorTotal,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'usuarioId': usuarioId,
        'status': 'PENDENTE',
        'dataPedido': DateTime.now().toIso8601String(),
        'valorTotal': valorTotal,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_parseErro(response));
    }
    final data = jsonDecode(response.body);
    return data['id'] as int;
  }

  /// Adiciona um item ao pedido (POST /pedidos/{pedidoId}/itens).
  Future<void> adicionarItem({
    required int pedidoId,
    required int produtoId,
    required int quantidade,
    required double precoUnit,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$pedidoId/itens'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'produtoId': produtoId,
        'quantidade': quantidade,
        'precoUnit': precoUnit,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_parseErro(response));
    }
  }

  Future<Pedido> buscarPorId(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'));
    if (response.statusCode != 200) {
      throw Exception(_parseErro(response));
    }
    return Pedido.fromJson(jsonDecode(response.body));
  }

  /// Lista os pedidos de um usuário (GET /pedidos/usuario/{usuarioId}),
  /// usado pela aba Pedidos do cliente (Em Aberto / Histórico).
  Future<List<Pedido>> listarPorUsuario(int usuarioId) async {
    final response = await http.get(Uri.parse('$baseUrl/usuario/$usuarioId'));
    if (response.statusCode != 200) {
      throw Exception(_parseErro(response));
    }
    final List data = jsonDecode(response.body);
    return data.map((e) => Pedido.fromJson(e)).toList();
  }

  Future<List<ItemPedido>> listarItensPorPedido(int pedidoId) async {
    final response = await http.get(Uri.parse('$baseUrl/$pedidoId/itens'));
    if (response.statusCode != 200) {
      throw Exception(_parseErro(response));
    }
    final List data = jsonDecode(response.body);
    return data.map((e) => ItemPedido.fromJson(e)).toList();
  }

  /// Atualiza o status do pedido (PATCH /pedidos/{id}/status?status=...).
  /// O backend recebe o status como @RequestParam, não no corpo.
  Future<void> atualizarStatus(int id, String status) async {
    final uri = Uri.parse('$baseUrl/$id/status').replace(queryParameters: {'status': status});
    final response = await http.patch(uri);
    if (response.statusCode != 200) {
      throw Exception(_parseErro(response));
    }
  }
}
