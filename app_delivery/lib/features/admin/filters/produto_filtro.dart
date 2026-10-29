import '../../catalogo/models/produto.dart';
import 'status_filtro.dart';
import 'texto_busca.dart';

enum TipoFiltro {
  todos('Todos'),
  vinhos('Vinhos'),
  acessorios('Acessórios');

  final String label;
  const TipoFiltro(this.label);
}

enum EstoqueFiltro {
  todos('Todos'),
  semEstoque('Sem estoque'),
  baixo('Estoque baixo (1 a 5)'),
  disponivel('Disponível (acima de 5)');

  final String label;
  const EstoqueFiltro(this.label);

  bool aceita(int estoque) => switch (this) {
        EstoqueFiltro.todos => true,
        EstoqueFiltro.semEstoque => estoque <= 0,
        EstoqueFiltro.baixo => estoque >= 1 && estoque <= 5,
        EstoqueFiltro.disponivel => estoque > 5,
      };
}

enum OrdenacaoProduto {
  maisRecentes('Mais recentes'),
  menorPreco('Menor preço'),
  maiorPreco('Maior preço'),
  nomeAZ('Nome A-Z'),
  menorEstoque('Menor estoque');

  final String label;
  const OrdenacaoProduto(this.label);
}

/// Categorias de [CategoriaProduto] com o rótulo exibido nos chips.
const categoriasProduto = {
  'VINHO_TINTO': 'Tinto',
  'VINHO_BRANCO': 'Branco',
  'VINHO_ROSE': 'Rosé',
  'VINHO_ESPUMANTE': 'Espumante',
  'VINHO_SOBREMESA': 'Sobremesa',
  'VINHO_ORGANICO': 'Orgânico',
  'VINHO_IMPORTADO': 'Importado',
};

/// Faixa [min, max] de preço dos produtos carregados, usada como limite do
/// RangeSlider. Arredonda para reais inteiros (para baixo/para cima).
({double min, double max}) faixaDePreco(List<Produto> produtos) {
  if (produtos.isEmpty) return (min: 0, max: 0);
  var min = produtos.first.preco, max = produtos.first.preco;
  for (final p in produtos) {
    if (p.preco < min) min = p.preco;
    if (p.preco > max) max = p.preco;
  }
  return (min: min.floorToDouble(), max: max.ceilToDouble());
}

/// Estado imutável dos filtros da tela de Produtos do admin. Toda a
/// filtragem é local, sobre a lista já carregada de /produtos/admin.
class ProdutoFiltro {
  final String busca;
  final StatusFiltro status;
  final TipoFiltro tipo;

  /// Categorias selecionadas; vazio significa todas.
  final Set<String> categorias;
  final EstoqueFiltro estoque;

  /// Limites de preço; `null` significa sem limite naquele lado.
  final double? precoMin;
  final double? precoMax;
  final OrdenacaoProduto ordenacao;

  const ProdutoFiltro({
    this.busca = '',
    this.status = StatusFiltro.todos,
    this.tipo = TipoFiltro.todos,
    this.categorias = const {},
    this.estoque = EstoqueFiltro.todos,
    this.precoMin,
    this.precoMax,
    this.ordenacao = OrdenacaoProduto.maisRecentes,
  });

  ProdutoFiltro copyWith({
    String? busca,
    StatusFiltro? status,
    TipoFiltro? tipo,
    Set<String>? categorias,
    EstoqueFiltro? estoque,
    OrdenacaoProduto? ordenacao,
  }) =>
      ProdutoFiltro(
        busca: busca ?? this.busca,
        status: status ?? this.status,
        tipo: tipo ?? this.tipo,
        categorias: categorias ?? this.categorias,
        estoque: estoque ?? this.estoque,
        precoMin: precoMin,
        precoMax: precoMax,
        ordenacao: ordenacao ?? this.ordenacao,
      );

  /// Define a faixa de preço; passar `null` remove o limite.
  ProdutoFiltro comPreco(double? min, double? max) => ProdutoFiltro(
        busca: busca,
        status: status,
        tipo: tipo,
        categorias: categorias,
        estoque: estoque,
        precoMin: min,
        precoMax: max,
        ordenacao: ordenacao,
      );

  /// Mantém busca e status, zerando apenas o que fica no painel "Filtros".
  ProdutoFiltro limparAvancados() => ProdutoFiltro(busca: busca, status: status);

  /// Categoria só se aplica quando o tipo permite vinhos.
  bool get categoriaVisivel => tipo != TipoFiltro.acessorios;

  bool get temFaixaPreco => precoMin != null || precoMax != null;

  /// Quantidade de opções do painel diferentes do padrão (badge do botão).
  int get avancadosAtivos => [
        tipo != TipoFiltro.todos,
        categoriaVisivel && categorias.isNotEmpty,
        estoque != EstoqueFiltro.todos,
        temFaixaPreco,
        ordenacao != OrdenacaoProduto.maisRecentes,
      ].where((a) => a).length;

  bool get temFiltroAtivo =>
      busca.trim().isNotEmpty || status != StatusFiltro.todos || avancadosAtivos > 0;

  List<Produto> aplicar(List<Produto> produtos) {
    final resultado = produtos
        .where((p) =>
            status.aceita(p.ativo) &&
            _aceitaBusca(p) &&
            _aceitaTipo(p) &&
            _aceitaCategoria(p) &&
            estoque.aceita(p.estoque) &&
            _aceitaPreco(p))
        .toList();
    resultado.sort(_comparar);
    return resultado;
  }

  bool _aceitaBusca(Produto p) {
    final t = normalizar(busca);
    if (t.isEmpty) return true;
    return [p.nome, p.descricao, p.paisOrigem, p.marca]
        .any((campo) => normalizar(campo).contains(t));
  }

  bool _aceitaTipo(Produto p) => switch (tipo) {
        TipoFiltro.todos => true,
        TipoFiltro.vinhos => p.isVinho,
        TipoFiltro.acessorios => p.isAcessorio,
      };

  bool _aceitaCategoria(Produto p) =>
      !categoriaVisivel || categorias.isEmpty || categorias.contains(p.categoria);

  bool _aceitaPreco(Produto p) =>
      (precoMin == null || p.preco >= precoMin!) &&
      (precoMax == null || p.preco <= precoMax!);

  int _comparar(Produto a, Produto b) {
    final r = switch (ordenacao) {
      OrdenacaoProduto.maisRecentes => 0,
      OrdenacaoProduto.menorPreco => a.preco.compareTo(b.preco),
      OrdenacaoProduto.maiorPreco => b.preco.compareTo(a.preco),
      OrdenacaoProduto.nomeAZ => normalizar(a.nome).compareTo(normalizar(b.nome)),
      OrdenacaoProduto.menorEstoque => a.estoque.compareTo(b.estoque),
    };
    // Desempate (e critério de "Mais recentes"): id decrescente.
    return r != 0 ? r : (b.id ?? 0).compareTo(a.id ?? 0);
  }
}
