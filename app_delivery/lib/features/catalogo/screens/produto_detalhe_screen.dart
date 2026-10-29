import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../carrinho/controllers/carrinho_controller.dart';
import '../models/produto.dart';
import '../services/produto_service.dart';
import '../../carrinho/widgets/carrinho_appbar_action.dart';
import 'catalogo_screen.dart' show labelCategoria, labelTipo;
import '../../../core/theme/app_colors.dart';

class ProdutoDetalheScreen extends StatefulWidget {
  final int id;
  const ProdutoDetalheScreen({super.key, required this.id});

  @override
  State<ProdutoDetalheScreen> createState() => _ProdutoDetalheScreenState();
}

class _ProdutoDetalheScreenState extends State<ProdutoDetalheScreen> {
  final service = ProdutoService();
  Produto? _produto;
  bool _carregando = true;
  String? _erro;

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
      final produto = await service.buscarPorId(widget.id);
      if (!mounted) return;
      setState(() {
        _produto = produto;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      final mensagem = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _erro = mensagem;
        _carregando = false;
      });
    }
  }

  void _adicionarAoCarrinho(Produto produto) {
    context.read<CarrinhoController>().adicionar(produto);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Produto adicionado ao carrinho!'),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('DETALHES DO PRODUTO'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Voltar ao catálogo',
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [CarrinhoAppBarAction()],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : _erro != null
              ? _ErroView(mensagem: _erro!, onTentarNovamente: _carregar)
              : _buildConteudo(_produto!),
    );
  }

  Widget _buildConteudo(Produto p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: Colors.white,
            elevation: 2,
            shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: kPrimary.withValues(alpha: 0.1),
                        child: Icon(
                          p.isAcessorio ? Icons.local_mall_outlined : Icons.wine_bar_outlined,
                          color: kPrimary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.nome,
                              style: const TextStyle(
                                  color: kTextPrimary, fontWeight: FontWeight.w700, fontSize: 20),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              labelTipo(p.tipo),
                              style: const TextStyle(color: kPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Text(
                    'R\$ ${p.preco.toStringAsFixed(2)}',
                    style: const TextStyle(color: kPrimary, fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Estoque: ${p.estoque} unidade(s)',
                    style: const TextStyle(color: kTextSecondary, fontSize: 13),
                  ),
                  if (p.descricao != null && p.descricao!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Descrição',
                        style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(p.descricao!, style: const TextStyle(color: kTextSecondary, fontSize: 14)),
                  ],
                  const SizedBox(height: 20),
                  if (p.isVinho) ..._camposVinho(p) else if (p.isAcessorio) ..._camposAcessorio(p),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _adicionarAoCarrinho(p),
              icon: const Icon(Icons.shopping_cart_outlined),
              label: const Text('ADICIONAR AO CARRINHO'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimary,
                side: const BorderSide(color: kPrimary),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.arrow_back),
              label: const Text('VOLTAR AO CATÁLOGO'),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _camposVinho(Produto p) {
    return [
      const Text('Detalhes do vinho',
          style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
      const SizedBox(height: 10),
      _InfoLinha(icone: Icons.category_outlined, label: 'Categoria', valor: labelCategoria(p.categoria)),
      _InfoLinha(
          icone: Icons.flag_outlined,
          label: 'País de Origem da Uva',
          valor: (p.paisOrigem != null && p.paisOrigem!.isNotEmpty) ? p.paisOrigem! : '-'),
      _InfoLinha(
          icone: Icons.calendar_today_outlined,
          label: 'Safra',
          valor: p.safra?.toString() ?? '-'),
      _InfoLinha(
          icone: Icons.opacity_outlined,
          label: 'Teor alcoólico',
          valor: p.teorAlcool != null ? '${p.teorAlcool}%' : '-'),
      _InfoLinha(
          icone: Icons.restaurant_outlined,
          label: 'Harmonização',
          valor: (p.harmonizacao != null && p.harmonizacao!.isNotEmpty) ? p.harmonizacao! : '-'),
    ];
  }

  List<Widget> _camposAcessorio(Produto p) {
    return [
      const Text('Detalhes do acessório',
          style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
      const SizedBox(height: 10),
      _InfoLinha(
          icone: Icons.category_outlined,
          label: 'Tipo de acessório',
          valor: (p.tipoAcessorio != null && p.tipoAcessorio!.isNotEmpty) ? p.tipoAcessorio! : '-'),
      _InfoLinha(
          icone: Icons.local_offer_outlined,
          label: 'Marca',
          valor: (p.marca != null && p.marca!.isNotEmpty) ? p.marca! : '-'),
      _InfoLinha(
          icone: Icons.build_outlined,
          label: 'Material',
          valor: (p.material != null && p.material!.isNotEmpty) ? p.material! : '-'),
    ];
  }
}

class _InfoLinha extends StatelessWidget {
  final IconData icone;
  final String label;
  final String valor;

  const _InfoLinha({required this.icone, required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: kTextSecondary, size: 18),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(color: kTextSecondary, fontSize: 13)),
          Expanded(
            child: Text(valor,
                style: const TextStyle(color: kTextPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _ErroView extends StatelessWidget {
  final String mensagem;
  final VoidCallback onTentarNovamente;

  const _ErroView({required this.mensagem, required this.onTentarNovamente});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(mensagem, textAlign: TextAlign.center, style: const TextStyle(color: kTextSecondary)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onTentarNovamente, child: const Text('TENTAR NOVAMENTE')),
          ],
        ),
      ),
    );
  }
}
