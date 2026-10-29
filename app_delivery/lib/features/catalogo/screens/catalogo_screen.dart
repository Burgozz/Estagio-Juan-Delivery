import 'package:flutter/material.dart';
import '../models/produto.dart';
import '../services/produto_service.dart';
import '../../carrinho/widgets/carrinho_appbar_action.dart';
import 'produto_detalhe_screen.dart';
import '../../../core/theme/app_colors.dart';

const Map<String, String> _categoriaLabels = {
  'VINHO_TINTO': 'Tinto',
  'VINHO_BRANCO': 'Branco',
  'VINHO_ROSE': 'Rosé',
  'VINHO_ESPUMANTE': 'Espumante',
  'VINHO_SOBREMESA': 'Sobremesa',
  'VINHO_ORGANICO': 'Orgânico',
  'VINHO_IMPORTADO': 'Importado',
};

String labelCategoria(String? categoria) => _categoriaLabels[categoria] ?? categoria ?? '-';

String labelTipo(String tipo) => tipo == 'ACESSORIO' ? 'Acessório' : 'Vinho';

/// Sentinela local para o card "Acessórios" da grade de categorias: não
/// existe valor correspondente em CategoriaProduto no backend (categoria é
/// campo exclusivo de Vinho), então a filtragem é feita localmente sobre a
/// lista já carregada, comparando `produto.tipo`. Mesmo padrão já usado em
/// InicioScreen para o mesmo caso.
const _kChaveAcessorios = 'ACESSORIOS';

/// Sentinela local para o card "Harmonizações": também não existe categoria
/// correspondente no backend — `harmonizacao` é um texto livre do Vinho
/// (ex.: "Carnes vermelhas"), não uma categoria. É tratado como "vinhos com
/// harmonização preenchida", filtrado localmente.
const _kChaveHarmonizacoes = 'HARMONIZACOES';

/// Categorias sem correspondência em CategoriaProduto no backend: filtradas
/// localmente sobre a lista completa em vez de chamar GET /produtos?categoria=.
const _kChavesLocais = {_kChaveAcessorios, _kChaveHarmonizacoes};

class _CategoriaGrid {
  final String chave;
  final String label;
  final Color cor;
  final String emoji;

  const _CategoriaGrid(this.chave, this.label, this.cor, this.emoji);
}

const _categoriasGrid = [
  _CategoriaGrid('VINHO_TINTO', 'Tintos', Color(0xFF8B1A1A), '🍷'),
  _CategoriaGrid('VINHO_BRANCO', 'Brancos', Color(0xFFC8A84B), '🥂'),
  _CategoriaGrid('VINHO_ROSE', 'Rosés', Color(0xFFD4698A), '🌸'),
  _CategoriaGrid('VINHO_ESPUMANTE', 'Espumantes', Color(0xFF2D5A8E), '🍾'),
  _CategoriaGrid(_kChaveAcessorios, 'Acessórios', Color(0xFF4A4A4A), '🧴'),
  _CategoriaGrid(_kChaveHarmonizacoes, 'Harmonizações', Color(0xFF2D7A4F), '🧀'),
  _CategoriaGrid('VINHO_ORGANICO', 'Orgânicos', Color(0xFF5A8A2D), '🌿'),
  _CategoriaGrid('VINHO_IMPORTADO', 'Importados', Color(0xFF6B3A8A), '🌍'),
];

/// Cor do badge de categoria exibido nos cards de resultado. Inclui
/// VINHO_SOBREMESA (fora da grade, mas alcançável via navegação vinda da
/// InicioScreen) com uma cor própria para não ficar sem badge colorido.
const Map<String, Color> _categoriaCores = {
  'VINHO_TINTO': Color(0xFF8B1A1A),
  'VINHO_BRANCO': Color(0xFFC8A84B),
  'VINHO_ROSE': Color(0xFFD4698A),
  'VINHO_ESPUMANTE': Color(0xFF2D5A8E),
  'VINHO_SOBREMESA': Color(0xFFA85C32),
  'VINHO_ORGANICO': Color(0xFF5A8A2D),
  'VINHO_IMPORTADO': Color(0xFF6B3A8A),
};
const _kCorAcessorio = Color(0xFF4A4A4A);

Color _corBadge(Produto p) => p.isAcessorio ? _kCorAcessorio : (_categoriaCores[p.categoria] ?? kTextSecondary);

String _labelBadge(Produto p) => p.isAcessorio ? 'Acessório' : labelCategoria(p.categoria);

/// Rótulo de exibição (chip do filtro ativo) para uma chave de categoria,
/// cobrindo tanto as 8 chaves da grade quanto categorias do backend
/// alcançáveis apenas via navegação externa (ex.: VINHO_SOBREMESA).
String _labelChave(String chave) {
  for (final c in _categoriasGrid) {
    if (c.chave == chave) return c.label;
  }
  return labelCategoria(chave);
}

class CatalogoScreen extends StatefulWidget {
  /// Categoria (valor do enum CategoriaProduto) usada para a busca inicial
  /// via GET /produtos?categoria=. Usado ao chegar filtrado a partir da
  /// InicioScreen.
  final String? categoriaInicial;

  /// Filtro local por tipo de produto ('VINHO' ou 'ACESSORIO'), aplicado
  /// sobre a lista completa — não existe um parâmetro de categoria para
  /// isso no backend, então segue o mesmo padrão local da busca por nome.
  final String? tipoInicial;

  const CatalogoScreen({super.key, this.categoriaInicial, this.tipoInicial});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  final service = ProdutoService();
  final _buscaCtrl = TextEditingController();

  List<Produto> _todosProdutos = [];
  List<Produto>? _resultadosCategoria; // resultado do backend p/ categoria ativa (chave não-local)
  bool _carregandoInicial = true;
  bool _carregandoCategoria = false;
  String _termoBusca = '';
  String? _categoriaChave; // chave da grade selecionada (local ou de backend); null = nenhuma
  String? _tipoFiltro; // filtro local por tipo 'VINHO', vindo da InicioScreen (Acessório vira _kChaveAcessorios)

  @override
  void initState() {
    super.initState();
    if (widget.tipoInicial == 'ACESSORIO') {
      _categoriaChave = _kChaveAcessorios;
    } else {
      _categoriaChave = widget.categoriaInicial;
      _tipoFiltro = widget.tipoInicial == 'VINHO' ? 'VINHO' : null;
    }
    _carregarInicial();
    _buscaCtrl.addListener(() {
      setState(() => _termoBusca = _buscaCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarInicial() async {
    setState(() => _carregandoInicial = true);
    try {
      final produtos = await service.listarAtivos();
      if (!mounted) return;
      setState(() {
        _todosProdutos = produtos;
        _carregandoInicial = false;
      });
      final chave = _categoriaChave;
      if (chave != null && !_kChavesLocais.contains(chave)) {
        await _carregarCategoriaBackend(chave);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _carregandoInicial = false);
      _mostrarErro(e);
    }
  }

  Future<void> _carregarCategoriaBackend(String categoria) async {
    setState(() => _carregandoCategoria = true);
    try {
      final resultado = await service.listarPorCategoria(categoria);
      if (!mounted) return;
      setState(() {
        _resultadosCategoria = resultado;
        _carregandoCategoria = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _carregandoCategoria = false);
      _mostrarErro(e);
    }
  }

  void _mostrarErro(Object e) {
    final mensagem = e.toString().replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _selecionarCategoria(String? chave) async {
    if (chave == _categoriaChave && _tipoFiltro == null) return;
    setState(() {
      _categoriaChave = chave;
      _tipoFiltro = null;
      if (chave == null || _kChavesLocais.contains(chave)) {
        _resultadosCategoria = null;
      }
    });
    if (chave != null && !_kChavesLocais.contains(chave)) {
      await _carregarCategoriaBackend(chave);
    }
  }

  Future<void> _limparFiltro() => _selecionarCategoria(null);

  List<Produto> get _produtosExibidos {
    List<Produto> lista;
    final chave = _categoriaChave;
    if (chave == null) {
      lista = _todosProdutos;
    } else if (chave == _kChaveAcessorios) {
      lista = _todosProdutos.where((p) => p.isAcessorio).toList();
    } else if (chave == _kChaveHarmonizacoes) {
      lista = _todosProdutos.where((p) => p.isVinho && (p.harmonizacao?.trim().isNotEmpty ?? false)).toList();
    } else {
      lista = _resultadosCategoria ?? [];
    }
    if (_tipoFiltro != null) {
      lista = lista.where((p) => p.tipo == _tipoFiltro).toList();
    }
    if (_termoBusca.isEmpty) return lista;
    return lista.where((p) => p.nome.toLowerCase().contains(_termoBusca)).toList();
  }

  bool get _modoResultados => _termoBusca.isNotEmpty || _categoriaChave != null || _tipoFiltro != null;

  @override
  Widget build(BuildContext context) {
    final modoResultados = _modoResultados;
    final produtos = modoResultados ? _produtosExibidos : const <Produto>[];
    final carregando = _carregandoInicial || _carregandoCategoria;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('BUSCA'),
        actions: const [CarrinhoAppBarAction()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: TextField(
              controller: _buscaCtrl,
              style: const TextStyle(color: kTextPrimary),
              cursorColor: kPrimary,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Buscar produto pelo nome',
                prefixIcon: const Icon(Icons.search, color: kTextSecondary),
                suffixIcon: _termoBusca.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, color: kTextSecondary),
                        onPressed: () => _buscaCtrl.clear(),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (modoResultados && (_categoriaChave != null || _tipoFiltro != null))
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  label: Text(_categoriaChave != null
                      ? _labelChave(_categoriaChave!)
                      : (_tipoFiltro == 'ACESSORIO' ? 'Acessórios' : 'Vinhos')),
                  onDeleted: _limparFiltro,
                  backgroundColor: kPrimary.withValues(alpha: 0.08),
                  labelStyle: const TextStyle(color: kPrimary, fontWeight: FontWeight.w600),
                  deleteIconColor: kPrimary,
                  side: BorderSide.none,
                ),
              ),
            ),
          Expanded(
            child: carregando
                ? const Center(child: CircularProgressIndicator(color: kPrimary))
                : !modoResultados
                    ? _GradeCategorias(onSelecionar: _selecionarCategoria)
                    : produtos.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'Nenhum produto encontrado',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: kTextSecondary, fontSize: 16),
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            color: kPrimary,
                            onRefresh: _carregarInicial,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              itemCount: produtos.length,
                              itemBuilder: (_, i) {
                                final p = produtos[i];
                                return _ProdutoCard(
                                  produto: p,
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProdutoDetalheScreen(id: p.id!),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _GradeCategorias extends StatelessWidget {
  final ValueChanged<String> onSelecionar;

  const _GradeCategorias({required this.onSelecionar});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        mainAxisExtent: 110,
      ),
      itemCount: _categoriasGrid.length,
      itemBuilder: (_, i) {
        final cat = _categoriasGrid[i];
        return _CategoriaCard(categoria: cat, onTap: () => onSelecionar(cat.chave));
      },
    );
  }
}

class _CategoriaCard extends StatelessWidget {
  final _CategoriaGrid categoria;
  final VoidCallback onTap;

  const _CategoriaCard({required this.categoria, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        clipBehavior: Clip.none,
        decoration: BoxDecoration(
          color: categoria.cor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 16,
              top: 14,
              right: 40,
              child: Text(
                categoria.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Positioned(
              right: -6,
              bottom: -8,
              child: Text(categoria.emoji, style: const TextStyle(fontSize: 48)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProdutoCard extends StatelessWidget {
  final Produto produto;
  final VoidCallback onTap;

  const _ProdutoCard({required this.produto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: kPrimary.withValues(alpha: 0.1),
                child: Icon(
                  produto.isAcessorio ? Icons.local_mall_outlined : Icons.wine_bar_outlined,
                  color: kPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produto.nome,
                      style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          labelTipo(produto.tipo),
                          style: const TextStyle(color: kPrimary, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _corBadge(produto),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _labelBadge(produto),
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'R\$ ${produto.preco.toStringAsFixed(2)}',
                      style: const TextStyle(color: kTextSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: kTextSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
