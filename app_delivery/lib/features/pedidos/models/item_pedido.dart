import '../../catalogo/models/produto.dart';

/// Um item de um pedido, retornado por GET /pedidos/{pedidoId}/itens.
///
/// O backend serializa a entidade ItemPedido diretamente, com o produto
/// (Vinho ou Acessorio) aninhado. Diferente de GET /produtos, essa rota não
/// passa pelo ProdutoRespostaDTO, então o JSON do produto não traz o campo
/// "tipo" — [_normalizarProduto] infere VINHO/ACESSORIO a partir dos campos
/// específicos de cada subtipo que efetivamente vieram no JSON.
class ItemPedido {
  final int id;
  final int quantidade;
  final double precoUnit;
  final Produto produto;

  ItemPedido({
    required this.id,
    required this.quantidade,
    required this.precoUnit,
    required this.produto,
  });

  double get subtotal => precoUnit * quantidade;

  factory ItemPedido.fromJson(Map<String, dynamic> json) {
    final produtoJson = _normalizarProduto(json['produto'] as Map<String, dynamic>? ?? {});
    return ItemPedido(
      id: json['id'],
      quantidade: json['quantidade'] ?? 0,
      precoUnit: (json['precoUnit'] as num?)?.toDouble() ?? 0.0,
      produto: Produto.fromJson(produtoJson),
    );
  }

  static Map<String, dynamic> _normalizarProduto(Map<String, dynamic> json) {
    if (json['tipo'] != null) return json;
    final normalizado = Map<String, dynamic>.from(json);
    final isAcessorio = json.containsKey('tipoAcessorio') || json.containsKey('marca') || json.containsKey('material');
    normalizado['tipo'] = isAcessorio ? 'ACESSORIO' : 'VINHO';
    return normalizado;
  }
}
