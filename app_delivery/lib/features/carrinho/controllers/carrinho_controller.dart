import 'package:flutter/foundation.dart';
import '../../catalogo/models/produto.dart';

/// Um item do carrinho: o produto, a quantidade escolhida e o preço unitário
/// no momento em que foi adicionado (evita que uma mudança de preço no
/// catálogo altere o valor de um item já no carrinho).
class ItemCarrinho {
  /// Atualizado a cada nova adição, para o limite usar o estoque mais recente.
  Produto produto;
  int quantidade;
  final double precoUnit;

  ItemCarrinho({
    required this.produto,
    this.quantidade = 1,
    required this.precoUnit,
  });

  double get subtotal => precoUnit * quantidade;

  /// A quantidade já é igual ao estoque disponível: não dá para aumentar.
  bool get noLimiteDoEstoque => quantidade >= produto.estoque;
}

/// Estado do carrinho de compras, compartilhado por todo o app.
///
/// Singleton registrado com ChangeNotifierProvider em main.dart: qualquer
/// tela que precise ler ou alterar o carrinho consome a mesma instância via
/// Provider/Consumer, sem precisar passá-la manualmente entre widgets.
class CarrinhoController extends ChangeNotifier {
  CarrinhoController._();

  static final CarrinhoController instance = CarrinhoController._();

  final List<ItemCarrinho> _itens = [];

  List<ItemCarrinho> get itens => List.unmodifiable(_itens);

  /// Quantidade do produto já no carrinho (0 se não estiver).
  int quantidadeDe(Produto produto) {
    final index = _itens.indexWhere((i) => i.produto.id == produto.id);
    return index >= 0 ? _itens[index].quantidade : 0;
  }

  /// Ainda cabe mais uma unidade sem passar do estoque disponível.
  bool podeAdicionar(Produto produto) => quantidadeDe(produto) < produto.estoque;

  /// Adiciona o produto ao carrinho. Se já existir um item para o mesmo
  /// produto, apenas incrementa a quantidade em vez de duplicar a linha.
  /// Retorna false (sem alterar nada) se passaria do estoque disponível.
  bool adicionar(Produto produto) {
    if (!podeAdicionar(produto)) return false;
    final index = _itens.indexWhere((i) => i.produto.id == produto.id);
    if (index >= 0) {
      _itens[index]
        ..produto = produto
        ..quantidade += 1;
    } else {
      _itens.add(ItemCarrinho(produto: produto, precoUnit: produto.preco));
    }
    notifyListeners();
    return true;
  }

  void remover(int index) {
    if (index < 0 || index >= _itens.length) return;
    _itens.removeAt(index);
    notifyListeners();
  }

  /// Aumenta a quantidade em 1. Retorna false se já está no limite do estoque.
  bool incrementar(int index) {
    if (index < 0 || index >= _itens.length) return false;
    if (_itens[index].noLimiteDoEstoque) return false;
    _itens[index].quantidade++;
    notifyListeners();
    return true;
  }

  /// Decrementa a quantidade do item; se chegar a zero, remove o item.
  void decrementar(int index) {
    if (index < 0 || index >= _itens.length) return;
    _itens[index].quantidade--;
    if (_itens[index].quantidade <= 0) {
      _itens.removeAt(index);
    }
    notifyListeners();
  }

  void limpar() {
    _itens.clear();
    notifyListeners();
  }

  double get total => _itens.fold(0.0, (soma, item) => soma + item.subtotal);

  int get totalItens => _itens.fold(0, (soma, item) => soma + item.quantidade);
}
