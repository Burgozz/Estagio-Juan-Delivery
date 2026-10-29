import 'package:flutter/material.dart';
import '../models/item_pedido.dart';
import '../models/pedido.dart';
import '../../perfil/models/endereco.dart';
import '../services/pedido_service.dart';
import 'pedido_concluido_screen.dart';
import '../../../core/theme/app_colors.dart';

const _kStatusLabels = {
  'PENDENTE': 'Pendente',
  'CONFIRMADO': 'Confirmado',
  'EM_PREPARO': 'Em preparo',
  'EM_ENTREGA': 'Em entrega',
  'ENTREGUE': 'Entregue',
  'CANCELADO': 'Cancelado',
};

const _kStatusCores = {
  'PENDENTE': Color(0xFFEF6C00), // laranja
  'CONFIRMADO': Color(0xFF1565C0), // azul
  'EM_PREPARO': Color(0xFF6A1B9A), // roxo
  'EM_ENTREGA': Color(0xFFF9A825), // amarelo
  'ENTREGUE': Color(0xFF2E7D32), // verde
  'CANCELADO': Color(0xFFC62828), // vermelho
};

const _kVerdeEntrega = Color(0xFF2E7D32);

/// Tela de detalhes de um pedido: busca o pedido (GET /pedidos/{id}) e seus
/// itens (GET /pedidos/{pedidoId}/itens), exibindo status, itens, endereço
/// de entrega e um botão para o cliente confirmar que recebeu o pedido.
class DetalhesPedidoScreen extends StatefulWidget {
  final int pedidoId;

  const DetalhesPedidoScreen({super.key, required this.pedidoId});

  @override
  State<DetalhesPedidoScreen> createState() => _DetalhesPedidoScreenState();
}

class _DetalhesPedidoScreenState extends State<DetalhesPedidoScreen> {
  final _service = PedidoService();

  Pedido? _pedido;
  List<ItemPedido> _itens = [];
  bool _carregando = true;
  String? _erro;
  bool _atualizandoStatus = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final pedido = await _service.buscarPorId(widget.pedidoId);
      final itens = await _service.listarItensPorPedido(widget.pedidoId);
      if (!mounted) return;
      setState(() {
        _pedido = pedido;
        _itens = itens;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '');
        _carregando = false;
      });
    }
  }

  // O backend não recalcula valorTotal ao adicionar itens (fica em 0), então
  // o total exibido é somado a partir dos itens, que carregam o preço
  // praticado no momento da compra.
  double get _totalCalculado => _itens.fold(0.0, (soma, item) => soma + item.subtotal);

  Future<void> _confirmarEntrega() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Confirmar recebimento?', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600)),
        content: const Text(
          'Você confirma que recebeu seu pedido?',
          style: TextStyle(color: kTextSecondary),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: kTextSecondary),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: _kVerdeEntrega),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    setState(() => _atualizandoStatus = true);
    try {
      await _service.atualizarStatus(widget.pedidoId, 'ENTREGUE');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pedido confirmado! Obrigado pela sua compra!'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const PedidoConcluidoScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      final mensagem = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem), backgroundColor: Colors.red.shade700),
      );
    } finally {
      if (mounted) setState(() => _atualizandoStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Detalhes do Pedido'),
        backgroundColor: kPrimary,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : _erro != null
              ? _buildErro()
              : _buildConteudo(_pedido!),
    );
  }

  Widget _buildErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(_erro!, textAlign: TextAlign.center, style: const TextStyle(color: kTextSecondary)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _carregar, child: const Text('TENTAR NOVAMENTE')),
          ],
        ),
      ),
    );
  }

  Widget _buildConteudo(Pedido pedido) {
    final cor = _kStatusCores[pedido.status] ?? kTextSecondary;
    final label = _kStatusLabels[pedido.status] ?? pedido.status;
    // O botão de confirmar entrega aparece para qualquer pedido ainda em
    // andamento (PENDENTE, CONFIRMADO, EM_PREPARO, EM_ENTREGA); só some
    // quando o pedido já está no histórico (ENTREGUE ou CANCELADO).
    final podeConfirmarEntrega = pedido.status != 'ENTREGUE' && pedido.status != 'CANCELADO';
    final endereco = pedido.enderecosUsuario.isNotEmpty ? pedido.enderecosUsuario.first : null;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCabecalho(pedido, cor, label),
                const SizedBox(height: 20),
                const Text('Itens', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                for (final item in _itens) _buildItem(item),
                if (endereco != null) ...[
                  const SizedBox(height: 8),
                  const Text('Endereço de entrega', style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  _buildEndereco(endereco),
                ],
                if (podeConfirmarEntrega) ...[
                  const SizedBox(height: 24),
                  _buildBotaoConfirmarEntrega(),
                ],
              ],
            ),
          ),
        ),
        _buildRodapeTotal(),
      ],
    );
  }

  Widget _buildCabecalho(Pedido pedido, Color cor, String label) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pedido #${pedido.id}',
                style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.w700, fontSize: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            pedido.dataPedido != null ? _formatarData(pedido.dataPedido!) : '-',
            style: const TextStyle(color: kTextSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildEndereco(Endereco endereco) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const Icon(Icons.location_on, color: kPrimary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${endereco.rua}, ${endereco.numero}',
                  style: const TextStyle(color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(endereco.bairro, style: const TextStyle(color: kTextSecondary, fontSize: 13)),
                Text('${endereco.cidade} - ${endereco.estado}', style: const TextStyle(color: kTextSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoConfirmarEntrega() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _kVerdeEntrega,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _atualizandoStatus ? null : _confirmarEntrega,
        icon: _atualizandoStatus
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.check_circle_outline),
        label: const Text('CONFIRMAR ENTREGA', style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.6)),
      ),
    );
  }

  Widget _buildItem(ItemPedido item) {
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
                  '${item.quantidade}x R\$ ${item.precoUnit.toStringAsFixed(2)}',
                  style: const TextStyle(color: kTextSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            'R\$ ${item.subtotal.toStringAsFixed(2)}',
            style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRodapeTotal() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total', style: TextStyle(color: kTextSecondary, fontSize: 15)),
            Text(
              'R\$ ${_totalCalculado.toStringAsFixed(2)}',
              style: const TextStyle(color: kPrimary, fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year} às $hora:$minuto';
  }
}
