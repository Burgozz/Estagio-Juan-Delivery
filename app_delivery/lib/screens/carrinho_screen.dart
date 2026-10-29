import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/carrinho_controller.dart';
import '../services/pedido_service.dart';
import '../core/session/sessao_usuario.dart';
import 'catalogo_screen.dart' show kPrimary, kBackground, kTextPrimary, kTextSecondary;
import 'confirmacao_pedido_screen.dart';

/// Tela do carrinho de compras: lista os itens adicionados, permite ajustar
/// quantidades e finaliza o pedido chamando POST /pedidos e
/// POST /pedidos/{id}/itens para cada item.
class CarrinhoScreen extends StatefulWidget {
  const CarrinhoScreen({super.key});

  @override
  State<CarrinhoScreen> createState() => _CarrinhoScreenState();
}

class _CarrinhoScreenState extends State<CarrinhoScreen> {
  final _service = PedidoService();
  bool _finalizando = false;

  Future<void> _finalizarPedido(CarrinhoController carrinho) async {
    if (_finalizando || carrinho.itens.isEmpty) return;
    setState(() => _finalizando = true);
    try {
      final itens = carrinho.itens;
      final total = carrinho.total;
      final pedidoId = await _service.criar(
        usuarioId: SessaoUsuario.id!,
        valorTotal: total,
      );
      for (final item in itens) {
        await _service.adicionarItem(
          pedidoId: pedidoId,
          produtoId: item.produto.id!,
          quantidade: item.quantidade,
          precoUnit: item.precoUnit,
        );
      }
      carrinho.limpar();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ConfirmacaoPedidoScreen(pedidoId: pedidoId)),
      );
    } catch (e) {
      if (!mounted) return;
      final mensagem = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _finalizando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CarrinhoController>(
      builder: (context, carrinho, _) {
        final itens = carrinho.itens;
        return Scaffold(
          backgroundColor: kBackground,
          appBar: AppBar(
            title: const Text('Meu Carrinho'),
            backgroundColor: kPrimary,
          ),
          body: itens.isEmpty ? _buildVazio() : _buildLista(itens, carrinho),
          bottomNavigationBar: itens.isEmpty ? null : _buildRodape(carrinho),
        );
      },
    );
  }

  Widget _buildVazio() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 72, color: kTextSecondary),
          SizedBox(height: 16),
          Text(
            'Seu carrinho está vazio',
            style: TextStyle(color: kTextSecondary, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildLista(List<ItemCarrinho> itens, CarrinhoController carrinho) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      itemCount: itens.length,
      itemBuilder: (_, i) {
        final item = itens[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: kPrimary.withValues(alpha: 0.1),
                child: Icon(
                  item.produto.isAcessorio ? Icons.local_mall_outlined : Icons.wine_bar_outlined,
                  color: kPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.produto.nome,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'R\$ ${item.precoUnit.toStringAsFixed(2)} un.',
                      style: const TextStyle(color: kTextSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _BotaoQuantidade(
                          icone: Icons.remove,
                          onTap: () => carrinho.decrementar(i),
                        ),
                        SizedBox(
                          width: 32,
                          child: Text(
                            '${item.quantidade}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                        _BotaoQuantidade(
                          icone: Icons.add,
                          onTap: () => carrinho.incrementar(i),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 20),
                    tooltip: 'Remover item',
                    onPressed: () => carrinho.remover(i),
                  ),
                  Text(
                    'R\$ ${item.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRodape(CarrinhoController carrinho) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(color: kTextSecondary, fontSize: 15)),
                Text(
                  'R\$ ${carrinho.total.toStringAsFixed(2)}',
                  style: const TextStyle(color: kPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _finalizando ? null : () => _finalizarPedido(carrinho),
                child: _finalizando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('FINALIZAR PEDIDO', style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1.0)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotaoQuantidade extends StatelessWidget {
  final IconData icone;
  final VoidCallback onTap;

  const _BotaoQuantidade({required this.icone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: kPrimary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icone, size: 16, color: kPrimary),
      ),
    );
  }
}
