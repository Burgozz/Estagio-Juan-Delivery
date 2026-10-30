import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:front_delivery/features/carrinho/controllers/carrinho_controller.dart';
import 'package:front_delivery/features/catalogo/screens/produto_detalhe_screen.dart';

import '../../helpers/api_falsa.dart';

Map<String, dynamic> _vinho({String? harmonizacao}) => {
      'id': 7,
      'nome': 'Malbec Reserva',
      'preco': 89.9,
      'tipo': 'VINHO',
      'estoque': 10,
      'ativo': true,
      'categoria': 'VINHO_TINTO',
      'paisOrigem': 'Argentina',
      'safra': 2020,
      'teorAlcool': 13.5,
      'harmonizacao': harmonizacao,
    };

Future<void> _abrirDetalhe(WidgetTester tester, Map<String, dynamic> produto) async {
  usarTelaAlta(tester);
  final api = ApiFalsa((_) => respostaJson(produto));
  await api.executar(() async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: CarrinhoController.instance,
        child: const MaterialApp(home: ProdutoDetalheScreen(id: 7)),
      ),
    );
    await tester.pumpAndSettle();
  });
}

void main() {
  setUp(CarrinhoController.instance.limpar);

  testWidgets('adicionar ao carrinho para no estoque disponível', (tester) async {
    await _abrirDetalhe(tester, {..._vinho(harmonizacao: 'Carnes vermelhas'), 'estoque': 2});
    final adicionar = find.widgetWithText(ElevatedButton, 'ADICIONAR AO CARRINHO');
    await tester.tap(adicionar);
    await tester.pump();
    await tester.tap(adicionar);
    await tester.pump();
    expect(CarrinhoController.instance.itens.single.quantidade, 2);
    expect(find.text('No carrinho: 2 de 2 disponível(is)'), findsOneWidget);

    final botao = find.widgetWithText(ElevatedButton, 'ESTOQUE MÁXIMO NO CARRINHO');
    expect(tester.widget<ElevatedButton>(botao).onPressed, isNull);
    await tester.tap(botao);
    await tester.pump();
    expect(CarrinhoController.instance.itens.single.quantidade, 2);
    await tester.pump(const Duration(seconds: 3)); // deixa o SnackBar sair
  });

  testWidgets('vinho com harmonização mostra a seção', (tester) async {
    await _abrirDetalhe(tester, _vinho(harmonizacao: 'Carnes vermelhas'));
    expect(find.text('Harmonização: '), findsOneWidget);
    expect(find.text('Carnes vermelhas'), findsOneWidget);
  });

  for (final semHarmonizacao in [null, '', '   ']) {
    testWidgets('vinho com harmonização ${semHarmonizacao == null ? 'null' : '"$semHarmonizacao"'} esconde a seção',
        (tester) async {
      await _abrirDetalhe(tester, _vinho(harmonizacao: semHarmonizacao));
      expect(find.text('Teor alcoólico: '), findsOneWidget); // a tela carregou
      expect(find.text('Harmonização: '), findsNothing);
    });
  }
}
