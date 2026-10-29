import '../../perfil/models/endereco.dart';

/// Representa um pedido retornado pelo backend (GET /pedidos/{id}).
///
/// A API expõe a entidade Pedido diretamente, com o usuário completo
/// aninhado (incluindo seus endereços) — por isso o endereço de entrega é
/// lido diretamente de `usuario.enderecos`, sem precisar de uma chamada à
/// parte.
class Pedido {
  final int id;
  final int usuarioId;
  final String status;
  final DateTime? dataPedido;
  final double valorTotal;
  final List<Endereco> enderecosUsuario;

  Pedido({
    required this.id,
    required this.usuarioId,
    required this.status,
    this.dataPedido,
    required this.valorTotal,
    this.enderecosUsuario = const [],
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    final usuario = json['usuario'] as Map<String, dynamic>?;
    final enderecosJson = usuario?['enderecos'] as List?;
    return Pedido(
      id: json['id'],
      usuarioId: usuario?['id'] ?? 0,
      status: json['status'] ?? 'PENDENTE',
      dataPedido: json['dataPedido'] != null ? DateTime.tryParse(json['dataPedido'].toString()) : null,
      valorTotal: (json['valorTotal'] as num?)?.toDouble() ?? 0.0,
      enderecosUsuario:
          enderecosJson?.map((e) => Endereco.fromJson(e as Map<String, dynamic>)).toList() ?? const [],
    );
  }
}
