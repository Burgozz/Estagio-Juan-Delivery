import 'package:flutter_test/flutter_test.dart';
import 'package:front_delivery/features/carrinho/controllers/carrinho_controller.dart';
import 'package:front_delivery/features/catalogo/models/produto.dart';

Produto _produto({int id = 1, int estoque = 2}) => Produto(id: id, nome: 'Malbec', preco: 89.9, estoque: estoque);

void main() {
  final carrinho = CarrinhoController.instance;
  setUp(carrinho.limpar);

  test('adicionar respeita o estoque disponível', () {
    final p = _produto(estoque: 2);
    expect(carrinho.adicionar(p), isTrue);
    expect(carrinho.adicionar(p), isTrue);
    expect(carrinho.podeAdicionar(p), isFalse);
    expect(carrinho.adicionar(p), isFalse);
    expect(carrinho.quantidadeDe(p), 2);
    expect(carrinho.itens.single.noLimiteDoEstoque, isTrue);
  });

  test('incrementar para no estoque disponível', () {
    carrinho.adicionar(_produto(estoque: 2));
    expect(carrinho.incrementar(0), isTrue);
    expect(carrinho.incrementar(0), isFalse);
    expect(carrinho.itens.single.quantidade, 2);
  });

  test('produto sem estoque não entra no carrinho', () {
    expect(carrinho.adicionar(_produto(estoque: 0)), isFalse);
    expect(carrinho.itens, isEmpty);
  });

  test('nova adição usa o estoque mais recente do produto', () {
    carrinho.adicionar(_produto(estoque: 1));
    expect(carrinho.incrementar(0), isFalse);
    expect(carrinho.adicionar(_produto(estoque: 3)), isTrue); // estoque aumentou desde a primeira adição
    expect(carrinho.incrementar(0), isTrue);
    expect(carrinho.incrementar(0), isFalse);
    expect(carrinho.itens.single.quantidade, 3);
  });
}
