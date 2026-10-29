import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../catalogo/models/produto.dart';
import '../../catalogo/services/produto_service.dart';
import '../../carrinho/widgets/carrinho_appbar_action.dart';
import '../../catalogo/screens/produto_detalhe_screen.dart';
import '../../../core/theme/app_colors.dart';

/// Fundo dos ícones de categoria.
const _kCategoriaBg = Color(0xFFF0E8EF);

/// Sentinela usada em [_categoriaAtiva] para representar o filtro de
/// acessórios, que não existe como valor do enum CategoriaProduto e por
/// isso é sempre aplicado localmente sobre a lista completa.
const _acessorioSentinel = 'ACESSORIO';

class _CategoriaInicio {
  final String label;
  final String emoji;
  final String? categoriaApi;
  final bool isAcessorio;

  const _CategoriaInicio(this.label, this.emoji, {this.categoriaApi, this.isAcessorio = false});
}

const _categorias = [
  _CategoriaInicio('Tinto', '🍷', categoriaApi: 'VINHO_TINTO'),
  _CategoriaInicio('Branco', '🥂', categoriaApi: 'VINHO_BRANCO'),
  _CategoriaInicio('Rosé', '🌷', categoriaApi: 'VINHO_ROSE'),
  _CategoriaInicio('Espumante', '🍾', categoriaApi: 'VINHO_ESPUMANTE'),
  _CategoriaInicio('Sobremesa', '🍯', categoriaApi: 'VINHO_SOBREMESA'),
  _CategoriaInicio('Orgânico', '🌿', categoriaApi: 'VINHO_ORGANICO'),
  _CategoriaInicio('Importado', '🌍', categoriaApi: 'VINHO_IMPORTADO'),
  _CategoriaInicio('Acessórios', '🛍️', isAcessorio: true),
];

const _kQtdCategoriasColapsado = 5;

class _BannerInfo {
  final String titulo;
  final String subtitulo;
  final Color cor;

  const _BannerInfo(this.titulo, this.subtitulo, this.cor);
}

const _banners = [
  _BannerInfo('Vinhos tintos selecionados', 'Os melhores rótulos com até 20% off', kPrimary),
  _BannerInfo('Espumantes para celebrar', 'Brinde os momentos especiais', kGradienteFim),
  _BannerInfo('Novos acessórios chegaram', 'Taças, decanters e muito mais', Color(0xFF8C2F63)),
];

/// Intervalo entre as trocas automáticas do carrossel.
const _kIntervaloBanner = Duration(seconds: 7);

/// Duração da animação de transição entre banners.
const _kTransicaoBanner = Duration(milliseconds: 600);

/// Página inicial do carrossel infinito: alta e múltipla da quantidade de
/// banners, para o usuário poder arrastar para os dois lados sem chegar ao
/// fim e começar no primeiro banner.
final _kPaginaInicialBanner = 1000 * _banners.length;

class _ExplorarInfo {
  final String titulo;
  final String emoji;
  final Color cor;

  const _ExplorarInfo(this.titulo, this.emoji, this.cor);
}

/// Tela inicial exibida após o login, primeira aba da BottomNavigationBar.
/// Todo o conteúdo (categorias e produtos) é carregado a partir da API já
/// existente via [ProdutoService].
class InicioScreen extends StatefulWidget {
  /// Navega para a aba de Catálogo, opcionalmente já filtrada por
  /// categoria (GET /produtos?categoria=) ou por tipo (filtro local).
  final void Function({String? categoria, String? tipo}) onNavegarCatalogo;

  const InicioScreen({super.key, required this.onNavegarCatalogo});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> with WidgetsBindingObserver {
  final _service = ProdutoService();
  final _buscaCtrl = TextEditingController();
  final _bannerCtrl = PageController(initialPage: _kPaginaInicialBanner);
  Timer? _bannerTimer;
  int _bannerIndex = 0;

  // Condições para a passagem automática rodar.
  bool _rotaVisivel = true;
  bool _appAtivo = true;
  bool _arrastandoBanner = false;

  String? _nomeUsuario;
  List<Produto> _produtos = [];
  bool _carregando = true;
  String _termoBusca = '';
  String? _categoriaAtiva; // null = recentes; categoriaApi ou _acessorioSentinel
  String _tituloSecao = 'Adicionados recentemente';
  bool _categoriasExpandidas = false;

  @override
  void initState() {
    super.initState();
    _carregarNomeUsuario();
    _carregarProdutos();
    _buscaCtrl.addListener(() {
      setState(() => _termoBusca = _buscaCtrl.text.trim().toLowerCase());
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // isCurrent fica false quando outra tela é aberta por cima desta.
    _rotaVisivel = ModalRoute.of(context)?.isCurrent ?? true;
    _reiniciarTimerBanner();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appAtivo = state == AppLifecycleState.resumed;
    _reiniciarTimerBanner();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bannerTimer?.cancel();
    _buscaCtrl.dispose();
    _bannerCtrl.dispose();
    super.dispose();
  }

  /// Cancela o timer atual e, se a tela estiver visível e o usuário não
  /// estiver arrastando, começa uma nova contagem de [_kIntervaloBanner].
  void _reiniciarTimerBanner() {
    _bannerTimer?.cancel();
    _bannerTimer = null;
    if (!_rotaVisivel || !_appAtivo || _arrastandoBanner) return;
    _bannerTimer = Timer.periodic(_kIntervaloBanner, (_) => _avancarBanner());
  }

  /// Sempre segue para a próxima página (nunca volta ao início), já que o
  /// PageView é infinito.
  void _avancarBanner() {
    if (!mounted || !_bannerCtrl.hasClients) return;
    final atual = _bannerCtrl.page?.round() ?? _kPaginaInicialBanner;
    _bannerCtrl.animateToPage(
      atual + 1,
      duration: _kTransicaoBanner,
      curve: Curves.easeInOut,
    );
  }

  /// Pausa a passagem automática enquanto o usuário arrasta o carrossel e
  /// reinicia a contagem quando ele solta.
  bool _onBannerScroll(ScrollNotification n) {
    if (n is ScrollStartNotification && n.dragDetails != null) {
      _arrastandoBanner = true;
      _reiniciarTimerBanner();
    } else if (n is ScrollEndNotification && _arrastandoBanner) {
      _arrastandoBanner = false;
      _reiniciarTimerBanner();
    }
    return false;
  }

  Future<void> _carregarNomeUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final nome = prefs.getString('usuario_nome');
    setState(() => _nomeUsuario = (nome != null && nome.trim().isNotEmpty) ? nome.trim() : null);
  }

  Future<void> _carregarProdutos() async {
    setState(() => _carregando = true);
    try {
      List<Produto> produtos;
      if (_categoriaAtiva == null) {
        produtos = await _service.listarAtivos();
        produtos.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
      } else if (_categoriaAtiva == _acessorioSentinel) {
        final todos = await _service.listarAtivos();
        produtos = todos.where((p) => p.isAcessorio).toList();
      } else {
        produtos = await _service.listarPorCategoria(_categoriaAtiva!);
      }
      if (!mounted) return;
      setState(() {
        _produtos = produtos;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _carregando = false);
      final mensagem = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _selecionarCategoria(_CategoriaInicio categoria) async {
    final valor = categoria.isAcessorio ? _acessorioSentinel : categoria.categoriaApi;
    final desmarcar = valor == _categoriaAtiva;
    setState(() {
      _categoriaAtiva = desmarcar ? null : valor;
      _tituloSecao = desmarcar ? 'Adicionados recentemente' : categoria.label;
    });
    await _carregarProdutos();
  }

  void _verMaisCatalogo() {
    if (_categoriaAtiva == null) {
      widget.onNavegarCatalogo();
    } else if (_categoriaAtiva == _acessorioSentinel) {
      widget.onNavegarCatalogo(tipo: 'ACESSORIO');
    } else {
      widget.onNavegarCatalogo(categoria: _categoriaAtiva);
    }
  }

  String _saudacao() {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Bom dia';
    if (hora < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  List<Produto> get _produtosExibidos {
    var lista = _produtos;
    if (_termoBusca.isNotEmpty) {
      return lista.where((p) => p.nome.toLowerCase().contains(_termoBusca)).toList();
    }
    if (_categoriaAtiva == null) {
      lista = lista.take(10).toList();
    }
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final nome = _nomeUsuario;
    final saudacao = nome == null ? '${_saudacao()}!' : '${_saudacao()}, ${nome.split(' ').first}';

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        toolbarHeight: 76,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              saudacao,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Seu marketplace de vinhos',
              style: TextStyle(color: kCreme, fontSize: 13, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          const CarrinhoAppBarAction(),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              // Apenas visual por enquanto, sem funcionalidade.
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: _carregarProdutos,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBusca(),
              const SizedBox(height: 28),
              _buildCategorias(),
              const SizedBox(height: 28),
              _buildBanners(),
              const SizedBox(height: 32),
              _buildExplorar(),
              const SizedBox(height: 32),
              _buildRecentes(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusca() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.black12),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: TextField(
          controller: _buscaCtrl,
          style: const TextStyle(color: kTextPrimary),
          cursorColor: kPrimary,
          decoration: InputDecoration(
            hintText: 'Busque por vinho tinto...',
            hintStyle: const TextStyle(color: kTextSecondary),
            prefixIcon: const Icon(Icons.search, color: kTextSecondary),
            suffixIcon: _termoBusca.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, color: kTextSecondary),
                    onPressed: () => _buscaCtrl.clear(),
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorias() {
    final visiveis = _categoriasExpandidas ? _categorias : _categorias.take(_kQtdCategoriasColapsado).toList();
    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          for (final cat in visiveis)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: _CategoriaTile(
                emoji: cat.emoji,
                label: cat.label,
                ativa: (cat.isAcessorio ? _acessorioSentinel : cat.categoriaApi) == _categoriaAtiva,
                onTap: () => _selecionarCategoria(cat),
              ),
            ),
          _CategoriaTile(
            icone: _categoriasExpandidas ? Icons.expand_less : Icons.expand_more,
            label: _categoriasExpandidas ? 'Ver menos' : 'Ver mais',
            ativa: false,
            onTap: () => setState(() => _categoriasExpandidas = !_categoriasExpandidas),
          ),
        ],
      ),
    );
  }

  Widget _buildBanners() {
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onBannerScroll,
            // Sem itemCount: o carrossel é infinito e o índice com módulo
            // escolhe qual banner exibir.
            child: PageView.builder(
              controller: _bannerCtrl,
              onPageChanged: (i) => setState(() => _bannerIndex = i % _banners.length),
              itemBuilder: (_, i) {
                final b = _banners[i % _banners.length];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: b.cor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: b.cor.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6)),
                    ],
                  ),
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.titulo,
                        style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        b.subtitulo,
                        style: const TextStyle(color: kCreme, fontSize: 13),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _banners.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _bannerIndex == i ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _bannerIndex == i ? kPrimary : Colors.black12,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildExplorar() {
    final cards = [
      (_ExplorarInfo('Vinhos', '🍷', kPrimary), () => widget.onNavegarCatalogo(tipo: 'VINHO')),
      (_ExplorarInfo('Acessórios', '🛍️', const Color(0xFF6A3EA1)), () => widget.onNavegarCatalogo(tipo: 'ACESSORIO')),
      (_ExplorarInfo('Espumantes', '🍾', const Color(0xFF8C2F63)), () => widget.onNavegarCatalogo(categoria: 'VINHO_ESPUMANTE')),
      (_ExplorarInfo('Harmonizações', '🍽️', kCreme), () => widget.onNavegarCatalogo()),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explorar',
            style: TextStyle(color: kTextPrimary, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [for (final (info, onTap) in cards) _ExplorarCard(info: info, onTap: onTap)],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentes() {
    final produtos = _produtosExibidos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _tituloSecao,
                style: const TextStyle(color: kTextPrimary, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: _verMaisCatalogo,
                child: const Row(
                  children: [
                    Text('Ver mais', style: TextStyle(color: kPrimary, fontWeight: FontWeight.w600)),
                    Icon(Icons.chevron_right, color: kPrimary, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_carregando)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator(color: kPrimary)),
          )
        else if (produtos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Text(
              _categoriaAtiva != null
                  ? 'Nenhum produto encontrado para esta categoria'
                  : 'Nenhum produto encontrado',
              textAlign: TextAlign.center,
              style: const TextStyle(color: kTextSecondary, fontSize: 15),
            ),
          )
        else
          SizedBox(
            height: 158,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: produtos.length,
              itemBuilder: (_, i) {
                final p = produtos[i];
                return Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: _ProdutoCardPequeno(
                    produto: p,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProdutoDetalheScreen(id: p.id!)),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _CategoriaTile extends StatelessWidget {
  final String? emoji;
  final IconData? icone;
  final String label;
  final bool ativa;
  final VoidCallback onTap;

  const _CategoriaTile({
    this.emoji,
    this.icone,
    required this.label,
    required this.ativa,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ativa ? kPrimary : _kCategoriaBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: emoji != null
                  ? Text(emoji!, style: const TextStyle(fontSize: 26))
                  : Icon(icone, color: ativa ? Colors.white : kPrimary, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: ativa ? kPrimary : kTextSecondary,
                fontWeight: ativa ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplorarCard extends StatelessWidget {
  final _ExplorarInfo info;
  final VoidCallback onTap;

  const _ExplorarCard({required this.info, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: info.cor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.none,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 16,
              top: 14,
              right: 16,
              child: Text(
                info.titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
                ),
              ),
            ),
            Positioned(
              right: -6,
              bottom: -10,
              child: Text(info.emoji, style: const TextStyle(fontSize: 54)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProdutoCardPequeno extends StatelessWidget {
  final Produto produto;
  final VoidCallback onTap;

  const _ProdutoCardPequeno({required this.produto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 128,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                produto.isAcessorio ? Icons.local_mall_outlined : Icons.wine_bar_outlined,
                color: kPrimary,
                size: 20,
              ),
            ),
            const Spacer(),
            Text(
              produto.nome,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'R\$ ${produto.preco.toStringAsFixed(2)}',
              style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
