import 'package:flutter/foundation.dart';
import '../../catalogo/models/produto.dart';

/// Um item do carrinho: o produto, a quantidade escolhida e o preço unitário
/// no momento em que foi adicionado (evita que uma mudança de preço no
/// catálogo altere o valor de um item já no carrinho).
class ItemCarrinho {
  final Produto produto;
  int quantidade;
  final double precoUnit;

  ItemCarrinho({
    required this.produto,
    this.quantidade = 1,
    required this.precoUnit,
  });

  double get subtotal => precoUnit * quantidade;
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

  /// Adiciona o produto ao carrinho. Se já existir um item para o mesmo
  /// produto, apenas incrementa a quantidade em vez de duplicar a linha.
  void adicionar(Produto produto) {
    final index = _itens.indexWhere((i) => i.produto.id == produto.id);
    if (index >= 0) {
      _itens[index].quantidade++;
    } else {
      _itens.add(ItemCarrinho(produto: produto, precoUnit: produto.preco));
    }
    notifyListeners();
  }

  void remover(int index) {
    if (index < 0 || index >= _itens.length) return;
    _itens.removeAt(index);
    notifyListeners();
  }

  void incrementar(int index) {
    if (index < 0 || index >= _itens.length) return;
    _itens[index].quantidade++;
    notifyListeners();
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
