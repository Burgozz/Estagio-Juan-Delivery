import 'package:flutter/material.dart';
import '../models/pedido.dart';
import '../services/pedido_service.dart';
import '../../../core/session/sessao_usuario.dart';
import '../../catalogo/screens/catalogo_screen.dart' show kPrimary, kBackground, kTextPrimary, kTextSecondary;
import 'detalhes_pedido_screen.dart';

const _kCreme = Color(0xFFF5E6C8);
const _kHistoricoBg = Color(0xFFF5F5F5);

const _kStatusEmAberto = ['PENDENTE', 'CONFIRMADO', 'EM_PREPARO', 'EM_ENTREGA'];
const _kStatusHistorico = ['ENTREGUE', 'CANCELADO'];

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

/// Aba "Pedidos" do cliente: busca os pedidos do usuário logado (GET
/// /pedidos/usuario/{usuarioId}) e os separa em duas sub-abas — Em Aberto
/// (status ainda em andamento) e Histórico (pedidos encerrados).
class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> with SingleTickerProviderStateMixin {
  final _service = PedidoService();
  late final TabController _tabController;

  List<Pedido> _pedidos = [];
  // O backend não recalcula valorTotal do pedido ao adicionar itens (fica
  // sempre em 0 — ver comentário em DetalhesPedidoScreen), então o total de
  // cada card é somado a partir dos itens de cada pedido.
  final Map<int, double> _totais = {};
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Pedido> get _emAberto => _pedidos.where((p) => _kStatusEmAberto.contains(p.status)).toList();

  List<Pedido> get _historico {
    final lista = _pedidos.where((p) => _kStatusHistorico.contains(p.status)).toList();
    lista.sort((a, b) {
      final dataA = a.dataPedido;
      final dataB = b.dataPedido;
      if (dataA == null || dataB == null) return 0;
      return dataB.compareTo(dataA);
    });
    return lista;
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final pedidos = await _service.listarPorUsuario(SessaoUsuario.id!);
      final totais = <int, double>{};
      await Future.wait(pedidos.map((p) async {
        try {
          final itens = await _service.listarItensPorPedido(p.id);
          totais[p.id] = itens.fold(0.0, (soma, item) => soma + item.subtotal);
        } catch (_) {
          totais[p.id] = p.valorTotal;
        }
      }));
      if (!mounted) return;
      setState(() {
        _pedidos = pedidos;
        _totais
          ..clear()
          ..addAll(totais);
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _carregando = false);
      final mensagem = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem), backgroundColor: Colors.red.shade700),
      );
    }
  }

  void _abrirDetalhes(int pedidoId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetalhesPedidoScreen(pedidoId: pedidoId)),
    ).then((_) {
      if (!mounted) return;
      _carregar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Meus Pedidos'),
        backgroundColor: kPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: _kCreme,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Em Aberto'),
            Tab(text: 'Histórico'),
          ],
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : RefreshIndicator(
              color: kPrimary,
              onRefresh: _carregar,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEmAberto(),
                  _buildHistorico(),
                ],
              ),
            ),
    );
  }

  Widget _buildEmAberto() {
    final pedidos = _emAberto;
    if (pedidos.isEmpty) {
      return _buildVazio(
        icone: Icons.inventory_2_outlined,
        mensagem: 'Nenhum pedido em aberto',
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: pedidos.length,
      itemBuilder: (_, i) => _CardPedido(
        pedido: pedidos[i],
        total: _totais[pedidos[i].id] ?? pedidos[i].valorTotal,
        onVerDetalhes: () => _abrirDetalhes(pedidos[i].id),
      ),
    );
  }

  Widget _buildHistorico() {
    final pedidos = _historico;
    if (pedidos.isEmpty) {
      return _buildVazio(
        icone: Icons.list_alt_outlined,
        mensagem: 'Nenhum pedido no histórico',
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: pedidos.length,
      itemBuilder: (_, i) => _CardPedido(
        pedido: pedidos[i],
        total: _totais[pedidos[i].id] ?? pedidos[i].valorTotal,
        encerrado: true,
        onVerDetalhes: () => _abrirDetalhes(pedidos[i].id),
      ),
    );
  }

  Widget _buildVazio({required IconData icone, required String mensagem}) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icone, size: 56, color: kTextSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(mensagem, style: const TextStyle(color: kTextSecondary, fontSize: 15)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardPedido extends StatelessWidget {
  final Pedido pedido;
  final double total;
  final bool encerrado;
  final VoidCallback onVerDetalhes;

  const _CardPedido({
    required this.pedido,
    required this.total,
    required this.onVerDetalhes,
    this.encerrado = false,
  });

  @override
  Widget build(BuildContext context) {
    final cor = _kStatusCores[pedido.status] ?? kTextSecondary;
    final label = _kStatusLabels[pedido.status] ?? pedido.status;
    final data = pedido.dataPedido != null ? _formatarData(pedido.dataPedido!) : '-';

    return InkWell(
      onTap: onVerDetalhes,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: encerrado ? _kHistoricoBg : Colors.white,
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
                  style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.w700, fontSize: 16),
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
            const SizedBox(height: 6),
            Text(data, style: const TextStyle(color: kTextSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'R\$ ${total.toStringAsFixed(2)}',
                  style: const TextStyle(color: kPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (!encerrado)
                  TextButton(
                    onPressed: onVerDetalhes,
                    style: TextButton.styleFrom(foregroundColor: kPrimary),
                    child: const Text('Ver detalhes', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
              ],
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
    return '$dia/$mes/${data.year} $hora:$minuto';
  }
}
