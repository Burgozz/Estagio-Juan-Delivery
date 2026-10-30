import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:front_delivery/core/session/sessao_usuario.dart';
import 'package:front_delivery/features/carrinho/controllers/carrinho_controller.dart';
import 'package:front_delivery/features/carrinho/screens/carrinho_screen.dart';
import 'package:front_delivery/features/catalogo/models/produto.dart';

import '../../helpers/api_falsa.dart';

const _msgEstoque = 'Estoque insuficiente para Saca-rolhas. Disponível: 1';

final _vinho = Produto(id: 1, nome: 'Malbec', preco: 89.9, estoque: 5);
final _acessorio = Produto(id: 2, nome: 'Saca-rolhas', preco: 49.9, estoque: 5, tipo: 'ACESSORIO');

/// Backend falso: cria o pedido 5 e aceita os itens, exceto o produto [recusar].
http.Response Function(http.Request) _backend({int? recusar}) => (req) {
      final path = req.url.path;
      if (req.method == 'POST' && path == '/pedidos') return respostaJson({'id': 5}, 201);
      if (req.method == 'POST' && path == '/pedidos/5/itens') {
        final produtoId = jsonDecode(req.body)['produtoId'];
        if (produtoId == recusar) return respostaJson({'erro': _msgEstoque}, 400);
        return respostaJson({'id': produtoId}, 201);
      }
      if (req.method == 'PATCH') return respostaJson({'id': 5, 'status': 'CANCELADO'});
      return respostaJson({}, 404);
    };

Future<void> _abrirCarrinho(WidgetTester tester) async {
  usarTelaAlta(tester);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: CarrinhoController.instance,
      child: const MaterialApp(home: CarrinhoScreen()),
    ),
  );
}

void main() {
  final carrinho = CarrinhoController.instance;
  setUp(() {
    carrinho.limpar();
    SessaoUsuario.id = 9;
  });
  tearDown(() => SessaoUsuario.id = null);

  testWidgets('item recusado cancela o pedido, mostra a mensagem da API e mantém o carrinho', (tester) async {
    carrinho.adicionar(_vinho);
    carrinho.adicionar(_acessorio);
    carrinho.adicionar(_acessorio);
    final api = ApiFalsa(_backend(recusar: 2));
    await api.executar(() async {
      await _abrirCarrinho(tester);
      await tester.tap(find.text('FINALIZAR PEDIDO'));
      await tester.pumpAndSettle();
    });

    final patch = api.doMetodo('PATCH').single;
    expect(patch.url.path, '/pedidos/5/status');
    expect(patch.url.queryParameters['status'], 'CANCELADO');
    expect(find.text(_msgEstoque), findsOneWidget);
    expect(carrinho.itens.length, 2);
    expect(carrinho.quantidadeDe(_acessorio), 2);
    expect(find.byType(CarrinhoScreen), findsOneWidget); // continua no carrinho
    await tester.pump(const Duration(seconds: 6)); // deixa o SnackBar sair
  });

  testWidgets('pedido aceito limpa o carrinho e não cancela nada', (tester) async {
    carrinho.adicionar(_vinho);
    final api = ApiFalsa(_backend());
    await api.executar(() async {
      await _abrirCarrinho(tester);
      await tester.tap(find.text('FINALIZAR PEDIDO'));
      await tester.pumpAndSettle();
    });
    expect(api.doMetodo('PATCH'), isEmpty);
    expect(carrinho.itens, isEmpty);
    expect(find.text('Pedido Realizado!'), findsOneWidget);
  });

  testWidgets('botão + para no estoque disponível', (tester) async {
    carrinho.adicionar(Produto(id: 3, nome: 'Rosé', preco: 59.9, estoque: 2));
    await _abrirCarrinho(tester);
    final mais = find.byTooltip('Aumentar quantidade');
    await tester.tap(mais);
    await tester.pump();
    expect(carrinho.itens.single.quantidade, 2);
    expect(find.text('Máximo disponível: 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Estoque máximo atingido'));
    await tester.pump();
    expect(carrinho.itens.single.quantidade, 2);
  });
}
