import 'package:flutter/material.dart';
import '../filters/produto_filtro.dart';
import '../filters/status_filtro.dart';
import '../filters/texto_busca.dart';
import '../../catalogo/models/produto.dart';
import '../../catalogo/services/produto_service.dart';
import '../widgets/barra_busca_filtros.dart';
import '../widgets/filtro_chip.dart';
import '../widgets/painel_filtros.dart';
import '../widgets/resultados_header.dart';
import '../widgets/status_chips.dart';
import 'produto_form_screen.dart';
import '../../../core/session/logout.dart';
import '../../../core/theme/app_colors.dart';

class ProdutoListScreen extends StatefulWidget {
  const ProdutoListScreen({super.key});

  @override
  State<ProdutoListScreen> createState() => _ProdutoListScreenState();
}

class _ProdutoListScreenState extends State<ProdutoListScreen> {
  final service = ProdutoService();
  final _buscaCtrl = TextEditingController();
  List<Produto>? _produtos;
  bool _carregando = true;
  Object? _erro;

  // Fica no State (e não no carregamento), então sobrevive aos recarregamentos
  // feitos depois de editar ou excluir.
  ProdutoFiltro _filtro = const ProdutoFiltro();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final lista = await service.listarTodosAdmin();
      if (!mounted) return;
      setState(() {
        _produtos = lista;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e;
        _carregando = false;
      });
    }
  }

  void _limparFiltros() {
    _buscaCtrl.clear();
    setState(() => _filtro = const ProdutoFiltro());
  }

  Future<void> _abrirFiltros() async {
    final faixa = faixaDePreco(_produtos ?? const []);
    final escolhido = await abrirPainelFiltros<ProdutoFiltro>(
      context: context,
      rascunho: _filtro,
      limpar: (f) => f.limparAvancados(),
      construir: (f, atualizar) => [
        SecaoFiltro(
          titulo: 'Tipo',
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final t in TipoFiltro.values)
              FiltroChip(
                label: t.label,
                selecionado: f.tipo == t,
                onTap: () => atualizar(f.copyWith(
                  tipo: t,
                  categorias: t == TipoFiltro.acessorios ? const {} : null,
                )),
              ),
          ]),
        ),
        if (f.categoriaVisivel)
          SecaoFiltro(
            titulo: 'Categoria',
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              FiltroChip(
                label: 'Todas',
                selecionado: f.categorias.isEmpty,
                onTap: () => atualizar(f.copyWith(categorias: const {})),
              ),
              for (final c in categoriasProduto.entries)
                FiltroChip(
                  label: c.value,
                  selecionado: f.categorias.contains(c.key),
                  onTap: () {
                    final novas = {...f.categorias};
                    if (!novas.remove(c.key)) novas.add(c.key);
                    atualizar(f.copyWith(categorias: novas));
                  },
                ),
            ]),
          ),
        SecaoFiltro(
          titulo: 'Estoque',
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final e in EstoqueFiltro.values)
              FiltroChip(
                label: e.label,
                selecionado: f.estoque == e,
                onTap: () => atualizar(f.copyWith(estoque: e)),
              ),
          ]),
        ),
        SecaoFiltro(
          titulo: 'Faixa de preço',
          child: _buildFaixaPreco(f, faixa, atualizar),
        ),
        SecaoFiltro(
          titulo: 'Ordenar por',
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final o in OrdenacaoProduto.values)
              FiltroChip(
                label: o.label,
                selecionado: f.ordenacao == o,
                onTap: () => atualizar(f.copyWith(ordenacao: o)),
              ),
          ]),
        ),
      ],
    );
    if (escolhido == null || !mounted) return;
    // Busca e status vêm do estado atual (o debounce pode ter disparado com
    // o painel aberto); do painel só interessam os filtros avançados.
    setState(() => _filtro = escolhido.copyWith(busca: _filtro.busca, status: _filtro.status));
  }

  Widget _buildFaixaPreco(
    ProdutoFiltro f,
    ({double min, double max}) faixa,
    void Function(ProdutoFiltro) atualizar,
  ) {
    if (faixa.max <= faixa.min) {
      return const DicaFiltro('Todos os produtos têm o mesmo preço.');
    }
    final valores = RangeValues(
      (f.precoMin ?? faixa.min).clamp(faixa.min, faixa.max),
      (f.precoMax ?? faixa.max).clamp(faixa.min, faixa.max),
    );
    final amplitude = (faixa.max - faixa.min).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${formatarReais(valores.start)}  –  ${formatarReais(valores.end)}',
          style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w600),
        ),
        RangeSlider(
          values: valores,
          min: faixa.min,
          max: faixa.max,
          divisions: amplitude <= 500 ? amplitude : null,
          activeColor: kPrimary,
          inactiveColor: kPrimary.withValues(alpha: 0.15),
          labels: RangeLabels(formatarReais(valores.start), formatarReais(valores.end)),
          // Encostado no limite = sem limite, assim produtos novos mais
          // caros/baratos continuam aparecendo depois de recarregar.
          onChanged: (v) => atualizar(f.comPreco(
            v.start <= faixa.min ? null : v.start,
            v.end >= faixa.max ? null : v.end,
          )),
        ),
      ],
    );
  }

  Future<void> _deletar(int id, String nome) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Excluir produto?',
          style: TextStyle(color: kPrimary, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'O produto $nome será removido definitivamente da plataforma. '
          'Esta ação não pode ser desfeita.',
          style: const TextStyle(color: kTextPrimary),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: kTextSecondary),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await service.deletar(id);
      // _filtro fica no State, então os filtros aplicados são mantidos.
      await _carregar();
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Produto excluído'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      // Ex.: produto com pedidos -> backend orienta a zerar o estoque.
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  String _labelCategoria(String? cat) => categoriasProduto[cat] ?? cat ?? '-';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PRODUTOS'), actions: const [BotaoSair()]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kPrimary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProdutoFormScreen()));
          _carregar();
        },
      ),
      body: Column(
        children: [
          BarraBuscaFiltros(
            controller: _buscaCtrl,
            hint: 'Nome, descrição, país ou marca',
            filtrosAtivos: _filtro.avancadosAtivos,
            onBusca: (t) => setState(() => _filtro = _filtro.copyWith(busca: t)),
            onFiltros: _abrirFiltros,
          ),
          StatusChips(
            selecionado: _filtro.status,
            onChanged: (st) => setState(() => _filtro = _filtro.copyWith(status: st)),
          ),
          Expanded(child: _buildConteudo()),
        ],
      ),
    );
  }

  Widget _buildConteudo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator(color: kPrimary));
    }
    if (_erro != null) {
      return Center(child: Text('Erro: $_erro'));
    }
    final produtos = _produtos ?? const <Produto>[];
    if (produtos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wine_bar_outlined, size: 64, color: kPrimary),
            SizedBox(height: 16),
            Text('Nenhum produto cadastrado.', style: TextStyle(color: kTextSecondary, fontSize: 16)),
          ],
        ),
      );
    }

    final filtrados = _filtro.aplicar(produtos);
    return Column(
      children: [
        ResultadosHeader(
          total: filtrados.length,
          filtrosAtivos: _filtro.temFiltroAtivo,
          onLimpar: _limparFiltros,
        ),
        Expanded(
          child: filtrados.isEmpty ? SemResultados(onLimpar: _limparFiltros) : _buildLista(filtrados),
        ),
      ],
    );
  }

  Widget _buildLista(List<Produto> filtrados) {
    const padding = EdgeInsets.fromLTRB(20, 4, 20, 88);
    // Com status "Ativos" ou "Inativos" a lista já é de um tipo só.
    if (_filtro.status != StatusFiltro.todos) {
      return ListView(
        padding: padding,
        children: filtrados.map((p) => _buildProdutoCard(p, inativo: !p.ativo)).toList(),
      );
    }
    final ativos = filtrados.where((p) => p.ativo);
    final inativos = filtrados.where((p) => !p.ativo);
    return ListView(
      padding: padding,
      children: [
        ...ativos.map((p) => _buildProdutoCard(p, inativo: false)),
        if (inativos.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 12),
            child: Text(
              'Inativos',
              style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          ...inativos.map((p) => _buildProdutoCard(p, inativo: true)),
        ],
      ],
    );
  }

  Widget _buildProdutoCard(Produto p, {required bool inativo}) {
    final card = Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: kPrimary.withOpacity(0.1),
            child: Icon(
              inativo ? Icons.warning_amber_rounded : Icons.wine_bar_outlined,
              color: kPrimary,
              size: 22,
            ),
          ),
          title: Text(p.nome, style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_labelCategoria(p.categoria), style: const TextStyle(color: kPrimary, fontSize: 12)),
                Text(
                  'R\$ ${p.preco.toStringAsFixed(2)}  •  Estoque: ${p.estoque}',
                  style: const TextStyle(color: kTextSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: kPrimary, size: 20),
                onPressed: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => ProdutoFormScreen(produto: p)));
                  _carregar();
                },
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 20),
                onPressed: () => _deletar(p.id!, p.nome),
              ),
            ],
          ),
        ),
      ),
    );

    if (!inativo) return card;

    return Stack(
      children: [
        Opacity(opacity: 0.5, child: card),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Inativo',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }
}
